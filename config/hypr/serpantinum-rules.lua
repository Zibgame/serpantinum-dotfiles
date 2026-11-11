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
-- The bar, launchers and notification daemons get the frosted-glass
-- treatment; the wallpaper layers obviously do not. Fullscreen transparent
-- overlays (qs-floating-overlay) must NOT be blurred: a blur rule on a
-- full-screen transparent layer blurs the entire desktop seen through it.
local blurrable_layers = {
    "quickshell",           -- Serpantinum bar, dock and widgets
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
        -- Do not blur the transparent padding of layer surfaces.  The
        -- Serpantinum top bar is 40 px high but its surface is 52 px high in
        -- fill mode so it can draw the rounded bottom corners.  Blurring the
        -- fully transparent 12 px tail creates a dark strip below the bar.
        ignore_alpha = 0.18,
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
