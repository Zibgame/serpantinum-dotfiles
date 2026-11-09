-- Serpantinum — Hyprland entry point (Lua config, Hyprland >= 0.57).
--
-- Modules are resolved from ~/.config/hypr/ (Hyprland sets the Lua path
-- there). The installer symlinks every file from config/hypr/ into place.

-- Terminal shortcuts are registered here, before optional modules.
-- If a secondary config module fails, these still work in Hyprland 0.57.
local home = os.getenv("HOME")
local terminal = home .. "/.local/bin/serpantinum-terminal"

hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("foot"), { description = "Emergency terminal (Foot)" })

require("serpantinum-appearance")
require("serpantinum-rules")
require("serpantinum-keybinds")
