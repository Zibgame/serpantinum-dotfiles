#!/usr/bin/env bash
# Status helpers (used by install.sh --status and bin/serpantinum).

print_status() {
    local state_dir="${SERP_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum}"
    local codex_bin
    codex_bin="$(command -v codex 2>/dev/null || true)"
    if [[ -z "$codex_bin" && -x "$HOME/.npm-global/bin/codex" ]]; then
        codex_bin="$HOME/.npm-global/bin/codex"
    fi

    printf 'Serpantinum\n'
    printf '  installe   : %s\n' "$([[ -f "$state_dir/installed" ]] && echo "oui ($(cat "$state_dir/installed"))" || echo non)"
    printf '  source     : %s\n' "$([[ -f "$state_dir/source" ]] && cat "$state_dir/source" || echo inconnu)"
    printf '  zsh        : %s\n' "$(getent passwd "${USER:-$(id -un)}" | cut -d: -f7)"
    printf '  hyprland   : %s\n' "$(command -v Hyprland || echo absent)"
    printf '  hypr actif : %s\n' "$(hyprctl version >/dev/null 2>&1 && echo oui || echo non)"
    printf '  ghostty    : %s\n' "$(command -v ghostty || echo absent)"
    printf '  codex      : %s\n' "${codex_bin:-absent}"
    printf '  alt-tab    : %s\n' "$([[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/hypr-app-switcher/shell.qml" ]] && echo installe || echo absent)"
}
