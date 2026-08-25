# Gamification test docs — the whole loop, across every open PR

> **2026-08-23.** One document to test what the five open app PRs and four open
> backend PRs actually do, in the order a real person would hit them.
> Target: the **development** API
> (`https://kolabing-v2-development-uhzrzd.laravel.cloud`).
>
> Narrower documents already exist and are still correct — this one is the
> spine that connects them:
> - [`2026-08-22-event-challenge-qr-test-plan.md`](2026-08-22-event-challenge-qr-test-plan.md) — the QR loop in fine detail
> - [`2026-08-22-dev-qa-runbook.md`](2026-08-22-dev-qa-runbook.md) — pointing a build at dev, seeding, signing in

---

## 1. What is under test

| PR | What it added | Flow below |
|---|---|---|
| app **#133** | The event-challenge QR loop: organizer QR → check-in → peer scan → challenges → XP | 3, 4 |
| app **#137** | QA surfaces opened: community-member screens, attendee sign-up, feature flags | 2 |
| app **#139** | **Follow** replaced Join; **Become a member** asks the leader's questions | 5 |
| app **#141** | One scan, not three; both sides paid; one shared screen | 4 |
| app **#143** | **All events / Following** on the attendee feed | 6 |
| be **#208** | `kolabing:seed-qa-gamification` — one command for all the fixtures | 2 |
| be **#210** | Attendee tickets + the attendee web panel | — (out of scope here) |
| be **#213** | A completed challenge credits **both** participants | 4 |
| be **#214** | `?following=1` on discover, and the member-event listing leak closed | 6, 7 |

**Deploy order matters in exactly one place.** #143 sends `following=1`; against an
API without #214 that is a **422**, which the app shows as the feed's error card.
So be#214 goes out before the app build is handed to anyone. Everything else is
additive in either direction.

---

## 2. Setup

### 2.1 Seed the fixtures

On the deployed dev environment:

```bash
php artisan kolabing:seed-qa-gamification
# re-running is safe; add --fresh to delete the previously seeded event/kolab first
```

It refuses to run against the `main` database without `--force`. **`main` is
production** — if it ever asks you to confirm that target, say no.

What it creates:

| Thing | Detail |
|---|---|
| Community | `[QA] Eixample Runners`, **open** join policy, one default tier, chat thread |
| Leader | `qa-leader@kolabing.test` |
| Attendee A | `qa-attendee-a@kolabing.test` — the one who scans |
| Attendee B | `qa-attendee-b@kolabing.test` — the one who confirms |
| Business | `hello@eixample46.com` — **pre-existing**, not invented by the seeder |
| Collaboration | active, between the business and the community |
| Event | `[QA] Gamification Test Run` — **today, 18:00**, public, in Barcelona |
| Challenges | 3: selfie (**5 pts**), introduce each other (**15**), finish the route (**30**) |

**Password for every seeded account: `Kolabing2026!`**

Both attendees are already `going` to the event and active **members** of the
community. The event deliberately has **no check-in token** — minting one is the
first thing you test.

### 2.1a State on dev right now (verified 2026-08-23)

Deployed from `integration/all-open-prs`; all 170 migrations ran, nothing pending.
Checked against the live API, not assumed:

| Check | Result |
|---|---|
| `POST /auth/login` as attendee A | 200 — seeded accounts exist |
| Event date | **today**, 18:00, public, Barcelona |
| `checkin_token` | **null** — step 1 of flow 3 is genuinely untested |
| `GET /events/discover?following=1` | **200** — be#214 is live (it would be 422 without it) |
| `?following=1&date=today` | composes, returns the seeded event |
| `?following=0` with no city | **422 on lat/lng** — the strip guard works |
| `GET /me/tickets` | 200 — be#210 is live |

**Attendee A has been pre-followed** to `[QA] Eixample Runners`, so their Following
tab has content immediately. **Attendee B is deliberately left following nobody**,
so the empty state in flow 6 is still testable. Use B for step 2 and A for step 3.

> **The seeded attendees are already members of the QA community, so it does NOT
> appear in Explore → discover communities for them** — discover hides what you
> have already joined. To reach it, open the event and tap the host community, or
> use a fresh attendee account.

### 2.2 Get the app onto something with a camera

```bash
make ipa-dev      # release IPA against dev, for TestFlight / a device
make run-dev      # or run straight onto an attached device / simulator
```

