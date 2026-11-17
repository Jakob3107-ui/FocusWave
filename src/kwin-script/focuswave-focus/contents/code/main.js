/*
 * FocusWave Focus Mode — KWin script (Plasma 6, Wayland)
 *
 * How it works
 *   1. You pick a window (Meta+F, the window's right-click menu, or the top-bar toggle).
 *   2. The helper `focuswave-focus-overlay` (D-Bus: org.focuswave.FocusMode) opens one
 *      transparent full-screen "overlay" window per screen. Each overlay asks KWin for
 *      blur-behind, so KWin's own GPU blur (the same one used for panels) blurs
 *      everything underneath it.
 *   3. This script keeps the overlay directly underneath your chosen window:
 *        - the chosen window (and its dialogs) get "keep above",
 *        - the overlay sits on top of every other window.
 *   4. Turning it off fades the overlay out and restores everything.
 *
 * The helper also provides a tiny "Wait" D-Bus method that this script uses as a timer
 * for the fade animation (KWin scripts have no setTimeout).
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

const SERVICE = "org.focuswave.FocusMode";
const OBJECT_PATH = "/FocusMode";
const IFACE = "org.focuswave.FocusMode";
const OVERLAY_PREFIX = "FocusWave Overlay";
const SHORTCUT_NAME = "FocusWave Focus Mode";

const state = {
    active: false,
    target: null,          // the window the user is focusing on
    sharp: [],             // [{ win, keepAbove }] windows kept un-blurred (target + its dialogs)
    overlays: [],          // overlay windows currently on screen
    settings: {
        keepDock: true,    // panels (dock + top bar) stay sharp and usable
        follow: true,      // switching apps (Alt+Tab, dock) moves the focus to that app
        fade: true,
        fadeMs: 220
    },
    fadeToken: 0,
    targetMinimizedHandler: null
};

function log(msg) {
    print("[FocusWave] " + msg);
}

// ---------------------------------------------------------------------------
// Window helpers
// ---------------------------------------------------------------------------

function isOverlay(w) {
    return !!w && typeof w.caption === "string" && w.caption.indexOf(OVERLAY_PREFIX) === 0;
}

function alive(w) {
    return !!w && !w.deleted;
}

function isCandidate(w) {
    if (!alive(w) || isOverlay(w)) {
        return false;
    }
    if (w.desktopWindow || w.dock || w.popupWindow) {
        return false;
    }
    return !!(w.normalWindow || w.dialog);
}

function relatedTo(w, t) {
    if (!alive(w) || !alive(t)) {
        return false;
    }
    if (w === t) {
        return true;
    }
    // Dialogs that belong to the focused window
    let parent = w.transient ? w.transientFor : null;
    for (let depth = 0; parent && depth < 8; depth++) {
        if (parent === t) {
            return true;
        }
        parent = parent.transient ? parent.transientFor : null;
    }
    // Other windows of the same app (e.g. a file picker)
    return w.pid > 0 && w.pid === t.pid;
}

function isSharp(w) {
    return state.sharp.some(function (s) { return s.win === w; });
}

function raise(w) {
    if (alive(w) && typeof workspace.raiseWindow === "function") {
        workspace.raiseWindow(w);
    }
}

function keepSharp(w) {
    if (!alive(w) || isSharp(w)) {
        return;
    }
    state.sharp.push({ win: w, keepAbove: w.keepAbove });
    w.keepAbove = true;
    raise(w);
}

function releaseSharp() {
    for (const s of state.sharp) {
        if (alive(s.win)) {
            s.win.keepAbove = s.keepAbove;
        }
    }
    state.sharp = [];
}

function outputByName(name) {
    const screens = workspace.screens || [];
    for (const s of screens) {
        if (s.name === name) {
            return s;
        }
    }
    return null;
}

function configureOverlay(o) {
    o.skipTaskbar = true;
    o.skipSwitcher = true;
    o.skipPager = true;
    o.onAllDesktops = true;
    o.noBorder = true;
    o.skipsCloseAnimation = true;
    const name = o.caption.substring(OVERLAY_PREFIX.length).trim();
    const out = outputByName(name) || o.output;
    if (out) {
        o.frameGeometry = out.geometry;
    }
}

// ---------------------------------------------------------------------------
// Stacking: other windows < overlay < sharp windows
// ---------------------------------------------------------------------------

function applyStacking() {
    if (!state.active) {
        return;
    }
    for (const o of state.overlays) {
        if (alive(o)) {
            // keepDock: overlay stays in the normal layer, so panels (dock layer) stay on top.
            // otherwise the overlay goes into the "above" layer and covers the panels too.
            o.keepAbove = !state.settings.keepDock;
            raise(o);
        }
    }
    for (const s of state.sharp) {
        raise(s.win);
    }
    if (alive(state.target) && workspace.activeWindow !== state.target && !isSharp(workspace.activeWindow)) {
        workspace.activeWindow = state.target;
    }
}

// ---------------------------------------------------------------------------
// Fade animation (opacity steps, timed with the helper's Wait method)
// ---------------------------------------------------------------------------

function easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
}

function fade(windows, from, to, done) {
    const token = ++state.fadeToken;
    const list = windows.slice();
    const apply = function (v) {
        for (const w of list) {
            if (alive(w)) {
                w.opacity = v;
            }
        }
    };
    if (!state.settings.fade || state.settings.fadeMs <= 0) {
        apply(to);
        if (done) {
            done();
        }
        return;
    }
    const steps = Math.max(2, Math.round(state.settings.fadeMs / 16));
    let i = 0;
    apply(from);
    const step = function () {
        if (token !== state.fadeToken) {
            return; // a newer animation took over
        }
        i++;
        apply(from + (to - from) * easeOutCubic(i / steps));
        if (i < steps) {
            callDBus(SERVICE, OBJECT_PATH, IFACE, "Wait", "16", step);
        } else if (done) {
            done();
        }
    };
    callDBus(SERVICE, OBJECT_PATH, IFACE, "Wait", "16", step);
}

// ---------------------------------------------------------------------------
// Target tracking
// ---------------------------------------------------------------------------

function watchTarget(w) {
    unwatchTarget();
    if (!alive(w)) {
        return;
    }
    state.targetMinimizedHandler = function () {
        if (state.active && alive(w) && w.minimized && w === state.target) {
            disable(true);
        }
    };
    w.minimizedChanged.connect(state.targetMinimizedHandler);
}

function unwatchTarget() {
    if (state.targetMinimizedHandler && alive(state.target)) {
        try {
            state.target.minimizedChanged.disconnect(state.targetMinimizedHandler);
        } catch (e) {
            // window already gone
        }
    }
    state.targetMinimizedHandler = null;
}

function setTarget(w) {
    releaseSharp();
    state.target = w;
    watchTarget(w);
    keepSharp(w);
}

// ---------------------------------------------------------------------------
// On / off
// ---------------------------------------------------------------------------

function applySettings(json) {
    try {
        const s = JSON.parse(json);
        if (typeof s.keepDock === "boolean") state.settings.keepDock = s.keepDock;
        if (typeof s.follow === "boolean") state.settings.follow = s.follow;
        if (typeof s.fade === "boolean") state.settings.fade = s.fade;
        if (typeof s.fadeMs === "number") state.settings.fadeMs = s.fadeMs;
    } catch (e) {
        log("could not read settings: " + e);
    }
}

function enable() {
    const t = workspace.activeWindow;
    if (!isCandidate(t)) {
        log("nothing to focus (active window is not a normal window)");
        return;
    }
    state.fadeToken++; // cancel a fade-out that is still running, so it can't undo this session
    state.active = true;
    setTarget(t);
    callDBus(SERVICE, OBJECT_PATH, IFACE, "Show", function (json) {
        applySettings(json);
        applyStacking();
    });
}

function disable(animated) {
    if (!state.active) {
        return;
    }
    state.active = false;
    unwatchTarget();
    state.target = null;
    const overlays = state.overlays.filter(alive);
    const finish = function () {
        releaseSharp();
        callDBus(SERVICE, OBJECT_PATH, IFACE, "Hide");
    };
    if (animated && overlays.length > 0) {
        fade(overlays, overlays[0].opacity, 0, finish);
    } else {
        finish();
    }
}

function toggle() {
    if (state.active) {
        disable(true);
    } else {
        enable();
    }
}

// ---------------------------------------------------------------------------
// Workspace signals
// ---------------------------------------------------------------------------

workspace.windowAdded.connect(function (w) {
    if (!isOverlay(w)) {
        return;
    }
    w.opacity = 0; // invisible until positioned and stacked
    state.overlays.push(w);
    configureOverlay(w);
    if (!state.active) {
        callDBus(SERVICE, OBJECT_PATH, IFACE, "Hide"); // stray overlay
        return;
    }
    applyStacking();
    fade(state.overlays, 0, 1);
});

workspace.windowRemoved.connect(function (w) {
    const i = state.overlays.indexOf(w);
    if (i >= 0) {
        state.overlays.splice(i, 1);
    }
    if (state.active && w === state.target) {
        disable(true); // the focused window was closed
        return;
    }
    state.sharp = state.sharp.filter(function (s) { return s.win !== w; });
});

workspace.windowActivated.connect(function (w) {
    if (!state.active || !w) {
        return;
    }
    if (isOverlay(w)) {
        // Clicking the blurred area must not hide the focused window.
        if (alive(state.target)) {
            workspace.activeWindow = state.target;
        }
        return;
    }
    if (isSharp(w) || !isCandidate(w)) {
        return;
    }
    if (relatedTo(w, state.target)) {
        keepSharp(w);
        return;
    }
    if (state.settings.follow) {
        setTarget(w);
        applyStacking();
    } else if (alive(state.target)) {
        workspace.activeWindow = state.target;
    }
});

workspace.currentDesktopChanged.connect(function () {
    if (state.active) {
        disable(true);
    }
});

workspace.screensChanged.connect(function () {
    if (state.active) {
        // Re-create overlays for the new screen layout.
        callDBus(SERVICE, OBJECT_PATH, IFACE, "Show", function (json) {
            applySettings(json);
            applyStacking();
        });
    }
});

// ---------------------------------------------------------------------------
// Entry points
// ---------------------------------------------------------------------------

registerShortcut(SHORTCUT_NAME, "FocusWave: Toggle Focus Mode", "Meta+F", toggle);

registerUserActionsMenu(function (w) {
    if (!isCandidate(w)) {
        return {};
    }
    const focused = state.active && isSharp(w);
    const label = "Focus Mode (blur everything else)";
    return {
        text: label,
        title: label,
        checkable: true,
        checked: focused,
        triggered: function () {
            if (focused) {
                disable(true);
                return;
            }
            if (state.active) {
                disable(false);
            }
            workspace.activeWindow = w;
            enable();
        }
    };
});

log("loaded");
