# Backend contract — the People Layer, camera challenges, ghost invites (#183)

> 2026-08-27 · For `kolabing-v2`. The Flutter side is built and merged against
> this contract and **self-gates on 404**, so nothing here is urgent and nothing
> ships broken while it is missing. Design:
> `docs/superpowers/specs/2026-08-27-camera-challenges-people-layer-design.md`.

Everything below is additive. No existing endpoint changes shape.

---

## 1. `encounters` — ✅ BUILT (kolabing-v2#244, PR kolabing-v2#245)

Shipped, and the shape changed from what this contract first proposed. The
as-built version:

```sql
CREATE TABLE encounters (
  id                uuid PRIMARY KEY,
  profile_id        uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  other_profile_id  uuid NULL REFERENCES profiles(id) ON DELETE SET NULL,
  ghost_name        text NULL,
  community_id      uuid NULL REFERENCES communities(id) ON DELETE SET NULL,
  event_id          uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  met_at            timestamptz NOT NULL,
  times_met         int NOT NULL DEFAULT 1,
  proof_photo_url   text NULL,
  claimed_at        timestamptz NULL,
  created_at        timestamptz NOT NULL,
  updated_at        timestamptz NOT NULL
);

CREATE UNIQUE INDEX encounters_unique_per_event
  ON encounters (profile_id, other_profile_id, event_id)
  WHERE other_profile_id IS NOT NULL;

CREATE INDEX encounters_by_viewer ON encounters (profile_id, met_at);
```

**What changed, and why.** The original proposal had one mutable row per pair
with `first_met_at` / `last_met_at` and an incrementing `times_met`. The built
version is **one row per pair per event, frozen**: a row says *at this event
these two met, and it was their Nth time*, and it keeps saying that. Nothing is
recounted or denormalised after the fact, so no value can drift. The current
count for a pair is the `times_met` of its most recent row.

The cost is a `DISTINCT ON` when `GET /me/encounters` lands. That is the right
trade: a read query is cheap to write once, and a denormalised counter that goes
wrong is expensive forever.

**The partial unique index is the anti-farming mechanism and must not be
dropped.** It makes *a meeting is an EVENT, not a challenge* a guarantee of the
schema rather than a rule in a service somebody has to remember: ten challenges
with the same person in one night is one meeting. Partial, because ghosts have
no `other_profile_id` and one attendee may hold several at a single event
(capped at three, §4).

`ghost_claim_token`, `ghost_contact` and `expires_at` are **not** in the built
table — they belong to §4, which is unbuilt, and adding them now would be three
columns nothing reads.

---

## 2. Wiring into settlement — ✅ BUILT

In `ChallengeCompletionService::verify`, **after the settlement transaction
commits**, inside a `try`/`catch`:

1. `EncounterService::recordChallengeMeeting()` writes both directions and
   carries `proof_photo_url` across (including from a later challenge that
   night, if the first produced no photo);
2. a crossed rung pays its one-time bonus to **both** participants;
3. the rung is hung on the model as `pairLevel` for the resource to emit.

**Outside the transaction, not inside it.** The original contract said "in the
same transaction", and that was wrong: in Postgres a failed statement poisons
the surrounding transaction, so an encounter bug would roll back the points two
people just earned. The points are the contract between two people standing in a
room; this ledger is bookkeeping that happens afterwards. `CommunityPointsService`
was already wired this way and this follows it. There is a test that throws from
the ledger and asserts the verification and the points both survive.

**The pair ladder is config** — `config/gamification.php` → `pair_ladder`, a list
of `{at, key, bonus}` ascending. No decay, no streaks.

`ChallengeCompletionResource` carries an additive `pair_level`:

```json
{ "times_met": 3, "key": "regulars", "next_at": 5,
  "just_levelled_up": true, "bonus_awarded": 10 }
```

`key` is a **slug, not a display string**: the app localizes it in three
languages, and the API has no business picking English.

---

