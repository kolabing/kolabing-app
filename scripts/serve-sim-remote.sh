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

LOG=/tmp/kolabing-serve-sim.log
PIDFILE=/tmp/kolabing-serve-sim.pid

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
  *)
    echo "usage: $0 {start|status|stop} [device] [port]" >&2
    exit 1
    ;;
esac
