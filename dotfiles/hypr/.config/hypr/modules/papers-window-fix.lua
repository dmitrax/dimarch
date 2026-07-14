-- =========================================================
-- DimArch OS — Papers maximize-on-open fix
--
-- Papers (org.gnome.Papers) requests its own maximized state on every
-- fresh window, which wins the race against rules.lua's static `size`
-- window_rule for the same class. Confirmed live 2026-07-14/15:
--
--   1. win.monitor.width/height in this Lua API are PHYSICAL pixels
--      (e.g. 3840x2160 on DP-1 at scale 1.5), but win.monitor.x/y are
--      LOGICAL layout coordinates (e.g. 1920,0) — a mixed-unit struct.
--      Divide width/height by win.monitor.scale before computing a
--      target size, or the numbers overshoot the real logical monitor
--      bounds and Hyprland clamps the window back to maximized.
--   2. hl.dsp.window.resize is flatly REJECTED ("Window is fullscreen")
--      while the window is in Hyprland's true fullscreen mode
--      (fullscreen=2) — retrying a rejected resize never helps.
--   3. hl.dsp.window.fullscreen({window=...}) — called with NO
--      `fullscreen` key — is a plain TOGGLE: from MAXIMIZED (1) it lands
--      on true FULLSCREEN (2), not normal (0); a second toggle from (2)
--      lands on (0). Passing an explicit `fullscreen = false` does NOT
--      mean "turn off" — it still just toggles.
--   4. Papers' own maximize request is already in effect by the time
--      window.open fires — a poll immediately after open already reads
--      fullscreen=1, so there is nothing to "wait for". The original
--      version of this fix added a 400ms delay before checking at all,
--      which only made the visible maximized flash longer for no reason.
--      Removed — settle() runs immediately.
--
-- Net fix: toggle fullscreen off in a bounded loop (checking real state
-- each time, since one toggle may only get partway from 1 to 0 via 2)
-- before resizing to the target fraction of the monitor. This means a
-- brief (~250ms) visible flash of the maximized state is unavoidable
-- with this approach — investigated going lower 2026-07-15:
--   - The 2 dispatches (1→2, then 2→0) are a hard floor, not just this
--     code's choice — tried passing explicit fullscreen=0 and
--     fullscreen=1 arguments hoping one would jump 1→0 directly, both
--     still only ever moved one step (to 2), never straight to 0.
--   - 250ms between the two dispatches is the shortest tested gap that
--     works reliably; 120ms was tried and the window got stuck at
--     fullscreen=1 (the state check after 120ms was still reading the
--     pre-toggle value, so the bounded-attempts loop ran out and gave up
--     mid-toggle). Something between 120-250ms might work but would need
--     many repeated runs to trust — the downside of guessing wrong is a
--     window stuck maximized, worse than a slightly longer flash.
--   - Hiding the window (opacity) during the fix instead of racing it
--     was considered and rejected: no opacity/visibility dispatcher is
--     documented or found for a specific window address, and patching
--     Papers itself to not request maximize at all would break this
--     project's policy against hand-patching package-managed software
--     (same reasoning as the mpv-uosc / Looking Glass decisions).
-- =========================================================

local function find_window(address)
    for _, w in ipairs(hl.get_windows({ class = "org.gnome.Papers" })) do
        if w.address == address then
            return w
        end
    end
    return nil
end

hl.on("window.open", function(win)
    if win.class ~= "org.gnome.Papers" then
        return
    end
    if not win.monitor then
        return
    end

    local scale = win.monitor.scale or 1
    local logical_w = win.monitor.width / scale
    local logical_h = win.monitor.height / scale

    local w = math.floor(logical_w * 0.6)
    local h = math.floor(logical_h * 0.85)
    local x = win.monitor.x + math.floor((logical_w - w) / 2)
    local y = win.monitor.y + math.floor((logical_h - h) / 2)

    local address = win.address

    local function settle(attempts_left)
        local current = find_window(address)
        if not current then
            return
        end

        if current.fullscreen ~= 0 and attempts_left > 0 then
            hl.dispatch(hl.dsp.window.fullscreen({ window = "address:" .. address }))
            hl.timer(function()
                settle(attempts_left - 1)
            end, { timeout = 250, type = "oneshot" })
            return
        end

        hl.dispatch(hl.dsp.window.resize({ x = w, y = h, window = "address:" .. address }))
        hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = "address:" .. address }))
    end

    -- Calling settle() synchronously in the same call stack as window.open
    -- itself did nothing at all (not even a failed attempt) — deferring to
    -- a timer, even a very short one, is required. 400ms was massive
    -- overkill though (see note 4 above); a minimal defer is enough.
    hl.timer(function()
        settle(3)
    end, { timeout = 10, type = "oneshot" })
end)
