"""FocusWave engine: turns the FocusWave settings into KDE Plasma settings.

Only uses tools that ship with Plasma 6 / systemd:
  kwriteconfig6, kreadconfig6, plasma-apply-colorscheme, busctl, /usr/libexec/plasma-changeicons
Everything is best-effort: a failing step is logged and the rest still runs.
"""
from __future__ import annotations

import glob
import json
import logging
import shutil
import subprocess
from datetime import datetime, time
from pathlib import Path

from . import layouts
from .state import normalize_hex, wallpaper_image

log = logging.getLogger("focuswave")

DECORATION_ID = "org.focuswave.decoration"
SPEED = {"instant": 0.0, "fast": 0.5, "normal": 0.75, "relaxed": 1.25}
OPEN_EFFECTS = ("scale", "fade", "glide")
MINIMIZE_EFFECTS = ("magiclamp", "squash")


# --------------------------------------------------------------------------- helpers

def run(cmd: list[str], timeout: int = 30) -> subprocess.CompletedProcess | None:
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.SubprocessError) as exc:
        log.warning("failed to run %s: %s", cmd[0], exc)
        return None
    if res.returncode != 0:
        log.warning("%s exited with %s: %s", " ".join(cmd[:3]), res.returncode, res.stderr.strip()[:300])
    return res


def kwrite(file: str, groups: list[str], key: str, value, notify: bool = False) -> None:
    cmd = ["kwriteconfig6", "--file", file]
    for g in groups:
        cmd += ["--group", g]
    cmd += ["--key", key]
    if isinstance(value, bool):
        cmd += ["--type", "bool"]
        value = "true" if value else "false"
    if notify:
        cmd.append("--notify")
    cmd.append(str(value))
    run(cmd)


def kdelete(file: str, groups: list[str], key: str) -> None:
    cmd = ["kwriteconfig6", "--file", file]
    for g in groups:
        cmd += ["--group", g]
    run(cmd + ["--key", key, "--delete"])


def kread(file: str, groups: list[str], key: str, default: str = "") -> str:
    cmd = ["kreadconfig6", "--file", file]
    for g in groups:
        cmd += ["--group", g]
    cmd += ["--key", key, "--default", default]
    res = run(cmd)
    return res.stdout.strip() if res and res.returncode == 0 else default


def dbus_call(service: str, path: str, iface: str, method: str, signature: str = "", *args) -> str:
    cmd = ["busctl", "--user", "call", service, path, iface, method]
    if signature:
        cmd.append(signature)
        cmd += [str(a) for a in args]
    res = run(cmd, timeout=60)
    return res.stdout if res and res.returncode == 0 else ""


def kwin_reconfigure() -> None:
    dbus_call("org.kde.KWin", "/KWin", "org.kde.KWin", "reconfigure")


def reconfigure_effect(name: str) -> None:
    dbus_call("org.kde.KWin", "/Effects", "org.kde.kwin.Effects", "reconfigureEffect", "s", name)


def notify_global_change(kind: int, arg: int = 0) -> None:
    # KGlobalSettings change types: 0 palette, 1 fonts, 2 style, 3 settings, 4 icons
    run(["busctl", "--user", "emit", "/KGlobalSettings", "org.kde.KGlobalSettings",
         "notifyChange", "ii", str(kind), str(arg)])


def plasma_script(js: str) -> str:
    return dbus_call("org.kde.plasmashell", "/PlasmaShell", "org.kde.PlasmaShell", "evaluateScript", "s", js)


def qt_font(family: str, size: int, weight: int = 400) -> str:
    return f"{family},{size},-1,5,{weight},0,0,0,0,0,0,0,0,0,0,1"


def parse_hhmm(value: str, fallback: time) -> time:
    try:
        h, m = value.strip().split(":")
        return time(int(h) % 24, int(m) % 60)
    except (ValueError, AttributeError):
        return fallback


def is_dark(state: dict, now: datetime | None = None) -> bool:
    mode = state.get("mode", "auto")
    if mode in ("light", "dark"):
        return mode == "dark"
    now_t = (now or datetime.now()).time()
    light = parse_hhmm(state.get("autoLight", "07:00"), time(7, 0))
    dark = parse_hhmm(state.get("autoDark", "19:00"), time(19, 0))
    if light < dark:
        return not (light <= now_t < dark)
    return dark <= now_t < light


