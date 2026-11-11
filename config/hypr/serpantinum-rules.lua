-- Serpantinum — window rules.
--
-- Serpantinum is a *floating* desktop: no automatic tiling, no Tiling Shell.
-- Every window opens floating and centred, so it can be moved, resized and
-- organised freely, exactly like Ubuntu's window manager.

hl.window_rule({
    name  = "serpantinum-float-all",
    match = { class = ".*" },
    float  = true,
})

hl.window_rule({
    name   = "serpantinum-center-all",
    match  = { class = ".*" },
    center = true,
})

-- XWayland helper windows (empty class/title) must not steal focus.
hl.window_rule({
    name  = "serpantinum-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Serpantinum — glass blur for every layer surface that can be blurred.
-- The bar, dock, floating panels, launchers and notification daemons get the
-- frosted-glass treatment; the wallpaper layers obviously do not.
local blurrable_layers = {
    "quickshell",           -- Serpantinum bar, dock and widgets
    "qs-floating-overlay",  -- Serpantinum floating panels / quick actions
    "wofi",                 -- application launcher
    "rofi",                 -- launcher (alternative)
    "dunst",                -- notification daemon
    "swaync",               -- notification center
    "waybar",               -- in case a third-party bar is used
}

for _, namespace in ipairs(blurrable_layers) do
    hl.layer_rule({
        name = "serpantinum-blur-" .. namespace,
        match = { namespace = namespace },
        blur = true,
        blur_popups = true,
    })
end

-- kitty and foot ship their own background alpha (background-only, so the
-- text stays crisp). GNOME Terminal has no native transparency: make it
-- translucent at the compositor level so the glass blur still applies.
hl.window_rule({
    name   = "serpantinum-blur-gnome-terminal",
    match  = { class = "org.gnome.Terminal" },
    opacity = "0.85",
})
