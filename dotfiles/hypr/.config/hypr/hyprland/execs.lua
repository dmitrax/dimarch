-- =========================================================
-- DimArch OS — Initialization and Autostart Applications
-- =========================================================

hl.on("hyprland.start", function()
    -- Export Hyprland session environment to DBus and systemd user services.
    -- Important for portals, keyring, Secret Service, browsers and desktop apps.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE")

    -- GNOME Keyring / Secret Service.
    -- Required by Chromium/Vivaldi when using libsecret password storage.
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11,ssh")

    -- Desktop services
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("hyprland-per-window-layout")
end)
