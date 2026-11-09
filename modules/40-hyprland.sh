#!/usr/bin/env bash
# 40 — Hyprland: configuration modules, helpers and live reload.

HYPR_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
mkdir -p "$HYPR_CONFIG_DIR" "$HOME/.local/bin"

for module in \
    hyprland.lua \
    serpantinum-appearance.lua \
    serpantinum-rules.lua \
    serpantinum-keybinds.lua
do
    link_config "$SERP_ROOT/config/hypr/$module" "$HYPR_CONFIG_DIR/$module"
done

for helper in serpantinum-terminal serpantinum-snap serpantinum-shell serpantinum-app-switcher; do
    link_config "$SERP_ROOT/bin/$helper" "$HOME/.local/bin/$helper"
done

# Keep the personal management CLI separate from the official shell CLI.
link_config "$SERP_ROOT/bin/serpantinum" "$HOME/.local/bin/serpantinum-dotfiles"

chmod +x "$SERP_ROOT/bin/"*

hypr_reload
