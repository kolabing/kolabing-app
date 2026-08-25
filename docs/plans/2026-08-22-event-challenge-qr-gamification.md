# Event Challenge QR Gamification Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the event-challenge loop playable end to end with QR only — organizer QR → check-in → peer scan → event challenges → initiate → verify QR → XP.

**Architecture:** One scanner screen routes three QR payload kinds (opaque check-in token, `/u/{profileId}` peer, `/qr/verify/{completionId}` verify). A locally-persisted `ActiveEventSession`, seeded by the `POST /checkin` response, supplies the event context for peer pairing. All five endpoints are already live and already wrapped by `CheckinService` / `ChallengeService`, so **no backend or service-layer work** — this is models, providers, screens, routing and i18n.

**Tech Stack:** Flutter, Riverpod 3 (`Notifier`/`NotifierProvider`), GoRouter, `mobile_scanner` ^7.2.0, `qr_flutter` ^4.1.0, `shared_preferences`, gen-l10n (en/es/ca).

**Ticket:** #132 · **Branch:** `feat/event-challenge-qr-gamification` · **Design:** `docs/plans/2026-08-22-event-challenge-qr-gamification-design.md`

---

## Task 1: QR payload parser

**Files:**
- Create: `lib/features/gamification/models/qr_payload.dart`
- Test: `test/features/gamification/models/qr_payload_test.dart`

**Step 1 — write the failing test.** Cover: prod host peer URL, dev host peer URL, verify URL, opaque token, too-short junk, a random https URL, empty string, uppercase/trailing-slash tolerance, and a peer URL with a query string.

**Step 2 — run it, expect a compile failure** (`QrPayload` undefined): `flutter test test/features/gamification/models/qr_payload_test.dart`

**Step 3 — implement.** A sealed class with `QrCheckinToken`, `QrPeerProfile`, `QrVerifyCompletion`, `QrUnknown` and a static `QrPayload.parse(String raw)`. Match on **path segments only** — never on host (`Environment.shareHost` differs between prod and dev). Path shapes: `u/{id}` → peer, `qr/verify/{id}` → verify. A value that does not parse as an `http(s)` URI and is 16–128 chars of `[A-Za-z0-9_-]` → check-in token. Everything else → unknown.

**Step 4 — run the test, expect PASS.**

**Step 5 — commit:** `feat(gamification): QR payload parser for check-in, peer and verify codes`

---

## Task 2: Active event session

**Files:**
- Create: `lib/features/gamification/models/active_event_session.dart`
- Create: `lib/features/gamification/providers/active_event_session_provider.dart`
- Test: `test/features/gamification/models/active_event_session_test.dart`

**Step 1 — write the failing test.** `isExpired` false right after check-in, true 13h later; `toJson`/`fromJson` round-trip; `fromJson` on malformed JSON returns null.

**Step 2 — run it, expect failure.**

**Step 3 — implement.** `ActiveEventSession {eventId, eventName, checkedInAt, expiresAt}`. `Event` has no `endsAt` field (verified), so the rule is **`expiresAt = checkedInAt + 12h`**. `ActiveEventSessionNotifier extends Notifier<ActiveEventSession?>` persists to `SharedPreferences` under `active_event_session`, exposes `start(EventCheckin)`, `clear()`, and drops an expired session on read.

**Step 4 — run the test, expect PASS.**

**Step 5 — commit:** `feat(gamification): persisted active-event session from check-in`

---

## Task 3: i18n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_ca.arb`

**Step 1.** Add every string this feature needs (scanner modes, pairing sheet, challenge list, verify QR, XP celebration, all §6 error messages). es = European/Castilian Spanish, ca = Catalan.

**Step 2.** Run `flutter gen-l10n`, then `flutter analyze lib/l10n` — expect 0 errors.

**Step 3 — commit:** `i18n(gamification): en/es/ca strings for the QR challenge loop`

---

## Task 4: Scanner screen — three payload kinds

**Files:**
- Rewrite: `lib/features/gamification/screens/qr_scanner_screen.dart` → `AttendeeScannerScreen`
- Create: `lib/features/gamification/widgets/scan_result_sheet.dart`
- Test: `test/features/gamification/screens/attendee_scanner_test.dart`

**Step 1 — write the failing widget test** with a fake `CheckinService`: scanning a check-in token calls `checkIn` and opens the active session; scanning an unknown payload shows the localized unknown-code message and keeps the camera alive.