def decoration_available() -> bool:
    patterns = [f"/usr/lib*/qt6/plugins/org.kde.kdecoration3/{DECORATION_ID}.so",
                f"/usr/lib/*/qt6/plugins/org.kde.kdecoration3/{DECORATION_ID}.so"]
    return any(glob.glob(p) for p in patterns)


# --------------------------------------------------------------------------- appliers

def apply_colors(state: dict) -> None:
    dark = is_dark(state)
    scheme = "FocusWaveDark" if dark else "FocusWaveLight"
    accent = normalize_hex(state.get("accent", "#6E5BFF"))
    current = kread("kdeglobals", ["General"], "ColorScheme")
    if current == scheme:
        run(["plasma-apply-colorscheme", "--accent-color", accent])
    else:
        run(["plasma-apply-colorscheme", "--accent-color", accent, scheme])
    apply_icons(dark)
    apply_lockscreen(state)


def apply_icons(dark: bool) -> None:
    theme = "Papirus-Dark" if dark else "Papirus"
    if not Path("/usr/share/icons", theme).is_dir():
        theme = "breeze-dark" if dark else "breeze"
    if kread("kdeglobals", ["Icons"], "Theme") == theme:
        return
    tool = "/usr/libexec/plasma-changeicons"
    if Path(tool).exists():
        run([tool, theme])
    else:
        kwrite("kdeglobals", ["Icons"], "Theme", theme, notify=True)
        notify_global_change(4, 0)


def apply_wallpaper(state: dict) -> None:
    wp = state.get("wallpaper") or "/usr/share/wallpapers/FocusWave-Wave"
    if not Path(wp).exists():
        log.warning("wallpaper %s not found", wp)
        return
    uri = Path(wp).as_uri()
    js = (
        "var ds = desktops();"
        "for (var i = 0; i < ds.length; ++i) {"
        "  var d = ds[i];"
        "  d.wallpaperPlugin = 'org.kde.image';"
        "  d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];"
        f"  d.writeConfig('Image', {json.dumps(uri)});"
        "}"
    )
    plasma_script(js)
    apply_lockscreen(state)


def apply_lockscreen(state: dict) -> None:
    wp = state.get("wallpaper") or "/usr/share/wallpapers/FocusWave-Wave"
    if not Path(wp).exists():
        return
    lock_uri = Path(wallpaper_image(wp, is_dark(state))).as_uri()
    for key in ("Image", "PreviewImage"):
        kwrite("kscreenlockerrc", ["Greeter", "Wallpaper", "org.kde.image", "General"], key, lock_uri)


def apply_buttons(state: dict) -> None:
    style = state.get("buttons", "mac")
    if style == "mac" and decoration_available():
        library, theme, left, right = DECORATION_ID, "", "XIA", ""
    elif style == "mac":
        library, theme, left, right = "org.kde.breeze", "Breeze", "XIA", ""
    else:
        library, theme, left, right = "org.kde.breeze", "Breeze", "", "IAX"
    group = ["org.kde.kdecoration2"]
    kwrite("kwinrc", group, "library", library)
    kwrite("kwinrc", group, "theme", theme)
    kwrite("kwinrc", group, "ButtonsOnLeft", left)
    kwrite("kwinrc", group, "ButtonsOnRight", right)
    kwin_reconfigure()


def apply_windows(state: dict) -> None:
    w = state.get("windows", {})
    opening = w.get("openAnimation", "scale")
    for eff in OPEN_EFFECTS:
        kwrite("kwinrc", ["Plugins"], f"{eff}Enabled", eff == opening)
    minimize = w.get("minimizeAnimation", "magiclamp")
    for eff in MINIMIZE_EFFECTS:
        kwrite("kwinrc", ["Plugins"], f"{eff}Enabled", eff == minimize)
    kwrite("kwinrc", ["Plugins"], "wobblywindowsEnabled", bool(w.get("wobbly", False)))
    kwrite("kwinrc", ["Plugins"], "blurEnabled", True)
    kwrite("kwinrc", ["Effect-blur"], "BlurStrength", max(1, min(15, int(w.get("blurStrength", 10)))))
    kwrite("kwinrc", ["Effect-blur"], "NoiseStrength", 0)
    speed = SPEED.get(w.get("speed", "normal"), 0.75)
    kwrite("kdeglobals", ["KDE"], "AnimationDurationFactor", speed, notify=True)
    kwin_reconfigure()
    reconfigure_effect("blur")


