hl.config({
    misc = {
        disable_hyprland_logo    = true,
        force_default_wallpaper  = 0,
        disable_splash_rendering = true,
        allow_session_lock_restore = true,
        animate_manual_resizes   = false,
    },
})

-- Blur for Waybar panels
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
hl.layer_rule({ match = { namespace = "waybar" }, ignore_alpha = 0.3 })
