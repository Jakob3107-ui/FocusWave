"""FocusWave settings: defaults, load/save, saved themes, import/export.

The whole look of FocusWave is described by one small JSON document
(~/.config/focuswave/state.json). The engine turns it into KDE settings.
A "theme" is just a saved copy of that document (plus a custom wallpaper, if any).
"""
from __future__ import annotations

import copy
import json
import os
import re
import shutil
import tempfile
import zipfile
from pathlib import Path

HOME = Path.home()
CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME") or HOME / ".config")
DATA_HOME = Path(os.environ.get("XDG_DATA_HOME") or HOME / ".local" / "share")
CONFIG_DIR = CONFIG_HOME / "focuswave"
STATE_FILE = CONFIG_DIR / "state.json"
WELCOME_FLAG = CONFIG_DIR / "welcome-done"
THEMES_DIR = DATA_HOME / "focuswave" / "themes"
SYSTEM_WALLPAPERS = Path("/usr/share/wallpapers")
USER_WALLPAPERS = DATA_HOME / "wallpapers"

DEFAULT_LAUNCHERS = [
    "preferred://browser",          # the default browser (Zen; Firefox if Zen is missing)
    "applications:org.kde.dolphin.desktop",
    "applications:org.kde.discover.desktop",
    "applications:org.focuswave.Customize.desktop",
    "applications:systemsettings.desktop",
]

DEFAULTS: dict = {
    "version": 1,
    "mode": "auto",            # light | dark | auto
    "autoLight": "07:00",      # auto mode: light from this time...
    "autoDark": "19:00",       # ...dark from this time
    "accent": "#6E5BFF",
    "wallpaper": "/usr/share/wallpapers/FocusWave-Wave",
    "buttons": "mac",          # mac (traffic lights, left) | windows (right)
    "layout": {
        "preset": "mix",       # mix | mac | windows
        "topBar": True,
        "topBarHeight": 30,
        "dockSize": 54,
        "dockPosition": "bottom",   # bottom | left | right
        "dockFloating": True,
        "dockHiding": "none",       # none | dodgewindows | autohide
        "panelOpacity": "adaptive",  # adaptive | translucent | opaque
        "launchers": DEFAULT_LAUNCHERS,
    },
    "windows": {
        "openAnimation": "scale",        # scale | fade | glide | none
        "minimizeAnimation": "magiclamp",  # magiclamp | squash | none
        "wobbly": False,
        "speed": "normal",               # instant | fast | normal | relaxed
        "blurStrength": 10,              # 1..15 (panels, menus, translucent windows)
    },
    "font": {"family": "Inter", "size": 10, "mono": "JetBrains Mono"},
    "focus": {
        "blur": 12,            # 1..15
        "dim": 20,             # 0..80 %
        "keepDock": True,
        "follow": True,
        "fade": True,
        "fadeMs": 220,
    },
}

PRESET_BUTTONS = {"mix": "mac", "mac": "mac", "windows": "windows"}

HEX_RE = re.compile(r"^#?([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$")


def normalize_hex(value: str, fallback: str = DEFAULTS["accent"]) -> str:
    """Accept '#rrggbb', 'rrggbb' or Qt's '#aarrggbb' and return '#RRGGBB'."""
    if not isinstance(value, str):
        return fallback
    v = value.strip()
    m = re.match(r"^#([0-9a-fA-F]{8})$", v)
    if m:  # Qt writes #AARRGGBB
        return "#" + m.group(1)[2:].upper()
    m = HEX_RE.match(v)
    return ("#" + m.group(1).upper()) if m else fallback


def deep_merge(base: dict, override: dict) -> dict:
    out = copy.deepcopy(base)
    for key, value in (override or {}).items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], value)
        elif key in out or key in ("name",):
            out[key] = copy.deepcopy(value)
    return out


def _coerce(default, value):
    """Keep JSON types stable (QML sliders send floats for int settings)."""
    if isinstance(default, bool):
        return bool(value)
    if isinstance(default, int) and not isinstance(default, bool):
        try:
            return int(round(float(value)))
        except (TypeError, ValueError):
            return default
    if isinstance(default, str):
        return str(value)
    return value


def get_path(state: dict, path: str):
    node = state
    for part in path.split("."):
        node = node[part]
    return node


def set_path(state: dict, path: str, value) -> None:
    parts = path.split(".")
    node, default = state, DEFAULTS
    for part in parts[:-1]:
        node = node.setdefault(part, {})
        default = default.get(part, {}) if isinstance(default, dict) else {}
    key = parts[-1]
    if isinstance(default, dict) and key in default:
        value = _coerce(default[key], value)
    if path == "accent":
        value = normalize_hex(value)
    node[key] = value


def load() -> dict:
    try:
        data = json.loads(STATE_FILE.read_text())
    except (OSError, ValueError):
        data = {}
    return deep_merge(DEFAULTS, data)


def save(state: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state, indent=2))
    tmp.replace(STATE_FILE)


def defaults() -> dict:
    return copy.deepcopy(DEFAULTS)


# --------------------------------------------------------------------------- wallpapers

