# Test the Kolabing iOS app in your browser (serve-sim)

Run the **real** iOS app on the iOS Simulator and view/tap it in a web browser — locally, or
remotely over Tailscale. Built for QA and for anyone on the team (Volkan, Maria, Daniel) to run on
their own Mac. Uses [serve-sim](https://github.com/EvanBacon/serve-sim) to stream the Simulator.

> **Why not just a web build?** The iOS Simulator only runs on **macOS (Apple Silicon)**. A Flutter
> **web** build is *not* an iOS test — it has no Apple In-App Purchase, no native plugins (scanner,
> push), and a different payment rail. So iOS QA runs the actual iOS Simulator, always on a Mac.

---

## Set it up on your own Mac (one-time)

You need an **Apple-Silicon Mac** with:

1. **Xcode** (from the App Store) + an **iOS 15.5+** simulator runtime (Xcode ▸ Settings ▸ Components).
   ```bash
   xcode-select --install
   sudo xcodebuild -license accept
   ```
2. **Toolchain** (Homebrew):
   ```bash
   brew install node cocoapods
   brew install --cask flutter        # or fvm; needs Dart >= 3.10.7
   flutter doctor                     # confirm ✓ Xcode / ✓ iOS toolchain
   ```
   `serve-sim` runs via `npx` and needs **Node >= 18** (no global install required).
3. **~15 GB free disk.** A first iOS debug build writes several GB; if the disk is near-full the
   build dies with `No space left on device (errno 28)`. Check with `df -h /`.
4. *(Optional, for remote viewing)* **Tailscale** — lets you watch the stream from your iPad/laptop.
   Not needed if you'll view on the same Mac.

Then clone the app (private repo, use your GitHub account):
```bash
git clone https://github.com/kolabing/kolabing-app.git
cd kolabing-app
```

No Apple Developer account or code-signing is needed for the **simulator** (the Podfile disables
signing in Debug). Signing is only for real-device / TestFlight builds.

---

## Run it

```bash
make serve-sim
# or:  ./scripts/serve-sim.sh              # auto-detects your iPhone simulator, port 3200
#      ./scripts/serve-sim.sh "iPhone 17" 3399   # pin a device / port
```

The script: picks an available iPhone simulator → `pub get` + `pod install` → starts **serve-sim**
(bound to your Tailscale IP if present, else localhost) → runs the **dev** build in the foreground.
First run is slow (Xcode compiles everything, ~3–5 min); later runs are fast.

## View the stream

The script prints the URL. Open it in a browser:
- **Same Mac:** `http://localhost:3200` (or the Tailscale IP it prints).
- **Another device over Tailscale:** `http://<your-mac-tailscale-ip>:3200` (find it with `tailscale ip -4`).

You can tap, type, and swipe right in the browser. When the build reaches
`Installing and launching…` / `Flutter run key commands`, the app is live on the sim and in the stream.

## Stop
```bash
# press q in the terminal to quit the app, then:
npx serve-sim --kill        # stop the stream
```

---

## Troubleshooting (things we actually hit)

| Symptom | Cause & fix |
|---|---|
| `No space left on device (errno 28)` during build | Disk full. macOS `df -h /` shows the shared APFS free space. Free ~15 GB (Xcode `DerivedData`, old iPhone backups, Docker image, caches) and retry. |
| Browser: **"refused to connect"** on the Tailscale IP | serve-sim binds `127.0.0.1` by default. This script binds your Tailscale IP; if it fell back to localhost, either view on the Mac itself, or ensure `tailscale ip -4` returns an address. |
| Stream loads once then dies on refresh | serve-sim exited (don't background it in tmux — this script uses its native `--detach` daemon). Re-run `make serve-sim`. |
| `Target native_assets required define SdkRoot…` | Benign Flutter warning — the build continues and launches. Ignore. |
| CocoaPods "did not set the base configuration…" | Benign — Flutter's own xcconfigs already include the Pods config. Ignore unless the build actually fails. |
| `make: serve-sim: Permission denied` | `chmod +x scripts/serve-sim.sh` (or `bash scripts/serve-sim.sh`). |
| Only wrong simulator exists | The script auto-detects any available iPhone; add a device in Xcode ▸ Settings ▸ Components if none. |

---

## Agent QA harness (optional, agent-driven)

serve-sim is CLI-drivable, so an agent can run a smoke flow and capture screenshots. Verify exact
syntax with `npx serve-sim --help`.

| Step | Action | Verify |
|---|---|---|
| 1 | App launches | `xcrun simctl io booted screenshot /tmp/01-launch.png` |
| 2 | Onboarding → continue | screenshot; advances |
| 3 | Reach sign-in (Google/Apple/email) | screenshot; auth screen (dark theme) |
| 4 | Role dashboard (Business/Community) | screenshot; 4-tab nav (Home · Explore · My Kolabs · Profile) |
| 5 | Explore feed | screenshot; cards render, no error |
| 6 | Open a detail screen | screenshot |

Input primitives: `serve-sim tap <x> <y>` (normalized 0..1), `serve-sim button home|lock`,
`serve-sim gesture '<json>'`, `serve-sim type <text>`, `xcrun simctl openurl booted "<deep-link>"`.
**Log bugs** as `kolabing/kolabing-app` GitHub issues (ticket-first per the repo `CLAUDE.md`), with the
failing step + screenshot.

## Known simulator limitations (need a real device / TestFlight)

serve-sim covers **UI / flow / layout** QA. These can't be validated in a bare simulator:
**Apple In-App Purchase** (iOS payment rail), **push notifications** (OneSignal/APNs), and
**camera / QR scan** (`mobile_scanner`; serve-sim camera-injection may partially help — verify).

## Security

serve-sim has **no authentication** and, when bound beyond localhost, exposes a token-gated
shell-exec route. Keep it reachable **only over Tailscale** (this script binds the Tailscale
interface, not `0.0.0.0`); never forward the port to a public network. The sim runs the **dev**
backend, never prod.
