# Task: welcome-screen-redesign

## Status
- Created: 2026-05-17 13:30
- Started: 2026-05-17 13:30
- Completed:

## Description
Redesign the first welcome screen (`lib/features/auth/screens/welcome_screen.dart`).
Goals when the user lands on the screen:
1. Instantly communicate "this app is FOR me as a business OR as a community"
2. Provoke the thought: "I need to register this app for my business / community"
3. One signature animation (not a loop of micro-effects) — feels alive but premium
4. Tighten to the Kolabing yellow + black system (primary `#FFE28C`, near-black `#0D0D0D`, warm beige bg `#F5F1E8`)
5. Keep the existing `KolabingLogo` (light/transparent variant)
6. Maintain existing CTAs: CREATE ACCOUNT → user type selection, LOGIN → login

## Out of scope
- Splash route logic
- User type selection screen
- Backend / routing changes

## Assigned Agents
- [x] @ui-designer (spec)
- [x] @flutter-expert (implementation)

## Progress

### UX Design
**Status:** Done — see inline spec from ui-designer subagent run.

### Flutter Implementation
**Status:** Done — `lib/features/auth/screens/welcome_screen.dart` rewritten.

## Notes
Animation choice: single hero entrance — the Kolabing cloud logo rises into frame,
a yellow spotlight blooms behind it, and two role chips ("FOR BUSINESS" / "FOR COMMUNITY")
slot in below with a staggered slide so both audiences see themselves immediately.
