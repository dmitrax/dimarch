#!/usr/bin/env bash
# Claude Code status line:
#   model · effort │ [context bar] % tokens/window │ 5h / 7d: used, forecast, reset │ cache
#
# Copied to ~/.claude/statusline.sh by install/phases/06-dotfiles.sh (STEP 12),
# which also merges the statusLine key that points at it into
# ~/.claude/settings.json. Ported from dmitrax/mac-setup's
# dotfiles/claude/statusline.sh; the body is meant to stay identical on both
# machines, so a fix found on one side goes to the other as a diff.
#
# Claude Code pipes the session as JSON on stdin and shows whatever this prints.
# Field names are the schema documented inside the claude binary (read 2026-09-10,
# 2.1.267) and confirmed against a live session: context_window.{used_percentage,
# total_input_tokens, context_window_size}, effort.level, rate_limits.five_hour /
# seven_day.{used_percentage, resets_at}, prompt_cache.{caching_observed, warm,
# ttl, expires_at}. Any of them can be absent — rate_limits and prompt_cache
# arrive only after the first API response — and an absent field drops its
# segment instead of printing a hole.
#
# The limit percentages are only as fresh as this session's last API response:
# the server sends them in the anthropic-ratelimit-unified-* response headers,
# and the limit is account-wide, so other sessions spend it unseen here. Nothing
# in the input dates them, but prompt_cache.expires_at is that response's time
# plus the cache TTL (checked 2026-09-10 against a live render to the second),
# so the age falls out without keeping any state. Past five minutes the limits
# carry it — `·26м` — and the forecast is computed as of that moment, not now:
# an old percentage stretched over a longer elapsed time would drift down while
# idle and flatter the pace.
#
# Colours are ANSI slots, never hexes, so they inherit dimarch-sage from ghostty
# and cannot drift from it. Sage / ochre / red mark STATE and nothing else is
# coloured: the model and effort are identity, so they stay on the default
# foreground. A forecast is state too, and takes the bright tier of its slot
# (10 / 11 / 9) — the same hue, so no new meaning, just set apart from the
# measured percentage beside it. Secondary text takes slot 8 (neutral.muted, the palette's dim-text
# role, raised to clear 4.5:1), never SGR 2: under ghostty's faint-opacity 0.5
# faint text lands near 2.5:1.
#
# Numbers are fixed-width, so a value gaining a digit does not shove every
# segment to its right sideways between renders.
#
# Times use bash's own printf '%(…)T', not date(1): GNU date reads -r as a FILE
# and BSD date as an epoch, so no spelling of `date -r` means the same thing on
# both machines this script runs on (the Mac even puts GNU first in PATH).

# No -e: a status line prints what it can rather than dying on one odd field.
set -uo pipefail
shopt -s extglob

RESET=$'\e[0m'
DIM=$'\e[90m'                 # slot 8, neutral.muted
SAGE=$'\e[32m'                # slot 2
OCHRE=$'\e[33m'               # slot 3
RED=$'\e[31m'                 # slot 1
# A forecast takes the bright tier of the same state: one hue, so it is the
# same state, a lighter tier, so it reads as derived rather than measured.
SAGE_FC=$'\e[92m'             # slot 10, sage.bright
OCHRE_FC=$'\e[93m'            # slot 11, ochre.bright
RED_FC=$'\e[91m'              # slot 9, red.bright
SEP="${DIM} │ ${RESET}"
BAR_WIDTH=20
# Thresholds, owner's calls: the context at 65 / 85 (2026-09-10) — on a 1M
# window ochre at half full came too early to mean anything; the limits at
# 70 / 90 (2026-09-14) — 50 / 80 turned 7d ochre at 66 % with ten hours left.
CTX_WARN=65
CTX_CRIT=85
LIM_WARN=70
LIM_CRIT=90
STALE_AFTER=300               # seconds before the limits show their age
NOW=$EPOCHSECONDS

# A gauge: how full it is right now. Ochre from the second argument, red from
# the third; the limits use the defaults, the context passes its own.
gauge() {
    local pct=$1 warn=${2:-$LIM_WARN} crit=${3:-$LIM_CRIT}
    if (( pct >= crit )); then printf '%s' "$RED"
    elif (( pct >= warn )); then printf '%s' "$OCHRE"
    else printf '%s' "$SAGE"
    fi
}

