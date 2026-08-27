# Camera challenges and the People Layer

> 2026-08-27 · Design approved by Volkan in five sections (spine, ghost contact,
> camera, quests, surfaces). Written in English to match its sibling specs; the
> conversation that produced it was in Turkish.
>
> **Goal, in Volkan's words:** make the challenge system *attract* users
> (acquisition) **and** bring attendees back between events (retention) —
> "kullanıcıyı yakalamak". Camera challenges are the hook.

---

## 1. Why

The challenge loop works end to end today (IF-27 #132, IF-30 #140/#141, #150,
#152, #154): check in, pick a challenge, scan a person, both confirm, **both**
earn XP. What it does not do is give anyone a reason to be there in the first
place, or to come back.

Five gaps, each verified against the tree rather than remembered:

| # | Gap | Evidence |
|---|-----|----------|
| 1 | **The room is invisible.** Everything is 1:1; no shared surface. | `eventLeaderboardProvider` (`leaderboard_provider.dart:21`) has **zero consumers** in `lib/`. `GET /events/{id}/leaderboard` is served and never drawn. |
| 2 | **Nothing remembers the meeting.** | `lib/features/friends/` exists; `lib/features/gamification/` never calls it outside the profile screen. `_Reveal` (`challenge_together_screen.dart:418`) ends on "+N XP each" and a Done button. |
| 3 | **The loop dies outside the event.** | `pendingChallengeProvider` polls only while an `ActiveEventSession` exists. |
| 4 | **No solo or async challenge exists.** | `grep trigger_action lib/` → 0 matches. Every challenge needs a second person physically present. |
| 5 | **Nothing is smart.** | `requires_new_person` is a rule the server enforces, but the app never tells you *who* you have not met. |

The diagnosis in one line: **the system is a receipt printer for two people
already standing next to each other.** It has no reason to exist before the
event, no memory after it, and no awareness of the room around it.

The 2026-08-23 social review named the same thing from the other side — "the app
is a ledger, not a game" — and left open question 3: *how much of the challenge
should the app actually run?* This spec answers it: **the camera**.

---

## 2. The spine — the People Layer

Today the system keeps a ledger of **actions** (`challenge_completions` +
`profiles.total_points`). We add a ledger of **people**.

### 2.1 Data model (backend, `kolabing-v2`)

```
encounters
  id
  profile_id             uuid   -- the viewer
  other_profile_id       uuid   NULL  -- null while the other side is a ghost
  ghost_name             text   NULL
  ghost_claim_token      text   NULL  UNIQUE
  community_id           uuid
  event_id               uuid         -- the event this row was created at
  first_met_at           timestamptz
  last_met_at            timestamptz
  times_met              int    DEFAULT 1
  photo_url              text   NULL  -- the co-selfie, when there is one
  claimed_at             timestamptz NULL

  UNIQUE (profile_id, other_profile_id, event_id)
```

Three decisions live inside that table:

**`times_met` counts distinct EVENTS, not challenges.** Ten challenges in one
night with the same person is still `times_met = 1`. The unique index enforces
it, so farming is closed by the schema rather than by a rule someone has to
remember. It also makes the number mean the right thing: *how many times were we
in the same room*.

**Pair level is derived from `times_met`, never stored.** The ladder and its
threshold bonuses are **backend-authored** (same place as NF-5's admin economy);
the app hardcodes no threshold and no bonus. **Levels never decay and there is no
streak** — a breakable streak turns showing up at a run club into an obligation,
which is the opposite of what this is for.

**An encounter is not a friendship.** A completed challenge does *not* auto-add a
friend. The encounter is a fact; friendship is a choice. The reveal screen offers
an optional "Add friend" that calls the already-built `POST /friends/{id}`. This
keeps the product model's §17 restraint (we do not impose a friend system) while
still feeding the graph.

### 2.2 Where it hooks in

`ChallengeCompletionService::verify` gains exactly one new responsibility, after
it settles points:

1. upsert the encounter row in both directions (one direction only for a ghost);
2. attach `photo_url` when the challenge produced one;
3. recompute the pair level and award the one-time threshold bonus if it crossed.

XP arithmetic stays in one place, on the server. The app never computes it.

---

## 3. Ghost contact — the acquisition engine

The most qualified prospect Kolabing will ever have is the person standing next
to an attendee at an event who does not have the app. Today they cannot
participate at all: `initiate` requires a `verifier_profile_id` and both parties
checked in.

### 3.1 Flow

```
A picks a challenge → "This person isn't on Kolabing"
  → A enters a name (phone / @handle optional)
  → server creates a ghost encounter + claim token
  → A shares an invite in one tap (share_plus → WhatsApp / SMS)
  → XP IS NOT PAID YET, but it is named on screen:
      "Ana gets 15 XP for both of you when she joins"
  → Ana installs, the deep link opens, she creates an attendee account
    and checks in to that community
  → the token claims the row → the reverse row is created
  → BOTH are paid retroactively + push to A: "Ana joined — 15 XP landed"
```

Paying A up front invites imaginary friends. Paying nothing means nobody
bothers. **A visible, named, pending reward** is the honest middle, and loss
aversion does the work.

### 3.2 Server-enforced protections

- claim window **30 days**;
- a claim pays **only for a genuinely new account** — an existing profile cannot
  harvest ghosts;
- **max 3 unclaimed ghosts per attendee per event**;
- unclaimed rows expire silently: no notification, no penalty, no shaming.

### 3.3 Hard prerequisite

There is **no deep-link package in the project today** — `app_links`,
`uni_links`, `firebase_dynamic_links` are all absent from `pubspec.yaml`. Nothing
in this section works until:

- `app_links` is added;
- iOS Universal Links (`apple-app-site-association`) is served and the
  Associated Domains entitlement is set;
- Android App Links (`assetlinks.json`) is served and the intent filter added;
- the backend resolves `/i/{token}`.

Also: **attendees have no referral code.** `referral_screen.dart` is routed only
at `/community/referrals` and `/business/referrals`, so the ability to invite is
switched off in exactly the person who would invite. Attendee referral is part
of this work.

---

## 4. Camera challenges — the hook

### 4.1 Three shapes

**Co-frame** — two people, one photo. The frame attaches to the encounter row,
so "you met Ana" acquires a face.

**Solo quest** — "find something yellow in the venue", "shoot the stage". No
second person. This is the biggest unlock in the spec: today the system is dead
until you have *spoken* to someone. A solo camera task works in the first ten
minutes, for the person who came alone, and for the person too shy to open with
a stranger. It closes gap #4.

**Proof** — do the thing, photograph the result.

**Video is deliberately out of MVP.** Storage, moderation and upload-failure
surface all triple; the photo carries ~90% of the value.

### 4.2 Where a photo lands — three layers

1. **The encounter** — the meeting has a picture (feeds retention).
2. **The event wall** — a shared wall filling up through the night.
   `POST /events/{event}/photos` (multipart `photos[]`) **already exists**
   (`event_service.dart:327`). This is also the answer to gap #1, and it is a
   *better* answer than the leaderboard: the social review warned that ranking
   strangers competitively "pushes the confident up and everyone else out".
   **A photo wall has no losers.**
3. **The night recap** — the night's frames as one shareable card. This is the
   acquisition artifact: a photo of four people at Sunset Run goes to Instagram;
   an XP stat card does not. `share_plus` is already a dependency.

### 4.3 Two things that are not optional

**`NSCameraUsageDescription` currently lies about what we do.**
`ios/Runner/Info.plist` says, verbatim:

> "Kolabing needs camera access to scan QR codes for event check-in."

Shipping photo capture behind that string is precisely the Guideline 5.1.1 class
of rejection this app has **already taken twice** (FX-43). The string is rewritten
in Phase 0.

**Moderation becomes mandatory.** Photos of people, on a wall strangers can see,
is App Review Guideline 1.2 territory. `ModerationService` (report / block,
self-gating on 404) already exists from IF-26. Every wall photo needs:

- report;
- block the uploader;
- **a blocked person's frames never render for you**;
- **either person in a co-frame can delete it** — that is what consent means here.

### 4.4 No new camera package

`image_picker: ^1.0.7` is already a dependency and `ImageSource.camera` opens the
camera. The `camera` package is **not** added: a custom in-app viewfinder,
countdown and BeReal-style simultaneous capture would grow the App Review
surface, the code and the device-specific bug count. **The hook is the photo
existing and landing somewhere, not the shutter chrome.** A custom camera is
polish for after we see real usage.

Camera permission is already granted (`mobile_scanner`), and Android already
declares `CAMERA` + `READ_MEDIA_IMAGES`. **No new permission prompt.**

### 4.5 Effect on the existing flow

```
pick challenge → scan → CAMERA OPENS → shoot → the other person sees the frame
                                              and confirms → both earn
```

The confirm step already existed. It now carries a second meaning: *should this
frame go on the wall?*

### 4.6 Privacy default

Default destination is the **event wall**. A co-frame does **not** reach the wall
until **both** people confirm. Solo frames go straight to the wall. **Nothing is
public**; sharing outward is the user's own act through `share_plus`. "Who you
have met" is visible **only to you** — seeing someone else's meetings would read
as surveillance.

---

## 5. Quests — the retention engine

`pendingChallengeProvider` only polls during an active event session, so outside
events the app has nothing to say. Quests are what it says.

### 5.1 Model (backend-authored, app hardcodes nothing)

```
quests
  id · scope (global|community) · community_id NULL
  goal_type · goal_value
  window (month|rolling_30d)
  reward_points · reward_badge_id NULL
  starts_at · ends_at · active
```

`goal_type`, all fed by data the People Layer now produces:

`new_people_met` · `events_attended` · `challenges_completed` ·
`photos_captured` · `return_to_community` · **`invites_claimed`** (this one
serves acquisition directly)

`GET /me/quests` returns active quests with **server-computed progress**. Never
computed client-side — FX-8 is the standing lesson about app-side numbers
disagreeing with what the server actually awards.

Badges need no new machinery: `GamificationBadge` already carries
`milestone_type` + `milestone_value`.

### 5.2 Push, and its two guardrails

The strongest return trigger the People Layer unlocks is *"someone you met is
going to X on Saturday"* — and it is also the most privacy-sensitive
notification in the design, because it tells you where another person will be.

**Guardrail 1 — aggregate by default.** Ship *"Sunset Run on Saturday — 3 people
you've met are going"*. Nearly as motivating, no consent problem. The named
variant fires only if that person has turned their own discoverability on.

**Guardrail 2 — a hard cap.** **At most 2 gamification pushes per user per
week**, enforced server-side, priority-ordered:

`ghost claimed` > `quest ending` > `people you've met are going` > `quest progress`

Uncapped, this design would comfortably produce eight notifications a week, and
then it is an uninstall reason rather than a hook.

### 5.3 Intersection with FX-51

The waiting screen polled `/me/challenge-completions` **1302 times in one
session**. The camera step *lengthens* that wait, so the problem gets worse
unless it is addressed: this work adds exponential backoff and a ceiling. The
correct long-term fix is pushing challenge state over the Reverb WebSocket once
Part A ops lands — **out of scope here**, but the shape fits exactly.

---

## 6. Surfaces

**Changed**

- `challenge_together_screen.dart` `_Reveal` — ends on the **person**, not the
  number: the frame, "You met Ana · 1st time", optional "Add friend", and the
  wall consent.
- `event_challenges_screen.dart` — solo vs co-frame, a `capture_type` badge.
- `attendee_profile_screen.dart` — a "People you've met" section (private).
- `attendee_home_screen.dart` — the active quest card: the reason the page exists
  when no event is on.

**New**

`CameraCaptureStep` (image_picker wrapper: compress, retry) · `EventWallScreen` ·
`EncountersScreen` · `NightRecapSheet` · `GhostInviteSheet` · `QuestsScreen`

---

## 7. Error handling

Half the design is here.

- **Upload fails (venue wifi is bad) — the critical one.** The frame goes to a
  local queue and **XP is paid before the photo uploads**: the challenge is done,
  the evidence follows. Retried in the background. Otherwise a bad connection
  costs someone the moment, and we must not punish a user for their signal.
- **Camera permission denied** — a clear message plus a route to Settings. The
  challenge stays cancellable; the user is never trapped.
- **Ghost unclaimed after 30 days** — expires silently. No notification, no
  penalty.
- **Friends API returns 404** (not yet deployed) — the existing self-gating
  holds; "Add friend" is hidden rather than broken.
- **Blocked user** — their frames never render on the wall.
- **Unknown challenge `capture_type`** — treated as `none`, i.e. the challenge
  still works without a camera. Never a dead end.

---

## 8. i18n

Every new string lands in all three ARBs (`app_en`, `app_es`, `app_ca`), Spanish
being Castilian. Counts use ICU placeholders (`{count}`), never interpolation.
No literal user-facing string in a `.dart` file.

---

## 9. Tests

- ten challenges with the same person in one night → `times_met == 1`;
- a ghost claim pays **only** a new account, and only inside the window;
- unclaimed-ghost cap of 3 per attendee per event;
- a blocked uploader's frames are filtered out of the wall;
- upload queue retries and does not block the XP award;
- push cap of 2/week holds under a burst of eligible triggers;
- unknown `capture_type` degrades to `none`.

---

## 10. Build order

| # | Piece | Why here | Size |
|---|---|---|---|
| 0 | `NSCameraUsageDescription` rewrite · `app_links` · Universal/App Links | Prerequisite for everything; App Review risk | S |
| 1 | `encounters` + wiring into `verify` + pair level | The spine; everything reads it | M |
| 2 | Camera step + upload queue + event wall + moderation | The hook itself | L |
| 3 | Reveal / People-you've-met / night recap + share | The acquisition artifact | M |
| 4 | Ghost contact + invite + claim + retroactive XP | Needs 0 and 1 | M |
| 5 | Quests + `GET /me/quests` + capped push | The retention engine | M |
| 6 | Attendee referral code | Independent | S |

## 11. Deliberately out of scope

Video · a custom camera UI (the `camera` package) · pair streaks · the
leaderboard as the primary frame · real-time challenge delivery over Reverb (the
natural sequel once Part A ops ships) · leaders authoring custom challenges
(the `POST /events/{event}/challenges` endpoint stays, it is just not the path).

---

## 12. Open items carried into the plan

None. The five decisions raised during design were settled:

| Decision | Settled as |
|---|---|
| Does repeat meeting pay, or only badge? | One-time XP bonus at each threshold **and** a badge |
| Is a phone number required for a ghost? | No — name only; number optional, purely to ease the invite |
| Is the "people you've met" list public? | No, private to the viewer |
| Named or aggregate "people are going" push? | **Aggregate**; named only on the subject's opt-in |
| Push ceiling | **2 per user per week**, server-side, priority-ordered |
