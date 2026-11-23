#!/usr/bin/env bash
# 18 — Install Ungoogled Chromium with Chrome Web Store support and Google defaults.

if [[ "$SERP_PKG_FAMILY" != "arch" ]]; then
    log_skip "Ungoogled Chromium ignore: installation AUR reservee a Arch"
    return 0
fi

install_aur_package() {
    local package="$1"
    local helper aur_dir

    if command -v paru >/dev/null 2>&1; then
        helper="paru"
    elif command -v yay >/dev/null 2>&1; then
        helper="yay"
    else
        helper=""
    fi

    if [[ -n "$helper" ]]; then
        log_info "installation de $package avec $helper"
        "$helper" -S --needed --noconfirm "$package"
        return
    fi

    log_info "aucun helper AUR detecte: construction de $package"
    sudo_run pacman -S --needed --noconfirm base-devel git
    aur_dir="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum-aur/$package"
    mkdir -p "$(dirname "$aur_dir")"

    if [[ -d "$aur_dir/.git" ]]; then
        git -C "$aur_dir" pull --ff-only
    else
        git clone "https://aur.archlinux.org/$package.git" "$aur_dir"
    fi

    (cd "$aur_dir" && makepkg -si --needed --noconfirm)
}

if ! pacman -Qq ungoogled-chromium-bin >/dev/null 2>&1; then
    if [[ "${SERP_SKIP_PACKAGES:-0}" -eq 1 ]]; then
        log_skip "Ungoogled Chromium absent et paquets ignores (--no-packages)"
        return 0
    fi
    install_aur_package ungoogled-chromium-bin
else
    log_skip "ungoogled-chromium-bin deja installe"
fi

# Ungoogled Chromium deliberately disables direct Chrome Web Store installs.
# This maintained companion extension restores the "Add to Chrome" button and
# updates installed extensions without replacing the privacy-focused browser.
if ! pacman -Qq chromium-extension-web-store >/dev/null 2>&1; then
    if [[ "${SERP_SKIP_PACKAGES:-0}" -eq 1 ]]; then
        log_skip "support Chrome Web Store absent et paquets ignores (--no-packages)"
    else
        install_aur_package chromium-extension-web-store
    fi
else
    log_skip "chromium-extension-web-store deja installe"
fi

command -v /usr/bin/chromium >/dev/null 2>&1 || {
    log_warn "Chromium installe mais executable /usr/bin/chromium introuvable"
    return 0
}

# A prebuilt AUR release can briefly lag behind an Arch soname transition.
# Keep the old library private to Chromium instead of downgrading the system
# copy required by VTE and other applications.
install_chromium_simdutf_compat() {
    local binary="/usr/lib/chromium/chromium"
    local missing="libsimdutf.so.36"
    local compat_dir="${XDG_DATA_HOME:-$HOME/.local/share}/serpantinum/chromium-compat"
    local cache_dir="$SERP_STATE_DIR/cache"
    local archive="$cache_dir/simdutf-9.2.2-1-x86_64.pkg.tar.zst"
    local archive_url="https://archive.archlinux.org/packages/s/simdutf/simdutf-9.2.2-1-x86_64.pkg.tar.zst"
    local archive_sha256="68d5e2e7795e9036ce2f4a8855e3927c701fa365d6b552f55b0ebad5cd4e1150"

    [[ -x "$binary" ]] || return 0
    ldd "$binary" 2>/dev/null | grep -Fq "$missing => not found" || return 0

    mkdir -p "$cache_dir" "$compat_dir"
    if [[ ! -f "$archive" ]] || \
       ! printf '%s  %s\n' "$archive_sha256" "$archive" | sha256sum --check --status; then
        log_info "telechargement de la compatibilite simdutf pour Chromium"
        curl -fL --retry 3 -o "$archive" "$archive_url"
    fi
    printf '%s  %s\n' "$archive_sha256" "$archive" | sha256sum --check --status || \
        die "archive simdutf de compatibilite invalide"

    bsdtar -xOf "$archive" usr/lib/libsimdutf.so.36.0.0 \
        > "$compat_dir/libsimdutf.so.36.0.0"
    ln -sfn libsimdutf.so.36.0.0 "$compat_dir/libsimdutf.so.36"
    log_ok "compatibilite simdutf isolee pour Chromium"
}

install_chromium_simdutf_compat

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

log_ok "Ungoogled Chromium configure: extensions Chrome Web Store, navigateur par defaut et recherche Google"
