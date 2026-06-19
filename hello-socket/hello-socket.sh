#!/usr/bin/env bash
#
# hello-socket.sh -- the same "hello" as hello-world, but written DIRECTLY to
# AppBar's Unix socket instead of through the `appbar` CLI. It shows the
# underlying protocol: newline-delimited JSON envelopes on /tmp/appbar.sock.
#
# `appbar widget ...` is just a thin wrapper around exactly this. Any language
# that can write to a Unix socket can drive AppBar the same way -- and this path
# can reach things the CLI doesn't expose (e.g. pie-chart `segments` and
# multi-point chart `values` arrays).
#
# Envelope: only `type` is required. For a widget update, add a `widget` object
# whose only required field is `channel`; everything else is optional. Full
# protocol + field list: ../docs/SOCKETJSON.md.
#
# Setup
#   1. In Settings -> Widgets, add a Custom + Text widget (channel `text_1`).
#   2. AppBar must be running (it owns the socket). No `appbar` CLI needed.
#
# Usage
#   ./hello-socket.sh                 # pushes "hello via socket"
#   ./hello-socket.sh "your text"     # pushes whatever you pass
#
# Dependencies: bash + built-in /usr/bin/nc (Apple netcat). No appbar CLI, no
# python3, no jq, no socat.

set -euo pipefail

SOCKET="/tmp/appbar.sock"
MESSAGE="${1:-hello via socket}"

[[ -S "${SOCKET}" ]] || { echo "error: ${SOCKET} not found -- is AppBar running?" >&2; exit 1; }

# Escape backslashes and double quotes so the message can't break the
# hand-built JSON (backslashes first, then quotes).
escaped="${MESSAGE//\\/\\\\}"
escaped="${escaped//\"/\\\"}"

json="{\"type\":\"widget.update\",\"widget\":{\"channel\":\"text_1\",\"text\":\"${escaped}\",\"icon\":\"bolt.fill\"}}"

# The socket reads newline-delimited JSON; nc -U writes one frame and exits when
# AppBar closes the connection.
printf '%s\n' "${json}" | nc -U "${SOCKET}"
echo "sent: ${MESSAGE}"
