
#!/usr/bin/env bash
# =============================================================================
# Serpantinum Dotfiles
# =============================================================================
# Personal Arch Linux environment:
# Hyprland, Serpantinum Shell, Zsh, Vim and modular installer.
#
# Usage:
#   git clone git@github.com:Zibgame/serpantinum-dotfiles.git
#   cd serpantinum-dotfiles
#   ./install.sh
#
# Existing files are backed up under:
# ~/.local/state/serpantinum/backups/
# =============================================================================

set -euo pipefail

SERP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SERP_ROOT

export SERP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum"
export SERP_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/serpantinum"
export SERP_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/serpantinum"

# Official Serpantinum project
SERP_UPSTREAM_REPO="https://github.com/ilyamiro/serpantinum.git"
SERP_UPSTREAM_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum-upstream"
SERP_UPSTREAM_VERSION="$SERP_STATE_DIR/version"
SERP_UPSTREAM_BIN="$SERP_DATA_DIR/bin/serpantinum"

# Shared libraries
# shellcheck source=lib/common.sh
source "$SERP_ROOT/lib/common.sh"

# shellcheck source=lib/detect.sh
source "$SERP_ROOT/lib/detect.sh"


# =============================================================================
# Usage
# =============================================================================

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --help, -h       Show this help.
  --status         Show current installation status.
  --no-packages    Skip package installation (including upstream).
  --no-upstream    Skip official Serpantinum installation.
  --no-shell       Do not change login shell to Zsh.
  --no-vim         Skip Vim plugin installation.
EOF
}


# =============================================================================
# Arguments
# =============================================================================

parse_args() {
    SERP_SKIP_PACKAGES=0
    SERP_SKIP_UPSTREAM=0
    SERP_SKIP_SHELL=0
    SERP_SKIP_VIM=0

    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage
                exit 0
                ;;
            --status)
                source "$SERP_ROOT/lib/status.sh"
                print_status
                exit 0
                ;;
            --no-packages)
                SERP_SKIP_PACKAGES=1
                ;;
            --no-upstream)
                SERP_SKIP_UPSTREAM=1
                ;;
            --no-shell)
                SERP_SKIP_SHELL=1
                ;;
            --no-vim)
                SERP_SKIP_VIM=1
                ;;
            *)
                die "Option inconnue: $arg (voir --help)"
                ;;
        esac
    done
}


# =============================================================================
# Banner
# =============================================================================

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
    printf '  dotfiles - Arch Linux | Hyprland | Zsh | Vim\n'
    printf '  Official Serpantinum Shell integration\n\n'
}


# =============================================================================
# Official Serpantinum installation
# =============================================================================

install_serpantinum_upstream() {
    log_step "Installation de Serpantinum officiel"

    # Respect installer options
    if [[ "$SERP_SKIP_UPSTREAM" -eq 1 ]]; then
        log_skip "Serpantinum upstream ignore (--no-upstream)"
        return 0
    fi

    if [[ "$SERP_SKIP_PACKAGES" -eq 1 ]]; then
        log_skip "Serpantinum upstream ignore (--no-packages)"
        return 0
    fi

    # Already installed
    if [[ -f "$SERP_UPSTREAM_VERSION" ]] &&
       [[ -x "$SERP_UPSTREAM_BIN" ]]; then
        log_skip "Serpantinum officiel deja installe"
        return 0
    fi

    # Requirements
    if ! command -v git >/dev/null 2>&1; then
        die "Git est necessaire pour installer Serpantinum"
    fi

    # Clone or update installer sources
    if [[ -d "$SERP_UPSTREAM_DIR/.git" ]]; then
        log_info "Actualisation des sources upstream"

        git -C "$SERP_UPSTREAM_DIR" fetch \
            --depth 1 origin master

        git -C "$SERP_UPSTREAM_DIR" reset \
            --hard FETCH_HEAD
    else
        if [[ -e "$SERP_UPSTREAM_DIR" ]]; then
            die "Dossier upstream existant non Git: $SERP_UPSTREAM_DIR"
        fi

        log_info "Clonage du projet officiel"

        git clone \
            --depth 1 \
            --branch master \
            "$SERP_UPSTREAM_REPO" \
            "$SERP_UPSTREAM_DIR"
    fi

    local installer="$SERP_UPSTREAM_DIR/install/install.sh"

    if [[ ! -f "$installer" ]]; then
        die "Installateur officiel introuvable: $installer"
    fi

    log_info "Lancement de l'installateur officiel"
    log_info "Selectionne Hyprland dans le menu interactif."

    # Run upstream installer separately to avoid variable conflicts
    bash "$installer"

    # Verify installation
    if [[ ! -f "$SERP_UPSTREAM_VERSION" ]] ||
       [[ ! -x "$SERP_UPSTREAM_BIN" ]]; then
        die "Installation de Serpantinum upstream incomplete"
    fi

    log_ok "Serpantinum officiel installe"
}


