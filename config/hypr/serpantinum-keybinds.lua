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
-- Per-window maximized intent (Windows-like Alt+Tab)
------------------------------------------------------------
-- Hyprland permits only one internally maximized window per workspace. Keep
-- a tag on every window the user maximized, so the switcher can restore that
-- window's own state without copying maximization to ordinary windows.
local maximized_tag = "serpantinum-wants-maximized"
local maximize_generation = 0
local maximize_state_timers = {}

local function window_has_tag(w, wanted)
    for _, tag in ipairs((w and w.tags) or {}) do
        if tag == wanted then return true end
    end
    return false
end

local function set_maximized_tag(w, enabled)
    if not w or window_has_tag(w, maximized_tag) == enabled then return end
    hl.dispatch(hl.dsp.window.tag({
        tag = (enabled and "+" or "-") .. maximized_tag,
        window = w,
    }))
end

local function tagged_maximized_candidate(workspace, excluded)
    if not workspace then return nil end
    local best = nil
    local best_focus = math.huge
    for _, w in ipairs(hl.get_windows() or {}) do
        if w ~= excluded and w.mapped and not w.hidden and
           w.workspace and w.workspace.id == workspace.id and
           window_has_tag(w, maximized_tag) then
            local focus = tonumber(w.focus_history_id) or math.huge
            if focus < best_focus then
                best = w
                best_focus = focus
            end
        end
    end
    return best
end

local function restore_window_maximized(w)
    if not w then return end
    hl.dispatch(hl.dsp.window.fullscreen({
        action = "set",
        mode = "maximized",
        window = w,
    }))
    hl.dispatch(hl.dsp.focus({ window = w }))
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = w }))
end

for _, existing_window in ipairs(hl.get_windows() or {}) do
    local mode = tonumber(existing_window.fullscreen) or 0
    if mode == 1 or mode == 3 then set_maximized_tag(existing_window, true) end
end

local maximized_state_subscription = hl.on("window.fullscreen", function(w)
    if not w then return end
    local mode = tonumber(w.fullscreen) or 0
    if mode == 1 or mode == 3 then
        maximize_generation = maximize_generation + 1
        set_maximized_tag(w, true)
        return
    end

    if mode ~= 0 or not window_has_tag(w, maximized_tag) then return end
    local generation_at_restore = maximize_generation
    local address = tostring(w.address or w)
    if maximize_state_timers[address] then
        maximize_state_timers[address]:set_enabled(false)
    end
    maximize_state_timers[address] = hl.timer(function()
        maximize_state_timers[address] = nil
        -- A different window becoming maximized immediately afterwards means
        -- Hyprland transferred its exclusive max slot during Alt+Tab. Keep
        -- both intentions. Otherwise this was an explicit user restore.
        if generation_at_restore == maximize_generation and
           tonumber(w.fullscreen) == 0 then
            set_maximized_tag(w, false)
        end
    end, { timeout = 150, type = "oneshot" })
end)

-- Closing the exclusive maximized window makes Hyprland restore the previous
-- window's old floating geometry. Recover the next window's own maximized
-- intent immediately, including closes performed with a titlebar button.
local close_restore_timer = nil
local close_restore_subscription = hl.on("window.destroy", function()
    if close_restore_timer then close_restore_timer:set_enabled(false) end
    close_restore_timer = hl.timer(function()
        close_restore_timer = nil
        for _, workspace in ipairs(hl.get_workspaces() or {}) do
            if workspace.visible and not workspace.has_fullscreen then
                local candidate = tagged_maximized_candidate(workspace, nil)
                if candidate then restore_window_maximized(candidate) end
            end
        end
    end, { timeout = 1, type = "oneshot" })
end)

------------------------------------------------------------
-- Launchers
------------------------------------------------------------
-- Terminal shortcuts live in hyprland.lua, so they are always registered.
hl.bind("Super_L", hl.dsp.exec_cmd("serpantinum msg toggle launcher"), { release = true })

------------------------------------------------------------
-- Close / focus
------------------------------------------------------------
local function close_active_window()
    local closing = hl.get_active_window()
    if not closing then return end
    local mode = tonumber(closing.fullscreen) or 0
    local restore = nil
    if mode == 1 or mode == 3 then
        restore = tagged_maximized_candidate(closing.workspace, closing)
    end

    -- Close and restore in the same Lua dispatch cycle so the underlying
    -- window is never presented for a frame at its old small geometry.
    hl.dispatch(hl.dsp.window.close())
    if restore then restore_window_maximized(restore) end
