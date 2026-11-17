# FocusWave: put FocusWave's default settings in front of the system defaults.
# Only affects settings a user has never changed; Plasma sources this at login.
case ":${XDG_CONFIG_DIRS:-}:" in
    *":/usr/share/focuswave/xdg:"*) ;;
    *) export XDG_CONFIG_DIRS="/usr/share/focuswave/xdg:${XDG_CONFIG_DIRS:-/etc/xdg}" ;;
esac
