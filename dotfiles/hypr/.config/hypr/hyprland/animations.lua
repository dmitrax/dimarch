hl.config({
    animations = {
        enabled = true,
        bezier = {
            {"maclike", 0.25, 1, 0.5, 1},
        },
        animation = {
            {"windows",    true, 4, "maclike", "slide"},
            {"windowsOut", true, 3, "maclike", "slide"},
            {"fade",       true, 4, "maclike"},
            {"workspaces", true, 5, "maclike", "slidevert"},
        },
    },
})
