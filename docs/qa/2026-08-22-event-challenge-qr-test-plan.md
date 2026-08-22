# QA test plan — event-challenge QR loop (#132 / PR #133)

> Covers the whole loop: organizer QR → member check-in → peer pairing →
> challenge → verification → XP. Written to be run by someone who did not build
> it. Every scenario says what it *guards*, so a failure points at a cause.
>
> **Two devices are mandatory.** The loop is inherently two-person: one member
> shows a code, the other scans it. A single device can only cover §A, §C and §J.

---

## 0. Setup

### 0.1 Accounts and data

| Role | Needed for | Notes |
|---|---|---|
| **Community leader** (owns a community with an event) | §A, §M1 | Must be the event's organizer — `generate-qr` is 403 for anyone else |
| **Attendee A** ("challenger") | §B–§K | Must be **going** to that event |
| **Attendee B** ("verifier") | §D–§H | Must be **going** to the same event |

Attendee **sign-up is still disabled** in the app (`user_type_selection_screen.dart`
`isEnabled: false`). Use two **existing** attendee accounts; you cannot register
new ones from this build.

The event needs **at least one challenge**. Event challenges are the ones with
`trigger_action IS NULL` (`GET /events/{id}/challenges`) — general missions are
deliberately excluded. If the list comes back empty, §E4 is the expected result
and §F onwards cannot run: seed a challenge first (leader → event → challenges,
or directly).

### 0.2 Builds

Android could not be built here (no Android SDK on the build machine), so the
artifact below is iOS-simulator only. Android needs a build on a machine with
the SDK before §M and §L can be signed off on that platform.

| Build | Command | Points at |
|---|---|---|
| iOS simulator (dev backend) | `flutter build ios --simulator --debug` | `kolabing-v2-development…laravel.cloud` |
| iOS simulator (**prod** data) | `flutter build ios --simulator --debug --dart-define=APP_ENV=prod` | `kolabing.com` |
| iOS device / TestFlight | `flutter build ipa` | prod (release default) |

**Which one to use.** The dev backend is unlikely to have a community, an event
and challenges seeded, so the loop cannot be exercised there — run the QA
against **prod** (`APP_ENV=prod`). Be aware this writes real data: real
check-ins, real `point_ledger` rows, real XP on the test accounts.

Install the simulator build with:

```bash
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
```

Two simulators (two "devices") work fine for everything except camera scanning —
a simulator has no camera. **§D onwards needs at least one real device**, and
ideally two. A practical mix: real device for the scanning side, simulator (or a
second device) for the side displaying a QR.

### 0.3 A note on scanning screens

Scanning a QR off another screen works, but keep brightness up and hold ~15cm
away. The QR quiet zone is deliberately white in both light and dark theme — if
you see a dark background behind any QR, that is a bug.

---

## §A — Organizer shows the check-in QR

| | |
|---|---|
| **Guards** | The entry point `EventQRCodeScreen` never had: its route existed but nothing pushed it, so step 1 of the loop was impossible. |

**A1 — happy path.** Leader → community → the event → **⋮** → **Show check-in QR**.
*Expect:* a QR renders, with the event name above it. No spinner stuck, no error card.

**A2 — refresh rotates the token.** On that screen, tap the refresh icon (top right).
*Expect:* a brief spinner, then a QR that is **visibly different** (`POST /events/{id}/generate-qr` issues a new token). A previously-shown code should no longer check anyone in — worth confirming together with **C2**.

**A3 — copy token.** Tap **Copy token**. *Expect:* a confirmation snackbar.

**A4 — not the organizer.** Sign in as a *different* community leader and open the same event's QR action (or hit the route directly).
*Expect:* the error card reads **"Only this event's organizer can show its check-in code."** — **not** a Dart exception string like `CheckinException(CheckinFailure.unauthorized): …`. *(Guards `4a8daf3`.)*

**A5 — no dead ends.** Confirm there is **no** "View check-ins" button on this screen.
*Expect:* absent. It used to push an unregistered route and land on the router's error page. *(Guards `4a8daf3`.)*

---

## §B — Member checks in (happy path)

| | |
|---|---|
| **Guards** | Direction of the flow. `POST /checkin` checks in *the caller*, so the member must be the one scanning; the previous wiring had the leader scanning members. |

**B1 — from the event hub.** Attendee A → the event → **Check in** → scan the leader's QR (§A1).
*Expect:* a success sheet titled "Check-in Successful!", the event name, **"Now scan someone's profile QR to play a challenge together."**, and — if the server awarded any — a **+N XP** pill. Primary button reads **SCAN SOMEONE**.

**B2 — the XP figure is the server's.** Note the number in B1's pill.
*Expect:* it matches `points_earned` from the response. If the server awards nothing, **no pill at all** — never a "+0 XP". *(Points are never computed client-side; BACKLOG FX-8.)*

