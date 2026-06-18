#!/usr/bin/env bash
#
# weather.sh -- push the current temperature + a condition-mapped SF Symbol to
# an AppBar text widget. Uses wttr.in, which needs NO API key.
#
# Setup
#   1. In Settings -> Widgets, add a Custom + Text widget. The first one you add
#      is auto-named channel `text_1` -- that's what this targets. (A mini/gauge
#      widget would misread the temperature as a 0-1 percentage, so use Text.)
#   2. Install the `appbar` CLI from AppBar -> Settings (there's a button for it).
#   3. Set your city (default London) and run:
#        export WEATHER_CITY="London"       # spaces as +, e.g. "New+York"
#        ./weather.sh                        # one-shot: push once and exit
#        ./weather.sh text_1                 # target a specific channel
#        ./weather.sh text_1 --watch         # keep pushing every 10 min
#
# Dependencies: bash + the `appbar` CLI + built-in /usr/bin/curl and tr. No API
# key, no python3, no jq.

set -uo pipefail

CHANNEL="${1:-text_1}"
WATCH=""
[[ "${2:-}" == "--watch" ]] && WATCH=1
INTERVAL=600   # wttr.in asks callers not to poll hard; 10 min is polite.
CITY="${WEATHER_CITY:-London}"

# Map wttr.in's free-text condition to an SF Symbol. Patterns are checked
# most-specific first (thunder/snow before rain, partly before cloud).
condition_icon() {
    local c
    c="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "${c}" in
        *thunder*)                       echo "cloud.bolt.rain.fill" ;;
        *snow* | *blizzard* | *sleet* | *ice*) echo "cloud.snow.fill" ;;
        *rain* | *drizzle*)              echo "cloud.rain.fill" ;;
        *mist* | *fog* | *haze*)         echo "cloud.fog.fill" ;;
        *partly*)                        echo "cloud.sun.fill" ;;
        *cloud* | *overcast*)            echo "cloud.fill" ;;
        *sun* | *clear*)                 echo "sun.max.fill" ;;
        *)                               echo "cloud" ;;
    esac
}

push_once() {
    local raw condition temp icon
    # wttr.in's format string returns "<Condition>|<temp>", e.g. "Light rain|+13°C".
    # /usr/bin/curl is the system curl -- a broken/absent Homebrew curl on PATH
    # would otherwise break this.
    raw="$(/usr/bin/curl -fsS --max-time 15 "https://wttr.in/${CITY}?format=%C|%t" 2>/dev/null)" \
        || { echo "weather: wttr.in request failed" >&2; return 1; }

    # Guard against an error page / unexpected payload.
    if [[ "${raw}" != *"|"* ]]; then
        echo "weather: unexpected response: ${raw}" >&2
        return 1
    fi

    condition="${raw%%|*}"
    temp="${raw#*|}"
    temp="${temp#+}"   # drop wttr.in's leading + on positive temps
    [[ -z "${temp}" ]] && { echo "weather: no temperature in response" >&2; return 1; }

    icon="$(condition_icon "${condition}")"
    appbar widget --channel "${CHANNEL}" \
        --text "${temp}" --label "${condition:-weather}" --icon "${icon}" >/dev/null
    echo "pushed: ${temp} ${condition}"
}

if [[ -n "${WATCH}" ]]; then
    while true; do push_once || true; sleep "${INTERVAL}"; done
else
    push_once
fi
