# The gamification model, read against the code

> 2026-08-23. Volkan's 20-point product model, mapped onto what is actually
> built. Every claim below is checked against the tree, not remembered.
>
> The model: **FOLLOW → ATTEND → BECOME MEMBER → STAY ACTIVE → PARTICIPATE →
> EARN XP → COME BACK**, with communities controlling which behaviour they
> encourage. Kolabing supplies the system and the library; communities decide
> how to use it.

---

## 1. Three things the model already describes correctly

**§20 Polling.** Already exactly this: `pendingChallengeProvider` polls every 4s
and only while an active event session exists. No work.

**§17 No friends system.** Nothing exposes connections, and
`challenge_completions` already records that A and B did something together —
which is precisely the "remember internally so we can use it for challenge
rules" the model asks for. `FriendshipService` exists and this flow does not
touch it. No work; the deliberate restraint is already in place.

**§5, the auto-verified half — partly there.** Challenges already come in two
shapes: `trigger_action` (a `MissionTrigger`, progressed by the system) and null
(peer-verified). `ChallengeService::listForEvent()` deliberately returns *system
challenges with a null trigger_action* plus the event's own — so trigger-driven
ones are excluded from event surfaces on purpose. "Attend 3 events this month"
is therefore already expressible; what is missing is surfacing it to the
attendee as a challenge rather than an invisible mission.

## 2. Five places the model contradicts what is merged

These are the ones worth deciding before more is built on top.

### 2.1 The flow is the other way round (§4)

