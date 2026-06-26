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
| `dimarchctl version` | Print version |

All commands support `--json` for machine-readable output.

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
