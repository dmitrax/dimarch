#!/usr/bin/env bash
# Wrapper for Thunar's "Copy Full Path" custom action — same reasoning as
# thunar-scribe.sh: keep %f as plain argv instead of interpolating it into
# an inline `bash -c "..."` string, which breaks on filenames containing
# the same quote character used to wrap the command.

set -euo pipefail

printf '%s' "$1" | wl-copy