The model: **choose challenge → scan person → they confirm**.
What ships: **scan person → choose challenge → they confirm** (#133, #141).

The model's reasoning is better — the intention is clear before you point a
camera at someone, and "I want to do *this* with you" is a different social act
from "let me scan you and see what's on offer". Backend is indifferent:
`initiate` takes `challenge_id`, `event_id` and `verifier_profile_id` together,
so this is a UI reordering, not a contract change.

Consequence: the challenge list has to be reachable **without** a peer, which
means it belongs on the event screen, and `PeerChallengeSheet` becomes a
confirmation step rather than a menu.

### 2.2 Member does not currently imply Follow (§12, §13)

Built as strictly independent — deliberately, and there is a test named
`membership and following are independent` locking it (kolabing-v2#211, merged).
The model says a member is always a follower and should never have to press
Follow separately.

That is a better model, and it makes §13 free: members see their communities'
events in Following without any extra rule. But it needs an explicit change:
`join()` creates a follow row, the test's assertion inverts, and the
follower/member docs are rewritten. Existing members need a backfill, or every
one of them is a "member who does not follow".

### 2.3 There is an XP cap, and the model says there should not be (§8)

`events.max_challenges_per_attendee` (default 10) is enforced in
`ChallengeCompletionService::initiate`. The model: no cap for MVP, watch real
behaviour first. Small change — but note the column already exists, so "no cap"
is best expressed as a null default rather than deleting the mechanism.

### 2.4 Repeating a challenge with the same person is impossible, not configurable (§6)

A hard unique index on `(challenge_id, event_id, challenger_profile_id,
verifier_profile_id)`. The model wants this to be a **community choice**: some
communities encourage meeting different people, others do not care.

So the constraint has to move out of the schema and into community
configuration, which is a migration plus a service-level check. Note this is
also the mechanism the model wants for §7 ("Meet someone new" requiring a
genuinely new person) — same data, opposite direction.

### 2.5 Event visibility has three levels, the model wants four (§15)

`EventVisibility` is `public | members | tier`. The model wants
**public / followers / members / active members**.

`followers` and `active_members` are both new, and `active_members` cannot exist
until §11's definition does. Worth doing carefully: `EventSignupService` already
has a known gap where visibility is not checked for community events
(BACKLOG IF-28) — adding levels to a gate that is not fully enforced would
create the appearance of control without it.

## 3. What is not built at all

### 3.1 The challenge library, and community-level enablement (§2, §3)

The biggest gap, and the spine of the model. Today a challenge is either
`is_system` (global) or `event_id`-scoped (one event). There is **no community
layer**: no library to choose from, no per-community enabled set, no way for a
run club to say "we want people meeting each other" while another community says
"we only care about attendance".

Shape this needs:

```
challenge library (Kolabing-authored, is_system)
        ↓  community enables a subset
community_challenges (community_id, challenge_id, + options)
        ↓  available at that community's events
event override (optional, later)
```

The per-community options are where §6, §7 and §9 live: repeat allowed, new
person required, and any restrictiveness a community wants. That keeps
anti-abuse a community setting rather than a platform rule, which is what §9
asks for.

Deliberately **not** in MVP: leaders authoring custom challenges. The
`POST /events/{event}/challenges` endpoint that does this already exists and can
stay; it just is not the primary path.

### 3.2 The member lifecycle (§10, §11, §14, §16)

None of this exists:

- **§10** the post-check-in prompt ("you came — want to become a member?").
  This is the moment the whole funnel turns on and there is currently nothing
  there.
- **§11** membership requiring **at least one attendance**. Today anyone can
  join an open community without ever turning up. This is a real change to the
  join flow — see the open question below.
- **§14** Active Member: attended within 90 days, decays silently, comes back on
  the next check-in. `community_members` has `joined_at` and `status` but no
  notion of recent attendance; the data to compute it exists in
  `event_checkins`.
- **§16** three counts for leaders (Followers / Members / Active Members), two
  in public (Followers / Active Members).

On §16 there is a trap with evidence behind it: adding counts to
`CommunityResource` took `/me/rewards-overview` from 12 to 21 queries and broke
`MeRewardsOverviewNPlusOneTest`. These counts belong on the specific endpoints
that need them, via `withCount`, never on the shared resource.

### 3.3 The challenge request lifecycle (§18, §19)

- **§18** pending requests never expire and A cannot cancel. The model wants
  expiry at the end of the event / check-in session, and a cancel.
- **§19** one-at-a-time is already how it behaves (the poller returns the oldest
  pending where you are the verifier), but there is no explicit queue and no
  "duplicate pending for the same challenge + pair" rule — because today a
  *duplicate of any kind* is impossible (§2.4). Once repeats become allowed, the
  duplicate-pending rule becomes necessary rather than redundant.

## 4. The open question worth answering before building

**§11 says a Member must have attended at least one event. §10 says the prompt
comes after check-in. Together they mean: you cannot become a member of a
community you have never attended.**

That is coherent and it is a real product position — membership means something
because you showed up. But it removes something that exists today: the
"Become a member" button on a community profile (#139, open), which works for
anyone. Under the new model that button has to either disappear until you have
attended, or become "Follow, and we will ask when you come".

I would ask before implementing it, because it changes what a community profile
can offer a stranger, and #139 is open right now with that button in it.

## 5. Build order

Sequenced by what unblocks what, not by size.

| # | Piece | Why here | Size |
|---|---|---|---|
| 1 | **Member implies Follow** (§12, §13) + backfill | Cheapest correction of a merged decision; every later count depends on it | S |
| 2 | **Active Member** (§11, §14) + the three counts (§16) | §15's `active_members` and the whole funnel need the definition to exist | M |
| 3 | **Post-check-in membership prompt** (§10) | The moment the funnel turns on; needs 1 and 2 | S |
| 4 | **Challenge library + community enablement** (§2, §3, §6, §7, §9) | The spine. Everything about "communities control the behaviour" is here | L |
| 5 | **Flow reversal** (§4) | Depends on 4: choosing a challenge first only works once a community has a set | M |
| 6 | **Request lifecycle** (§18, §19) | Follows the reversal, and the duplicate rule needs 4's repeat option | M |
| 7 | **Four visibility levels** (§15) | Needs 2, and needs IF-28's signup gate closed first or it is decoration | M |
| 8 | **Drop the XP cap** (§8) | Independent, do it whenever | XS |
| 9 | **Surface auto-verified challenges** (§5) | Independent of the rest; the machinery exists | M |

Items 1–3 are one coherent piece of work and should probably be one ticket.
Item 4 is the one that deserves its own design pass.
