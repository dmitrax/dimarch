-- =========================================================
-- DimArch OS — Environment
-- Hyprland / Lua config
-- =========================================================

-- Single source of truth: execs.lua reads this table back (via require) to
-- finalize the same variable names into the systemd --user manager environment.
-- Without that, only Hyprland's own direct children (spawned via hl.exec_cmd)
-- ever see these vars — anything launched as its own systemd unit (XDG autostart
-- .desktop entries under UWSM, hypridle.service, etc.) runs with none of them.
local env_vars = {
    -- Session identity
    {"XDG_CURRENT_DESKTOP", "Hyprland"},
    {"XDG_SESSION_DESKTOP", "Hyprland"},
    {"XDG_SESSION_TYPE", "wayland"},

    -- Cursor
    {"XCURSOR_THEME", "Bibata-Modern-Classic"},
    {"XCURSOR_SIZE", "24"},
    {"HYPRCURSOR_THEME", "Bibata-Modern-Classic"},
    {"HYPRCURSOR_SIZE", "24"},

    -- Qt / GTK / Mozilla Wayland
    {"QT_QPA_PLATFORM", "wayland;xcb"},
    {"QT_QPA_PLATFORMTHEME", "qt6ct"},
    {"GDK_BACKEND", "wayland,x11,*"},
    {"GDK_SCALE", "1"},
    {"GDK_DPI_SCALE", "1"},
    {"MOZ_ENABLE_WAYLAND", "1"},
}

-- hl.env(), not hl.config({ env = ... }): the latter is accepted without any
-- error or configerrors entry and sets nothing (probed via `hyprctl repl` +
-- os.getenv on 0.56.2, 2026-09-19) — every var below was silently missing from
-- every process, so uwsm finalize in execs.lua had nothing to export either.
for _, pair in ipairs(env_vars) do
    hl.env(pair[1], pair[2])
end

return env_vars
