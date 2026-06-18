#!/usr/bin/env bash
#
# ping-latency.sh — graph round-trip latency to a host on an AppBar line-chart
# widget. Each ping pushes the numeric value, which the chart rotates into its
# history; the formatted "42 ms" text rides along on the same push for any
# widget that renders text.
#
# Setup
#   1. In Settings → Widgets, add a Custom + Line Chart widget. The first one
#      you add is auto-named channel `line_chart_1` — that's what this targets.
#   2. Install the `appbar` CLI from AppBar → Settings (there's a button for it).
#   3. Run this script:
#        ./ping-latency.sh                    # default: 1.1.1.1, 5s interval
#        ./ping-latency.sh 8.8.8.8 2          # custom target + interval
#
# Quit with Ctrl-C. The channel keeps its last value when the script stops.

set -euo pipefail

TARGET="${1:-1.1.1.1}"
INTERVAL="${2:-5}"
CHANNEL="line_chart_1"

while true; do
    # `ping -c 1 -W 1000 …` sends one packet, 1s timeout. The RTT line
    # ends in `time=N.NNN ms` — awk pulls that out. On timeout / unreachable
    # ping exits non-zero and the awk match is empty.
    rtt=$(ping -c 1 -W 1000 "${TARGET}" 2>/dev/null \
        | awk -F'time=' '/time=/ { split($2, a, " "); printf "%.0f", a[1]; exit }')

    if [[ -n "${rtt}" ]]; then
        # Push numeric value (line_chart consumes this and rotates history)
        # AND formatted text in one call (text widget renders the string).
        # Sending both explicitly skips WidgetDataStore's auto-conversion,
        # so the text widget shows "42 ms" not "42.0".
        appbar widget --channel "${CHANNEL}" --value "${rtt}" --text "${rtt} ms" \
            --label "ping" --icon "antenna.radiowaves.left.and.right"
    else
        # Treat timeout as an explicit "down" state: push 0 to the chart
        # (visible as a flatline) and "—" to the text. SF Symbol switches
        # to the slashed antenna so the user sees something is wrong.
        appbar widget --channel "${CHANNEL}" --value 0 --text "—" \
            --label "ping" --icon "antenna.radiowaves.left.and.right.slash"
    fi

    sleep "${INTERVAL}"
done
