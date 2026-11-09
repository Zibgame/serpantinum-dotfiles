-- Serpantinum — monitors, look and feel, environment, autostart.

local home = os.getenv("HOME")
local data_home = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
local wallpaper = data_home .. "/serpantinum/wallpapers/serpantinum.jpg"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        resize_on_border = true,
        layout = "dwindle",
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
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
            size = 3,
            passes = 1,
        },
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = { natural_scroll = true },
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },
})

hl.on("hyprland.start", function()
    -- The systemd user autostart watcher runs the shell using hyprctl eval
    -- after the Hyprland Wayland session becomes available.
    hl.exec_cmd("swaybg -i '" .. wallpaper .. "' -m fill")
    hl.exec_cmd("xdg-user-dirs-update")
    -- VirtualBox guests: clipboard sharing between host and guest.
    hl.exec_cmd("command -v VBoxClient >/dev/null 2>&1 && VBoxClient --clipboard")
end)
