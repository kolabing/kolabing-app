# Gamification test docs

> **Rewritten 2026-08-23**, after the nine-item product-model series (#146–#158)
> and the code-review fixes. Everything below is checked against the deployed
> **development** API, not against the code.
>
> The model this tests:
> **FOLLOW → ATTEND → BECOME MEMBER → STAY ACTIVE → PARTICIPATE → EARN XP → COME BACK**
>
> Narrower documents that are still correct:
> [`2026-08-22-event-challenge-qr-test-plan.md`](2026-08-22-event-challenge-qr-test-plan.md) ·
> [`2026-08-22-dev-qa-runbook.md`](2026-08-22-dev-qa-runbook.md)

---

## 0. What changed since the last version of this document

If you tested from the previous version, **four things now work differently**:

| Then | Now |
|---|---|
| Scan a person → pick a challenge | **Pick a challenge → scan the person** (#152) |
| Check-in only via the organizer's QR | **"I'm here"** works with no organizer (#144) |
| A pending request lived forever | It can be **cancelled**, and it **runs out** (#154) |
| Members and followers were independent | **Every member is a follower** (#146) |

And the old trap in this document — *"the seeded attendees are members but not
followers, so Following is empty"* — **is gone.** #146's backfill gave every
existing member a follow row. Verified on dev: attendee A has 5 follows, B has 1.
The Following tab is now populated for both, which means **testing the empty
state needs a brand-new account.**

---

## 1. Setup

### 1.1 Seed

```bash
php artisan kolabing:seed-qa-gamification      # accounts, community, event, 3 challenges
php artisan db:seed --class=PeerChallengeLibrarySeeder   # the challenge library
```

The second one is new and matters: **#150 built the library and left it empty.**
Verified on dev before adding it — `challenges where is_system and trigger_action
is null`, the query that *is* the library, returned **0 rows**, because all 49
seeded system challenges are trigger-driven missions. A leader opening the
curation screen was told there was nothing to choose from. The seeder adds 8
peer-playable ones, deliberately about meeting people rather than about the app.

### 1.2 Accounts — password `Kolabing2026!` for all

| Role | Email | State on dev |
|---|---|---|
| Leader | `qa-leader@kolabing.test` | owns `[QA] Eixample Runners` |
| Attendee A | `qa-attendee-a@kolabing.test` | member + follower, 5 follows |
| Attendee B | `qa-attendee-b@kolabing.test` | member + follower, 1 follow |
| Business | `hello@eixample46.com` | pre-existing, your password |
| **A fresh one** | sign up in the app | **needed** — see §1.3 |

### 1.3 You need a fresh account, and here is why

Three things can only be tested by someone who is not already a member:

1. the **Following empty state** (A and B both follow things now);
2. **Follow** as a first action, and **Become a member** as a separate one;
3. the **post-check-in membership prompt** — an existing member is never asked.

Attendee sign-up is reachable in the app (`kAttendeeSignupEnabled`). Note that
flag carries a **RELEASE CHECK** comment: it is on for this QA, not because the
track is launch-ready.

### 1.4 Build

```bash
make ipa-dev      # release IPA against dev
make run-dev      # or straight onto a device / simulator
```

- **iOS 17.5 simulators crash this app** (`objective_c.framework` FFI). Use a
  26.2 runtime — iPhone 17 Pro, Air, 16e.
- **Flows 3 and 4 need two real phones.** The simulator has no camera, and the
  loop is two-person. Everything else works on one device.

---

## 2. Flow — check in

Two doors now. Test both; they are meant to be identical once you are through.

| # | Who | Do | Expect |
|---|---|---|---|
| 1 | Leader | Community hub → the event → **Show check-in QR** (a **button** now, not hidden in ⋮) | QR + short code |
| 2 | Leader | Tap the refresh icon | A **new** code — and if it fails, a message. It used to fail silently |
| 3 | A | Event screen → **I'm here** | "You're in." **No organizer needed** (#144) |
| 4 | A | The button becomes **Choose a challenge** | Not "Scan someone" — the flow reversed (#152) |
| 5 | B | Scan the leader's QR instead | Same result through the other door |
| 6 | Either | Kill and reopen the app | Still checked in (12-hour session) |

**Also check:** **I'm here** is refused for an event that is not today, and for
one you have not said you are going to.

---

## 3. Flow — the membership prompt (#148)

**Use the fresh account.** RSVP to today's `[QA]` event, then check in.

| # | Do | Expect |
|---|---|---|
| 1 | Check in (either door) | A sheet: *"You're at [QA] Eixample Runners"* + **Become a member** / **Not now** |
| 2 | **Not now** | Check in again, or reopen the event → **it does not ask again** |
| 3 | New account #2, check in, **Become a member** | The membership flow runs — including the leader's questions if any exist |
| 4 | As that member, open the community profile | **One** button. No separate Follow — membership implies it (#146) |
| 5 | `GET /me/community-follows` or the Following tab | The community is there, without anyone pressing Follow |

**Fixed since the review:** tapping **Become a member** and then dismissing the
form used to leave nothing recorded, so the next check-in asked again. It is
remembered either way now.

---

## 4. Flow — a challenge, together (two phones)

**The order changed.** Choose first, then scan.

| # | Who | Do | Expect |
|---|---|---|---|
| 1 | A | **Choose a challenge** → the event's list | The community's set (see §5), plus anything the leader wrote for this event |
| 2 | A | Tap one → the sheet shows **what to do**, not just its name | Then **Scan the person you're doing it with** |
| 3 | A | Scan **B's** profile QR | It starts **immediately**. No second picker |
| 4 | A | | The shared screen: the challenge, its instruction, **"15 XP each"**, "waiting for B" |
| 5 | **B** | **Touch nothing** | Within a few seconds B's phone opens **the same screen** with VERIFY / REJECT |
| 6 | B | **VERIFY** | Both land on the same reveal |
| 7 | Both | Profile | **Both** totals went up. Both challenge counts went up |

### 4.1 The negatives — these are where the bugs were

| Do | Expect |
|---|---|
| B taps **REJECT** | "Not confirmed" on both. Nobody paid |
| A taps **Cancel this request** while waiting | Request withdrawn, screen closes, **B stops seeing it** (#154) |
| A asks the same challenge again after cancelling | **It works.** Cancelling is not a permanent block |
| Ask B the same challenge twice without confirming | *"You've already asked them to confirm this one."* — its own sentence |
| Ask a challenge you two already completed | *"You two have already done this one."* — a **different** sentence |
| Only one of you is checked in | *"You both have to be checked in"* — **inside the sheet**, in red |
| Wait more than two minutes with no answer | **"Still waiting on B"** + **Keep waiting**. It used to be a spinner forever (review fix) |

> **The one that used to look like nothing happening:** a refused challenge put
> its message in a snackbar, which the full-height sheet covered completely. The
> row span, stopped, and nothing else. If you ever see a tap do nothing, that is
> a bug — every refusal now has a visible place to appear.

---

## 5. Flow — the community's challenge library (#150, one device)

| # | Do | Expect |
|---|---|---|
| 1 | Leader → community hub → **Challenges** (above Events) | The library as a checklist. Banner: *"Nothing chosen, so your events play every Kolabing challenge."* |
| 2 | Tick one → two switches appear under it | *Let the same two people repeat it* · *Only with someone they haven't played with* |
| 3 | Save, reopen | Banner: *"Your events play only what's ticked here."* |
| 4 | As A, open that event's challenge list | **Only the ticked one**, plus the leader's own event challenges |
| 5 | Untick everything, save | Back to the default — the whole library. **This is the only way back** |

### 5.1 The two options, with two attendees

| Setting | Do | Expect |
|---|---|---|
| Repeat **off** (default) | A and B complete it, then try again | Refused — *"already done this one"* |
| Repeat **on** | Same again | **Works** |
| Repeat on, ask twice unconfirmed | | Still refused — *"already asked them"*. Two live requests is never a community's choice |
| **Only with someone new** on | Try with a pair who have completed anything together, **either direction** | Refused — *"for someone you haven't played with yet"* |

---

## 6. Flow — the Following feed (#143, #157)

| # | Do | Expect |
|---|---|---|
| 1 | Attendee home | **All events \| Following** |
| 2 | **Fresh account**, no follows → Following | *"You don't follow anyone yet"* + Explore communities |
| 3 | Follow a community, return | Its events appear, and **the city chip is gone** |
| 4 | All events → set the city to **Madrid** → back to Following | The Barcelona event is **still there**. That is the whole point |
| 5 | Back to All events | City chip is back, still Madrid. You are not asked to pick twice |
| 6 | Following → date chip **Today** | Still Following, narrowed |
| 7 | **Never picked a city**, toggle Following on then off | The **"pick a city"** prompt — not an error feed (review fix) |

**Discovery:** an invite-only community is now **followable** from Explore.
Following needs no approval; `join_policy` governs membership. And a community
you already follow shows **Following**, not an enabled Follow button that does
nothing.

---

## 7. Flow — who can attend (#157)

The four audiences, narrowest last. Leader creates one event per level.

| Event visibility | Fresh account | Follower | Member (quiet 200 days) | Member (attended recently) | Leader |
|---|---|---|---|---|---|
| **Public** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Followers** | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Members** | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Active members** | ❌ | ❌ | ❌ | ✅ | ✅ |

**A lapsed member is still a Member.** They only stop counting as *Active*, and
their next check-in makes them Active again with nobody doing anything.

**Also check:** the list view's lock state agrees with what happens when you try
to join. They used to be computed in three separate places.

`followers` events appear in the **Following** feed and **not** in the city feed.

---

## 8. Flow — the numbers, and solo challenges

| # | Do | Expect |
|---|---|---|
| 1 | Leader → community stats | **Followers, Members, Active Members** — all three |
| 2 | Open the community as an attendee | **Followers + Active Members only.** Total membership is deliberately hidden — it only ever grows, so it flatters rather than describes |
| 3 | Attendee profile → **Challenges you do on your own** (#158) | Missions with progress, and a line saying Kolabing tracks these from check-ins and nobody confirms them |
| 4 | Do more than 10 challenges at one event (#156) | **No cap.** It used to stop at 10, from a default nobody chose |

---

## 9. ⚠️ Looks like a bug, isn't

| You see | Why |
|---|---|
| The QA attendees' Following tab is **not** empty | Correct now — #146 gave every member a follow. Use a fresh account for the empty state |
| The `[QA]` community is missing from Explore for A/B | Explore hides what you have already joined. Reach it from the event's host community link |
| B's phone takes 3–5 seconds | 4-second poll, by design |
| B backgrounded the app and got nothing | The poll only runs with the app open. They see it on reopening |
| No date/type/city chips in Following | Deliberate — place and category answer nothing about a relationship you chose |
| **Become a member** shows no form | That community asks no questions. The form appears only when a leader added some |
| A challenge shows no photo step | `proof_type` is per challenge. Only some open the camera |
| An old member has no `last_attended_at` | Backfilled from real check-ins. Someone who never attended has none, and is not Active |
| Share/QR links point at `laravel.cloud` | Correct for a dev build |
| Launch image placeholder warning | Pre-existing, cosmetic |

---

## 10. Known and open

- **Screenshots and device QA are the only thing standing between this series and
  merge.** Every PR carries an unticked box for them.
- **#141 wants a two-phone recording**, not stills — what makes it worth
  reviewing is what the two devices do at the same moment.
- `kAttendeeSignupEnabled` / `kCommunityMembersTabEnabled` are **on for this QA**
  and carry a RELEASE CHECK comment. Decide both before `make ipa-prod`.
- BACKLOG **IF-28** claims `EventSignupService` never checks visibility for
  community events. **That is stale** — `assertEligible` has always required
  membership for anything non-public. The BACKLOG needs the correction, not the
  code.
- No leader UI for **join questions** yet; create them over the API:
  ```bash
  curl -X POST "$BASE/communities/$ID/join-questions" \
    -H "Authorization: Bearer $LEADER_TOKEN" -H 'Content-Type: application/json' \
    -d '{"prompt":"Why do you want to join?","required":true}'
  ```

---

## 11. Result sheet

```
Build:    APP_ENV=dev · version ____ (____) · integration/all-open-prs
Devices:  iOS ____________  Android ____________
API:      development, seeded ____-__-__   library seeded: [ ]

[ ] 2   check-in: both doors, rotate, survives restart
[ ] 3   membership prompt: asked once, never as a member          (#148)
[ ] 4   choose → scan → both paid                                 (#152, #141)
[ ] 4.1 cancel · re-ask · the three distinct refusals · 2-min timeout
[ ] 5   curation: banner, only-what's-ticked, empty = default     (#150)
[ ] 5.1 repeat off/on · duplicate pending · someone new           (#150)
[ ] 6   Following: empty state, cross-city, round-trip, no-city   (#143, #157)
[ ] 7   the four audiences, and list/gate agreement               (#157)
[ ] 8   three counts vs two · solo challenges · no cap            (#156-#158)

Screenshots: [ ]#133 [ ]#137 [ ]#139 [ ]#141 [ ]#143 [ ]#145 [ ]#149 [ ]#151 [ ]#153 [ ]#155
Two-phone recording (#141): [ ]
```
