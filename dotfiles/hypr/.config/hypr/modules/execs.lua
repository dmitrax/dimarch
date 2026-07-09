-- =========================================================
-- DimArch OS — Initialization and Autostart Applications
-- =========================================================

-- Every var set in env.lua, by name (single source of truth — see env.lua).
local env_var_names = {}
for _, pair in ipairs(require("modules/env")) do
    table.insert(env_var_names, pair[1])
end
local env_var_list = table.concat(env_var_names, " ")

hl.on("hyprland.start", function()
    -- Export Hyprland session environment to DBus and systemd user services.
    -- Important for portals, keyring, Secret Service, browsers and desktop apps.
    --
    -- `uwsm finalize` is the real fix here, not a formality: it's what actually
    -- marks the compositor unit started and lets graphical-session.target (and
    -- everything gated on it — every XDG autostart .desktop entry UWSM manages)
    -- proceed. Nothing in this repo called it before, so XDG-autostart apps ran
    -- as bare systemd --user units with NONE of env.lua's vars — not QT_QPA_*,
    -- not GDK_*, not even the cursor theme. That's a session-scoped mechanism
    -- distinct from Hyprland's own process env: hl.exec_cmd() children (below)
    -- inherit Hyprland's live env by fork() and always worked fine; anything
    -- launched as its own systemd unit (autostart .desktop entries, hypridle.service)
    -- only ever sees what's been explicitly finalized here. Confirmed live
    -- 2026-07-09: Enpass's autostart process had zero QT_* vars in /proc/<pid>/environ.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY " .. env_var_list)
    hl.exec_cmd("uwsm finalize " .. env_var_list)

    -- GNOME Keyring / Secret Service.
    -- Required by Chromium/Vivaldi when using libsecret password storage.
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,pkcs11,ssh")

    -- XWayland font rendering settings.
    -- Applies Xft.dpi and hinting from ~/.Xresources to all XWayland apps
    -- (Steam, Enpass, Zoom, etc). Must run before any XWayland app starts.
    hl.exec_cmd("xrdb -merge ~/.Xresources")

    -- Desktop services
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar -c ~/.config/waybar/config-top.jsonc -s ~/.config/waybar/style.css")

    -- Clipboard history daemon.
    -- Watches clipboard and stores entries in cliphist database.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- hypridle is managed by systemd user service.
    -- Do NOT start it here — that would create a second instance
    -- which may bypass idle inhibitors (caffeine / idle_inhibitor).
    -- Enable once: systemctl --user enable --now hypridle.service
    -- hl.exec_cmd("hypridle")

    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("hyprland-per-window-layout")
  -- hl.exec_cmd("hyprswitch init --show-title &")

    -- caffeine-ng removed: it uses org.freedesktop.ScreenSaver (X11-era),
    -- which is NOT the idle inhibit channel hypridle listens to on Wayland.
    -- Caffeine is now handled by the idle_inhibitor module in Waybar —
    -- it uses zwp_idle_inhibit_manager_v1 (native Wayland protocol).
    -- hl.exec_cmd("caffeine-ng")

    -- Polkit authentication agent (hyprpolkitagent) is started via its own
    -- systemd user service (WantedBy=graphical-session.target), not from here —
    -- see 03-base.sh. Keeps it alive across Hyprland Safe Mode / config reloads.

    -- Auto-mount daemon for removable media (USB drives, SD cards).
    -- Replaces automounting that GNOME/KDE handle out of the box.
    hl.exec_cmd("udiskie --tray")

    -- Network tray icon. Required for the WireGuard VPN tray toggle
    -- (dimarch.conf [vpn]) — without it Waybar's tray module stays empty.
    hl.exec_cmd("nm-applet --indicator")

    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
