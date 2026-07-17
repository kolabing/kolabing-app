# iOS Simulator QA via serve-sim (Mac host)

How agents (and Daniel) test the **real** Kolabing iOS app — not a web build, not screenshots.
The iOS Simulator streams to a browser over Tailscale via
[serve-sim](https://github.com/EvanBacon/serve-sim), and an agent can drive smoke flows via its CLI.

> **Why this exists / past mistakes:** the iOS Simulator only runs on **macOS (Apple Silicon)**. The
> Linux agent box `serra-ops-01` cannot run iOS. A prior attempt ran a Flutter **web** build on the box
> (which starved it — the "§13" incident) and treated web as a stand-in for iOS. It is not: web has no
> Apple In-App Purchase, no native plugins (scanner/push), and a different payment rail. iOS QA runs on
> the Mac, over Tailscale, always.

## Host

Daniel's personal Apple-Silicon Mac, on Tailscale (same tailnet as the box, already used for vault
sync). This is an **on-demand** capability — it works when the Mac is powered on and online.

## One-time setup (run on the Mac)

1. **Xcode + Simulator runtime** — install Xcode from the App Store, then:
   ```bash
   xcode-select --install
   sudo xcodebuild -license accept
   ```
   In Xcode ▸ Settings ▸ Components, install an **iOS 15.5+** simulator runtime (app min is 15.5).
2. **Toolchain** (Homebrew):
   ```bash
   brew install node cocoapods tmux
   brew install --cask flutter        # or fvm; needs Dart >= 3.10.7
   flutter doctor                     # confirm ✓ Xcode / ✓ iOS toolchain
   ```
   `serve-sim` needs **Node >= 18** (run via `npx serve-sim`, no global install required).
3. **Tailscale SSH** (so the agent box can drive the Mac):
   ```bash
   tailscale up --ssh
   ```
   Add a tailnet ACL allowing `serra-ops-01` → this Mac. Verify from the box: `ssh <mac-magicdns>`
   connects with no password/keys.
4. **Clone the app:**
   ```bash
   git clone https://github.com/kolabing/kolabing-app.git
   cd kolabing-app && flutter pub get && (cd ios && pod install)
   ```

No Apple Developer account / code-signing is needed for the **simulator** (the Podfile disables signing
in Debug). Signing is only for real-device / TestFlight builds (deferred).

## Run it

```bash
./scripts/serve-sim.sh              # auto-detects an available iPhone simulator, port 3200
./scripts/serve-sim.sh "iPhone 17" 3399   # pin a specific device / port
# or:  make serve-sim
```

The script boots the sim, runs the **dev** build, and starts serve-sim in tmux. Open the printed
Tailscale URL (`http://<mac-tailscale-ip>:3200`) in your browser to interact with the live app.

> First run: confirm serve-sim's flags with `npx serve-sim --help` and adjust the script if a flag or
> the default port differs for the installed version.

## Agent QA harness (smoke flow)

Run on the Mac, or over Tailscale SSH from the box. serve-sim CLI drives input; `simctl` captures
screen state for verification.

| Step | Action | Verify |
|---|---|---|
| 1 | App launches (`flutter run` above) | `xcrun simctl io booted screenshot /tmp/01-launch.png` |
| 2 | Onboarding carousel → continue | screenshot; onboarding advances |
| 3 | Auth: reach sign-in (Google/Apple/email) | screenshot; auth screen renders (dark theme) |
| 4 | Land on a role dashboard (Business / Community) | screenshot; 4-tab bottom nav (Home · Explore · My Kolabs · Profile) |
| 5 | Explore feed loads | screenshot; cards render, no error state |
| 6 | Open a detail (opportunity/collaboration) | screenshot; detail screen |

serve-sim input primitives (verify exact syntax with `npx serve-sim --help`):
`serve-sim tap <x> <y>` (normalized 0..1), `serve-sim button home|lock`,
`serve-sim gesture '<json>'`, and `xcrun simctl openurl booted "<deep-link>"`.

**Log bugs** to the Kolabing dev queue — open a `kolabing/kolabing-app` GitHub issue (ticket-first per
the repo `CLAUDE.md`) and/or a note under `kalah-ventures/kolabing/dev/tickets/` in the vault, routed to
the dev queue with the failing step + screenshot.

## Known simulator limitations (need a real device / TestFlight)

serve-sim is for **UI / flow / layout** QA. These cannot be validated in a bare simulator:
- **Apple In-App Purchase** — the iOS payment rail; needs a device / StoreKit config / TestFlight.
- **Push notifications** — OneSignal / APNs; real-device is authoritative.
- **Camera / QR scan** (`mobile_scanner`) — the sim has no camera (serve-sim camera-injection may help;
  verify).

## Security

serve-sim has **no authentication**. Keep it bound to the Mac and reachable **only over Tailscale**
(MagicDNS + ACL); never forward the port to a public network. The sim runs the **dev** backend, never
prod. Nothing here touches the production deploy gate.