def _package_entry(pkg: Path) -> dict | None:
    contents = pkg / "contents"
    images = contents / "images"
    if not images.is_dir():
        return None
    name = pkg.name
    try:
        meta = json.loads((pkg / "metadata.json").read_text())
        name = meta.get("KPlugin", {}).get("Name", name)
    except (OSError, ValueError):
        pass
    thumb = contents / "screenshot.png"
    if not thumb.exists():
        pics = sorted(images.glob("*"))
        thumb = pics[0] if pics else thumb
    thumb_dark = contents / "screenshot_dark.png"
    if not thumb_dark.exists():
        dark_dir = contents / "images_dark"
        pics = sorted(dark_dir.glob("*")) if dark_dir.is_dir() else []
        thumb_dark = pics[0] if pics else thumb
    return {"path": str(pkg), "name": name, "thumb": thumb.as_uri() if thumb.exists() else "",
            "thumbDark": thumb_dark.as_uri() if thumb_dark.exists() else ""}


def list_wallpapers(current: str | None = None) -> list[dict]:
    entries, seen = [], set()
    for root in (SYSTEM_WALLPAPERS, USER_WALLPAPERS):
        if not root.is_dir():
            continue
        pkgs = sorted(root.iterdir(), key=lambda p: (not p.name.startswith("FocusWave"), p.name.lower()))
        for pkg in pkgs:
            if pkg.is_dir() and pkg.name not in seen:
                entry = _package_entry(pkg)
                if entry:
                    seen.add(pkg.name)
                    entries.append(entry)
    if current and Path(current).is_file():
        uri = Path(current).as_uri()
        entries.append({"path": current, "name": Path(current).stem, "thumb": uri, "thumbDark": uri})
    return entries


def wallpaper_image(path: str, dark: bool) -> str:
    """Pick a concrete image file for a wallpaper (package dir or file)."""
    p = Path(path)
    if p.is_file():
        return str(p)
    for sub in (("images_dark", "images") if dark else ("images",)):
        d = p / "contents" / sub
        if d.is_dir():
            pics = sorted(d.glob("*"), key=lambda f: f.stat().st_size, reverse=True)
            if pics:
                return str(pics[0])
    return str(p)


# --------------------------------------------------------------------------- themes

def _slug(name: str) -> str:
    s = re.sub(r"[^A-Za-z0-9_-]+", "-", name.strip()).strip("-")
    return s or "theme"


def list_themes() -> list[dict]:
    out = []
    if THEMES_DIR.is_dir():
        for d in sorted(THEMES_DIR.iterdir()):
            f = d / "theme.json"
            if f.is_file():
                try:
                    data = json.loads(f.read_text())
                except (OSError, ValueError):
                    continue
                out.append({
                    "id": d.name,
                    "name": data.get("name", d.name),
                    "accent": data.get("accent", DEFAULTS["accent"]),
                    "mode": data.get("mode", "auto"),
                    "preset": data.get("layout", {}).get("preset", "mix"),
                    "wallpaper": data.get("wallpaper", ""),
                })
    return out


def save_theme(name: str, state: dict) -> str:
    slug = _slug(name)
    target = THEMES_DIR / slug
    target.mkdir(parents=True, exist_ok=True)
    data = copy.deepcopy(state)
    data["name"] = name
    wp = Path(data.get("wallpaper", ""))
    if wp.is_file() and target not in wp.parents:  # keep a copy of custom wallpapers
        dest = target / ("wallpaper" + wp.suffix.lower())
        shutil.copy2(wp, dest)
        data["wallpaper"] = str(dest)
    (target / "theme.json").write_text(json.dumps(data, indent=2))
    return slug


def load_theme(theme_id: str) -> dict:
    data = json.loads((THEMES_DIR / theme_id / "theme.json").read_text())
    return deep_merge(DEFAULTS, data)


def delete_theme(theme_id: str) -> None:
    d = THEMES_DIR / theme_id
    if d.is_dir() and THEMES_DIR in d.parents:
        shutil.rmtree(d)


def export_theme(state: dict, dest: str, name: str = "My FocusWave theme") -> str:
    """Write a .fwtheme file (a zip with theme.json and, if custom, the wallpaper)."""
    dest_path = Path(dest)
    if dest_path.suffix != ".fwtheme":
        dest_path = dest_path.with_suffix(".fwtheme")
    data = copy.deepcopy(state)
    data["name"] = data.get("name") or name
    with zipfile.ZipFile(dest_path, "w", zipfile.ZIP_DEFLATED) as z:
        wp = Path(data.get("wallpaper", ""))
        if wp.is_file():
            arc = "wallpaper" + wp.suffix.lower()
            z.write(wp, arc)
            data["wallpaper"] = arc
        z.writestr("theme.json", json.dumps(data, indent=2))
    return str(dest_path)


def import_theme(src: str) -> str:
    """Import a .fwtheme (or plain theme .json) and return the saved theme id."""
    src_path = Path(src)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        if zipfile.is_zipfile(src_path):
            with zipfile.ZipFile(src_path) as z:
                for member in z.namelist():
                    if member == "theme.json" or member.startswith("wallpaper."):
                        z.extract(member, tmp_path)
            data = json.loads((tmp_path / "theme.json").read_text())
        else:
            data = json.loads(src_path.read_text())
        name = data.get("name") or src_path.stem
        merged = deep_merge(DEFAULTS, data)
        merged["name"] = name
        wp = merged.get("wallpaper", "")
        if wp.startswith("wallpaper.") and (tmp_path / wp).is_file():
            merged["wallpaper"] = str(tmp_path / wp)
        elif not Path(wp).exists():
            merged["wallpaper"] = DEFAULTS["wallpaper"]
        return save_theme(name, merged)