## 3. Challenges: most of this already exists

**Do not build `capture_type`.** kolabing-v2#216 already shipped it under a
different name, and the app has been corrected to match:

| What exists | Where |
|---|---|
| `challenges.proof_type` — `text` \| `photo`, default `text` | `ChallengeProofType`, emitted by `ChallengeResource` |
| `challenge_completions.proof_photo_url` | `ChallengeCompletionResource` |
| `POST /challenge-completions/{id}/photo` (multipart, field `photo`) | either participant may attach |
| `DELETE /challenge-completions/{id}/photo` | either participant may remove |

`ChallengeProofType` is documented as an **engine selector, not a gate**: the
server does not refuse a verification that arrives with no photo. That is
exactly the behaviour §7 of the design asks for, so nothing needs changing.

What is left to build is one column:

```
challenges.participation  enum('pair','solo')  NOT NULL DEFAULT 'pair'
```

The app parses an unknown `proof_type` as `text`, so a challenge authored
against a newer backend still works on an older build — it just works without a
camera. Never a dead end. (Test:
`test/features/gamification/camera_challenge_test.dart`.)

`participation = 'solo'` is the important one. It lets a challenge be settled
without a partner, which is what makes the system usable in the first ten
minutes of an event, for someone who arrived alone, and for someone too shy to
open with a stranger.

**Solo challenges auto-verify.** Leader review does not scale and it kills the
instant reward. Abuse is handled by three cheaper things: solo challenges are
worth fewer points, they are capped per event, and the frame lands on the event
wall where nonsense is socially visible. Social visibility is the cheapest
moderation there is.

---

## 4. Ghost invites — ✅ BUILT (kolabing-v2#246, PR kolabing-v2#247)

Built as specified below, with three corrections worth recording:

1. **The invite URL is on the app host** — `https://app.kolabing.com/i/{code}`,
   from `config('webapp.url')`. The association files are served from
   `webapp.host` and only paths on that host are handed to an installed app, so
   a link on the marketing domain would open a browser on every phone. **The
   mobile entitlement and Android intent filter were registered against
   `kolabing.com` and have been corrected.**
2. **`/i/*` joined the existing `webapp.app_links.paths`.** Universal Links and
   App Links were already published for check-in QRs; this reuses that
   mechanism rather than starting a second one.
3. **The "new account" rule is `created_at` strictly before the invite**, not
   before-or-equal. Timestamps have second resolution, and *created in the same
   second as the invite* is honestly a new account.

Also built: `claim_self` as a sixth refusal, and `GET /i/{code}` rendering
claimed / expired / unknown as their own states rather than a 404.


### `POST /encounters/ghost`

```json
→ { "event_id": "...", "challenge_id": "...",
    "ghost_name": "Ana", "ghost_contact": "+34..." }   // contact optional

← { "data": { "encounter": {...}, "claim_code": "K7F2QX",
              "invite_url": "https://kolabing.com/i/<token>",
              "expires_at": "2026-09-26T18:00:00Z" } }
```

**No XP is paid here.** It is named on screen (`pending_points`) and paid to
both sides only on claim. Paying up front invites imaginary friends; paying
nothing means nobody bothers. A visible, named, pending reward is the honest
middle.

`ghost_name` is the only required detail. Asking a stranger for their phone
number at the moment you meet them is both bad manners and a larger
data-protection surface than this feature needs.

Refusals, as machine-readable `code`:

| code | when |
|---|---|
| `ghost_limit_reached` | this attendee already holds 3 unclaimed ghosts at this event |
| `not_checked_in` | the inviter is not checked in to the event |

### `POST /encounters/claim`

```json
→ { "claim_code": "K7F2QX" }
← { "data": { ...encounter, "claimed_at": "..." } }
```

On success: fill `other_profile_id`, create the reverse row, and **pay both
sides retroactively**.

| code | when |
|---|---|
| `invalid_claim_code` | no such token |
| `claim_expired` | past the 30-day window |
| `claim_requires_new_account` | the claimer is an existing profile |

