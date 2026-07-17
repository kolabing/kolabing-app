#!/usr/bin/env bash
#
# Kolabing iOS QA — boot the iOS Simulator, run the DEV build, and stream it to a
# browser via serve-sim (https://github.com/EvanBacon/serve-sim).
#
#   *** macOS + Apple Silicon ONLY. The Linux agent box CANNOT run this. ***
#   *** The iOS Simulator is NEVER faked with a Flutter web build (web != iOS). ***
#
# Access the stream over Tailscale only — serve-sim has NO auth, so never expose the
# port to a public network. The simulator always runs the DEV backend (dev data).
#
# Usage:   ./scripts/serve-sim.sh ["iPhone 16"] [PORT]
#   arg 1  simulator device name (default "iPhone 16")
#   arg 2  serve-sim port (default 3200)
#
# Requirements (see docs/ios-serve-sim-qa.md for the one-time setup):
#   Xcode + an iOS 15.5+ simulator runtime, Flutter (Dart >= 3.10.7), CocoaPods,
#   Node >= 18 (for `npx serve-sim`), Tailscale up, tmux.
#
# NOTE: This is a first-run SCAFFOLD. serve-sim's exact start flags/default port can
# change between versions — confirm with `npx serve-sim --help` on the Mac and adjust.
set -euo pipefail

DEVICE="${1:-}"          # optional simulator name; auto-detected if omitted or not present
PORT="${2:-3200}"
ENV_DEFINE="--dart-define=APP_ENV=dev"   # simulator always uses the DEV backend

if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: iOS Simulator needs macOS (Apple Silicon). This host is $(uname). Aborting." >&2
  exit 1
fi
command -v flutter >/dev/null || { echo "ERROR: flutter not found — see docs/ios-serve-sim-qa.md" >&2; exit 1; }
command -v tmux    >/dev/null || { echo "ERROR: tmux not found (brew install tmux)" >&2; exit 1; }

# Resolve a usable simulator: the requested name if available, else the first available
# iPhone (so this works on any Mac regardless of which simulator devices exist).
read -r UDID PICKED < <(xcrun simctl list devices available -j | python3 -c '
import json,sys
want = sys.argv[1] if len(sys.argv) > 1 else ""
devs = [x for r in json.load(sys.stdin)["devices"].values() for x in r]
def out(x): print(x["udid"], x["name"])
if want:
    for x in devs:
        if x["name"] == want: out(x); sys.exit()
for x in devs:
    if x["name"].startswith("iPhone"): out(x); sys.exit()
if devs: out(devs[0])
' "$DEVICE") || true
[[ -n "${UDID:-}" ]] || { echo "ERROR: no available iOS simulator found. Add one in Xcode > Settings > Components." >&2; exit 1; }
echo "==> Using simulator: $PICKED ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null || true   # non-zero if already booted; ignore
open -a Simulator

echo "==> Fetching dependencies (first run is slow)"
flutter pub get
( cd ios && pod install )

echo "==> Running the app on the simulator (DEV backend), tmux session 'kolabing-run'"
tmux kill-session -t kolabing-run 2>/dev/null || true
tmux new-session -d -s kolabing-run "flutter run -d $UDID $ENV_DEFINE"

echo "==> Starting serve-sim on port $PORT, tmux session 'serve-sim'"
tmux kill-session -t serve-sim 2>/dev/null || true
tmux new-session -d -s serve-sim "npx --yes serve-sim --port $PORT"

TS_IP="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
cat <<EOF

serve-sim is starting. Open the live stream over Tailscale (NOT a public URL):
$( [[ -n "$TS_IP" ]] && echo "   http://$TS_IP:$PORT" )
   or via MagicDNS:   http://$(hostname -s):$PORT   (depends on your tailnet config)

Agent control (run on this Mac, or over Tailscale SSH from the box):
   serve-sim tap <x> <y>                         # normalized coords, 0..1
   serve-sim button home|lock                    # hardware buttons
   xcrun simctl io booted screenshot /tmp/shot.png   # reliable native screenshot
   xcrun simctl openurl booted "<deep-link>"     # drive a deep link

Attach:  tmux attach -t kolabing-run   |   tmux attach -t serve-sim
Stop:    tmux kill-session -t kolabing-run ; tmux kill-session -t serve-sim
EOF
