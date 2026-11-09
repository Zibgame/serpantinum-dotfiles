#!/usr/bin/env bash
# Environment detection for the Serpantinum installer.

detect_environment() {
    [[ -n "${HOME:-}" ]] || die "HOME n'est pas defini"

    if [[ ! -r /etc/os-release ]]; then
        die "Distribution non supportee: /etc/os-release est absent"
    fi

    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "arch" ]]; then
        die "Serpantinum cible Arch Linux (detecte: ${PRETTY_NAME:-inconnu})"
    fi
    log_ok "Distribution: ${PRETTY_NAME:-Arch Linux}"

    command -v pacman >/dev/null 2>&1 || die "pacman est introuvable"
    command -v git >/dev/null 2>&1 || die "git est introuvable"

    if [[ $EUID -ne 0 ]]; then
        command -v sudo >/dev/null 2>&1 || die "sudo est introuvable"
        if [[ -z "${SERP_SUDO:-}" ]] && ! sudo -n true 2>/dev/null; then
            log_warn "sudo demandera un mot de passe (lance 'sudo -v' avant pour une installation non interactive)"
        fi
    fi

    if command -v Hyprland >/dev/null 2>&1; then
        log_ok "Hyprland: $(Hyprland --version 2>/dev/null | head -n1 || echo present)"
    else
        log_warn "Hyprland absent: il sera installe par le module paquets"
    fi

    log_info "Utilisateur: ${USER:-$(id -un)} — HOME=$HOME"
}
