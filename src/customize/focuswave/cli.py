"""focuswave-theme — command-line access to the FocusWave engine.

  focuswave-theme apply-all            apply every FocusWave setting for this user
  focuswave-theme auto                 switch light/dark if it is time (used by a timer)
  focuswave-theme login                run at login: auto light/dark + Focus Mode settings
  focuswave-theme set KEY VALUE        e.g. `set mode dark`, `set accent "#ff6b9d"`,
                                       `set layout.preset mac`, `set focus.dim 30`
  focuswave-theme get [KEY]            print the settings (or one value)
  focuswave-theme reset                back to FocusWave defaults
  focuswave-theme export FILE          save the current look as a .fwtheme file
  focuswave-theme import FILE          import a .fwtheme file and apply it
  focuswave-theme layout-js [PRESET]   print the Plasma layout script (used at build time)
"""
from __future__ import annotations

import argparse
import json
import logging
import sys

from . import engine, layouts, state


def _parse_value(raw: str):
    try:
        return json.loads(raw)
    except ValueError:
        return raw


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(level=logging.INFO, format="focuswave: %(message)s")
    parser = argparse.ArgumentParser(prog="focuswave-theme", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("apply-all")
    sub.add_parser("auto")
    sub.add_parser("login")
    p_set = sub.add_parser("set")
    p_set.add_argument("key")
    p_set.add_argument("value")
    p_get = sub.add_parser("get")
    p_get.add_argument("key", nargs="?")
    sub.add_parser("reset")
    p_exp = sub.add_parser("export")
    p_exp.add_argument("file")
    p_imp = sub.add_parser("import")
    p_imp.add_argument("file")
    p_js = sub.add_parser("layout-js")
    p_js.add_argument("preset", nargs="?")
    args = parser.parse_args(argv)

    st = state.load()

    if args.cmd == "apply-all":
        engine.apply_all(st)
        state.save(st)
    elif args.cmd == "auto":
        engine.apply_auto(st)
    elif args.cmd == "login":
        engine.apply_focus(st)
        engine.apply_auto(st)
    elif args.cmd == "set":
        state.set_path(st, args.key, _parse_value(args.value))
        state.save(st)
        top = args.key.split(".")[0]
        if top == "layout" and args.key == "layout.preset":
            st["buttons"] = state.PRESET_BUTTONS.get(st["layout"]["preset"], st["buttons"])
            state.save(st)
            engine.apply(st, ["buttons", "layout"])
        else:
            engine.apply(st, [engine.KEY_CATEGORY.get(top, "")])
    elif args.cmd == "get":
        value = state.get_path(st, args.key) if args.key else st
        print(json.dumps(value, indent=2) if isinstance(value, (dict, list)) else value)
    elif args.cmd == "reset":
        st = state.defaults()
        state.save(st)
        engine.apply_all(st)
    elif args.cmd == "export":
        print(state.export_theme(st, args.file))
    elif args.cmd == "import":
        theme_id = state.import_theme(args.file)
        st = state.load_theme(theme_id)
        state.save(st)
        engine.apply_all(st)
        print(f"imported and applied theme '{st.get('name', theme_id)}'")
    elif args.cmd == "layout-js":
        if args.preset:
            st["layout"]["preset"] = args.preset
        sys.stdout.write(layouts.layout_script(st))
    return 0


if __name__ == "__main__":
    sys.exit(main())
