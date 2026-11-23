-- Serpantinum — monitors, look and feel, environment, autostart.

local home = os.getenv("HOME")

-- ==========================================
-- MONITORS
-- ==========================================

-- Secondary monitor: iiyama, portrait, left
hl.monitor({
    output = "DP-1",
    mode = "1920x1080@60",
    position = "1920x0",
    scale = 1,
    transform = 1
})

-- Primary monitor: AOC, landscape, right
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@239.96",
    position = "0x0",
    scale = 1,
    transform = 0
})

-- ==========================================
-- WORKSPACES
-- ==========================================

-- Main workspace on AOC
hl.workspace_rule({
    workspace = "1",
    monitor = "HDMI-A-1",
    default = true
})

-- Secondary workspace on iiyama
hl.workspace_rule({
    workspace = "2",
    monitor = "DP-1",
    default = true
})

-- ==========================================
-- ENVIRONMENT
-- ==========================================

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- ==========================================
-- APPEARANCE AND INPUT
-- ==========================================

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        resize_on_border = true,
        layout = "dwindle",
        col = {
            active_border = {
                colors = {
                    "rgba(33ccffee)",
                    "rgba(00ff99ee)"
                },
                angle = 45
            },
            inactive_border = "rgba(595959aa)",
        },
    },

    decoration = {
        rounding = 8,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0xee1a1a1a,
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            vibrancy = 0.17,
            vibrancy_darkness = 0.0,
            noise = 0.0117,
            contrast = 0.8916,
            brightness = 1.0,
            ignore_opacity = false,
            xray = false,
            special = false,
            new_optimizations = true,
        },
    },

    input = {
        kb_layout = "us",
        -- Windows-like focus: Alt+Tab keeps the selected window focused even
        -- when the pointer is still over another window. Clicking a window
        -- focuses it; merely moving the pointer does not steal focus.
        follow_mouse = 0,
        touchpad = {
            natural_scroll = true
        },
    },

    binds = {
        -- Keep the exact point grabbed by the mouse when a window is restored
        -- and resized at the beginning of a drag.
        drag_center_window = false,
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },
    cursor = {
        no_hardware_cursors = 1,
    },
})
-- No move/resize animation: windows must change size instantly (e.g. when
-- the Alt+Tab switcher restores a maximized/fullscreen window).
hl.animation({ leaf = "windowsMove", enabled = false })

-- No fade animation anywhere (windows, workspaces, layers, popups, DPMS).
for _, leaf in ipairs({
    "fade", "fadeIn", "fadeOut", "fadeSwitch",
    "fadeShadow", "fadeDim", "fadeDpms", "fadeGlow",
    "fadeLayers", "fadeLayersIn", "fadeLayersOut",
    "fadePopups", "fadePopupsIn", "fadePopupsOut",
}) do
    hl.animation({ leaf = leaf, enabled = false })
end

-- ==========================================
-- AUTOSTART
-- ==========================================

hl.on("hyprland.start", function()
    -- Create standard user directories
    hl.exec_cmd("xdg-user-dirs-update")

    -- VirtualBox clipboard support
    hl.exec_cmd(
        "command -v VBoxClient >/dev/null 2>&1 && VBoxClient --clipboard"
    )

    -- Serpantinum startup
    hl.exec_cmd(
        "sh -c '" .. home .. "/.local/bin/serpantinum-autostart.sh'"
    )
    hl.exec_cmd("sh -c '" .. home .. "/.local/bin/serpantinum-app-switcher start &'")
end)
