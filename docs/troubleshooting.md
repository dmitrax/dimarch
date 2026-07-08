# Troubleshooting — DimArch OS

---

## Oversized fonts in GTK apps (Thunar, etc.)

**Symptom:** GTK applications (Thunar, settings dialogs, etc.) display oversized fonts
in Hyprland, while the same apps look normal in XFCE.

**Root cause:** A leftover `~/.config/environment.d/wayland.conf` from a previous XFCE
session was loaded by systemd at login — before Hyprland starts — and contained:

```ini
GDK_DPI_SCALE=1.5          # forces 150% font scaling on all GTK apps
XDG_CURRENT_DESKTOP=XFCE   # wrong desktop identity
XCURSOR_SIZE=36             # conflicts with Hyprland env.lua (24)
WAYLAND_DISPLAY=wayland-1  # hardcoded, unsafe
```

`GDK_DPI_SCALE=1.5` combined with Hyprland's own compositor scaling for the 4K monitor
resulted in fonts being scaled twice.

**Fix:**

```bash
rm ~/.config/environment.d/wayland.conf
```

All required environment variables are already correctly defined in
`~/.config/hypr/hyprland/env.lua`, including `GDK_DPI_SCALE=1`.

**Lesson:** After migrating from another DE, check `~/.config/environment.d/` for
leftover configs that may conflict with Hyprland's environment setup.



## Civilization V — native Linux profile (Hyprland 4K HiDPI)

**Setup:** Civilization V, native Linux version (not Proton), launched on
Hyprland with `force_zero_scaling = true` and `Xft.dpi: 144` (DP-1, LG 4K,
scale 1.5).

**Symptoms before fix:**
- Proton version: grey bar on the right side of the screen at 2560x1440,
  wrong window position at 3840x2160, Anti-Aliasing greyed out regardless
  of `AllowLeaderAA` in `GraphicsSettingsDX11.ini`.
- gamescope wrappers (`-F fsr`, `-F nearest`, various `-w/-h/-W/-H`
  combinations) either reintroduced the grey bar or produced oversized UI
  with soft fonts. With native version, gamescope also caused noticeable
  lag after ~10 turns.
- Native version without gamescope: game minimizes to a small window when
  switching workspaces, requiring Ctrl+F to restore fullscreen every time.

**Working fix — Launch Options:**

```
SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0 mesa_glthread=true allow_glsl_extension_directive_midshader=true MESA_GLSL_CACHE_DISABLE=false MESA_SHADER_CACHE_MAX_SIZE=1G %command%
```

- `SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0` — prevents the game from exiting
  fullscreen / minimizing when switching workspaces or losing focus. This
  was the key fix for the workspace-switch issue.
- `mesa_glthread=true` — improves OpenGL performance on Mesa.
- `allow_glsl_extension_directive_midshader=true` — compatibility for Civ V's
  older GLSL shader code on modern Mesa.
- `MESA_GLSL_CACHE_DISABLE=false` + `MESA_SHADER_CACHE_MAX_SIZE=1G` — keeps
  shader cache enabled with a reasonable size limit.

**Settings:** Display Mode = Fullscreen, resolution 2560x1440 (matches DP-1
effective resolution at scale 1.5).

**Rule of thumb:** Do not use gamescope for native Civ V on this hardware —
it caused either visual regressions (grey bar) or performance degradation
(lag after several turns) in every tested configuration. Proton was also
tested and rejected — see symptoms above.



## Zoom crashes/hangs joining a meeting via a clicked link

**Symptom:** Zoom's Linux client crashes (`QSGRhiLayer: Unsupported size requested`,
`stack smashing detected`, or a `libgallium`/Mesa RadeonSI abort) or silently hangs
(audio connects, meeting window never renders — `eglSwapBuffers failed with 0x300d`)
when joining a meeting by clicking an invite link (in a browser, Telegram, email, etc.).

**Root cause:** unresolved defect in Zoom's own Qt Quick rendering code — reproduces
even on pure software rendering (`llvmpipe`, GPU driver not involved at all), so it's not
an RX 580/Mesa/Hyprland bug. The trigger correlates with the **join path**: a
browser-mediated link click (`xdg-open` → browser → `zoommtg://` deep link → Zoom) is
where it fires; joining the same meeting directly through Zoom's own **Join** dialog
(manual meeting ID + password, no browser involved) reliably avoids it. Investigated
extensively without a confirmed root mechanism — treat as a known, unexplained Zoom
Linux-client defect, not something fixable from the DimArch side.

**Fix:** join through Zoom's own Join dialog instead of clicking links — or, automated,
install the link router (`docs/link-router.md`,
`install/utils/setup-link-router.sh`), which transparently converts any `zoom.us/j/...`
link into a direct app launch, skipping the browser hop entirely.

**Not a fix:** joining via the browser tab instead of the native app "works" but isn't a
real solution — it defeats the point of having a native client.
