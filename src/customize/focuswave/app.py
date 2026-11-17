"""FocusWave Customize + Welcome wizard (PySide6 + Kirigami).

  focuswave-customize                 the Customize app
  focuswave-customize --welcome       the first-boot wizard
  focuswave-customize --welcome --if-first-run
                                      used by autostart: only runs once, never in the live session
"""
from __future__ import annotations

import argparse
import copy
import logging
import os
import subprocess
import sys
import threading
from pathlib import Path

from PySide6.QtCore import Property, QObject, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

from . import engine, state

QML_DIR = Path(__file__).resolve().parent / "qml"
log = logging.getLogger("focuswave")


def is_live_session() -> bool:
    try:
        return "rd.live.image" in Path("/proc/cmdline").read_text()
    except OSError:
        return False


class Backend(QObject):
    settingsChanged = Signal()
    themesChanged = Signal()
    busyChanged = Signal()
    message = Signal(str)

    def __init__(self, welcome: bool = False):
        super().__init__()
        self._welcome = welcome
        self._state = state.load()
        self._pending: set[str] = set()
        self._busy = 0
        self._lock = threading.Lock()
        self._timer = QTimer(self)
        self._timer.setSingleShot(True)
        self._timer.setInterval(350)
        self._timer.timeout.connect(self._flush)
        self._wallpapers = state.list_wallpapers(self._state.get("wallpaper"))
        self._decoration = engine.decoration_available()
        if welcome:
            # Make the desktop match what the wizard shows (the layout is already the default one).
            QTimer.singleShot(400, lambda: self._run(engine.apply_all, copy.deepcopy(self._state), False))

    # ------------------------------------------------------------------ properties
    @Property("QVariantMap", notify=settingsChanged)
    def settings(self):
        return self._state

    @Property(bool, notify=settingsChanged)
    def previewDark(self):
        return engine.is_dark(self._state)

    @Property("QVariantList", notify=settingsChanged)
    def wallpapers(self):
        return self._wallpapers

    @Property("QVariantList", notify=themesChanged)
    def themes(self):
        return state.list_themes()

    @Property(bool, constant=True)
    def decorationAvailable(self):
        return self._decoration

    @Property(bool, notify=busyChanged)
    def busy(self):
        return self._busy > 0

    @Property(str, constant=True)
    def focusShortcut(self):
        raw = engine.kread("kglobalshortcutsrc", ["kwin"], "FocusWave Focus Mode", "Meta+F")
        first = raw.split(",")[0].strip() if raw else "Meta+F"
        return first if first and first != "none" else "Meta+F"

    # ------------------------------------------------------------------ background work
    def _run(self, fn, *args):
        def worker():
            with self._lock:
                try:
                    fn(*args)
                except Exception:
                    log.exception("FocusWave apply failed")
            self._busy -= 1
            self.busyChanged.emit()

        self._busy += 1
        self.busyChanged.emit()
        threading.Thread(target=worker, daemon=True).start()

    def _flush(self):
        cats = [c for c in ("colors", "wallpaper", "buttons", "windows", "fonts", "focus") if c in self._pending]
        self._pending.clear()
        if cats:
            self._run(engine.apply, copy.deepcopy(self._state), cats)

    def flush_now(self):
        """Finish all pending work before the app quits (waits for running jobs)."""
        self._timer.stop()
        cats = [c for c in ("colors", "wallpaper", "buttons", "windows", "fonts", "focus") if c in self._pending]
        self._pending.clear()
        with self._lock:
            if cats:
                engine.apply(copy.deepcopy(self._state), cats)

    def _changed(self, categories):
        state.save(self._state)
        self.settingsChanged.emit()
        for c in categories:
            if c and c != "layout":
                self._pending.add(c)
        self._timer.start()

    # ------------------------------------------------------------------ slots
    @Slot(str, "QVariant")
    def set(self, path, value):
        if hasattr(value, "toVariant"):
            value = value.toVariant()
        state.set_path(self._state, path, value)
        if path == "wallpaper" and not any(w["path"] == self._state["wallpaper"] for w in self._wallpapers):
            self._wallpapers = state.list_wallpapers(self._state["wallpaper"])
        self._changed([engine.KEY_CATEGORY.get(path.split(".")[0], "")])

    @Slot(str)
    def choosePreset(self, preset):
        """Pick a layout preset; also suggests the matching window buttons."""
        state.set_path(self._state, "layout.preset", preset)
        self._state["buttons"] = state.PRESET_BUTTONS.get(preset, self._state["buttons"])
        if preset == "windows":
            self._state["layout"]["dockFloating"] = False
        self._changed(["buttons"])

    @Slot()
    def applyLayout(self):
        self._run(engine.apply_layout, copy.deepcopy(self._state))
        self.message.emit("Updating your desktop layout…")

    @Slot()
    def applyEverything(self):
        self._timer.stop()
        self._pending.clear()
        self._run(engine.apply_all, copy.deepcopy(self._state))

    @Slot()
    def resetDefaults(self):
        self._state = state.defaults()
        state.save(self._state)
        self.settingsChanged.emit()
        self.applyEverything()
        self.message.emit("FocusWave defaults restored")

    @Slot(str)
    def saveTheme(self, name):
        name = name.strip() or "My theme"
        state.save_theme(name, self._state)
        self.themesChanged.emit()
        self.message.emit(f"Saved “{name}”")

    @Slot(str)
    def applyTheme(self, theme_id):
        try:
            self._state = state.load_theme(theme_id)
        except (OSError, ValueError):
            self.message.emit("That theme could not be read")
            return
        state.save(self._state)
        self._wallpapers = state.list_wallpapers(self._state.get("wallpaper"))
        self.settingsChanged.emit()
        self.applyEverything()
        self.message.emit(f"Applied “{self._state.get('name', theme_id)}”")

    @Slot(str)
    def deleteTheme(self, theme_id):
        state.delete_theme(theme_id)
        self.themesChanged.emit()

    @Slot(str)
    def exportTheme(self, file_url):
        path = self.localPath(file_url)
        if path:
            out = state.export_theme(self._state, path)
            self.message.emit(f"Exported to {out}")

    @Slot(str)
    def importTheme(self, file_url):
        path = self.localPath(file_url)
        try:
            theme_id = state.import_theme(path)
        except Exception:
            log.exception("import failed")
            self.message.emit("That file is not a FocusWave theme")
            return
        self.themesChanged.emit()
        self.applyTheme(theme_id)

    @Slot(str, bool, result=str)
    def thumbFor(self, path, dark):
        """Thumbnail URL for a wallpaper path (package or picture), light or dark variant."""
        for w in self._wallpapers:
            if w["path"] == path:
                return (w.get("thumbDark") if dark and w.get("thumbDark") else w.get("thumb")) or ""
        return QUrl.fromLocalFile(path).toString() if path else ""

    @Slot(str, result=str)
    def localPath(self, url):
        u = QUrl(url)
        return u.toLocalFile() if u.isLocalFile() else url

    @Slot()
    def tryFocusMode(self):
        # Give the click a moment to finish, then toggle Focus Mode on this window.
        QTimer.singleShot(250, lambda: subprocess.Popen(
            ["busctl", "--user", "call", "org.kde.kglobalaccel", "/component/kwin",
             "org.kde.kglobalaccel.Component", "invokeShortcut", "s", "FocusWave Focus Mode"]))

    @Slot(str)
    def openSettings(self, module):
        subprocess.Popen(["systemsettings", module] if module else ["systemsettings"],
                         start_new_session=True)

    @Slot()
    def editDesktop(self):
        subprocess.Popen(["busctl", "--user", "set-property", "org.kde.plasmashell", "/PlasmaShell",
                          "org.kde.PlasmaShell", "editMode", "b", "true"])

    def _launch(self, *extra):
        subprocess.Popen([sys.executable, "-m", "focuswave.app", *extra], start_new_session=True,
                         env=dict(os.environ, PYTHONPATH=str(Path(__file__).resolve().parent.parent)))

    @Slot()
    def openCustomize(self):
        self._launch()

    @Slot()
    def runWelcome(self):
        self._launch("--welcome")

    @Slot()
    def finishWelcome(self):
        state.CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        state.WELCOME_FLAG.write_text("done\n")
        state.save(self._state)


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="focuswave: %(message)s")
    parser = argparse.ArgumentParser(prog="focuswave-customize")
    parser.add_argument("--welcome", action="store_true", help="show the first-boot wizard")
    parser.add_argument("--if-first-run", action="store_true",
                        help="with --welcome: do nothing if the wizard already ran or in the live session")
    args, qt_args = parser.parse_known_args(argv if argv is not None else sys.argv[1:])

    if args.welcome and args.if_first_run and (state.WELCOME_FLAG.exists() or is_live_session()):
        return 0

    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "org.kde.desktop")
    app = QApplication([sys.argv[0]] + qt_args)
    app.setApplicationName("FocusWave Customize")
    app.setOrganizationName("FocusWave")
    app.setDesktopFileName("org.focuswave.Customize")
    app.setWindowIcon(QIcon.fromTheme("focuswave-customize"))

    backend = Backend(welcome=args.welcome)
    qml_engine = QQmlApplicationEngine()
    qml_engine.rootContext().setContextProperty("backend", backend)
    qml_engine.addImportPath(str(QML_DIR))
    qml_engine.load(QUrl.fromLocalFile(str(QML_DIR / ("Welcome.qml" if args.welcome else "Main.qml"))))
    if not qml_engine.rootObjects():
        log.error("could not load the user interface (is kf6-kirigami installed?)")
        return 1
    app.aboutToQuit.connect(backend.flush_now)
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
