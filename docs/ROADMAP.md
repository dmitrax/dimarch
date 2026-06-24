# DimArch Desktop — Strategic Roadmap v2

> Modern system. Old soul.
> Hyprland-based desktop system — built for one, designed for everyone.

**Changelog from v1:**
- Bug severity classified (P0/P1/P2) — not all 4 bugs are equal blockers
- dimarchctl skeleton moved to Phase 0 (was Phase 3)
- dimarch.conf hardware abstraction moved to Phase 0 (was Phase 4)
- Installer as parallel track across all phases (not a late Phase 4 task)
- dimarch-taskbar v0.1 scope reduced: no tray, no clock
- Right-click desktop removed from Phase 1 exit criteria
- dimarch-daycenter introduced as a dedicated component (not "clock applet")
- WinApps moved out of main roadmap → optional apps
- Phase count restructured accordingly

---

## Architecture Model

```
DimArch OS
├── Hyprland Core         ← compositor, WM, IPC, animations, Lua config
├── DimArch Session       ← uwsm, systemd user services, portals, audio, polkit
├── DimArch Shell         ← taskbar, notifications, desktop layer, launcher
├── DimArch CLI           ← dimarchctl: health, snapshots, display, streaming
├── Sage Theme            ← visual identity (dimarch-theme repo)
└── DimArch Installer     ← install.sh → phases 01–09 → system ready
```

---

## Hard Rules

1. **Stability gates progress.** Phase 0 P0 bugs block everything. P1 bugs
   don't block shell development but must be tracked.
2. **CLI before GUI.** dimarchctl is the stable API. Control Center GUI comes
   after the API is stable and tested.
3. **Sage theme ships with each component.** No "we'll theme it later."
4. **Public-quality standard from day one.** If it only works on Dima's hardware,
   it's not done.
5. **One Claude Code session per task.** Code → review → commit → update
   CLAUDE.md/STATUS.md.
6. **Installer is always reproducible.** At any point in the roadmap, a fresh
   install via install.sh must produce a working system for the phases completed
   so far.

---

## Bug Severity Classification

### P0 — Blocking (gate for all shell development)

**BUG-01: GPU app crash after suspend/resume**

Symptom: Chrome, Firefox, Electron, Thunar close after resume; Ghostty/Telegram survive.

Hypotheses (none confirmed — gather evidence first):
- A: wlopm --off triggers amdgpu power state change killing GPU subprocesses
- B: browser/Electron GPU process fails during DRM/Wayland reinitialization
- C: resume hooks run in wrong order — monitor/portal/XWayland recover after clients

Required evidence before fixing:
```
journalctl -b -1 | grep -E 'amdgpu|drm|hyprland|chrome'
coredump analysis
/sys/kernel/debug/dri/0/ state after resume
hyprland log after resume
```
Hard constraints: no s2idle, no `hyprctl dispatch dpms`, no SIGSTOP/SIGCONT.

**BUG-02: XWayland resolution after resume**

Symptom: XWayland reports 1920×1080 instead of 3840×2160 on DP-1 after resume.
Direction: XWayland reinitializes before monitor reconfiguration completes.
Fix target: Xrandr re-trigger on resume, or Hyprland monitor reload hook timing.

**BUG-04: restore-after-resume.sh broken IPC**

Symptom: uses `hl.dsp.window.move` — does not exist in Hyprland 0.55 Lua.
Fix: replace with `movetoworkspace`, `resizewindowpixel`, `movewindowpixel`
     via `hyprctl eval`.

### P1 — Important (tracked, not blocking shell)

**BUG-03: Thunar "Open Terminal Here" broken via keybind/Rofi**

Symptom: works from terminal, fails when Thunar launched from keybind/Rofi.
Root: env/cwd difference at launch time.
Fix target: wrapper ensuring correct XDG env regardless of launch source.

### P2 — UX/polish (tracked for future phases)

- Right-click desktop
- dimarch-preview quick-look
- Workspace persistence after resume

---

## Parallel Tracks (run through all phases)

**Track A — Installer reproducibility**
Every phase includes installer work. At any point, install.sh must produce
a working system for all completed phases.

**Track B — Sage theme**
Every new component gets Sage-themed before the task is closed.
"We'll theme it later" is not accepted.

