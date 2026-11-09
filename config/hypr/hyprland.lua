-- Serpantinum — Hyprland entry point (Lua config, Hyprland >= 0.57).
--
-- Modules are resolved from ~/.config/hypr/ (Hyprland sets the Lua path
-- there). The installer symlinks every file from config/hypr/ into place.

require("serpantinum-appearance")
require("serpantinum-rules")
require("serpantinum-keybinds")
