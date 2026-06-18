#!/usr/bin/env bash
#
# session.sh -- show your current Claude Code 5-hour session: how many tokens
# you've used in the active block and exactly when it resets. Pushes to an
# AppBar widget.
#
# Fully self-contained and READ-ONLY. It never touches or requires any Claude
# Code configuration (no statusLine, no settings changes). It derives everything
# from your local transcripts at ~/.claude/projects/<project>/*.jsonl -- the
# same approach as ccusage / Claude-Code-Usage-Monitor.
#
# Dependencies: bash + the `appbar` CLI + built-in macOS tools only
# (find, awk, sort, date). No python3, no jq, no ccusage.
#
# How the 5-hour block is computed (matches ccusage's algorithm)
#   - Each transcript line has a top-level ISO8601 `timestamp` (UTC).
#   - A block STARTS at its first message's timestamp floored to the top of the
#     hour (UTC); it RESETS 5 hours after that floored start.
#   - A new block begins when a message arrives >5h after the block start, or
#     >5h after the previous message (an idle gap).
#   - The ACTIVE block is the latest one whose last message was <5h ago and
#     whose 5h window hasn't elapsed.
#
# We deliberately do NOT show a "% of limit used": the official percentage is
# not in the transcripts (only Claude Code's statusLine/API has it), and a
# guessed plan cap would be a fabricated number. Reset time and token count are
# exact; the gauge fills with elapsed time through the 5h window.
#
# Setup
#   1. In Settings -> Widgets, add a Custom + Text widget. The first one you add
#      is auto-named channel `text_1` -- that's the default this targets.
#   2. Install the `appbar` CLI from AppBar -> Settings (there's a button for it).
#
# Usage
#   ./session.sh [channel]            # one-shot push and exit
#   ./session.sh text_1
#   ./session.sh text_1 --watch       # refresh every 60s

set -uo pipefail

CHANNEL="${1:-text_1}"
WATCH=""
[[ "${2:-}" == "--watch" ]] && WATCH=1
INTERVAL=60

PROJECTS_DIR="${HOME}/.claude/projects"
SESSION_SEC=$((5 * 3600))

human_tokens() {  # integer -> 1.3m / 812k / 240
    awk -v t="$1" 'BEGIN {
        if (t >= 1e9)      printf "%.1fb", t / 1e9
        else if (t >= 1e6) printf "%.1fm", t / 1e6
        else if (t >= 1e3) printf "%.1fk", t / 1e3
        else               printf "%d", t
    }'
}

active_block() {
    # Emit "<start_epoch> <reset_epoch> <tokens>" for the active 5h block, or
    # nothing if the session is idle. Pure find|awk|sort|awk pipeline.
    [[ -d "${PROJECTS_DIR}" ]] || return 0
    local now; now=$(date +%s)

    # The active block is always within the last 5h, so only scan transcripts
    # modified in the last 8h -- never months of history. BSD/macOS find takes a
    # unit suffix on -mtime (-8h), so no temp files and nothing to delete.
    # tail bounds each file to its most recent lines (recent activity is always
    # at the end of an append-only transcript; 200k lines is far more than any
    # real 8h of messages). grep (fast C scanner) then drops everything but
    # usage-bearing lines, so awk only parses those -- both keep this quick even
    # when a session file is hundreds of MB. -q/-h: no filename headers.
    find "${PROJECTS_DIR}" -name '*.jsonl' -mtime -8h -print0 2>/dev/null \
        | xargs -0 tail -qn 200000 2>/dev/null \
        | grep -hF '"usage"' 2>/dev/null \
        | awk '
            # extract (utc_epoch, input+output tokens) from each usage-bearing
            # transcript line. macOS awk has no mktime(), so derive the UTC epoch
            # from the date fields directly (days-from-civil algorithm).
            function dfc(y, m, d,   era, yoe, doy) {
                if (m <= 2) y -= 1
                era = int((y >= 0 ? y : y - 399) / 400)
                yoe = y - era * 400
                doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
                return era * 146097 + (yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy) - 719468
            }
            match($0, /"timestamp":"[0-9]+-[0-9]+-[0-9]+T[0-9]+:[0-9]+:[0-9]+/) {
                ts = substr($0, RSTART + 13, 19); gsub(/[-T:]/, " ", ts)
                split(ts, p, " ")
                epoch = dfc(p[1], p[2], p[3]) * 86400 + p[4] * 3600 + p[5] * 60 + p[6]
                toks = 0
                # leading quote anchors these so they cannot match
                # cache_*_input_tokens; match() takes only the first (top-level)
                # value, skipping the duplicated iterations block.
                if (match($0, /"input_tokens":[0-9]+/))  toks += substr($0, RSTART + 15, RLENGTH - 15)
                if (match($0, /"output_tokens":[0-9]+/)) toks += substr($0, RSTART + 16, RLENGTH - 16)
                if (epoch > 0) print epoch, toks
            }' \
        | sort -n \
        | awk -v now="${now}" -v sess="${SESSION_SEC}" '
            function floor_hour(t) { return t - (t % 3600) }
            function consider(s, k, l,   reset) {
                reset = s + sess
                if ((now - l) < sess && now < reset) { a_start = s; a_tok = k }
            }
            {
                ts = $1; toks = $2
                if (start == "") { start = floor_hour(ts); last = ts; tk = toks; next }
                if ((ts - start) > sess || (ts - last) > sess) {
                    consider(start, tk, last)
                    start = floor_hour(ts); tk = 0
                }
                tk += toks; last = ts
            }
            END {
                if (start != "") consider(start, tk, last)
                if (a_start != "") print a_start, a_start + sess, a_tok
            }'
}

push_once() {
    local now block start reset tokens value text when remain h m
    now=$(date +%s)
    block="$(active_block)"

    if [[ -z "${block}" ]]; then
        text="no active session"; value="0.0000"
    else
        read -r start reset tokens <<<"${block}"
        # gauge fills with elapsed time through the 5h window (exact).
        value="$(awk -v n="${now}" -v s="${start}" -v d="${SESSION_SEC}" \
            'BEGIN { v = (n - s) / d; if (v > 1) v = 1; if (v < 0) v = 0; printf "%.4f", v }')"
        when="$(date -r "${reset}" '+%I:%M%p' | sed -E 's/^0//' | tr -d '. ' | tr '[:upper:]' '[:lower:]')"
        remain=$(( reset - now )); [[ "${remain}" -lt 0 ]] && remain=0
        h=$(( remain / 3600 )); m=$(( (remain % 3600) / 60 ))
        if [[ "${h}" -gt 0 ]]; then remain="${h}h${m}m"; else remain="${m}m"; fi
        text="$(human_tokens "${tokens}") tok - resets ${when} (${remain})"
    fi

    appbar widget --channel "${CHANNEL}" \
        --value "${value}" --text "${text}" --label "claude session" --icon "clock" >/dev/null
    echo "pushed: ${text}"
}

if [[ -n "${WATCH}" ]]; then
    while true; do push_once; sleep "${INTERVAL}"; done
else
    push_once
fi