**Track C — Documentation**
Written as components ship. Not accumulated at the end.

---

## Phase 0 — Core Stability & Diagnostics

**Goal:** Stable foundation. Diagnostic tooling. Hardware abstraction skeleton.

**Entry:** Current state.
**Exit criteria:**
- P0 bugs resolved (BUG-01, BUG-02, BUG-04)
- `dimarchctl health` passes green on cold boot and after suspend/resume
- `dimarch.conf` minimal template exists and is read by install scripts

### 0.1 — Bug fixes

Fix BUG-01, BUG-02, BUG-04 per severity classification above.
Gather evidence before writing fixes. Do not assume root cause.

### 0.2 — dimarchctl skeleton

File: `install/utils/dimarchctl`

Phase 0 scope only:
```
dimarchctl health          Run health checks (--core by default)
dimarchctl display status  Show current monitor layout from hyprctl
dimarchctl version         DimArch OS version + component status
```

Design requirements:
- Bash-first implementation
- `--json` flag on every command (machine-readable output)
- Modular: each subcommand in a separate function, easy to extend

### 0.3 — dimarch-health-check v0.1

Invoked via `dimarchctl health --core`

Checks:
- [ ] Hyprland IPC socket present
- [ ] uwsm session active (`systemctl --user is-active graphical-session.target`)
- [ ] PipeWire running
- [ ] WirePlumber running as user service
- [ ] xdg-desktop-portal-hyprland responding
- [ ] polkit agent running
- [ ] amdgpu module loaded
- [ ] HSA_OVERRIDE_GFX_VERSION set
- [ ] BTRFS: all subvolumes mounted with correct options
- [ ] Snapper: limine-snapper-sync.service enabled
- [ ] journalctl: no amdgpu errors since last boot

Output format: `[✓] check name` / `[✗] check name — reason`
`--json` mode: `{"check": "...", "status": "ok|fail", "detail": "..."}`

Future checks added per phase:
- `--shell`: swaync, taskbar, waybar
- `--install`: phase scripts completion status

### 0.4 — dimarch.conf minimal template

File: `dimarch.conf.example` in repo root
File: `dimarch.conf` — gitignored, user's local copy

```ini
[system]
hostname = archiePC
username = archie

[gpu]
vendor = amd              # amd | nvidia | intel | auto
amd_gfx_version = 8.0.3  # Polaris override; set to "auto" to skip

[boot]
bootloader = limine

[desktop]
hyprland_scale_primary = 1.5
hyprland_scale_secondary = 1.0

[monitors]
primary = DP-1
secondary = DP-2
```

All install scripts must read from dimarch.conf, not hardcode values.
Dima's hardware values go into dimarch.conf, not into the scripts.

### Installer work (Track A — Phase 0)

- Document current manual setup steps (what would be needed if installing fresh)
- Verify 01-btrfs-setup.sh is still correct and idempotent

---

## Phase 1 — Shell Foundation + Installer Base

**Goal:** DimArch looks and feels like a DE. Installer reproduces base system.

**Entry:** Phase 0 complete (P0 bugs fixed, dimarchctl health passes).
**Exit criteria:**
- swaync running as user service, Sage-themed, Waybar integration working
- dimarch-taskbar v0.1 running on both monitors
- Installer phases 02–04 complete and tested

### 1.1 — swaync

- Install: `paru -S swaync`
- Sage CSS in `dimarch-theme/swaync/style.css`
- Systemd user service: `~/.config/systemd/user/swaync.service`
- Blur: Hyprland layer rule by namespace (verify with `hyprctl layers`)
- Waybar integration: notification icon + DND toggle module
- mako removed from autostart; may stay as optional emergency fallback
- dimarchctl extension: `dimarchctl notifications dnd on|off|status`

### 1.2 — dimarch-taskbar v0.1

**Repo:** `dmitrax/dimarch-taskbar`
**Stack:** Python + GTK4 + gtk4-layer-shell

Scope — strictly MVP:
- Bottom layer-shell panel, full-width
- Window list: open windows on current workspace, click to focus/restore
- Launcher button (left): opens rofi
- Static `config.toml`
- Polling allowed in v0.1