# A forecast is judged against the end of its window, not as a gauge: arriving
# at the reset with 95 % used is fine, arriving at 100 % before it is not.
pace() {
    if (( $1 >= 100 )); then printf '%s' "$RED_FC"
    elif (( $1 >= 80 )); then printf '%s' "$OCHRE_FC"
    else printf '%s' "$SAGE_FC"
    fi
}

# 327871 → 328k, 1000000 → 1M, 1500000 → 1.5M
tokens() {
    local n=$1 tenths
    if (( n >= 999500 )); then
        tenths=$(( (n + 50000) / 100000 ))
        if (( tenths % 10 == 0 )); then printf '%dM' $(( tenths / 10 ))
        else printf '%d.%dM' $(( tenths / 10 )) $(( tenths % 10 ))
        fi
    elif (( n >= 1000 )); then printf '%dk' $(( (n + 500) / 1000 ))
    else printf '%d' "$n"
    fi
}

# percent, tokens in context (may be empty), window size (may be empty)
context() {
    local pct=$1 filled i full="" empty="" colour
    colour=$(gauge "$pct" "$CTX_WARN" "$CTX_CRIT")
    filled=$(( pct * BAR_WIDTH / 100 ))
    (( filled > BAR_WIDTH )) && filled=$BAR_WIDTH
    for (( i = 0; i < filled; i++ )); do full+="█"; done
    for (( i = filled; i < BAR_WIDTH; i++ )); do empty+="░"; done
    printf '%s[%s%s%s%s]%s %s%3d%%%s' \
        "$DIM" "$colour" "$full" "$DIM" "$empty" "$RESET" \
        "$colour" "$pct" "$RESET"
    if [[ -n $2 && -n $3 ]]; then
        printf ' %s%4s/%s%s' "$DIM" "$(tokens "$2")" "$(tokens "$3")" "$RESET"
    fi
}

# label, used %, reset epoch (may be empty), window length in seconds,
# strftime format for times in this window, the moment the percentage is from
limit() {
    local label=$1 used=$2 reset=$3 window=$4 fmt=$5 at=$6 start elapsed proj
    printf '%s%s %3d%%%s' "$(gauge "$used")" "$label" "$used" "$RESET"
    [[ -n $reset ]] || return 0
    start=$(( reset - window ))
    elapsed=$(( at - start ))
    # The forecast is used / elapsed, stretched to the whole window. Too early
    # in a window that is noise — 20 % in its first ten minutes projects to
    # 600 % — so it waits for a twentieth of the window (15 min of 5h, ~8 h of
    # 7d), and says nothing about an untouched one.
    if (( used > 0 && elapsed * 20 >= window && elapsed < window )); then
        proj=$(( used * window / elapsed ))
        if (( proj >= 100 )); then
            # Would run out before the reset: say when, not by how much.
            printf " %s✗%($fmt)T%s" "$RED_FC" $(( start + elapsed * 100 / used )) "$RESET"
        else
            printf ' %s→%2d%%%s' "$(pace "$proj")" "$proj" "$RESET"
        fi
    fi
    printf "%s ↻%($fmt)T%s" "$DIM" "$reset" "$RESET"
}

# seconds → 26м / 2ч
age() {
    if (( $1 < 3600 )); then printf '%dм' $(( $1 / 60 ))
    else printf '%dч' $(( $1 / 3600 ))
    fi
}

# caching observed, warm, expires_at. Warm: sage ✓ and the time it goes cold —
# a pause past that makes the next request re-cache the whole context, which
# costs both time and limit. Cold: ochre ✗, that next request pays it.
cache() {
    [[ $1 == true ]] || return 0
    if [[ $2 == true && -n $3 ]] && (( $3 > NOW )); then
        printf '%sкэш ✓%s%s %(%H:%M)T%s' "$SAGE" "$RESET" "$DIM" "$3" "$RESET"
    else
        printf '%sкэш ✗%s' "$OCHRE" "$RESET"
    fi
}

