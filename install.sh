# =============================================================================
# Serpantinum Dotfiles
# =============================================================================
# Personal Arch Linux environment: Hyprland (floating, Ubuntu-like window
# management), Zsh, Vim and a modular, reproducible installer.
#
# Usage:
#   git clone git@github.com:Zibgame/serpantinum-dotfiles.git
#   cd serpantinum-dotfiles
#   ./install.sh
#
# The installer is idempotent: run it as many times as you want.
# Existing files are backed up under ~/.local/state/serpantinum/backups/.
# =============================================================================

set -euo pipefail

SERP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SERP_ROOT
export SERP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum"
export SERP_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/serpantinum"
export SERP_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/serpantinum"

# shellcheck source=lib/common.sh
source "$SERP_ROOT/lib/common.sh"
# shellcheck source=lib/detect.sh
source "$SERP_ROOT/lib/detect.sh"

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --help, -h     Show this help.
  --status       Show the current installation status and exit.
  --no-packages  Skip the package installation module.
  --no-shell     Do not change the login shell to Zsh.
  --no-vim      Do not run the Vim plugin installation.
EOF
}

parse_args() {
    SERP_SKIP_PACKAGES=0
    SERP_SKIP_SHELL=0
    SERP_SKIP_VIM=0
    for arg in "$@"; do
        case "$arg" in
            -h|--help) usage; exit 0 ;;
            --status) source "$SERP_ROOT/lib/status.sh"; print_status; exit 0 ;;
            --no-packages) SERP_SKIP_PACKAGES=1 ;;
            --no-shell) SERP_SKIP_SHELL=1 ;;
            --no-vim) SERP_SKIP_VIM=1 ;;
            *) die "Option inconnue: $arg (voir --help)" ;;
        esac
    done
}

banner() {
    printf '\n%s' "$C_BOLD"
    cat <<'EOF'
  ____                       _   _
 / ___|  ___ _ __ _ __   __ _| |_(_)_ __  _   _ _ __ ___
 \___ \ / _ \ '__| '_ \ / _` | __| | '_ \| | | | '_ ` _ \
  ___) |  __/ |  | |_) | (_| | |_| | | | | |_| | | | | |
 |____/ \___|_|  | .__/ \__,_|\__|_|_| |_|\__,_|_| |_| |_|
                 |_|
EOF
    printf '%s' "$C_RESET"
    printf '  dotfiles — Arch Linux · Hyprland · Zsh · Vim\n\n'
}

summary() {
    log_step "Serpantinum est pret"
    log_info "Depot        : $SERP_ROOT"
    log_info "Etat         : $SERP_STATE_DIR"
    log_info "Sauvegardes  : $SERP_STATE_DIR/backups"
    log_info "Fond d'ecran : $SERP_DATA_DIR/wallpapers/serpantinum.jpg"
    log_info ""
    log_info "Reconnecte-toi (ou lance 'exec zsh') pour charger Zsh."
    log_info "Si Hyprland tourne, la configuration est deja rechargee."
    log_info "Verifie l'etat avec: serpantinum status"
}

main() {
    parse_args "$@"
    banner
    detect_environment

    mkdir -p "$SERP_STATE_DIR/backups" "$SERP_DATA_DIR/wallpapers" "$SERP_CONFIG_DIR"

    if is_installed; then
        log_step "Serpantinum est deja installe — verification et mise a jour"
    else
        log_step "Premiere installation de Serpantinum"
    fi

    local module
    for module in "$SERP_ROOT"/modules/*.sh; do
        log_step "$(basename "$module" .sh | sed 's/^[0-9]*-//')"
        # shellcheck source=/dev/null
        source "$module"
    done

    mark_installed
    summary
}

main "$@"
