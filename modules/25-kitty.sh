#!/usr/bin/env bash
# 25 — Terminals: kitty + foot, translucent for the glass blur look.

link_config "$SERP_ROOT/config/kitty/kitty.conf" "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf"
link_config "$SERP_ROOT/config/foot/foot.ini" "${XDG_CONFIG_HOME:-$HOME/.config}/foot/foot.ini"