end

hl.bind("ALT + F4", close_active_window)
hl.bind(mod .. " + Q", close_active_window)
-- Quickshell visual Alt+Tab installed by modules/35-hypr-app-switcher.sh.
local switcher = home .. "/.local/bin/serpantinum-app-switcher"
hl.bind("ALT + Tab", hl.dsp.exec_cmd("'" .. switcher .. "' next"), { description = "Visual app switcher: next" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("'" .. switcher .. "' prev"), { description = "Visual app switcher: previous" })
-- Commit from Hyprland itself when Alt is released. A layer-shell surface can
-- miss the modifier release while it is acquiring keyboard focus, leaving an
-- invisible input-blocking overlay behind. These non-consuming global release
-- binds make the switcher close reliably even in that race.
local switcher_release_options = {
    release = true,
    locked = true,
    non_consuming = true,
    dont_inhibit = true,
}
hl.bind("Alt_L", hl.dsp.exec_cmd("'" .. switcher .. "' release"), switcher_release_options)
hl.bind("Alt_R", hl.dsp.exec_cmd("'" .. switcher .. "' release"), switcher_release_options)

------------------------------------------------------------
-- Windows/Ubuntu window snapping (floating windows)
------------------------------------------------------------
hl.bind(mod .. " + left", hl.dsp.exec_cmd("'" .. snap .. "' left"))
hl.bind(mod .. " + right", hl.dsp.exec_cmd("'" .. snap .. "' right"))

-- Super+Up maximizes immediately. Hyprland remembers the previous floating
-- geometry, so Super+Down can walk back through the same states as Windows.
local function window_near_cursor()
    local cursor = hl.get_cursor_pos()
    if not cursor then return nil end

    local best = nil
    local best_distance = math.huge
    local best_focus = math.huge
    for _, w in ipairs(hl.get_windows() or {}) do
        if w.mapped and w.visible and not w.hidden then
            local x = tonumber(w.at.x) or 0
            local y = tonumber(w.at.y) or 0
            local width = math.max(1, tonumber(w.size.x) or 1)
            local height = math.max(1, tonumber(w.size.y) or 1)
            local dx = math.max(x - cursor.x, 0, cursor.x - (x + width))
            local dy = math.max(y - cursor.y, 0, cursor.y - (y + height))
            local distance = dx * dx + dy * dy
            local focus = tonumber(w.focus_history_id) or math.huge
            -- Eight logical pixels cover borders/gaps at a split boundary.
            if distance <= 64 and
               (distance < best_distance or
                (distance == best_distance and focus < best_focus)) then
                best = w
                best_distance = distance
                best_focus = focus
            end
        end
    end
    return best
end

local function maximize_cursor_window()
    local w = window_near_cursor() or hl.get_active_window()
    if not w then return end
    restore_window_maximized(w)
end

hl.bind(mod .. " + up", maximize_cursor_window)

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
local drag_last_cursor_x = nil
local drag_last_cursor_y = nil
local drag_last_window_x = nil
local drag_last_window_y = nil

local function stop_drag_window()
    drag_active = false
    dragged_window = nil
    drag_last_cursor_x = nil
    drag_last_cursor_y = nil
    drag_last_window_x = nil
    drag_last_window_y = nil
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

    -- The native drag owns the mouse grab and ends automatically on button
    -- release. If the pointer moves but Hyprland no longer moved the window,
    -- the grab has ended: stop our size-enforcement timer as well.
    local cursor_moved = drag_last_cursor_x and
        (math.abs(cursor.x - drag_last_cursor_x) > 0.1 or
         math.abs(cursor.y - drag_last_cursor_y) > 0.1)
    local native_moved_window = drag_last_window_x and
        (math.abs((tonumber(dragged_window.at.x) or 0) - drag_last_window_x) > 0.1 or
         math.abs((tonumber(dragged_window.at.y) or 0) - drag_last_window_y) > 0.1)
    if cursor_moved and drag_last_window_x and not native_moved_window then
        stop_drag_window()
        return
    end

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
    drag_last_cursor_x = cursor.x
    drag_last_cursor_y = cursor.y
    drag_last_window_x = target_x
    drag_last_window_y = target_y
end

-- Normal Windows-style titlebar drag, without holding Super. Hyprland emits
-- this event when dragging a maximized window by its titlebar restores it.
-- Do not resize immediately: focus changes (including Alt+Tab) can emit the
-- same fullscreen-exit event. Require both the cursor and window goal to move
-- before recognizing this as a real mouse drag.
local titlebar_detection_timer = nil

local function stop_titlebar_detection()
    if titlebar_detection_timer then
        titlebar_detection_timer:set_enabled(false)
        titlebar_detection_timer = nil
    end
end

local titlebar_restore_subscription = hl.on("window.fullscreen", function(w)
    if not w or tonumber(w.fullscreen) ~= 0 then return end

    -- Keyboard snapping also exits maximized mode, but it is not a titlebar
    -- drag. The snap helper adds this short-lived tag around that transition.
    for _, tag in ipairs(w.tags or {}) do
        if tag == "serpantinum-keyboard-snap" then return end
    end

    local cursor = hl.get_cursor_pos()
    local monitor = hl.get_monitor_at_cursor() or w.monitor
    if not cursor or not monitor then return end

    local scale = tonumber(monitor.scale) or 1
    local monitor_width = (tonumber(monitor.width) or drag_width) / scale
    local monitor_height = (tonumber(monitor.height) or drag_height) / scale
    local transform = tonumber(monitor.transform) or 0
    if transform == 1 or transform == 3 or transform == 5 or transform == 7 then
        monitor_width, monitor_height = monitor_height, monitor_width
    end

    local reserved = monitor.reserved or {}
    local work_x = (tonumber(monitor.x) or 0) + (tonumber(reserved[1]) or 0)
    local work_y = (tonumber(monitor.y) or 0) + (tonumber(reserved[2]) or 0)
    local work_width = monitor_width - (tonumber(reserved[1]) or 0) - (tonumber(reserved[3]) or 0)
    local work_height = monitor_height - (tonumber(reserved[2]) or 0) - (tonumber(reserved[4]) or 0)

    -- A real titlebar restore starts next to the top edge. This guard avoids
    -- resizing a window restored with Super+Down or an application shortcut.
    if cursor.y < work_y or cursor.y > work_y + 90 then return end

    drag_ratio_x = clamp((cursor.x - work_x) / math.max(1, work_width), 0, 1)
    drag_ratio_y = clamp((cursor.y - work_y) / math.max(1, work_height), 0, 1)

    local start_cursor_x = cursor.x
    local start_cursor_y = cursor.y
    local start_window_x = tonumber(w.at.x) or 0
    local start_window_y = tonumber(w.at.y) or 0
    local checks = 0

    stop_titlebar_detection()
    titlebar_detection_timer = hl.timer(function()
        checks = checks + 1
        local current_cursor = hl.get_cursor_pos()
        if not current_cursor or not w.mapped or tonumber(w.fullscreen) ~= 0 then
            stop_titlebar_detection()
            return
        end

        local cursor_moved = math.abs(current_cursor.x - start_cursor_x) > 2 or
            math.abs(current_cursor.y - start_cursor_y) > 2
        local window_moved = math.abs((tonumber(w.at.x) or 0) - start_window_x) > 2 or
            math.abs((tonumber(w.at.y) or 0) - start_window_y) > 2

        if cursor_moved and window_moved then
            stop_titlebar_detection()
            stop_drag_window()
            dragged_window = w
            drag_active = true
            update_drag_window()
            drag_timer = hl.timer(update_drag_window, { timeout = 16, type = "repeat" })
        elseif checks >= 20 then
            stop_titlebar_detection()
        end
    end, { timeout = 16, type = "repeat" })
end)

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

    stop_titlebar_detection()
    stop_drag_window()
    dragged_window = w
    drag_active = true

    -- Establish the 65x18 geometry before starting Hyprland's mouse grab.
    -- The repeating timer below keeps that geometry fixed while the native
    -- grab takes care of detecting the exact mouse-button release.
    update_drag_window()
    hl.dispatch(hl.dsp.window.drag())
    drag_timer = hl.timer(update_drag_window, { timeout = 16, type = "repeat" })
end

hl.bind(mod .. " + mouse:272", start_drag_window, { mouse = true })
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
