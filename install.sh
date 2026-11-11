#!/usr/bin/env bash
# =============================================================================
# Serpantinum Dotfiles — Hyprland / Zsh / Vim
# =============================================================================
# Usage:
#   git clone git@github.com:Zibgame/serpantinum-dotfiles.git
#   cd serpantinum-dotfiles
#   ./install.sh
#
# Installation order:
#   1. Preflight + Arch packages
#   2. Official Serpantinum Shell
#   3. All personal dotfiles (Zsh, Kitty, Vim, Hyprland, wallpapers...)
#
# Existing personal configs are backed up before the upstream install.
# =============================================================================

set -euo pipefail

SERP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SERP_ROOT
export SERP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum"
export SERP_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/serpantinum"
export SERP_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/serpantinum"

SERP_UPSTREAM_REPO="https://github.com/ilyamiro/serpantinum.git"
SERP_UPSTREAM_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum-upstream"
SERP_UPSTREAM_VERSION="$SERP_STATE_DIR/version"
SERP_UPSTREAM_CLI="$SERP_DATA_DIR/bin/serpantinum"
SERP_UPSTREAM_DAEMON="$SERP_DATA_DIR/bin/serpantinumd"

# shellcheck source=lib/common.sh
source "$SERP_ROOT/lib/common.sh"
# shellcheck source=lib/detect.sh
source "$SERP_ROOT/lib/detect.sh"

usage() {
    cat <<'HELP'
Usage: ./install.sh [options]

Options:
  -h, --help       Show this help.
  --status         Show current installation status.
  --no-packages    Skip package installation and upstream install.
  --no-upstream    Skip official Serpantinum installation.
  --no-shell       Do not change the login shell to Zsh.
  --no-vim         Skip Vim plugin installation.

Supported distributions (package manager detected automatically):
  Arch family : Arch, BlackArch, EndeavourOS, Manjaro, CachyOS, Garuda, Artix
  Debian      : Debian, Ubuntu, Kali, Parrot, Mint, Pop!_OS
  Fedora      : Fedora, Nobara, RHEL, CentOS Stream, Rocky, Alma
  SUSE        : openSUSE Leap, openSUSE Tumbleweed
  Void        : Void Linux (glibc, musl)
  Other       : dotfiles only (packages skipped).

The official Serpantinum shell installs on Arch, Fedora and Void only.
On the other distributions the personal dotfiles (zsh, vim, Hyprland,
wallpaper, keybinds) install normally, without the graphical shell.
HELP
}

parse_args() {
    SERP_SKIP_PACKAGES=0
    SERP_SKIP_UPSTREAM=0
    SERP_SKIP_SHELL=0
    SERP_SKIP_VIM=0
    SERP_ONLY_APP_SWITCHER=0

    local arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help)       usage; exit 0 ;;
            --status)        source "$SERP_ROOT/lib/status.sh"; print_status; exit 0 ;;
            --no-packages)   SERP_SKIP_PACKAGES=1 ;;
            --no-upstream)   SERP_SKIP_UPSTREAM=1 ;;
            --no-shell)      SERP_SKIP_SHELL=1 ;;
            --no-vim)        SERP_SKIP_VIM=1 ;;
            --app-switcher-only) SERP_ONLY_APP_SWITCHER=1 ;;
            *)               die "Option inconnue: $arg (voir --help)" ;;
        esac
    done
}

banner() {
    printf '\n%s' "$C_BOLD"
    cat <<'BANNER'
  ____                       _   _
 / ___|  ___ _ __ _ __   __ _| |_(_)_ __  _   _ _ __ ___
 \___ \ / _ \ '__| '_ \ / _` | __| | '_ \| | | | '_ ` _ \
  ___) |  __/ |  | |_) | (_| | |_| | | | | |_| | | | | |
 |____/ \___|_|  | .__/ \__,_|\__|_|_| |_|\__,_|_| |_| |_|
                 |_|
BANNER
    printf '%s' "$C_RESET"
    printf '  dotfiles — Arch Linux · Hyprland · Zsh · Vim\n'
    printf '  Upstream d abord, configurations personnelles ensuite\n\n'
}

