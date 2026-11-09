-- Serpantinum — Ubuntu-like keybinds on a floating Hyprland desktop.
--
-- Reference: https://wiki.hypr.land/configuring/core/binds/
-- Window management is intentionally NOT tiling: windows float and are
-- snapped/moved explicitly, like on Ubuntu.

local home = os.getenv("HOME")
local terminal = home .. "/.local/bin/serpantinum-terminal"
local snap = home .. "/.local/bin/serpantinum-snap"
local mod = "SUPER"

local function exec(cmd)
    hl.dispatch(hl.dsp.exec_cmd(cmd))
end

local function minimize()
    local w = hl.get_active_window()
    if not w then return end
    hl.dispatch(hl.dsp.window.tag({ tag = "+minimized", window = w }))
    hl.dispatch(hl.dsp.window.move({
        workspace = "special:minimized",
        follow = false,
        window = w,
    }))
end

local function restore_minimized()
    local windows = hl.get_windows({ tag = "minimized" })
    if not windows or #windows == 0 then return end
    local workspace = hl.get_active_workspace()
    for _, w in ipairs(windows) do
        hl.dispatch(hl.dsp.window.move({ workspace = workspace, window = w }))
        hl.dispatch(hl.dsp.window.clear_tags({ window = w }))
    end
end

------------------------------------------------------------
-- Launchers
------------------------------------------------------------
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
-- Direct fallback in case kitty cannot start on a virtual graphics adapter.
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("foot"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mod .. " + A", hl.dsp.exec_cmd("wofi --show drun"))

------------------------------------------------------------
-- Close / focus
------------------------------------------------------------
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

------------------------------------------------------------
-- Ubuntu window snapping (floating windows)
------------------------------------------------------------
hl.bind(mod .. " + left", hl.dsp.exec_cmd("'" .. snap .. "' left"))
hl.bind(mod .. " + right", hl.dsp.exec_cmd("'" .. snap .. "' right"))

-- Super+Up: maximize (fills the work area, keeps decorations)
hl.bind(mod .. " + up", function()
    local w = hl.get_active_window()
    if not w then return end
    hl.dispatch(hl.dsp.window.fullscreen({ action = "set", mode = 1 }))
end)

-- Super+Down: restore when maximized/fullscreen, otherwise minimize.
-- fs 1 (maximized) needs "unset" with mode 1; fs 2 needs a plain "unset".
hl.bind(mod .. " + down", function()
    local w = hl.get_active_window()
    if not w then return end
    if w.fullscreen == 1 then
        hl.dispatch(hl.dsp.window.fullscreen({ action = "unset", mode = 1 }))
    elseif w.fullscreen ~= 0 then
        hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))
    else
        minimize()
    end
end)

-- Super+H: minimize / Super+Shift+H: restore all minimized windows
hl.bind(mod .. " + H", minimize)
hl.bind(mod .. " + SHIFT + H", restore_minimized)

------------------------------------------------------------
-- Move window between monitors
------------------------------------------------------------
hl.bind(mod .. " + SHIFT + left", hl.dsp.exec_cmd("'" .. snap .. "' monitor-left"))
hl.bind(mod .. " + SHIFT + right", hl.dsp.exec_cmd("'" .. snap .. "' monitor-right"))

------------------------------------------------------------
-- Workspaces
------------------------------------------------------------
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Ctrl+Alt+Left/Right: previous/next workspace (Ubuntu)
hl.bind("CTRL + ALT + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "e+1" }))

-- Ctrl+Alt+Shift+Left/Right: move the window to the previous/next workspace
hl.bind("CTRL + ALT + SHIFT + left", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "e+1" }))

-- Super+Shift+Up/Down: move the window to the workspace above/below
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ workspace = "e-1" }))

------------------------------------------------------------
-- Floating / fullscreen
------------------------------------------------------------
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

------------------------------------------------------------
-- Mouse: move/resize floating windows
------------------------------------------------------------
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

------------------------------------------------------------
-- Screenshots
------------------------------------------------------------
hl.bind("PRINT", hl.dsp.exec_cmd(
    "mkdir -p \"$HOME/Pictures/Screenshots\" && grim \"$HOME/Pictures/Screenshots/serpantinum-$(date +%Y%m%d-%H%M%S).png\""
))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

------------------------------------------------------------
-- Multimedia keys (when the guest/hardware exposes them)
------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