Both bake `APP_ENV=dev` in. A bare Xcode Archive does **not** — it silently
falls back to prod, so never produce a dev build that way.

> **Two real phones are required for flows 3–4.** The whole point of the loop is
> two people scanning each other, and the simulator has no camera. One phone can
> get you through flows 5–7.

---

## 3. Flow — check-in (app #133)

| # | Who | Do | Expect |
|---|---|---|---|
| 1 | Leader | Sign in → the community → the `[QA]` event → **Show check-in QR** | A QR plus a short code. The code is short on purpose — it keeps the QR at version 3 so a phone camera reads it across a room |
| 2 | Leader | Leave the screen and come back | The **same** code. It rotates only when you ask it to |
| 3 | A | Scanner → scan the leader's QR | "Checked in" and the event becomes the active session |
| 4 | A | Scan it a second time | Handled, not an error card — a double scan is a person being unsure, not a fault |
| 5 | B | Same scan | Checked in too |
| 6 | Either | Kill the app, reopen it | Still checked in. The session is stored with a **12-hour** TTL from the device clock |

**Also worth one look:** the QR the leader shows is the backend's canonical
`/checkin/{code}` link, so a code printed from the web panel scans in the app and
vice versa. If a printed code says "not a Kolabing code", that is a real bug.

---

## 4. Flow — one scan, one shared screen, both paid (app #141 + be #213)

This is the flow that changed most. **There is no verification QR any more.**

| # | Who | Do | Expect |
|---|---|---|---|
| 1 | A | Scanner → scan **B's profile QR** (Profile → your QR) | The peer sheet: "Paired with B" + this event's three challenges |
| 2 | A | Tap **Introduce each other to someone new** | A's screen shows the challenge, **"15 XP each"**, and "waiting for B" |
| 3 | **B** | **Touch nothing.** Wait, with the app open | Within a few seconds B's phone opens **the same screen** — same challenge, same "15 XP each" — with **VERIFY** / **REJECT** |
| 4 | B | **VERIFY** | Both screens land on the same reveal: "you and A both earned it" |
| 5 | Both | Profile / points | **Both** totals went up by 15. Both challenge counts went up by 1 |
| 6 | A | Try the same challenge with B again | Refused — a pair cannot repeat one challenge at one event |

That is **one** scan between two people, where it used to be three.

**The negative checks that matter:**

- B taps **REJECT** instead → "Not confirmed" on both phones, nobody paid.
- B dismisses the screen with the ✕ → it does **not** pop straight back on the
  next poll. It should come back only if B kills and reopens the app.
- Leave the event (or wait out the 12-hour session) → B's phone stops polling
  and a new challenge no longer appears unprompted.
- Only **one** of you is checked in → initiating is refused with "both must check
  in", not a generic error.

> **How B's phone knows:** a 4-second poll, running only while an active event
> session exists. Both people are in the same room with the app open, so it is
> invisible — but if B **fully backgrounds** the app, they see it when they next
> open it. That is expected, not a bug.

---

## 5. Flow — Follow vs Become a member (app #139)