def apply_fonts(state: dict) -> None:
    f = state.get("font", {})
    family = f.get("family") or "Inter"
    size = max(7, min(20, int(f.get("size", 10))))
    mono = f.get("mono") or "JetBrains Mono"
    kwrite("kdeglobals", ["General"], "font", qt_font(family, size), notify=True)
    kwrite("kdeglobals", ["General"], "menuFont", qt_font(family, size), notify=True)
    kwrite("kdeglobals", ["General"], "toolBarFont", qt_font(family, max(7, size - 1)), notify=True)
    kwrite("kdeglobals", ["General"], "smallestReadableFont", qt_font(family, max(7, size - 2)), notify=True)
    kwrite("kdeglobals", ["General"], "fixed", qt_font(mono, size), notify=True)
    kwrite("kdeglobals", ["WM"], "activeFont", qt_font(family, size, 600), notify=True)
    notify_global_change(1, 0)
    kwin_reconfigure()


def apply_focus(state: dict) -> None:
    f = state.get("focus", {})
    group = ["FocusMode"]
    kwrite("focuswaverc", group, "BlurStrength", max(1, min(15, int(f.get("blur", 12)))))
    kwrite("focuswaverc", group, "Dim", max(0, min(80, int(f.get("dim", 20)))))
    kwrite("focuswaverc", group, "KeepDockVisible", bool(f.get("keepDock", True)))
    kwrite("focuswaverc", group, "FollowActivation", bool(f.get("follow", True)))
    kwrite("focuswaverc", group, "Fade", bool(f.get("fade", True)))
    kwrite("focuswaverc", group, "FadeMs", max(0, min(1000, int(f.get("fadeMs", 220)))))


def restart_plasmashell() -> None:
    if shutil.which("systemctl"):
        res = run(["systemctl", "--user", "restart", "plasma-plasmashell.service"], timeout=60)
        if res and res.returncode == 0:
            return
    run(["kquitapp6", "plasmashell"])
    subprocess.Popen(["plasmashell"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def apply_layout(state: dict) -> None:
    plasma_script(layouts.layout_script(state))
    if state.get("layout", {}).get("panelOpacity", "adaptive") != "adaptive":
        restart_plasmashell()  # panel opacity is only read when Plasma starts


CATEGORIES = {
    "colors": apply_colors,
    "wallpaper": apply_wallpaper,
    "buttons": apply_buttons,
    "windows": apply_windows,
    "fonts": apply_fonts,
    "focus": apply_focus,
    "layout": apply_layout,
}

# Which category a top-level settings key belongs to
KEY_CATEGORY = {
    "mode": "colors", "autoLight": "colors", "autoDark": "colors", "accent": "colors",
    "wallpaper": "wallpaper", "buttons": "buttons", "windows": "windows",
    "font": "fonts", "focus": "focus", "layout": "layout",
}


def apply(state: dict, categories) -> None:
    for name in categories:
        fn = CATEGORIES.get(name)
        if not fn:
            continue
        try:
            fn(state)
        except Exception:  # keep going: one broken step must not stop the rest
            log.exception("applying %s failed", name)


def apply_all(state: dict, with_layout: bool = True) -> None:
    order = ["colors", "wallpaper", "buttons", "windows", "fonts", "focus"]
    if with_layout:
        order.append("layout")
    apply(state, order)


def apply_auto(state: dict) -> bool:
    """Called by the timer and at login: switch light/dark when it is time. Returns True if changed."""
    if state.get("mode") != "auto":
        return False
    wanted = "FocusWaveDark" if is_dark(state) else "FocusWaveLight"
    if kread("kdeglobals", ["General"], "ColorScheme") == wanted:
        return False
    apply_colors(state)
    return True