# =============================================================================
# Resolve CLI name conflicts
# =============================================================================

configure_serpantinum_cli() {
    # The dotfiles and upstream both provide a "serpantinum" CLI.
    # Give the dotfiles CLI a separate name.

    if [[ ! -f "$SERP_UPSTREAM_VERSION" ]] ||
       [[ ! -x "$SERP_UPSTREAM_BIN" ]]; then
        return 0
    fi

    log_step "Configuration des commandes Serpantinum"

    mkdir -p "$HOME/.local/bin"

    # Keep our dotfiles management CLI
    link_config \
        "$SERP_ROOT/bin/serpantinum" \
        "$HOME/.local/bin/serpantinum-dotfiles"

    # Restore official Serpantinum CLI after module 40
    link_config \
        "$SERP_UPSTREAM_BIN" \
        "$HOME/.local/bin/serpantinum"

    log_ok "CLI officiel: serpantinum"
    log_ok "CLI dotfiles: serpantinum-dotfiles"
}


# =============================================================================
# Summary
# =============================================================================

summary() {
    log_step "Serpantinum est pret"

    log_info "Depot        : $SERP_ROOT"
    log_info "Etat         : $SERP_STATE_DIR"
    log_info "Sauvegardes  : $SERP_STATE_DIR/backups"
    log_info "Fond d'ecran : $SERP_DATA_DIR/wallpapers/serpantinum.jpg"

    if [[ -f "$SERP_UPSTREAM_VERSION" ]] &&
       [[ -x "$SERP_UPSTREAM_BIN" ]]; then
        log_ok "Serpantinum Shell installe"
        log_info "Lancement    : serpantinumd start"
        log_info "Gestion      : serpantinum-dotfiles status"
    else
        log_info "Gestion      : serpantinum status"
    fi

    log_info ""
    log_info "Reconnecte-toi (ou lance 'exec zsh') pour charger Zsh."
    log_info "Si Hyprland tourne, la configuration est deja rechargee."
}


# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"

    banner
    detect_environment

    mkdir -p \
        "$SERP_STATE_DIR/backups" \
        "$SERP_DATA_DIR/wallpapers" \
        "$SERP_CONFIG_DIR"

    if is_installed; then
        log_step "Serpantinum deja installe - verification et mise a jour"
    else
        log_step "Premiere installation de Serpantinum"
    fi

    local module
    local module_name
    local upstream_processed=0

    # Execute modules in filename order.
    for module in "$SERP_ROOT"/modules/*.sh; do
        [[ -f "$module" ]] || continue

        module_name="$(basename "$module")"

        # Install upstream after package installation,
        # before desktop configuration modules.
        if [[ "$upstream_processed" -eq 0 ]] &&
           [[ "$module_name" > "10-packages.sh" ]]; then
            install_serpantinum_upstream
            upstream_processed=1
        fi

        log_step "$(basename "$module" .sh | sed 's/^[0-9]*-//')"

        # shellcheck source=/dev/null
        source "$module"
    done

    # Fallback if no module follows 10-packages.sh.
    if [[ "$upstream_processed" -eq 0 ]]; then
        install_serpantinum_upstream
    fi

    # Resolve upstream/dotfiles command conflicts.
    configure_serpantinum_cli

    mark_installed
    summary
}

main "$@"
