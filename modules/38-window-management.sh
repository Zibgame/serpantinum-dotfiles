#!/usr/bin/env bash
# 38 — Complete Windows/Ubuntu-style floating window management for Hyprland.
# Installs window rules, snapping, state restoration, minimize/restore,
# monitor/workspace movement, mouse controls and all related shortcuts.

WINDOW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
mkdir -p "$WINDOW_CONFIG_DIR" "$HOME/.local/bin"

for config in serpantinum-rules.lua serpantinum-keybinds.lua; do
    link_config "$SERP_ROOT/config/hypr/$config" "$WINDOW_CONFIG_DIR/$config"
done

for helper in serpantinum-snap serpantinum-app-switcher; do
    link_config "$SERP_ROOT/bin/$helper" "$HOME/.local/bin/$helper"
    chmod +x "$SERP_ROOT/bin/$helper"
done

log_ok "gestion des fenetres Windows/Ubuntu installee"
