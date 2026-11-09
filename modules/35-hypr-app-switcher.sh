#!/usr/bin/env bash
# 35 — Hypr App Switcher: install/update the upstream Quickshell Alt+Tab UI.
# The repository's install.sh sources modules/*.sh after installing Serpantinum.

install_hypr_app_switcher() {
    local repo="https://github.com/anshifmonz/hypr-app-switcher.git"
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/hypr-app-switcher"
    local origin

    if [[ -d "$dir/.git" ]]; then
        origin="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"
        case "$origin" in
            "$repo"|"https://github.com/anshifmonz/hypr-app-switcher"|"git@github.com:anshifmonz/hypr-app-switcher.git")
                ;;
            *)
                log_warn "hypr-app-switcher: depot existant d'une autre origine ($origin), laisse intact"
                return 0
                ;;
        esac
        log_info "Mise a jour de Hypr App Switcher"
        if ! git -C "$dir" pull --ff-only; then
            log_warn "hypr-app-switcher: mise a jour impossible, copie existante conservee"
        fi
    elif [[ -e "$dir" ]]; then
        log_warn "hypr-app-switcher: $dir existe sans depot Git, laisse intact"
        return 0
    else
        log_info "Installation de Hypr App Switcher"
        mkdir -p "$(dirname "$dir")"
        if ! git clone --depth 1 "$repo" "$dir"; then
            log_warn "hypr-app-switcher: clonage echoue (reseau ?), installation poursuivie"
            return 0
        fi
    fi

    if [[ ! -f "$dir/shell.qml" ]]; then
        log_warn "hypr-app-switcher: shell.qml introuvable, activation ignoree"
        return 0
    fi

    if ! command -v qs >/dev/null 2>&1; then
        log_warn "hypr-app-switcher installe mais 'qs' (Quickshell) est absent"
    fi
    log_ok "Hypr App Switcher disponible dans $dir"
}

install_hypr_app_switcher
