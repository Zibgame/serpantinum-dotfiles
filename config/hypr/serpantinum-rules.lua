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
