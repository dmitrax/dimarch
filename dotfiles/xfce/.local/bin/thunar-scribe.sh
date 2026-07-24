#!/usr/bin/env bash
# Wrapper for Thunar's "Transcribe with scribe" custom action.
#
# Exists so uca.xml's <command> can pass Thunar's %F-substituted file
# paths as plain argv (properly quoted by Thunar itself) instead of
# interpolating them into an inline `bash -c '...'` string — nesting
# Thunar's own quoting inside ours breaks on filenames with spaces
# (confirmed live 2026-07-24: window flashed and closed instantly on a
# file named "Silver trening 18.07.2026.webm").

set -euo pipefail

if command -v scribe &>/dev/null; then
    exec ghostty -e scribe --verbose "$@"
else
    notify-send "scribe not installed" \
        "Optional component — run install/apps/scribe.sh from the dimarch repo"
fi
