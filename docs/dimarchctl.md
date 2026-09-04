# dimarchctl — DimArch OS CLI

Unified command-line interface for DimArch OS.
Deployed to `/usr/local/bin/dimarchctl` by the installer.

---

## Quick reference

| Command | Description |
|---|---|
| `dimarchctl health` | Check that the system is properly configured |
| `dimarchctl power status` | Show current idle timeouts and their source |
| `dimarchctl power apply` | Apply changes from dimarch.conf |
| `dimarchctl vpn status` | Show WireGuard connection state (+ public IP when on) |
| `dimarchctl vpn up` / `down` / `toggle` | Connect / disconnect the VPN |
| `dimarchctl vpn ui` | Open the WireGuard admin UI (tunnel or direct) |
| `dimarchctl version` | Print version |
| `dimarchctl commands` | List every command, its arguments and what it does |

All commands support `--json` for machine-readable output.

---

## dimarchctl commands — discovery

The command table inside `dimarchctl` is the single source of truth: `usage`,
group help and this listing all read it, so the help text cannot drift away from
what the CLI actually dispatches.

```bash
dimarchctl commands              # human listing
dimarchctl commands --json       # one object per command
dimarchctl commands --check      # every table entry has a dispatch branch
dimarchctl power --help          # just one group
```

`--json` gives an agent (or any script) the route, group, name, arguments,
summary and whether the command needs root — so it can ask the system what
exists instead of remembering a syntax that may have moved:

```json
{"route": "power apply", "group": "power", "name": "apply", "args": "",
 "summary": "Regenerate ~/.config/hypr/hypridle.conf from the template, restart hypridle",
 "requires_root": false}
```

`--check` exists because a table can describe a command nobody wired up. It
exits non-zero and names the offender; run it after adding a command.

---

## dimarchctl health

Runs 10 checks to verify that Phase 0 components are correctly deployed.
Use after install or when something behaves unexpectedly.

```bash
dimarchctl health
dimarchctl health --json
```

Checks:
1. `/etc/dimarch.conf` exists
2. Swapfile exists on disk
3. Swapfile is active in `/proc/swaps`
4. GRUB cmdline contains `resume_offset=`
5. Sudoers rule for hibernate is present
6. `dimarch-sleep` is in PATH
7. `dimarch-monitor` is in PATH
8. `hypridle` is running *(warn if not — ok outside a Hyprland session)*
9. `~/.config/hypr/hypridle.conf` is generated
10. `~/.config/dimarch/dimarch.conf` exists *(warn if not — system defaults are used)*

Exit code: `0` if no failures, `1` if any check fails.

---

## dimarchctl power status

Shows current idle timeouts and whether each value comes from the user config
or the system config.

```bash
dimarchctl power status
```

Example output:
```
  sleep mode      : hibernate
  monitor off     : none
  lock timeout    : 300s (5 min)  [user]
  monitor timeout : 420s (7 min)  [user]
  hibernate       : 1200s (20 min)  [user]

  user config     : /home/user/.config/dimarch/dimarch.conf
```

---

## dimarchctl power apply

Regenerates `~/.config/hypr/hypridle.conf` from the template and restarts hypridle.
Run this after editing dimarch.conf.

```bash
dimarchctl power apply
```

**Workflow for changing idle timeouts:**

```bash
# 1. Edit user config (no sudo required)
$EDITOR ~/.config/dimarch/dimarch.conf

# 2. Apply
dimarchctl power apply
```

**User config keys** (`~/.config/dimarch/dimarch.conf`):

```ini
[power]
lock_timeout        = 300    # seconds until screen locks
monitor_off_timeout = 420    # seconds until monitors turn off
hibernate_timeout   = 1200   # seconds until hibernate
monitor_off         = none   # none | wlopm | ddcutil
```

> **Note for RX 580 / Polaris GPU:** `monitor_off` must be `none`.
> Both `wlopm` and `ddcutil` kill GPU processes on this hardware.
> See `docs/hardware.md` for details.

System-level keys (`sleep_mode`, `swapfile_path`, `gpu`) live in `/etc/dimarch.conf`
and require `sudo` to edit.

---

## dimarchctl vpn

WireGuard VPN client. Off by default — nothing runs until you opt in.

```bash
dimarchctl vpn status          # human-readable
dimarchctl vpn status --json   # for scripts / Waybar
dimarchctl vpn up              # connect
dimarchctl vpn down            # disconnect
dimarchctl vpn toggle          # flip current state
dimarchctl vpn ui              # open the WireGuard admin UI
```

**One-time setup:**

1. Get your own config from your WireGuard admin UI (e.g. [wg-easy](https://github.com/wg-easy/wg-easy))
   and place it at `/etc/wireguard/wg0.conf`.
2. Fill in `dimarch.conf [vpn]`:
   ```ini
   [vpn]
   enable        = true
   interface     = wg0
   wg_conf_path  = /etc/wireguard/wg0.conf
   admin_ui_mode = tunnel        # tunnel | direct
   admin_ui_port = 51821
   ssh_host      = myserver      # a Host entry in ~/.ssh/config, tunnel mode only
   admin_ui_url  =               # only used when admin_ui_mode = direct
   ```
3. Run:
   ```bash
   sudo install/utils/setup-wireguard.sh
   ```
   Installs `wireguard-tools`, `openresolv`, `networkmanager`, `network-manager-applet`,
   enables NetworkManager, imports the config, and disables autoconnect (VPN never
   starts on boot — manual only).

**Waybar tray icon:** `custom/vpn` module polls `dimarchctl vpn status --json` and shows
connected/disconnected state; click to toggle. Requires `nm-applet --indicator` running
(autostarted by `execs.lua`) for the NetworkManager tray icon itself.

> **No server details go in the dimarch repo.** Your VPN server's IP, port, keys, and SSH
> host live only in `/etc/wireguard/wg0.conf`, `dimarch.conf` (gitignored), and your own
> `~/.ssh/config` — never hardcode them into a script that gets committed.
