#!/usr/bin/env bash
#
# run-status.sh — wrap any command, show a "running" state widget while it
# executes, fire a `task.completed` or `task.failed` alert when it exits.
#
# Setup
#   1. In Settings → Widgets, add a Custom + State widget. The first one you
#      add is auto-named channel `state_1` — that's what this targets. (Optional
#      — if missing, the state update goes unrendered; the alert event still
#      fires either way.)
#   2. Install the `appbar` CLI from AppBar → Settings (there's a button for it).
#
# Usage
#   run-status.sh <label> <command> [args...]
#
# Examples
#   run-status.sh build npm run build
#   run-status.sh tests pytest -x
#   run-status.sh deploy ./scripts/deploy.sh prod
#
# The wrapped command's stdout/stderr stream through unchanged. The
# script's only output is the AppBar updates plus the wrapped exit code.

set -uo pipefail

if [[ $# -lt 2 ]]; then
    echo "usage: $(basename "$0") <label> <command> [args...]" >&2
    exit 64  # EX_USAGE
fi

LABEL="$1"
shift

CHANNEL="state_1"
START_TS=$(date +%s)

# Mark the state widget as "running": active=true with a hammer icon.
appbar widget --channel "${CHANNEL}" --active true \
    --label "${LABEL}" --text "${LABEL}: running…" \
    --icon "hammer.circle" >/dev/null

# Run the wrapped command; capture exit. We deliberately don't `set -e`
# here so the failure path (non-zero exit) is reachable.
"$@"
EXIT_CODE=$?

DURATION=$(( $(date +%s) - START_TS ))

if [[ ${EXIT_CODE} -eq 0 ]]; then
    appbar widget --channel "${CHANNEL}" --active false \
        --label "${LABEL}" --text "${LABEL}: ok (${DURATION}s)" \
        --icon "checkmark.circle.fill" >/dev/null
    appbar emit task.completed \
        --title "${LABEL} completed in ${DURATION}s" \
        --severity info
else
    appbar widget --channel "${CHANNEL}" --active false \
        --label "${LABEL}" --text "${LABEL}: failed (exit ${EXIT_CODE})" \
        --icon "xmark.octagon.fill" >/dev/null
    # Severity scales with exit reason: any non-zero is at least a
    # warning; a SIGKILL / OOM (137) escalates to critical.
    if [[ ${EXIT_CODE} -eq 137 ]]; then
        SEV="critical"
    else
        SEV="warning"
    fi
    appbar emit task.failed \
        --title "${LABEL} failed (exit ${EXIT_CODE}, ${DURATION}s)" \
        --severity "${SEV}"
fi

# Propagate the wrapped command's exit so this script is composable
# in CI pipelines and shell chains.
exit "${EXIT_CODE}"
