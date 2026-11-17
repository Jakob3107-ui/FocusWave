#!/usr/bin/env bash
# Install FocusWave's non-compiled files (Python app, themes, scripts, defaults).
# Used by the RPM spec:  tools/install-files.sh "$DESTDIR"
# The C++ parts are installed separately with `cmake --install`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTDIR="${1:?usage: install-files.sh DESTDIR}"
PREFIX=/usr
DATA="$DESTDIR$PREFIX/share"

copy_tree() { # copy_tree SRC DEST  (contents of SRC into DEST, no caches)
    install -d "$2"
    cp -a "$1/." "$2/"
    find "$2" -name '__pycache__' -prune -exec rm -rf {} + 2>/dev/null || true
    find "$2" -type d -exec chmod 755 {} +
    find "$2" -type f -exec chmod 644 {} +
}

# Python engine + Customize app
copy_tree "$ROOT/src/customize/focuswave" "$DATA/focuswave/python/focuswave"
install -Dm755 "$ROOT/data/bin/focuswave-customize" "$DESTDIR$PREFIX/bin/focuswave-customize"
install -Dm755 "$ROOT/data/bin/focuswave-theme" "$DESTDIR$PREFIX/bin/focuswave-theme"
install -Dm644 "$ROOT/data/applications/org.focuswave.Customize.desktop" "$DATA/applications/org.focuswave.Customize.desktop"

# Autostart (welcome tour once, session setup every login)
install -Dm644 "$ROOT/data/autostart/org.focuswave.Welcome.desktop" "$DESTDIR/etc/xdg/autostart/org.focuswave.Welcome.desktop"
install -Dm644 "$ROOT/data/autostart/org.focuswave.Session.desktop" "$DESTDIR/etc/xdg/autostart/org.focuswave.Session.desktop"

# Automatic light/dark timer, enabled for every user
install -Dm644 "$ROOT/data/systemd/focuswave-auto-theme.service" "$DESTDIR$PREFIX/lib/systemd/user/focuswave-auto-theme.service"
install -Dm644 "$ROOT/data/systemd/focuswave-auto-theme.timer" "$DESTDIR$PREFIX/lib/systemd/user/focuswave-auto-theme.timer"
install -d "$DESTDIR$PREFIX/lib/systemd/user/timers.target.wants"
ln -sf ../focuswave-auto-theme.timer "$DESTDIR$PREFIX/lib/systemd/user/timers.target.wants/focuswave-auto-theme.timer"

# Focus Mode: KWin script + panel toggle
copy_tree "$ROOT/src/kwin-script/focuswave-focus" "$DATA/kwin/scripts/focuswave-focus"
copy_tree "$ROOT/src/plasmoid/org.focuswave.focustoggle" "$DATA/plasma/plasmoids/org.focuswave.focustoggle"

# Global theme; its default layout is generated from the same code the Customize app uses
LNF="$DATA/plasma/look-and-feel/org.focuswave.desktop"
copy_tree "$ROOT/theme/look-and-feel/org.focuswave.desktop" "$LNF"
TMPHOME="$(mktemp -d)"
env -u XDG_CONFIG_HOME -u XDG_DATA_HOME HOME="$TMPHOME" PYTHONPATH="$ROOT/src/customize" \
    python3 -m focuswave.cli layout-js mix > "$LNF/contents/layouts/org.kde.plasma.desktop-layout.js"
rm -rf "$TMPHOME"
install -Dm644 "$ROOT/theme/wallpapers/FocusWave-Wave/contents/screenshot.png" "$LNF/contents/previews/preview.png"
install -Dm644 "$ROOT/theme/wallpapers/FocusWave-Wave/contents/images/2560x1600.jpg" "$LNF/contents/previews/fullscreenpreview.jpg"

# Colors, wallpapers, icons
for scheme in "$ROOT"/theme/color-schemes/*.colors; do
    install -Dm644 "$scheme" "$DATA/color-schemes/$(basename "$scheme")"
done
for wp in "$ROOT"/theme/wallpapers/FocusWave-*; do
    copy_tree "$wp" "$DATA/wallpapers/$(basename "$wp")"
done
for icon in "$ROOT"/theme/icons/*.svg; do
    install -Dm644 "$icon" "$DATA/icons/hicolor/scalable/apps/$(basename "$icon")"
done

# System-wide defaults, loaded at login via XDG_CONFIG_DIRS (users' own settings always win)
copy_tree "$ROOT/theme/xdg" "$DATA/focuswave/xdg"
install -Dm644 "$ROOT/theme/plasma-env/focuswave.sh" "$DESTDIR/etc/xdg/plasma-workspace/env/focuswave.sh"

echo "FocusWave files installed into $DESTDIR"