Unclaimed rows expire **silently** at 30 days: no notification, no penalty, no
shaming.

### The deep-link half — and the thing a Universal Link cannot do

`GET https://kolabing.com/i/{token}` must be a **real web page**, not a redirect.

The app is registered for `applinks:kolabing.com` (iOS entitlement) and
`android:autoVerify` App Links, so on a phone that **has** the app the URL opens
the app directly. On a phone that does **not**, the token cannot survive the trip
through the App Store — Universal Links do not carry state across an install, and
Firebase Dynamic Links shut down in 2025. Since the entire point of a ghost
invite is a person without the app, the landing page must therefore show:

- who invited them and to what ("Ana wants to do a challenge with you at Sunset Run");
- the **claim code**, large and copyable — this is the path that survives;
- App Store and Play Store buttons.

The attendee onboarding then offers an "I have an invite code" field, which posts
to `/encounters/claim`.

Also required, and small: `.well-known/apple-app-site-association` and
`.well-known/assetlinks.json` served from `kolabing.com`.

---

## 5. Reads

### `GET /me/encounters?page&limit`

The people you have met, `last_met_at` descending.

**There is deliberately no endpoint for anyone else's encounters.** Seeing whom
someone else has met would read as surveillance. Keep it that way.

### `GET /events/{event}/recap`

```json
{ "data": { "event_id": "...", "event_name": "Sunset Run",
            "community_name": "Real Run Club",
            "people_met": 4, "new_people_met": 3, "points_earned": 60,
            "photo_urls": ["...", "..."] } }
```

This is the artifact people actually share, so it is a first-class endpoint
rather than something the app assembles from three lists.

---

## 6. Quests

```
quests: id · scope('global'|'community') · community_id NULL
        goal_type · goal_value · window('month'|'rolling_30d')
        reward_points · reward_badge_id NULL · starts_at · ends_at · active
```

`goal_type`: `new_people_met` · `events_attended` · `challenges_completed` ·
`photos_captured` · `return_to_community` · `invites_claimed`

### `GET /me/quests`

Returns active quests **with progress computed server-side**. Never let the app
compute it: FX-8 is the standing lesson about app-side numbers disagreeing with
what the server actually awards.

Badges need no new machinery — `badges.milestone_type` / `milestone_value`
already carry it.

### Push, and its two guardrails

The strongest return trigger the People Layer unlocks is *"someone you met is
going to X on Saturday"*. It is also the most privacy-sensitive notification in
the design, because it tells one person where another will be.

**Aggregate by default.** Send *"Sunset Run on Saturday — 3 people you've met
are going"*. Nearly as motivating, and no consent problem. The **named** variant
fires only when that person has turned their own discoverability on.

**Cap at 2 gamification pushes per user per week**, server-side, priority
ordered:

`ghost claimed` > `quest ending` > `people you've met are going` > `quest progress`

Uncapped, this design comfortably produces eight a week, at which point it is an
uninstall reason rather than a hook.

---

## 7. Also worth doing while in here

- **Attendee referral codes.** `referral_screen.dart` is routed only at
  `/community/referrals` and `/business/referrals`, so the ability to invite is
  switched off in exactly the person who would invite.
- **FX-51.** The pending-challenge poller ran 1302 times in one session. The
  camera step *lengthens* that wait, so it gets worse untouched. The app side
  adds backoff; the real fix is pushing challenge state over Reverb once Part A
  ops lands — out of scope, but the shape fits exactly.

---

## 8. Moderation

Photos of people on a wall strangers can see is App Review Guideline 1.2
territory. The client already has `ModerationService` (report / block) from
IF-26. The backend needs the wall to honour it:

- `GET /events/{event}/photos` must **exclude uploads from profiles the viewer
  has blocked**;
- **either person in a co-frame** may delete it — that is what consent means
  here, and it must not be owner-only.