The seeded attendees are already members, which hides half of this. Use a
**third**, fresh attendee account — sign up in the app (attendee sign-up is on in
#137).

| # | Do | Expect |
|---|---|---|
| 1 | Explore communities → find `[QA] Eixample Runners` | The button says **Follow**, never "Join" |
| 2 | Tap **Follow** | Instant (optimistic). Turn airplane mode on and tap: it rolls back rather than lying |
| 3 | Open the community profile | **Two** buttons for a non-member: Following/Follow, and **Become a member** |
| 4 | Tap **Become a member** | The community asks nothing, so you are a member immediately — **no form at all** |
| 5 | Check the community's Members list | You are in it. Followers are **not** in it |

### 5.1 The questions path

There is **no leader UI for questions yet** — create them over the API. Sign in
as the leader, take the token, and:

```bash
BASE=https://kolabing-v2-development-uhzrzd.laravel.cloud/api/v1
curl -s -X POST "$BASE/communities/$COMMUNITY_ID/join-questions" \
  -H "Authorization: Bearer $LEADER_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"prompt":"Why do you want to join?","required":true}'
```

Then, with a fourth attendee account:

| # | Do | Expect |
|---|---|---|
| 1 | **Become a member** | Now a **form** appears with that question |
| 2 | Submit it empty | Blocked client-side with the required-field message |
| 3 | Answer and submit | The community is `open`, so you are admitted straight away |
| 4 | As the leader, reword the question, then look at the old answer | The answer still shows the prompt **as it was asked**. Rewording a live question must not rewrite history |

**Follow and membership are independent.** A member is not automatically a
follower, and unfollowing does not remove membership. That is the point of the
split — and it is also the trap in flow 6.

---

## 6. Flow — the Following feed (app #143 + be #214)

| # | Do | Expect |
|---|---|---|
| 1 | Attendee home | The events section has **All events \| Following** |
| 2 | With a fresh account that follows nobody, tap **Following** | "You don't follow anyone yet" + **Explore communities**. Not an error, not a blank list |
| 3 | As attendee **A** (already following), tap **Following** | The `[QA]` event is listed with its host community, and **the city chip is gone**. To do the follow yourself: the QA community is not in Explore for a member — open the event and tap the host community |
| 4 | Switch to **All events**, set the city to **Madrid**, switch back to **Following** | The Barcelona event is **still there**. This is the whole point: a community you followed is relevant wherever it is |
| 5 | Switch back to **All events** | The city chip is back, still saying Madrid, and the feed is city-scoped again — you are not asked to pick a city twice |
| 6 | In **Following**, set the date chip to **Today** | Still Following, now narrowed to today (the seeded event is today, so it stays) |
| 7 | Unfollow everything, return to **Following** | Back to the no-follows empty state |

> **The trap.** A seeded attendee is a **member** of the community but not a
> **follower** — so their Following tab is legitimately **empty**. If it looks
> broken, check whether that account has actually pressed Follow. This is the
> single most likely false bug report in this document.

---

## 7. Security check — a follower is not a member (be #214)

Worth doing deliberately, because it is the property the whole follower/member
split exists to protect, and it was **broken** until #214.

1. As the leader, create a second event on the `[QA]` community with visibility
   **Members only**.
2. As an attendee who **follows but is not a member**, open **Following**.
3. **The member-only event must not appear.** Neither must it appear in
   `GET /events?following=me`:

```bash
curl -s "$BASE/events?following=me&time=upcoming" \
  -H "Authorization: Bearer $FOLLOWER_TOKEN" | jq '.data.events[].name'
```

Before #214 that call returned member-only events with their ids. If you see one,
stop and report it — that is a privilege leak, not a display bug.

**Known and still open:** `EventSignupService` does not check visibility, so a
follower who somehow *has* a member-event id can still sign up to it. Discover no
longer hands out those ids, but the signup hole is real (BACKLOG IF-28) and is
not fixed by these PRs.

---

## 8. Things that look like bugs and are not

| You see | Why |
|---|---|
| A seeded attendee's **Following** tab is empty | They are a *member*, not a *follower*. Press Follow (§6) |
| B's phone takes a few seconds to show the challenge | 4-second poll, by design |
| B backgrounded the app and got nothing | The poll only runs with the app open |
| No date/type/city chips in **Following** | Deliberate: place and category answer nothing about a relationship you chose |
| "Become a member" shows **no form** | The community asks no questions. The form appears only when a leader has added some (§5.1) |
| The dev build's share/QR links point at `…laravel.cloud` | Correct for a dev build — `shareHost` follows `APP_ENV` |
| Launch image is the default placeholder (build warning) | Pre-existing, cosmetic, unrelated to these PRs |

---

## 9. Result sheet

Copy this into the PR you are signing off.

```
Build:    APP_ENV=dev · version ____ (____) · branch ____________
Devices:  iOS ____________  Android ____________
API:      development, seeded ____-__-__

[ ] 3  check-in: mint, scan, double-scan, survives restart
[ ] 4  one scan → shared screen on both phones → BOTH paid          (#141, be#213)
[ ] 4  reject / dismiss / not-checked-in negatives
[ ] 5  Follow (not Join) · Become a member with no questions
[ ] 5.1 questions path + prompt snapshot                            (#139)
[ ] 6  Following: empty state, cross-city, scope round-trip, date   (#143, be#214)
[ ] 7  member-only event hidden from a follower (API + UI)          (be#214)

Screenshots attached:  [ ] #133  [ ] #137  [ ] #139  [ ] #141  [ ] #143
Two-phone recording for #141:  [ ]
```

Screenshots are outstanding on **all five** app PRs, and #141 specifically wants
a **two-phone recording** — what makes it worth reviewing is what the two devices
do at the same moment, which a still cannot show.