**Step 2 — run, expect failure.**

**Step 3 — implement.** Replace `_isValidCheckinToken` (currently `length >= 10`) with `QrPayload.parse`. Route: check-in → `POST /checkin` (409 = informational, still opens the session); peer → pairing sheet; verify → `POST .../verify`. Debounce repeat scans of the same value for 3s instead of latching `_hasScanned` forever, so a failed scan can be retried without reopening the screen.

**Step 4 — run, expect PASS.**

**Step 5 — commit:** `feat(gamification): one attendee scanner for all three QR kinds`

---

## Task 5: Peer pairing → challenge list → initiate

**Files:**
- Create: `lib/features/gamification/widgets/peer_challenge_sheet.dart`
- Test: `test/features/gamification/widgets/peer_challenge_sheet_test.dart`

**Step 1 — write the failing widget test:** with an active session and a stubbed challenge list the sheet renders the challenges; tapping one calls `initiate` with the scanned profile as `verifier_profile_id`; a 422 shows the "both of you must check in" message.

**Step 2 — run, expect failure.**

**Step 3 — implement.** Header "you matched with X", then `eventChallengesProvider(activeSession.eventId)` as a list of `ChallengeCard`s with points + difficulty. No active session → show the live "going" events picker, or the "check in first" empty state with a shortcut to the scanner. Guard against scanning your own profile.

**Step 4 — run, expect PASS.**

**Step 5 — commit:** `feat(gamification): peer pairing sheet lists the event's challenges`

---

## Task 6: Verify QR + XP celebration

**Files:**
- Create: `lib/features/gamification/screens/challenge_verify_qr_screen.dart`
- Create: `lib/features/gamification/providers/completion_watch_provider.dart`
- Test: `test/features/gamification/providers/completion_watch_test.dart`

**Step 1 — write the failing test:** the watcher polls `getMyChallengeCompletions`, emits `verified` when the matching completion flips, and stops polling after a terminal status or the 2-minute timeout.

**Step 2 — run, expect failure.**

**Step 3 — implement.** `ChallengeVerifyQrScreen` renders `https://{Environment.shareHost}/qr/verify/{completionId}`, polls every 3s, and on `verified` shows a "+X XP" celebration built from `pointsEarned` (never a client-side guess), invalidating `myStatsProvider` / `myBadgesProvider`. On `rejected` show the rejected state. Timeout keeps a "show the QR again" action.

**Step 4 — run, expect PASS.**

**Step 5 — commit:** `feat(gamification): verify QR with live polling and XP celebration`

---

## Task 7: Entry points

**Files:**
- Modify: `lib/features/gamification/screens/attendee_main_screen.dart` (app-bar QR icon → QR hub sheet: **Scan** / **My QR**)
- Modify: `lib/features/event/screens/event_hub_screen.dart` (leader → "Show check-in QR" → `/attendee/events/:id/qr`; member → "Check in")
- Modify: `lib/features/gamification/screens/event_qr_code_screen.dart` (only if it needs token-refresh or theming fixes)
- Test: `test/features/gamification/screens/qr_hub_test.dart`

**Step 1 — write the failing widget test:** the app-bar QR action opens a sheet offering both Scan and My QR.

**Step 2 — run, expect failure. Step 3 — implement. Step 4 — run, expect PASS.**

**Step 5 — commit:** `feat(gamification): QR hub on the attendee app bar + event-hub check-in entries`

---

## Task 8: Unflag, clean up, verify

**Files:**
- Modify: `lib/config/feature_flags.dart` (`kGamificationSetupEnabled = true`)
- Modify: `lib/config/routes/routes.dart` (delete the dead `eventCheckins` and `editChallenge` constants)
- Modify: `BACKLOG.md`

**Step 1.** Flip the flag, delete the dead constants, and update `BACKLOG.md` (NF-21 status, and note that FX-21/FX-22 are obsolete since the attendee home was rebuilt).

**Step 2.** Run `flutter analyze` — expect 0 errors. Run `flutter test` — expect all green.

**Step 3 — commit:** `chore(gamification): enable the challenge loop, drop dead route constants`

---

## Task 9: Review and PR

**Step 1.** Run `/code-review` and fix whatever it confirms.
**Step 2.** Open the PR against `master` with the full `.github/pull_request_template.md`, every section filled, screenshots for the UI change, and `Closes #132`.