**Not in v0.1:**
- System tray (SNI/D-Bus — too complex, Waybar tray remains for now)
- Clock applet (clock stays in Waybar until dimarch-daycenter exists)
- Pinned apps
- Workspace indicator
- Socket-based events
- AUR packaging

Note on tray: StatusNotifierItem/D-Bus tray is a significant feature with
edge cases (Steam, Telegram, Nextcloud icons, menus). Waybar tray covers
this adequately for now. Don't rush it into v0.1.

Note on clock: A duplicate clock in the taskbar has no value.
A clock applet only makes sense as an entry point to dimarch-daycenter.
Until daycenter exists, clock stays in Waybar.

### 1.3 — Sage theme rollout

Apply Sage identity to all active components:

| Target    | Method                                      | Repo          |
|-----------|---------------------------------------------|---------------|
| Ghostty   | palette + background/foreground in config   | dimarch       |
| rofi      | .rasi theme                                 | dimarch       |
| hyprlock  | Lua config colors, blur, sage accent        | dimarch       |
| swaync    | style.css                                   | dimarch-theme |
| bat       | BAT_THEME env                               | dimarch       |
| delta     | [delta] section in .gitconfig               | dimarch       |
| lazygit   | config.yml color theme                      | dimarch       |
| fzf       | FZF_DEFAULT_OPTS env                        | dimarch       |

### 1.4 — BUG-03 fix (P1)

Fix Thunar "Open Terminal Here" env issue.
Not a blocker for Phase 1 entry, but closes during this phase.

### Installer work (Track A — Phase 1)

Scripts to write and test:
- `02-cachyos.sh` — CachyOS repos, kernel LTS/BORE, paru, reflector
- `03-base.sh` — locale, bluetooth, audio, Plymouth, core utilities
- `04-snapper.sh` — Snapper + limine-snapper-sync, snap-pac

All scripts must:
- Source `helpers.sh`
- Read from `dimarch.conf`
- Be idempotent (safe to run twice)
- Log to stdout with `ok/info/warn/die` format

---

## Phase 2 — Shell Polish + Installer Mid

**Goal:** Shell layer complete and stable. Installer covers GPU through dotfiles.

**Entry:** Phase 1 complete.
**Exit criteria:**
- dimarch-taskbar v0.2 running with socket events
- dimarch-preview working for common filetypes
- Installer phases 05–07 complete and tested

### 2.1 — dimarch-taskbar v0.2

Replace all polling with event-driven updates:
- Hyprland IPC socket for window/workspace events
- D-Bus signals for audio state (if audio indicator added)
Pinned apps: configurable in config.toml
Applet API: structured interface for future applets

### 2.2 — dimarch-preview

Quick-look file preview tool, Thunar-only (Yazi has built-in preview).

- Floating Hyprland window: `float, center, size 900 600`
- Mimetype dispatch: image → imv, PDF → zathura, video → mpv, text → bat in Ghostty
- Triggered from Thunar Custom Action
- Window rule: `class:dimarch-preview, float, center`

### 2.3 — Desktop & workspace features

- **hyprexpo**: workspace overview (Super+Tab or gesture)
- **hyprpicker**: color picker, rofi-accessible
- **Snap windows**: keybind-driven quadrant move+resize (floating-only — not tiling;
  snap = move to quadrant + resize to half/quarter, via hyprctl dispatch)

### 2.4 — dimarch-icons

Tela Circle green as base + DimArch-Icons overlay for custom/missing icons.
Managed in `dimarch-theme` repo.

### 2.5 — Desktop layer (prototype)

Prototype dimarch-desktop-layer: background layer that receives right-click.
Interim: keybind-triggered context menu if layer is not ready.

Phase 2 target: working right-click → context menu on desktop.
Full desktop icons: Phase 3+.

### 2.6 — Full Stow migration

All dotfiles as GNU Stow symlinks, no manual copies.
Validate: `stow -n -v` dry-run passes clean.

### dimarchctl extensions (Phase 2)

```
dimarchctl streaming on|off|status   Performance profile for GPU Screen Recorder
dimarchctl theme reload              Re-apply GTK/Qt/icon theme
```

### Installer work (Track A — Phase 2)

Scripts to write and test:
- `05-gpu.sh` — AMD/Nvidia/Intel detection, ROCm, HSA override
- `06-hyprland.sh` — Wayland stack, Ghostty, zsh+Starship, fonts
- `07-dotfiles.sh` — Stow apply all dotfiles

