#!/usr/bin/env bash
#
# hello.sh -- the smallest possible AppBar example. Pushes one string to a
# text widget so you can confirm the whole pipe works end to end:
#
#     this script  ->  appbar CLI  ->  /tmp/appbar.sock  ->  overlay
#
# Setup
#   1. In Settings -> Widgets, add a Custom + Text widget. The first one you
#      add is automatically named channel `text_1` -- that's what this targets.
#   2. Install the `appbar` CLI from AppBar -> Settings (there's a button for it).
#
# Usage
#   ./hello.sh                 # pushes "hello, AppBar"
#   ./hello.sh "your text"     # pushes whatever you pass
#
# If the text doesn't appear, no Custom + Text widget (channel `text_1`) exists
# yet -- the push still succeeds, it just has nowhere to render.

set -euo pipefail

MESSAGE="${1:-hello, AppBar}"

appbar widget --channel text_1 --text "${MESSAGE}" --icon "hand.wave"
