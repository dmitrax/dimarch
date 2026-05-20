-- =========================================================
-- DimArch OS — Environment
-- Hyprland / Lua config
-- =========================================================

hl.config({
    env = {
        -- AMD RX 580 Polaris / GFX 8.0.3 — mandatory ROCm fix
        {"HSA_OVERRIDE_GFX_VERSION", "8.0.3"},

        -- Session identity
        {"XDG_CURRENT_DESKTOP", "Hyprland"},
        {"XDG_SESSION_DESKTOP", "Hyprland"},
        {"XDG_SESSION_TYPE", "wayland"},

        -- Cursor
        {"XCURSOR_SIZE", "24"},

        -- Qt / GTK / Mozilla Wayland
        {"QT_QPA_PLATFORM", "wayland;xcb"},
        {"QT_QPA_PLATFORMTHEME", "qt6ct"},
        {"GDK_SCALE", "1"},
        {"GDK_DPI_SCALE", "1"},
        {"MOZ_ENABLE_WAYLAND", "1"},
    },
})
