# Link router — Zoom-direct joins + browser picker

Routes every http(s) link on the system through a small script instead of a single
hardcoded default browser. Deployed by `install/utils/setup-link-router.sh`.

---

## Why this exists

Zoom's Linux client has an unresolved render-layer bug (garbage buffer-size requests in
its Qt Quick rendering path — see `docs/troubleshooting.md`) that reliably crashes or
hangs when a meeting is joined through a browser-mediated link: click → browser opens
the `https://…zoom.us/j/…` page → the page's JS redirects to a `zoommtg://` deep link →
Zoom receives it. Joining the same meeting directly through Zoom's own **Join** dialog
(manual meeting ID + password, no browser involved) reliably avoids the bug. The link
router automates that workaround so it doesn't depend on remembering to do it manually
every time — and, since a default browser had to be re-registered to make that possible,
it also fixes an unrelated annoyance: only ever getting one hardcoded default browser
with no say in which one opens.

## What it does

- **`https://*.zoom.us/j/ID?pwd=...` links** are converted straight to
  `zoommtg://HOST/join?action=join&confno=ID&pwd=...` and handed to the Zoom app — no
  browser opens at all.
- **Every other http(s) link** prompts a `rofi` picker listing installed browsers,
  discovered dynamically from `.desktop` files declaring
  `MimeType=...x-scheme-handler/https...` (installing/removing a browser package needs
  no changes here — nothing is hardcoded). Duplicate `.desktop` entries pointing at the
  same underlying binary (common with Chrome/Edge/Yandex, which often ship two files for
  one browser) are collapsed to one, shown with their real display name and icon.
- After launching, jumps to whichever Hyprland workspace the browser's window ends up
  on (single-instance browsers reuse an existing window rather than opening on the
  current workspace). If the browser wasn't already running, Hyprland opens the new
  window on the current workspace anyway, so there's nothing extra to do there.

## How it's wired in

Unlike a per-app setting, there's no way to special-case just Zoom links without owning
the *entire* system default for `x-scheme-handler/https`/`/http` — `xdg-open`/portal/gio
resolution all bottom out at the same `~/.config/mimeapps.list` "default application"
entry, whichever it points to gets *every* http(s) link, not just Zoom's.
`setup-link-router.sh`:

1. Deploys `zoom-link-handler` + `link-router` to `~/.local/bin/`.
2. Deploys `link-router.desktop` to `~/.local/share/applications/` (a real, `NoDisplay`
   application entry — not a PATH trick).
3. Runs `xdg-mime default link-router.desktop x-scheme-handler/https x-scheme-handler/http`.

This is the same standard mechanism actual browsers use to register themselves as "the"
default browser — not a shim, not a shadowed binary. It's confirmed to work regardless
of *how* a caller resolves the default (a bare `xdg-open` call, an absolute-path
`/usr/bin/xdg-open` call — this is specifically what Telegram Desktop uses — or
`gio`/`gtk-launch`-based resolution).

## Setup

```bash
./install/utils/setup-link-router.sh
```

Run as your normal user, not root. Idempotent — safe to re-run after installing a new
browser (nothing needs updating; discovery is dynamic) or after a system reinstall.

## Known limitations

- **Chrome/browser multi-profile ambiguity.** If a browser has two profiles open as
  separate windows, the router can't target a specific one — the URL goes to whichever
  instance's singleton IPC lock is grabbed first. The workspace-jump logic best-effort
  guesses (the most-recently-focused window of the matching class), but can't guarantee
  it picks the profile you meant. Inherent to how single-instance browsers work, not
  fixable from the router's side without explicit profile-directory targeting.
- **Requires the caller to resolve links via `xdg-mime`/`mimeapps.list`.** This covers
  `xdg-open` (by name or absolute path) and `gio`/`gtk-launch`-based resolution, which is
  what's been observed and tested (including a real Telegram Desktop click). An app using
  a completely different, non-standard mechanism to open links would bypass it —
  no such case has been found yet on this system.
