"""Desktop layout presets, written as Plasma desktop scripts.

The same generator produces:
  * the default layout of the FocusWave global theme (built into the ISO), and
  * the layouts the Customize app applies live (via org.kde.PlasmaShell.evaluateScript).

Presets
  mix      slim top bar (app menu, Focus Mode, tray, clock) + floating centered dock with Start
  mac      top bar with Start ("apple menu") + app menu, dock with Launchpad and Trash
  windows  one bottom taskbar: centered Start + apps, tray and clock on the right
"""
from __future__ import annotations

import json

OPACITY = {"adaptive": 0, "opaque": 1, "translucent": 2}

_JS = r"""
// FocusWave layout script (generated)
var fw = __CONFIG__;

var existing = panels();
for (var i = 0; i < existing.length; ++i) {
    existing[i].remove();
}

function setOpacity(panel) {
    if (fw.opacity === 0) {
        return;
    }
    try {
        var views = ConfigFile("plasmashellrc", "PlasmaViews");
        var cfg = ConfigFile(views, "Panel " + panel.id);
        cfg.writeEntry("panelOpacity", fw.opacity);
    } catch (e) {
        print("FocusWave: could not set panel opacity: " + e);
    }
}

function addStart(panel) {
    var start = panel.addWidget("org.kde.plasma.kickoff");
    start.currentConfigGroup = ["General"];
    start.writeConfig("icon", "focuswave-start");
    return start;
}

function addLaunchpad(panel) {
    var pad = panel.addWidget("org.kde.plasma.kickerdash");
    pad.currentConfigGroup = ["General"];
    pad.writeConfig("customButtonImage", "focuswave-launchpad");
    pad.writeConfig("useCustomButtonImage", true);
    return pad;
}

function addTasks(panel) {
    var tasks = panel.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("launchers", fw.launchers.join(","));
    return tasks;
}

function addStatus(panel, twoLineClock) {
    panel.addWidget("org.focuswave.focustoggle");
    panel.addWidget("org.kde.plasma.systemtray");
    var clock = panel.addWidget("org.kde.plasma.digitalclock");
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", true);
    if (twoLineClock) {
        clock.writeConfig("dateDisplayFormat", "BelowTime");
        clock.writeConfig("dateFormat", "shortDate");
    } else {
        clock.writeConfig("dateDisplayFormat", "BesideTime");
        clock.writeConfig("dateFormat", "custom");
        clock.writeConfig("customDateFormat", "ddd d MMM");
    }
    return clock;
}

function topBar(withStart) {
    var bar = new Panel("org.kde.panel");
    bar.location = "top";
    bar.height = fw.topBarHeight;
    bar.floating = false;
    bar.lengthMode = "fill";
    bar.hiding = "none";
    if (withStart) {
        addStart(bar);
    }
    bar.addWidget("org.kde.plasma.appmenu");
    bar.addWidget("org.kde.plasma.panelspacer");
    addStatus(bar, false);
    setOpacity(bar);
    return bar;
}

function dock(kind) {
    var d = new Panel("org.kde.panel");
    d.location = fw.dockPosition;
    d.height = fw.dockSize;
    d.floating = fw.dockFloating;
    d.lengthMode = "fit";
    d.alignment = "center";
    d.hiding = fw.dockHiding;
    if (kind === "mac") {
        addLaunchpad(d);
    } else {
        addStart(d);
    }
    addTasks(d);
    if (kind === "mac") {
        d.addWidget("org.kde.plasma.marginsseparator");
        d.addWidget("org.kde.plasma.trash");
    }
    if (!fw.topBar) {
        d.addWidget("org.kde.plasma.marginsseparator");
        addStatus(d, true);
    }
    setOpacity(d);
    return d;
}

function windowsTaskbar() {
    var bar = new Panel("org.kde.panel");
    bar.location = "bottom";
    bar.height = Math.max(40, Math.min(fw.dockSize, 56));
    bar.floating = fw.dockFloating;
    bar.lengthMode = "fill";
    bar.hiding = fw.dockHiding;
    bar.addWidget("org.kde.plasma.panelspacer");
    addStart(bar);
    addTasks(bar);
    bar.addWidget("org.kde.plasma.panelspacer");
    addStatus(bar, true);
    bar.addWidget("org.kde.plasma.showdesktop");
    setOpacity(bar);
    return bar;
}

if (fw.preset === "windows") {
    windowsTaskbar();
} else {
    if (fw.topBar) {
        topBar(fw.preset === "mac");
    }
    dock(fw.preset);
}
"""


def layout_config(state: dict) -> dict:
    layout = state.get("layout", {})
    preset = layout.get("preset", "mix")
    if preset not in ("mix", "mac", "windows"):
        preset = "mix"
    position = layout.get("dockPosition", "bottom")
    if position not in ("bottom", "left", "right"):
        position = "bottom"
    hiding = layout.get("dockHiding", "none")
    if hiding not in ("none", "dodgewindows", "autohide"):
        hiding = "none"
    return {
        "preset": preset,
        "topBar": bool(layout.get("topBar", True)),
        "topBarHeight": int(layout.get("topBarHeight", 30)),
        "dockSize": int(layout.get("dockSize", 54)),
        "dockPosition": position,
        "dockFloating": bool(layout.get("dockFloating", True)),
        "dockHiding": hiding,
        "opacity": OPACITY.get(layout.get("panelOpacity", "adaptive"), 0),
        "launchers": list(layout.get("launchers", [])),
    }


def layout_script(state: dict) -> str:
    return _JS.replace("__CONFIG__", json.dumps(layout_config(state), indent=4))
