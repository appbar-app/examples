#!/usr/bin/env bash
#
# now-playing.sh — push the current track from Apple Music to an AppBar text
# widget. Demonstrates the AppleScript bridge.
#
# Setup
#   1. In Settings → Widgets, add a Custom + Text widget. The first one you add
#      is auto-named channel `text_1` — that's what this targets.
#   2. Install the `appbar` CLI from AppBar → Settings (there's a button for it).
#   3. Run:
#        ./now-playing.sh                # default: poll every 5s
#        ./now-playing.sh 10             # custom interval
#
# Behaviour
#   - Reads the current track from Apple Music (the Music app).
#   - Shows "<artist> — <title>" with a play.fill icon when playing, pause.fill
#     when paused/stopped.
#   - Shows a music.note placeholder when Music isn't running or has no track.

set -euo pipefail

INTERVAL="${1:-5}"
CHANNEL="text_1"

# Returns "<state>|<artist>|<title>" if Apple Music is running and has a current
# track, otherwise empty. <state> is one of: playing, paused, stopped.
read_track() {
    osascript <<'APPLESCRIPT' 2>/dev/null
if application "Music" is running then
    tell application "Music"
        try
            set s to player state as string
            set a to artist of current track
            set t to name of current track
            return s & "|" & a & "|" & t
        on error
            return ""
        end try
    end tell
end if
return ""
APPLESCRIPT
}

last_pushed=""

while true; do
    line=$(read_track)

    if [[ -n "${line}" ]]; then
        IFS='|' read -r state artist title <<< "${line}"
        if [[ "${state}" == "playing" ]]; then
            icon="play.fill"
        else
            # Paused / stopped — keep the track shown but switch to the paused
            # icon so it reads as "this was playing, it isn't now."
            icon="pause.fill"
        fi
        text="${artist} — ${title}"
    else
        text=" "
        icon="music.note"
    fi

    # Only push when the displayed string changes, to avoid churning the bar's
    # render path every interval for no reason.
    if [[ "${text}|${icon}" != "${last_pushed}" ]]; then
        appbar widget --channel "${CHANNEL}" \
            --text "${text}" --icon "${icon}" --label "now playing" >/dev/null
        last_pushed="${text}|${icon}"
    fi

    sleep "${INTERVAL}"
done
