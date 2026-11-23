-- Serpantinum — Windows/Ubuntu-like keybinds on a floating Hyprland desktop.
--
-- Reference: https://wiki.hypr.land/configuring/core/binds/
-- Window management is intentionally NOT tiling: windows float and are
-- snapped/moved explicitly, like on Ubuntu.

local home = os.getenv("HOME")
local snap = home .. "/.local/bin/serpantinum-snap"
local mod = "SUPER"
-- Calibrated on Ghostty at font-size 12: Hyprland/Ghostty displays 65 x 18.
local drag_width = 660
local drag_height = 428

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
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
-- Terminal shortcuts live in hyprland.lua, so they are always registered.
hl.bind("Super_L", hl.dsp.exec_cmd("serpantinum msg toggle launcher"), { release = true })

------------------------------------------------------------
-- Close / focus
------------------------------------------------------------
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mod .. " + Q", hl.dsp.window.close())
-- Quickshell visual Alt+Tab installed by modules/35-hypr-app-switcher.sh.
local switcher = home .. "/.local/bin/serpantinum-app-switcher"
hl.bind("ALT + Tab", hl.dsp.exec_cmd("'" .. switcher .. "' next"), { description = "Visual app switcher: next" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("'" .. switcher .. "' prev"), { description = "Visual app switcher: previous" })

------------------------------------------------------------
-- Windows/Ubuntu window snapping (floating windows)
------------------------------------------------------------
hl.bind(mod .. " + left", hl.dsp.exec_cmd("'" .. snap .. "' left"))
hl.bind(mod .. " + right", hl.dsp.exec_cmd("'" .. snap .. "' right"))

-- Super+Up maximizes immediately. Hyprland remembers the previous floating
-- geometry, so Super+Down can walk back through the same states as Windows.
hl.bind(mod .. " + up", hl.dsp.window.fullscreen({
    action = "set",
    mode = "maximized",
}))

-- Super+Down follows a predictable state cycle:
-- maximized/fullscreen -> restored -> unsnapped -> minimized.
hl.bind(mod .. " + down", hl.dsp.exec_cmd("'" .. snap .. "' down"))

-- Super+H: minimize / Super+Shift+H: restore all minimized windows
hl.bind(mod .. " + H", hl.dsp.exec_cmd("'" .. snap .. "' minimize"))
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
local drag_timer = nil
local drag_active = false
local dragged_window = nil
local drag_ratio_x = 0.5
local drag_ratio_y = 0

local function stop_drag_window()
    drag_active = false
    dragged_window = nil
    if drag_timer then
        drag_timer:set_enabled(false)
        drag_timer = nil
    end
end

local function update_drag_window()
    if not drag_active or not dragged_window then
        stop_drag_window()
        return
    end

    local cursor = hl.get_cursor_pos()
    local monitor = hl.get_monitor_at_cursor() or dragged_window.monitor
    if not cursor or not monitor then return end

    local scale = tonumber(monitor.scale) or 1
    local monitor_width = (tonumber(monitor.width) or drag_width) / scale
    local monitor_height = (tonumber(monitor.height) or drag_height) / scale
    local transform = tonumber(monitor.transform) or 0
    if transform == 1 or transform == 3 or transform == 5 or transform == 7 then
        monitor_width, monitor_height = monitor_height, monitor_width
    end

    local reserved = monitor.reserved or {}
    local reserved_left = tonumber(reserved[1]) or 0
    local reserved_top = tonumber(reserved[2]) or 0
    local reserved_right = tonumber(reserved[3]) or 0
    local reserved_bottom = tonumber(reserved[4]) or 0
    local work_x = (tonumber(monitor.x) or 0) + reserved_left
    local work_y = (tonumber(monitor.y) or 0) + reserved_top
    local work_width = math.max(1, monitor_width - reserved_left - reserved_right)
    local work_height = math.max(1, monitor_height - reserved_top - reserved_bottom)
    local target_width = math.min(drag_width, work_width)
    local target_height = math.min(drag_height, work_height)
    local target_x = math.floor(cursor.x - drag_ratio_x * target_width)
    local target_y = math.floor(cursor.y - drag_ratio_y * target_height)
    target_x = clamp(target_x, work_x, work_x + work_width - target_width)
    target_y = clamp(target_y, work_y, work_y + work_height - target_height)

    -- Reapply the dimensions at every cursor update. This prevents the old
    -- floating/maximized geometry from coming back during the drag.
    hl.dispatch(hl.dsp.window.resize({
        x = target_width,
        y = target_height,
        window = dragged_window,
    }))
    hl.dispatch(hl.dsp.window.move({
        x = target_x,
        y = target_y,
        relative = false,
        window = dragged_window,
    }))
end

local function start_drag_window()
    local w = hl.get_active_window()
    if not w then return end

    local cursor = hl.get_cursor_pos()
    if not cursor then return end

    local window_x = tonumber(w.at.x) or 0
    local window_y = tonumber(w.at.y) or 0
    local window_width = math.max(1, tonumber(w.size.x) or drag_width)
    local window_height = math.max(1, tonumber(w.size.y) or drag_height)
    drag_ratio_x = clamp((cursor.x - window_x) / window_width, 0, 1)
    drag_ratio_y = clamp((cursor.y - window_y) / window_height, 0, 1)

    local fullscreen = tonumber(w.fullscreen) or 0
    if fullscreen == 2 or fullscreen == 3 then
        hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))
    end
    if fullscreen == 1 or fullscreen == 3 then
        hl.dispatch(hl.dsp.window.fullscreen({ action = "unset", mode = 1 }))
    end

    -- A manual mouse move starts a new floating geometry. Forget a previous
    -- keyboard snap so Super+Down cannot restore an obsolete position.
    hl.dispatch(hl.dsp.exec_cmd("'" .. snap .. "' forget"))

    -- Do not call Hyprland's native window.drag() here: it continuously
    -- restores the previous floating size while the pointer moves.
    stop_drag_window()
    dragged_window = w
    drag_active = true
    update_drag_window()
    drag_timer = hl.timer(update_drag_window, { timeout = 16, type = "repeat" })
end

hl.bind(mod .. " + mouse:272", start_drag_window, { mouse = true })
hl.bind(mod .. " + mouse:272", stop_drag_window, { mouse = true, release = true })
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