**B3 — active-event banner.** After B1, tap **SCAN SOMEONE**.
*Expect:* back on the camera, with a banner at the top reading **"At \<event name\>"**. This is the context that decides which challenges a peer scan will offer.

**B4 — from the QR hub.** Sign in as a fresh attendee, tap the **QR icon in the app bar** → **Scan a code** → scan the leader's QR.
*Expect:* same as B1. (Two entry points, one scanner.)

**B5 — done closes the scanner.** Repeat B1 and press the secondary **Done**.
*Expect:* the sheet closes *and* the scanner closes, returning to where you were. No crash, no camera error in the console. *(Guards finding 10 — the scanner used to be popped from inside a sheet callback, restarting a camera controller that was being disposed.)*

**B6 — check-in button visibility.** Look at the event hub as a member who has **not** said they are going.
*Expect:* **no** Check in button. It appears only once `isGoing` is true.

---

## §C — Check-in failures

**C1 — a QR that is not ours.** Scan any random QR (a wifi code, a URL, a vCard, a shop's payment code).
*Expect:* a brief snackbar **"That isn't a Kolabing QR code."**, and **the camera stays live** — no sheet, no screen teardown. You can immediately scan something else. *(Guards the old behaviour: any string ≥10 chars was POSTed to `/checkin`, and one bad scan latched the scanner until you closed and reopened it.)*

**C2 — a rotated/invalid token.** Have the leader refresh the QR (§A2), then scan the **old** code (photograph it first).
*Expect:* an error sheet **"That check-in code isn't valid any more. Ask the organizer to show it again."** Not a raw backend message.

**C3 — scanning twice (the 409).** After a successful B1, scan the **same** code again.
*Expect:* an **informational** sheet — title **"You're checked in"**, body "You were already checked in — you're all set." plus the next-step line — **not** an error. Primary action **SCAN SOMEONE**.

**C4 — 409 recovery is the important half.** This is the one to be thorough about.
1. Attendee A checks in (B1).
2. Force-quit the app, and clear its storage (delete/reinstall, or sign out and back in — anything that drops the local session).
3. Reopen → the event hub → **Check in** → scan the same code. It 409s (C3).
4. Now tap **SCAN SOMEONE** and scan Attendee B's profile QR.

*Expect:* the challenge list opens for **that event**. *Do not* expect "Check in first".
*Guards:* the dead loop the review found — checked in server-side, no local session, and the app's only suggestion was to rescan the code that 409s. *(`c55cab3`, finding 3.)*

**C5 — event closed to check-ins.** If you can put the event in a state where check-in is refused (past its date, cancelled).
*Expect:* the backend's own reason, or "This event isn't taking check-ins right now." Never a Dart type name.

**C6 — camera permission denied.** Deny camera access for the app (Settings → Kolabing → Camera off), then open the scanner.
*Expect:* in place of the preview, "Kolabing needs camera access to scan QR codes." and a working **Open Settings** button. No crash, no blank black screen with nothing to do.

**C7 — offline.** Turn on airplane mode and scan a valid code.
*Expect:* a generic failure sheet with **Try again**, and the camera comes back. No exception text on screen.

---

## §D — Pairing up (happy path)

**D1 — B shows their code.** Attendee B → app-bar **QR icon** → **My QR code**.
*Expect:* a sheet with B's QR and their display name. The QR sits on a **white** panel.

**D2 — A scans B.** Attendee A (checked in) → scanner → scan B's QR.
*Expect:* a sheet headed **"Paired with \<B's name\>"**, subtitle "Pick a challenge to play together.", an **"At \<event\>"** chip, and a list of that event's challenges with difficulty and points.

**D3 — name unavailable is not "Unknown".** If B's profile lookup fails or returns no usable name (a known backend gap for attendees, FX-16).
*Expect:* the header falls back to **"Paired up"** — never the literal word "Unknown".

---

## §E — Pairing edge cases

**E1 — your own code.** A opens **My QR code** on one device, and scans it from... itself is impossible, so: sign in as A on a second device, show A's QR there, and scan it with A's first device.
*Expect:* snackbar **"That's your own code — ask the other person to show theirs."**, camera stays live. No pairing sheet.

**E2 — pairing without checking in.** Fresh attendee (no check-in) scans B's profile QR.
*Expect:* **"Check in first"** with an explanation and a single action **SCAN EVENT CODE**, which returns you to the camera. No challenge list, and no guessing at an event.

**E3 — an expired session.** Hard to force naturally (12h TTL). If you can change the device clock forward by 13h, or wait: check in, advance the clock, then scan a peer.
*Expect:* the **"Check in first"** state — *not* yesterday's challenge list. *(Guards `d368e6a`.)*

**E4 — event with no challenges.** Pair up at an event that has none.
*Expect:* "This event has no challenges yet." Not an empty white sheet, not a spinner.

**E5 — challenge list fails to load.** Airplane mode on, then pair up.
*Expect:* "Couldn't load this event's challenges." plus a **Retry** that actually retries once you are back online.

---

## §F — Starting a challenge

**F1 — happy path.** From D2, tap a challenge.
*Expect:* that row shows a spinner, the others dim, and no second tap registers. Then the **verification QR** screen opens: the challenge name, **"Ask \<B\> to scan this code to confirm you did it."**, a QR, and **"Waiting for confirmation…"** with a spinner.

**F2 — verifier not checked in.** Have B **not** check in, then A pairs with B and starts a challenge.
*Expect:* a snackbar **"Couldn't start this challenge. Make sure you're both checked in to this event."** — and the sheet stays open so A can retry after B checks in. *(The wording is deliberately hedged: the backend returns 422 for other validation failures too. Guards `c55cab3`, finding 6.)*

**F3 — starting the same challenge twice.** Start a challenge, leave it pending, and start the same one with the same partner again.
*Expect:* a failure snackbar (409 from the backend), not a duplicate pending record.

---

## §G — Verification and XP (the payoff)

**G1 — happy path.** With F1's QR on A's screen: Attendee B → scanner → scan A's screen.
*Expect on B:* a sheet naming the challenge and A — **"Did \<A\> complete “\<challenge\>”?"** — with **VERIFY** and **REJECT**. Tap VERIFY. Then a success sheet: **"Confirmed"**, "\<A\> earned N XP."
*Expect on A:* within ~3 seconds, without touching anything, the screen flips to **"Challenge complete!"** with a large **+N XP**.

**G2 — the two numbers agree.** Compare N on B's sheet and N on A's screen.
*Expect:* identical, and both equal the server's `points_earned`.

**G3 — XP actually landed.** On A: open profile → **Points** → the rewards screen.
*Expect:* the total reflects the new XP (pull to refresh if needed). **[VERIFY]** — this is the one open question on the PR: confirm the ledger credited **A** (the challenger), not B. If B's total moved instead, stop and report it; it is a backend issue and the app deliberately does not compensate.

**G4 — rejection.** Repeat F1, and this time B taps **REJECT**.
*Expect on B:* "Rejected". *Expect on A:* "Not confirmed" with "You can try another challenge." and **no** XP.

---

## §H — Verification edge cases

**H1 — dismissing must not read as success.** ⚠️ *The highest-severity bug the review caught — please do run this one.*
On B, scan A's verification QR so the confirm sheet appears, then dismiss it **without deciding**: Android back button or back gesture. (On iOS the sheet is deliberately not dismissible — confirm you *cannot* swipe it away.)
*Expect:* you land back on the live camera with **nothing claimed**. You must **not** see "Confirmed" or "+0 XP". A's screen stays "Waiting for confirmation…".
*Guards:* `isConfirmed` used to be the negation of the other three flags, so a dismissal satisfied it. *(`c55cab3`, finding 1.)*

**H2 — the wrong person scans.** A third member (not the designated verifier) scans A's verification QR.
*Expect:* **"Couldn't confirm"** / "That challenge isn't waiting for your confirmation." Note the title is *not* "Check-in Failed". *(Guards finding 7.)*

**H3 — a stale code.** After G1 completes, scan A's (now settled) verification QR again.
*Expect:* the same "not waiting for your confirmation" outcome — not a second award.

**H4 — offline verifier.** Airplane mode on B, then scan A's verification QR.
*Expect:* **"Couldn't reach the server. Check your connection and scan again."** — explicitly **not** "that challenge isn't waiting for your confirmation", which would send you chasing the wrong problem. *(Guards `c55cab3`, finding 2.)*

**H5 — a busy verifier.** If B has many recent completions (>10), verify that scanning a **fresh** code still resolves.
*Expect:* the confirm sheet, not "not waiting for your confirmation". *(Guards `d368e6a` — the lookup used to read only the first page of 10.)*

---

## §I — Waiting, timeout, resume

**I1 — timeout.** Start a challenge (F1) and leave A's screen untouched for **~2 minutes** without B scanning.
*Expect:* "Still waiting" with an explanation, a **KEEP WAITING** button and a **Done** link. Not an error, and not a spinner forever.

**I2 — resume after timeout.** From I1, tap **KEEP WAITING**, then have B scan and verify.
*Expect:* A's screen still flips to "+N XP".

**I3 — leaving and coming back.** From F1, close A's screen with **✕** while pending, then have B verify.
*Expect:* no crash on either side. A can see the completion later in their challenge history. *(Known v1 limit: there is no "show that QR again" surface yet — tracked as **NF-23**. If A closes the screen and B never scans, the completion stays pending. That is expected, not a bug.)*

**I4 — flaky network while waiting.** Toggle airplane mode on and off on A while the QR is displayed.
*Expect:* the screen keeps saying "Waiting for confirmation…" and recovers on its own — no error flash per failed poll.

---

## §J — QR kind discrimination (single device)

The scanner reads three kinds of Kolabing code and must never confuse them.

| Scan | Expect |
|---|---|
| **J1** Event check-in code | check-in flow (§B) |
| **J2** A member's profile QR | pairing flow (§D) |
| **J3** A verification QR | confirm flow (§G) |
| **J4** A wifi QR | "That isn't a Kolabing QR code.", camera stays live |
| **J5** A plain website URL | same as J4 |
| **J6** A vCard / contact QR | same as J4 |
| **J7** A very short code (<8 chars) | same as J4 |

**J8 — dev vs prod codes.** If you have both builds: a QR generated by the prod build must be readable by the prod build. (Codes are matched on their **path**, not the host, so a dev build can read a prod profile QR too — that is intended; the API call behind it will simply be scoped to whichever backend the build points at.)

---

## §K — Session lifecycle

**K1 — survives a restart.** Check in, force-quit the app, reopen, scan a peer.
*Expect:* the challenge list for the same event (the session is persisted).

**K2 — cleared on sign-out.** Check in as A, sign out, sign in as **B**, and scan a peer.
*Expect:* **"Check in first"** — B must not inherit A's active event.

**K3 — banner accuracy.** With a session open, the scanner banner names the event you checked into. Check into a *different* event and re-open the scanner.
*Expect:* the banner names the **new** event, and pairing lists the new event's challenges.

---

## §L — Localization

Switch the app language (profile → Language) and walk §B1, §D2, §F1, §G1 in each of **Spanish** and **Catalan**.

*Expect:* every string above is translated — sheet titles, bodies, buttons, snackbars, and **all error messages**. Specifically check the failure paths, which are the ones that used to leak untranslated backend English: C2, C3, E2, F2, H2, H4, A4.

*Expect no:* English text, and no `{name}`/`{points}` placeholders showing literally.

---

## §M — Regression checks (things this PR touched or exposed)

**M1 — the collaboration-detail gamification block stays hidden.** Sign in as a business or community user, open any collaboration detail.
*Expect:* **no** "Challenges" section and **no** QR card. They are gated off deliberately — the challenge checkboxes there are not wired to anything. *(Guards `c55cab3`, finding 4 — one flag used to gate both this and the event loop.)*

**M2 — the event chat button.** Open an event hub and look at **Open event chat**.
*Expect:* it now renders as a **pill** (previously a 12dp-radius rectangle). This is an intentional consequence of removing a `shape:` override the button-style lint forbids. Confirm it does not look out of place next to the other buttons on that screen. ⚠️ *This is the one deliberate visual change to pre-existing UI in this PR.*

**M3 — My QR still works.** App-bar QR icon → **My QR code**.
*Expect:* unchanged behaviour, with a subtitle that now mentions pairing as well as check-in.

**M4 — attendee navigation unchanged.** Bottom nav still has exactly **Home · Communities · Chats**.
*Expect:* no new tab. Scanning lives in the app-bar QR hub by design.

**M5 — the orphan screens are still unreachable.** Badges, Reward Wallet, Spin Wheel, Stats, Leaderboard.
*Expect:* no navigation reaches them. That is **out of scope** here and tracked as NF-21 — not a bug in this PR.

---

## Sign-off

| Area | iOS | Android |
|---|---|---|
| §A organizer QR | ☐ | ☐ |
| §B check-in | ☐ | ☐ |
| §C check-in failures (esp. **C4**) | ☐ | ☐ |
| §D pairing | ☐ | ☐ |
| §E pairing edges | ☐ | ☐ |
| §F starting a challenge | ☐ | ☐ |
| §G verification + XP (esp. **G3**) | ☐ | ☐ |
| §H verification edges (esp. **H1**) | ☐ | ☐ |
| §I waiting / timeout | ☐ | ☐ |
| §J QR discrimination | ☐ | ☐ |
| §K session lifecycle | ☐ | ☐ |
| §L es / ca | ☐ | ☐ |
| §M regressions | ☐ | ☐ |

**Screenshots the PR still needs** (see its Screenshots section): QR hub sheet ·
scanner with the "At \<event\>" banner · check-in success sheet · organizer
check-in QR · paired + challenge list · verification QR waiting · the "+X XP"
reveal · verifier confirm sheet.

**If G3 shows the XP on the wrong account**, stop and report it — that is the
open `[VERIFY]` on this PR (does `ChallengeCompletionService::verify()` credit
the challenger in `point_ledger`?) and it is a backend fix, not an app one.
