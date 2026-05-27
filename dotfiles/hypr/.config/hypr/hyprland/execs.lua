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
    hl.exec_cmd("waybar -c ~/.config/waybar/config-top.jsonc -s ~/.config/waybar/style.css")
        -- Clipboard history daemon
        -- Watches clipboard and stores entries in cliphist database
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("hyprland-per-window-layout")
  -- hl.exec_cmd("hyprswitch init --show-title &")

    -- Polkit authentication agent
    -- Required for GUI privilege escalation dialogs (Dolphin, Flatpak, etc.)
    -- Without this, GUI apps silently fail when requesting root permissions
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Auto-mount daemon for removable media (USB drives, SD cards)
    -- Replaces automounting that GNOME/KDE handle out of the box
    hl.exec_cmd("udiskie --tray")

    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
