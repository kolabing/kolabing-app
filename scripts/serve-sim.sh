#!/usr/bin/env bash
#
# Kolabing iOS QA — boot the iOS Simulator, stream it to a browser via serve-sim,
# and run the DEV build on it. Verified on macOS 26 / Xcode 26 / iPhone 17 (iOS 26.4).
#
#   *** macOS + Apple Silicon ONLY. A Linux box CANNOT run this. ***
#   *** The iOS Simulator is NEVER faked with a Flutter web build (web != iOS). ***
#
# serve-sim (https://github.com/EvanBacon/serve-sim) streams the REAL Simulator to a
# browser. It binds localhost by default; this script binds your Tailscale IP so you can
# watch from another device on your tailnet (falls back to localhost if Tailscale is off).
# serve-sim has NO password — only ever reach it over Tailscale, never a public network.
#
# Usage:   ./scripts/serve-sim.sh ["iPhone 17"] [PORT]
#   arg 1  simulator device name (optional; auto-detects an available iPhone)
#   arg 2  serve-sim port (default 3200)
#
# One-time requirements (see docs/ios-serve-sim-qa.md):
#   Xcode + an iOS 15.5+ simulator runtime, Flutter (Dart >= 3.10.7), CocoaPods,
#   Node >= 18 (for `npx serve-sim`), and ~15 GB free disk (a debug build needs it).
set -euo pipefail

DEVICE="${1:-}"
PORT="${2:-3200}"
ENV_DEFINE="--dart-define=APP_ENV=dev"   # the simulator always runs the DEV backend

[[ "$(uname)" == "Darwin" ]] || { echo "ERROR: iOS Simulator needs macOS (Apple Silicon). This is $(uname)." >&2; exit 1; }
command -v flutter >/dev/null || { echo "ERROR: flutter not found — see docs/ios-serve-sim-qa.md" >&2; exit 1; }

# Disk guard — a debug build failed once with 'No space left on device' (errno 28).
AVAIL_KB="$(df -k / | awk 'NR==2{print $4}')"
if [[ -n "${AVAIL_KB:-}" && "$AVAIL_KB" -lt 12000000 ]]; then
  echo "WARNING: only ~$((AVAIL_KB/1024/1024)) GB free on / — an iOS debug build needs ~10-15 GB." >&2
  echo "         If it dies with 'No space left on device (errno 28)', free space and retry." >&2
fi

# Resolve a usable simulator: requested name if available, else the first available iPhone.
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
[[ -n "${UDID:-}" ]] || { echo "ERROR: no available iOS simulator. Add one in Xcode > Settings > Components." >&2; exit 1; }
echo "==> Using simulator: $PICKED ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null || true   # non-zero if already booted; ignore
open -a Simulator

echo "==> Fetching dependencies"
flutter pub get
( cd ios && pod install )

# Bind serve-sim to the Tailscale interface only (reachable over the tailnet, NOT the
# public LAN). Fall back to localhost-only if Tailscale is not up.
# Resolve the tailscale CLI explicitly: under an SSH forced-command (headless, non-login)
# it is often not on PATH, and on macOS it lives at a Homebrew path or inside the app
# bundle rather than a standard bin dir. Without this, detection fails and the stream
# silently binds localhost-only (unreachable over the tailnet, incl. from the box).
TS_BIN="$(command -v tailscale || true)"
for _c in /usr/local/bin/tailscale /opt/homebrew/bin/tailscale \
          /Applications/Tailscale.app/Contents/MacOS/Tailscale; do
  [[ -n "$TS_BIN" ]] && break
  [[ -x "$_c" ]] && TS_BIN="$_c"
done
BIND="$( [[ -n "$TS_BIN" ]] && "$TS_BIN" ip -4 2>/dev/null | head -n1 || true )"
if [[ -z "$BIND" ]]; then
  BIND="127.0.0.1"; URL="http://127.0.0.1:$PORT   (localhost only — Tailscale not detected)"
else
  URL="http://$BIND:$PORT"
fi

echo "==> Starting serve-sim (daemon) on $BIND:$PORT"
npx --yes serve-sim --kill >/dev/null 2>&1 || true    # clear any earlier stream
npx --yes serve-sim --detach --host "$BIND" --port "$PORT"

cat <<EOF

serve-sim is streaming. Open it in a browser on your tailnet:
   $URL

No auth — keep it on Tailscale only, never a public network.
Stop the stream later with:   npx serve-sim --kill

Launching the app on the simulator (first build takes a few minutes)...
Press q to quit the app; the stream keeps running until you --kill it.
EOF

exec flutter run -d "$UDID" $ENV_DEFINE
