-- AMD RX 580 (Polaris / GFX 8.0.3) — mandatory ROCm fix
hl.config({
    env = {
        {"HSA_OVERRIDE_GFX_VERSION", "8.0.3"},
        {"XCURSOR_SIZE", "24"},
        {"QT_QPA_PLATFORM", "wayland"},
        {"QT_QPA_PLATFORMTHEME", "qt6ct"},
    },
})