---

## Phase 3 — Productivity + Installer Completion

**Goal:** Personal productivity layer. Installer end-to-end complete.

**Entry:** Phase 2 complete.
**Exit criteria:**
- dimarch-daycenter v0.1 working with local SQLite
- install.sh orchestrator works from zero to ready system
- dimarchctl full subcommand set stable

### 3.1 — dimarch-daycenter v0.1

**Concept:** Not a "clock applet". A personal productivity center.
Opened from taskbar date/time entry point (which replaces Waybar clock at this stage).

```
dimarch-daycenter (click from taskbar date/time)
├── Month calendar
├── Today agenda
├── Quick capture (note / task / reminder)
├── Local tasks (today / waiting / follow-up)
└── Reminders → delivered via swaync
```

**Backend:** Local SQLite database.
**Not in v0.1:**
- CalDAV / Google Calendar sync
- Mini-CRM / contacts
- Team features
- Cloud sync

**v0.2 additions:**
- CalDAV integration
- iCalendar import/export

**v0.3 additions (under DimArch's MLM/creator workflow):**
- Follow-up pipeline
- Contacts mini-CRM
- Quick outreach templates
- Integration with swaync for meeting reminders

### 3.2 — Clock/date applet in dimarch-taskbar

Only added when dimarch-daycenter v0.1 is ready.
Entry point only: shows date/time, click opens `dimarch-daycenter --toggle`.
No standalone clock logic in the taskbar itself.

### dimarchctl extensions (Phase 3)

```
dimarchctl snapshot list|create|restore
dimarchctl update check|apply
dimarchctl power balanced|performance|quiet
```

Full `--json` coverage on all subcommands.

### Installer work (Track A — Phase 3)

Scripts to write and test:
- `08-theme.sh` — GTK theme (Colloid), Qt/Kvantum, SDDM, Sage icons
- `09-browser.sh` — Firefox + optional Chromium/Thorium
- `install.sh` — orchestrator for phases 02–09, reads dimarch.conf

install.sh requirements:
- Reads dimarch.conf for hardware/user config
- Runs phases in order, skips already-completed
- Pre-install: dimarchctl health --pre-install check
- Post-install: dimarchctl health --core validation

---

## Phase 4 — Public Release Readiness

**Goal:** Another person with similar hardware can install DimArch.
v0.1 scope: tested on AMD desktop systems. Not guaranteed on Nvidia/laptop/HiDPI edge cases.

**Entry:** Phase 3 complete. install.sh fully functional.
**Exit criteria:** v0.1.0 tagged. README with screenshots. AUR packages published.

### 4.1 — Documentation

```
docs/
├── install-guide.md      Step-by-step, hardware requirements
├── hardware.md           Tested configurations + compatibility matrix
├── philosophy.md         "Modern system. Old soul." — what DimArch is
├── components.md         All DE components explained
├── theming.md            How Sage theme works, customization guide
├── troubleshooting.md    Known issues and solutions
└── migration.md          Upgrading between DimArch versions
```

### 4.2 — dimarch-health-check v2

Pre-install check:
```bash
./install/utils/dimarchctl health --pre-install
```
Validates: UEFI mode, NVMe present, GPU vendor detected, internet, disk space, Arch base.

### 4.3 — AUR packages

- `dimarch-taskbar` — PKGBUILD in dimarch-taskbar repo (v0.2+ minimum)
- `dimarch-theme` — PKGBUILD in dimarch-theme repo

Publish to AUR only when components are stable and self-contained.

### 4.4 — SDDM theme fix

Replace sed-based config patching with proper QML mechanism.
(GitHub issue already open — implement here.)

### 4.5 — README

Public-facing README for `dmitrax/dimarch`:
- Screenshots (Sage desktop, taskbar, swaync, hyprlock, daycenter)
- Philosophy section with "Modern system. Old soul." + "Dimmed, not dumbed down."
- Quick start (2-command install)
- Component table with status
- Hardware requirements and compatibility matrix
- Link to docs/

### 4.6 — Release versioning

`DIMARCH_VERSION` in `install.sh`. Tag format: `v0.1.0`.
`CHANGELOG.md` maintained from this point.

---

## Component Status Checklist

```
Phase 0 — Core Stability & Diagnostics
  [ ] BUG-01: GPU crash after resume (P0 — hypothesis first, then fix)
  [ ] BUG-02: XWayland resolution after resume (P0)
  [ ] BUG-04: restore-after-resume.sh IPC fix (P0)
  [ ] dimarchctl skeleton: health, display status, version
  [ ] dimarch-health-check v0.1 (--core)
  [ ] dimarch.conf minimal template + scripts read it
  [ ] 01-btrfs-setup.sh: verify still correct
  [ ] Current manual setup documented

Phase 1 — Shell Foundation + Installer Base
  [ ] swaync: install, Sage CSS, systemd service, Waybar integration
  [ ] dimarchctl: notifications dnd
  [ ] dimarch-taskbar v0.1: window list, launcher button (no tray, no clock)
  [ ] Sage theme: Ghostty, rofi, hyprlock, bat, delta, lazygit, fzf
  [ ] BUG-03: Thunar "Open Terminal Here" fix (P1)
  [ ] 02-cachyos.sh
  [ ] 03-base.sh
  [ ] 04-snapper.sh

Phase 2 — Shell Polish + Installer Mid
  [ ] dimarch-taskbar v0.2: socket events, pinned apps, applet API
  [ ] dimarch-preview: quick-look (imv, zathura, mpv, bat)
  [ ] hyprexpo: workspace overview
  [ ] hyprpicker: color picker
  [ ] Snap windows: keybind quadrant move+resize
  [ ] Desktop layer prototype: right-click on desktop
  [ ] dimarch-icons: Tela Circle + overlay
  [ ] Full Stow migration
  [ ] dimarchctl: streaming, theme reload
  [ ] 05-gpu.sh
  [ ] 06-hyprland.sh
  [ ] 07-dotfiles.sh

Phase 3 — Productivity + Installer Completion
  [ ] dimarch-daycenter v0.1: SQLite, calendar, tasks, quick capture, swaync reminders
  [ ] Clock/date applet in taskbar → opens daycenter
  [ ] dimarchctl: snapshot, update, power (full coverage)
  [ ] dimarchctl: --json on all commands
  [ ] 08-theme.sh
  [ ] 09-browser.sh
  [ ] install.sh orchestrator: reads dimarch.conf, phase skip logic, pre/post health

Phase 4 — Public Release Readiness
  [ ] Documentation: all docs/ files
  [ ] dimarchctl health --pre-install check
  [ ] AUR: dimarch-taskbar, dimarch-theme (when stable)
  [ ] SDDM theme: remove sed hack
  [ ] README with screenshots
  [ ] CHANGELOG.md
  [ ] Release tag: v0.1.0
```

---

## Optional Apps (out of main roadmap)

Separate install scripts, not part of core phases:

```
install/apps/
├── ollama.sh          Ollama + ROCm for AI workloads
├── davinci.sh         DaVinci Resolve (requires ROCM)
├── comfyui.sh         ComfyUI + checkpoints
├── mise.sh            Node/Python/Rust via mise
├── voicebox.sh        Local TTS/STT (evaluate; optional)
└── winapps.sh         WinApps VM (Looking Glass, UHD 630 passthrough)
```

These are not versioned with DimArch OS releases.
They are standalone scripts, tested independently.

---

## Claude Code Session Workflow

Each session targets one task from the active phase checklist.

```
1. Pick one unchecked task from the lowest numbered open phase
2. Claude Code session: read CLAUDE.md → implement → review
3. git commit (conventional: feat/fix/style/chore/docs)
4. Update STATUS.md and CLAUDE.md phase checklist
5. Push
6. Close session
```

Never span two unrelated tasks in one session.

---

## Naming Reference (branding)

See BRAND.md for full branding decisions. Summary:

- **DimArch OS** — the system (Dimmed Arch, not "Dima's Arch")
- **Sage** — visual identity / design language / theme (not a DE name)
- **dimarch-*** — all component repos and tools
- **Aloe** — reserved future codename for standalone DE (not in use publicly)

Primary tagline: **Modern system. Old soul.**
Secondary: **Dimmed, not dumbed down.**

---

*DimArch OS — Dimmed Arch. Modern system. Old soul.*
