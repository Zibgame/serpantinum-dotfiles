#!/usr/bin/env bash
# 50 — Wallpaper: install the asset and apply it live when possible.

WALLPAPER="$SERP_DATA_DIR/wallpapers/serpantinum.jpg"
install_asset "$SERP_ROOT/assets/wallpapers/serpantinum.jpg" "$WALLPAPER"

if hypr_running; then
    pkill -x swaybg 2>/dev/null || true
    if hyprctl dispatch "hl.dsp.exec_cmd(\"swaybg -i '$WALLPAPER' -m fill\")" >/dev/null 2>&1; then
        log_ok "fond d'ecran applique"
    else
        log_warn "impossible d'appliquer le fond d'ecran en direct"
    fi
else
    log_info "fond d'ecran configure (applique au prochain demarrage de Hyprland)"
fi
