#!/usr/bin/env bash
#
# Non-interactive wrapper around serve-sim.sh for SSH/agent-triggered starts.
#
# serve-sim.sh ends with `exec flutter run ...` in the foreground (by design, for a human
# at the terminal — it streams logs and takes hot-reload keystrokes). An SSH-triggered call
# needs to return immediately instead of blocking the connection for the life of the app, so
# this backgrounds it with nohup, logs to a fixed path, and adds start/status/stop.
#
# Meant to be reached via a Tailscale-only, forced-command SSH key (see
# docs/ios-serve-sim-qa.md, "Remote start (box -> Mac bridge)"), never called with a raw
# shell, so it stays a narrow launcher, not general remote access.
#
# Usage:
#   ./scripts/serve-sim-remote.sh start ["iPhone 17"] [PORT]
#   ./scripts/serve-sim-remote.sh status
#   ./scripts/serve-sim-remote.sh stop
#
# Agent QA verbs (so the box can drive a smoke run and pull evidence without a
# general shell — everything runs on the Mac, against the booted sim):
#   ./scripts/serve-sim-remote.sh shot [name]      # screenshot -> base64 to stdout
#   ./scripts/serve-sim-remote.sh tap <x> <y>      # normalized 0..1 coords
#   ./scripts/serve-sim-remote.sh type <text...>
#   ./scripts/serve-sim-remote.sh button <name>    # home | lock
#   ./scripts/serve-sim-remote.sh openurl <url>    # deep-link into the sim
#   ./scripts/serve-sim-remote.sh log [N]          # last N lines of the run log
set -euo pipefail
cd "$(dirname "$0")/.."

# An SSH forced-command runs in a NON-interactive, NON-login shell, so the user's
# zsh rc files never load and Homebrew's bin dir is not on PATH -- `flutter`, `node`
# and `pod` (all under /opt/homebrew/bin on Apple Silicon) then resolve as "not found"
# and serve-sim.sh aborts. Load the Homebrew environment so a box-triggered start
# sees the same toolchain an interactive Terminal does. Harmless if brew is absent.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# The forced-command key expands ${SSH_ORIGINAL_COMMAND} unquoted, but the Mac's
# login shell is zsh, which -- unlike bash -- does NOT word-split unquoted
# expansions. So `ssh ... shot 01-login` arrives here as a single argument
# "shot 01-login" that matches no case. Re-split it (this script is bash, which
# does word-split) so multi-arg verbs work regardless of the calling shell.
if [[ $# -eq 1 && "$1" == *" "* ]]; then
  # shellcheck disable=SC2086
  set -- $1
fi

LOG=/tmp/kolabing-serve-sim.log
PIDFILE=/tmp/kolabing-serve-sim.pid
QADIR=/tmp/kolabing-qa

running() { [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

case "${1:-start}" in
  start)
    shift || true
    if running; then
      echo "already running (pid $(cat "$PIDFILE")); see $LOG"
      grep -m1 "^   http" "$LOG" 2>/dev/null || true
      exit 0
    fi
    : > "$LOG"
    nohup ./scripts/serve-sim.sh "$@" >> "$LOG" 2>&1 &
    echo $! > "$PIDFILE"
    echo "started (pid $(cat "$PIDFILE")); waiting for the stream URL..."
    for _ in $(seq 1 30); do
      if grep -m1 "^   http" "$LOG" 2>/dev/null; then exit 0; fi
      sleep 1
    done
    echo "still starting after 30s, not yet failed -- check $LOG"
    ;;
  status)
    if running; then
      echo "running (pid $(cat "$PIDFILE"))"
      grep -m1 "^   http" "$LOG" 2>/dev/null || echo "(no stream URL captured yet, see $LOG)"
    else
      echo "not running"
    fi
    ;;
  stop)
    npx --yes serve-sim --kill >/dev/null 2>&1 || true
    if [[ -f "$PIDFILE" ]]; then
      kill "$(cat "$PIDFILE")" 2>/dev/null || true
      rm -f "$PIDFILE"
    fi
    echo "stopped"
    ;;
  shot)
    # Screenshot the booted sim and stream it back base64-encoded over the SSH
    # channel (the forced-command key has no port-forwarding / scp; base64-on-stdout
    # is how evidence leaves the Mac). Box side: `ssh ... shot login | base64 -d > login.png`.
    shift || true
    name="$(printf '%s' "${1:-shot}" | tr -cd 'A-Za-z0-9._-')"; [[ -n "$name" ]] || name="shot"
    mkdir -p "$QADIR"
    if ! xcrun simctl io booted screenshot "$QADIR/$name.png" >/dev/null 2>&1; then
      echo "SHOT_FAILED (no booted sim?)" >&2; exit 1
    fi
    base64 < "$QADIR/$name.png"
    ;;
  tap)
    shift || true
    npx --yes serve-sim tap "$@" >/dev/null 2>&1 && echo "tapped $*"
    ;;
  type)
    shift || true
    npx --yes serve-sim type "$@" >/dev/null 2>&1 && echo "typed"
    ;;
  button)
    shift || true
    npx --yes serve-sim button "$@" >/dev/null 2>&1 && echo "button $*"
    ;;
  openurl)
    shift || true
    xcrun simctl openurl booted "$@" >/dev/null 2>&1 && echo "opened $*"
    ;;
  log)
    tail -n "${2:-40}" "$LOG" 2>/dev/null || echo "(no log yet)"
    ;;
  *)
    echo "usage: $0 {start|status|stop|shot|tap|type|button|openurl|log} [args]" >&2
    exit 1
    ;;
esac
