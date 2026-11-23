#!/usr/bin/env bash
# 18 — Install Ungoogled Chromium on Arch and configure Google by default.

if [[ "$SERP_PKG_FAMILY" != "arch" ]]; then
    log_skip "Ungoogled Chromium ignore: installation AUR reservee a Arch"
    return 0
fi

install_ungoogled_chromium() {
    local helper aur_dir

    if command -v paru >/dev/null 2>&1; then
        helper="paru"
    elif command -v yay >/dev/null 2>&1; then
        helper="yay"
    else
        helper=""
    fi

    if [[ -n "$helper" ]]; then
        log_info "installation de ungoogled-chromium-bin avec $helper"
        "$helper" -S --needed --noconfirm ungoogled-chromium-bin
        return
    fi

    log_info "aucun helper AUR detecte: construction de ungoogled-chromium-bin"
    sudo_run pacman -S --needed --noconfirm base-devel git
    aur_dir="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum-aur/ungoogled-chromium-bin"
    mkdir -p "$(dirname "$aur_dir")"

    if [[ -d "$aur_dir/.git" ]]; then
        git -C "$aur_dir" pull --ff-only
    else
        git clone https://aur.archlinux.org/ungoogled-chromium-bin.git "$aur_dir"
    fi

    (cd "$aur_dir" && makepkg -si --needed --noconfirm)
}

if ! pacman -Qq ungoogled-chromium-bin >/dev/null 2>&1; then
    if [[ "${SERP_SKIP_PACKAGES:-0}" -eq 1 ]]; then
        log_skip "Ungoogled Chromium absent et paquets ignores (--no-packages)"
        return 0
    fi
    install_ungoogled_chromium
else
    log_skip "ungoogled-chromium-bin deja installe"
fi

command -v /usr/bin/chromium >/dev/null 2>&1 || {
    log_warn "Chromium installe mais executable /usr/bin/chromium introuvable"
    return 0
}

link_config "$SERP_ROOT/bin/chromium" "$HOME/.local/bin/chromium"
link_config "$SERP_ROOT/config/applications/chromium.desktop" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/applications/chromium.desktop"

# Recommended policies provide sensible defaults while remaining editable by
# the user in Chromium's settings.
sudo_run install -Dm644 \
    "$SERP_ROOT/config/chromium/policies/google-default.json" \
    /etc/chromium/policies/recommended/serpantinum-google-default.json

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${XDG_DATA_HOME:-$HOME/.local/share}/applications" || true
fi

if command -v xdg-mime >/dev/null 2>&1; then
    for mime in x-scheme-handler/http x-scheme-handler/https text/html application/xhtml+xml; do
        xdg-mime default chromium.desktop "$mime"
    done
fi

if command -v xdg-settings >/dev/null 2>&1; then
    xdg-settings set default-web-browser chromium.desktop || \
        log_warn "xdg-settings n'a pas pu definir le navigateur par defaut"
fi

log_ok "Ungoogled Chromium configure: navigateur par defaut, recherche et ouverture Google"