# One jq pass. Fields are joined by the unit separator, not a tab: tab is IFS
# whitespace, so `read` would collapse two empty fields into one and shift every
# value after them.
#
# stdin is read with cat, not $(</dev/stdin). Claude Code hands the JSON over a
# socketpair (libuv stdio), and on Linux /dev/stdin is /proc/self/fd/0, which
# cannot be opened for a socket: ENXIO, an empty input, a blank line and no
# error anyone sees. macOS dups the descriptor instead, so the Mac never showed
# it. Found porting the script to DimArch on 2026-09-15.
input=$(cat)
model="" effort="" ctx="" ctx_tokens="" ctx_size=""
five="" five_reset="" seven="" seven_reset=""
cache_seen="" cache_warm="" cache_ttl="" cache_expires=""
IFS=$'\x1f' read -r model effort ctx ctx_tokens ctx_size \
    five five_reset seven seven_reset \
    cache_seen cache_warm cache_ttl cache_expires < <(
    jq -r '
        def pct: if . == null then "" else (. + 0.5 | floor | tostring) end;
        def int: if . == null then "" else (floor | tostring) end;
        def str: if . == null then "" else tostring end;
        [
          (.model.display_name // "" | sub(" \\(.*\\)$"; "")),
          (.effort.level | str),
          (.context_window.used_percentage | pct),
          (.context_window.total_input_tokens | int),
          (.context_window.context_window_size | int),
          (.rate_limits.five_hour.used_percentage | pct),
          (.rate_limits.five_hour.resets_at | int),
          (.rate_limits.seven_day.used_percentage | pct),
          (.rate_limits.seven_day.resets_at | int),
          (.prompt_cache.caching_observed | str),
          (.prompt_cache.warm | str),
          (.prompt_cache.ttl | str),
          (.prompt_cache.expires_at | int)
        ] | join("")
    ' <<<"$input" 2>/dev/null
)

# When the last API response arrived, i.e. how old the limit percentages are.
# Unknown (empty) when the cache reported nothing; then the forecast falls back
# to now and no age is shown — better silent than a made-up number.
data_at=""
case $cache_ttl in
    1h) ttl_seconds=3600 ;;
    5m) ttl_seconds=300 ;;
    *)  ttl_seconds="" ;;
esac
if [[ -n $cache_expires && -n $ttl_seconds ]]; then
    data_at=$(( cache_expires - ttl_seconds ))
fi

parts=()
[[ -n $model ]] && parts+=("${model}${effort:+${DIM} · ${effort}${RESET}}")
[[ -n $ctx ]] && parts+=("$(context "$ctx" "$ctx_tokens" "$ctx_size")")
[[ -n $five ]] && parts+=("$(limit 5h "$five" "$five_reset" 18000 '%H:%M' "${data_at:-$NOW}")")
[[ -n $seven ]] && parts+=("$(limit 7d "$seven" "$seven_reset" 604800 '%d.%m' "${data_at:-$NOW}")")
if [[ -n $data_at && ( -n $five || -n $seven ) ]] && (( NOW - data_at > STALE_AFTER )); then
    parts[-1]+="${DIM} ·$(age $(( NOW - data_at )))${RESET}"
fi
seg=$(cache "$cache_seen" "$cache_warm" "$cache_expires")
[[ -n $seg ]] && parts+=("$seg")

out=""
if (( ${#parts[@]} )); then
    out=${parts[0]}
    for p in "${parts[@]:1}"; do out+="${SEP}${p}"; done
fi
printf '%s' "$out"

# Opt-in trace, off unless the command sets it: STATUSLINE_DEBUG=<file> logs
# every render (time, then the line without colour) and keeps the last raw input
# beside it — how often Claude Code calls this, and whether segments come and go.
# It is how "the line jumps" was measured on 2026-09-10: 11 renders, one width,
# no segment ever missing, so the jump was not this script's.
if [[ -n ${STATUSLINE_DEBUG:-} ]]; then
    printf '%s\t%s\n' "$EPOCHREALTIME" "${out//$'\e['*([0-9;])m/}" >>"$STATUSLINE_DEBUG"
    printf '%s\n' "$input" >"$STATUSLINE_DEBUG.json"
fi