# The upstream version marker alone is not sufficient: the daemon can create
# this marker even when a full official installation has not completed.
is_upstream_installed() {
    [[ -f "$SERP_UPSTREAM_VERSION" &&
       -x "$SERP_UPSTREAM_CLI" &&
       -x "$SERP_UPSTREAM_DAEMON" &&
       -f "$SERP_DATA_DIR/src/quickshell/Shell.qml" ]]
}

install_serpantinum_upstream() {
    log_step "Installation de Serpantinum officiel"

    if [[ "$SERP_SKIP_UPSTREAM" -eq 1 ]]; then
        log_skip "upstream ignore (--no-upstream)"
        return 0
    fi
    if [[ "$SERP_SKIP_PACKAGES" -eq 1 ]]; then
        log_skip "upstream ignore (--no-packages)"
        return 0
    fi
    if is_upstream_installed; then
        log_skip "Serpantinum officiel deja installe"
        return 0
    fi
    # The official Serpantinum installer only supports Arch, Fedora and Void
    # (pacman/dnf/xbps). On other distributions the personal dotfiles still
    # install fine, the graphical shell is simply not available.
    case "$SERP_PKG_FAMILY" in
        arch|fedora|void) ;;
        *)
            log_warn "Serpantinum officiel indisponible sur cette distribution (Arch/Fedora/Void seulement)"
            log_info "les dotfiles personnels (zsh, vim, hyprland, fond d'ecran) seront installes normalement"
            return 0
            ;;
    esac

    # The official installer can replace Hyprland and Kitty configuration.
    # Save the current configuration before it starts.
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    backup_file "$config_home/hypr"
    backup_file "$config_home/kitty"
    backup_file "$config_home/serpantinum"

    command -v git >/dev/null 2>&1 || die "git est introuvable"

    if [[ -d "$SERP_UPSTREAM_DIR/.git" ]]; then
        log_info "Mise a jour des sources officielles"
        git -C "$SERP_UPSTREAM_DIR" fetch --depth 1 origin master
        git -C "$SERP_UPSTREAM_DIR" reset --hard FETCH_HEAD
    else
        [[ ! -e "$SERP_UPSTREAM_DIR" ]] || \
            die "Le dossier $SERP_UPSTREAM_DIR existe mais n'est pas un depot Git"
        log_info "Clonage de Serpantinum officiel"
        git clone --depth 1 --branch master \
            "$SERP_UPSTREAM_REPO" "$SERP_UPSTREAM_DIR"
    fi

    local installer="$SERP_UPSTREAM_DIR/install/install.sh"
    [[ -f "$installer" ]] || die "Installateur officiel introuvable: $installer"

    log_info "Dans le menu officiel, choisis Hyprland."
    log_info "Ne redemarre pas la VM avant la fin des dotfiles personnels."
    bash "$installer"

    is_upstream_installed || die "Installation officielle incomplete: verifie les messages ci-dessus"
    log_ok "Serpantinum officiel installe"
}

run_module() {
    local module="$1"
    [[ -f "$module" ]] || return 0
    log_step "$(basename "$module" .sh | sed 's/^[0-9]*-//')"
    # shellcheck source=/dev/null
    source "$module"
}

# The robust launcher ~/.local/bin/serpantinum-autostart.sh (linked by the
# Hyprland module) starts the shell from serpantinum-appearance.lua and works
# even without the Hyprland/Wayland environment variables. The systemd user
# watcher (module 45) is the fallback for sessions where exec-once failed.
ensure_serpantinum_autostart() {
    local config="$SERP_ROOT/config/hypr/serpantinum-appearance.lua"
    local script="$HOME/.local/bin/serpantinum-autostart.sh"

    if [[ ! -e "$script" ]]; then
        log_warn "autostart absent: $script — relance ./install.sh pour recree les liens"
        return 0
    fi

    if ! grep -Fq 'serpantinum-autostart.sh' "$config"; then
        log_warn "autostart non branche dans $config — relance ./install.sh"
        return 0
    fi

    log_ok "autostart Serpantinum branche: $script"

    is_upstream_installed || return 0
    [[ -x "$HOME/.local/bin/serpantinum-shell" ]] || \
        die "Lanceur Serpantinum introuvable dans ~/.local/bin"
    if command -v systemctl >/dev/null 2>&1 \
        && ! systemctl --user is-enabled --quiet serpantinum-dotfiles-autostart.service; then
        log_warn "watcher systemd inactif (secours autostart): systemctl --user status serpantinum-dotfiles-autostart.service"
    fi
}

