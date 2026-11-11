# Serpantinum — environment variables and console-first autostart.
# Sourced from ~/.zshrc (and safe to source from bash).

export SERPANTINUM_HOME="${SERPANTINUM_HOME:-$HOME/.local/share/serpantinum}"
export SERPANTINUM_CONFIG="${SERPANTINUM_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/serpantinum}"
export SERPANTINUM_STATE="${SERPANTINUM_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum}"

case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# No display manager: log in on tty1 and Hyprland starts immediately.
# Guarded so it never runs inside an existing Wayland session or on another TTY.
if [[ -z "${WAYLAND_DISPLAY:-}" && "$(tty 2>/dev/null)" == "/dev/tty1" ]]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland >"$SERPANTINUM_STATE/hyprland.log" 2>&1
    elif command -v Hyprland >/dev/null 2>&1; then
        exec Hyprland >"$SERPANTINUM_STATE/hyprland.log" 2>&1
    fi
fi
