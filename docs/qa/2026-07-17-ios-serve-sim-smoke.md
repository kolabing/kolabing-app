# Kolabing iOS — serve-sim QA smoke plan (2026-07-17)

Companion to `docs/ios-serve-sim-qa.md`. A prioritized smoke checklist for the iOS app on the
Simulator (via `make serve-sim`), weighted to the most recently changed areas (highest regression
risk). Run it against the **dev** backend.

**Results start `pending` — mark pass/fail only from actual observation on the stream (no guessing).**
Log any failure as a `kolabing/kolabing-app` GitHub issue (ticket-first per `CLAUDE.md`) with the step
+ a screenshot (`xcrun simctl io booted screenshot <path>`).

## 1. Closing / completing a Kolab  *(most churn: #42, #37, #53, #50, #40, #56)*
- **1.1** Complete a Kolab (confirm-first) → both confirmers reach the **review form** (#53).
- **1.2** Submit the **5-star review** → shows only when reviewable; blocked otherwise (#50).
- **1.3** QR shown **on demand**, not forced (#37).
- **1.4** Tap the completion **notification** → opens the collaboration detail (#40), incl. cold start (#56).

## 2. Consent — Terms + Privacy  *(#66/#67; ties to kolabing-v2 PR #92 Estonia)*
- **2.1** Fresh sign-up → consent screen appears; can't proceed without accepting.
- **2.2** Terms/Privacy links are **readable** and open (#67).
- **2.3** Re-open app → not re-prompted unless `terms_version` changed.

## 3. Kolabs — create & apply  *(#41, #44, #45, #30)*
- **3.1** Business: create + publish (redesigned flow #41); default cover fallback.
- **3.2** Explore: Recommended / All / **Saved** + bookmark toggle (#44).
- **3.3** Own kolab not shown / not applyable in Explore (#30).
- **3.4** Community: apply to a Kolab.
- **3.5** My Kolabs hub: sub-filters + unified action bar render, no overflow (#45).

## 4. Chats  *(#35 + changelog)*
- **4.1** Sender's **name** shows on others' messages.
- **4.2** Business "View opportunity" shows the community submission, not "Apply Now" on own kolab (#35).
- **4.3** New ungated chat visible to members by default.

## 5. Gamification / rewards  *(⚠️ #60 hid in-app gamification — verify visibility first; #33, #38, #51, #58)*
- **5.1** Confirm what gamification is actually visible now (#60) before testing.
- **5.2** Community dashboard after session reset → no `WalletNotifier` crash (#33).
- **5.3** Missions screen + profile entry points (#38).
- **5.4** Reputation summary on public profile (#51); "0 partners" hidden when none (#58).

## 6. Profile / dashboard  *(#68, #52)*
- **6.1** Business Dashboard redesign matches Community styling (#68).
- **6.2** Profile → Past Kolabs + gallery render, no empty gaps (#52).

## Not testable on a bare simulator (need real device / TestFlight)
Apple **In-App Purchase** (iOS subscription paywall), **push notifications** (OneSignal/APNs delivery),
**camera / QR scan** (`mobile_scanner`).