# The 40-hyprland module links the dotfiles command to `serpantinum`.
# Restore the official CLI there, keeping our own CLI under another name.
configure_serpantinum_cli() {
    is_upstream_installed || return 0
    log_step "Commandes Serpantinum"
    mkdir -p "$HOME/.local/bin"

    link_config "$SERP_ROOT/bin/serpantinum" \
        "$HOME/.local/bin/serpantinum-dotfiles"
    link_config "$SERP_UPSTREAM_CLI" \
        "$HOME/.local/bin/serpantinum"

    log_ok "serpantinum = CLI officiel"
    log_ok "serpantinum-dotfiles = gestion de tes dotfiles"
}

summary() {
    log_step "Serpantinum est pret"
    log_info "Depot        : $SERP_ROOT"
    log_info "Etat         : $SERP_STATE_DIR"
    log_info "Sauvegardes  : $SERP_STATE_DIR/backups"
    log_info "Fond d'ecran : $SERP_DATA_DIR/wallpapers/serpantinum.jpg"

    if is_upstream_installed; then
        log_ok "Serpantinum Shell installe"
        log_info "CLI          : serpantinum"
        log_info "Dotfiles     : serpantinum-dotfiles status"
        log_info "Autostart    : ~/.local/bin/serpantinum-autostart.sh"
    else
        log_info "Serpantinum officiel non detecte"
    fi
    log_info "Reconnecte-toi a la session Hyprland pour appliquer l'autostart."
    log_info "Reconnecte-toi (ou exec zsh) pour charger Zsh."
}

main() {
    parse_args "$@"

    # Upstream refuses root/sudo and a root install damages per-user paths.
    [[ "$EUID" -ne 0 ]] || die "Ne lance pas ce script avec sudo/root: ./install.sh"

    banner
    detect_environment
    mkdir -p "$SERP_STATE_DIR/backups" "$SERP_DATA_DIR/wallpapers" "$SERP_CONFIG_DIR"

    # Install only the visual Alt+Tab, leaving the current wallpaper untouched.
    if [[ "$SERP_ONLY_APP_SWITCHER" -eq 1 ]]; then
        run_module "$SERP_ROOT/modules/35-hypr-app-switcher.sh"
        local switcher_dir="${XDG_DATA_HOME:-$HOME/.local/share}/hypr-app-switcher"
        [[ -f "$switcher_dir/shell.qml" ]] || die "Hypr App Switcher n'a pas ete installe"
        run_module "$SERP_ROOT/modules/40-hyprland.sh"
        run_module "$SERP_ROOT/modules/45-autostart.sh"
        log_ok "Hypr App Switcher configure : ALT+TAB / ALT+SHIFT+TAB"
        return 0
    fi

    if is_installed; then
        log_step "Verification / mise a jour des dotfiles"
    else
        log_step "Premiere installation des dotfiles"
    fi

    # Stage 1: preparation, including the distribution dependencies.
    local module filename
    for module in "$SERP_ROOT"/modules/*.sh; do
        [[ -f "$module" ]] || continue
        filename="${module##*/}"
        case "$filename" in
            0[0-9]-*|1[0-9]-*) run_module "$module" ;;
        esac
    done

    # Stage 2: official Serpantinum must run BEFORE personal configurations.
    install_serpantinum_upstream

    # Stage 3: restore all personal configurations AFTER the official installer.
    for module in "$SERP_ROOT"/modules/*.sh; do
        [[ -f "$module" ]] || continue
        filename="${module##*/}"
        case "$filename" in
            0[0-9]-*|1[0-9]-*) ;; # already executed
            *) run_module "$module" ;;
        esac
    done

    ensure_serpantinum_autostart
    configure_serpantinum_cli

    mark_installed
    summary
}

main "$@"
