# The challenge library, and communities choosing from it

> Design for §2, §3, §6, §7, §9 of the product model. Ticket: kolabing-app#150.
> Everything below is checked against the tree.
>
> The line the model draws: **Kolabing supplies the gamification system and the
> challenge library; communities decide how they want to use it.**

---

## 1. What exists today

| Fact | Where |
|---|---|
| A challenge is either **global** (`is_system = true`) or **one event's** (`event_id` set) | `challenges` table |
| An event's list = system challenges with a **null `trigger_action`**, plus that event's own | `ChallengeService::listForEvent()` |
| `trigger_action` challenges are missions, progressed by the system, and deliberately excluded from event surfaces | same |
| A pair can **never** repeat a challenge | `challenge_completions_unique` on `(challenge_id, event_id, challenger_profile_id, verifier_profile_id)` |
| A leader can author a challenge for one event | `POST /events/{event}/challenges` |

**There is no community layer at all.** Every community's events show the same
global list, so a run club that wants people meeting each other and a community
that only cares about attendance get identical challenges.

## 2. The shape

```
challenges where is_system AND trigger_action IS NULL     ← THE LIBRARY
                         │
                         │  a community enables a subset, with options
                         ▼
              community_challenges                        ← THE CHOICE
                         │
                         ▼
        available at that community's events              ← THE PLAY
                         +
        challenges with event_id = this event             (already works)
```

### 2.1 The library is not a new table

The library **is** `challenges where is_system = true and trigger_action is
null` — the exact set `listForEvent()` already returns. A second table would
duplicate a shape that already has name, description, difficulty, points,
audience and `proof_type`, and would force a copy step where a foreign key does.

So: no migration for the library. Only for the choice.

### 2.2 `community_challenges`

```
id                              uuid pk
community_id                    fk communities  cascade
challenge_id                    fk challenges   cascade
allow_repeat_with_same_person   bool default false
requires_new_person             bool default false
timestamps
unique (community_id, challenge_id)
index (community_id)
```

**Presence means enabled.** No `is_enabled` flag: the row means "this community
plays this challenge", and a flag would add a state that every read has to filter
and that says nothing the absence of a row does not. Disabling deletes the row
and loses two booleans, which are two taps to set again.

## 3. The decision that matters most: an empty set

**A community with no rows gets the whole library.**

The alternative — empty means empty, opt in or your events have no challenges —
is a purer reading of "communities decide", and it would blank every existing
community's events the day this deploys. No community has curated anything yet,
because until now there was nothing to curate.

So the default is today's behaviour, and curating is what changes it. Same shape
as `challenges.proof_type` defaulting to `text`: additive, nothing breaks, opting
in is the act that means something.

### 3.1 Resolution order

For an event, the challenges offered are:

1. challenges with `event_id = this event` — the leader's own, always included;
2. **plus** the community's enabled set, if it has one;
3. **else** the whole library.

Level 1 is unchanged and already works, which is why an event *addition* needs no
new code. §3's "a leader could later override them for a specific event" is the
part that is **not in this piece** — deliberately, the model says "later" — but
the order above is where it slots in, as a level between 1 and 2.

## 4. §6 Repeating with the same person

Currently impossible, by unique index. It has to become a community choice, which
means the constraint moves out of the schema and into the service.

**The index is dropped and replaced by two service checks:**

| Rule | When | Why |
|---|---|---|
| No second **pending** completion for (challenge, event, pair) | always | §19. Two live requests for the same thing between the same two people is never intended, whatever the community allows |
| No second **verified** completion for (challenge, event, pair) | only when `allow_repeat_with_same_person` is false | §6, as a community choice |

Dropping a unique index gives up a database-level guarantee against a double
write — a retried request could pass both checks concurrently. Replaced with a
`lockForUpdate` on the event row inside the transaction, which serialises
initiates per event. Initiates are rare and per-event contention is not a
problem. (On SQLite the lock is a no-op, so the test suite exercises the checks
rather than the locking; the lock is for production Postgres.)

The migration's `down()` recreates the index, and **will fail if repeats have
happened by then** — which is correct, because at that point the old constraint
is genuinely false and silently deleting rows to satisfy it would be worse.

## 5. §7 Requiring a new person

`requires_new_person` on the community's row for that challenge. When set,
initiating is refused if the pair has **any verified completion together, in
either direction, at any event**.

Either direction, because "we already met" is symmetric. Any event, because the
point is meeting someone new, not meeting someone new this evening.

This is also the answer to "whose property is it?" — the model says §7 is a
community choice *and* mentions challenges that specifically require it. A
per-community-per-challenge option covers both: a community enabling "Meet
someone new" sets the flag on it.

## 6. §9 Anti-abuse

Nothing beyond §5 and §6. The model is explicit: do not overengineer, communities
decide how restrictive to be, add limits if abuse actually appears. The two
options above *are* the restrictiveness dial, and they are per community.

Note `events.max_challenges_per_attendee` (default 10) still caps XP per attendee
per event, which §8 says should not exist for MVP. That is a separate change and
is not in this piece.

## 7. Endpoints

| Method | Path | Who | What |
|---|---|---|---|
| GET | `/challenge-library` | any signed-in profile | The library, paginated. What a leader picks from |
| GET | `/communities/{community}/challenges` | any signed-in profile | The community's enabled set with its options. Public because members should be able to see what is on |
| PUT | `/communities/{community}/challenges` | leader / can_manage | **Sync** the whole set at once |

`PUT` as a sync rather than add/remove one at a time: the screen is a checklist,
so the request should be a checklist. `SyncCollaborationChallengesRequest` is the
existing precedent for this shape in the repo.

An empty array is meaningful and allowed: it means "no curation", which returns
the community to the whole-library default. That is the only way back, so it
cannot be a validation error — note `SyncCollaborationChallengesRequest` requires
`min:1`, and this one deliberately does not.

## 8. What the app does with it

Out of scope for this doc beyond the contract, but the shape it enables:

- a leader screen listing the library with a checkbox and the two options each;
- the event challenge list, unchanged in code — it already calls
  `GET /events/{event}/challenges`, and the resolution happens server-side;
- §4's flow reversal (choose challenge → scan person) becomes possible, because
  the list is now a community's curated set rather than a global dump.

## 9. Testing

The ones that pin down the decisions rather than the code:

1. a community with no rows gets the whole library — **today's behaviour**;
2. a community with rows gets only those, plus its own event-specific ones;
3. one community's choice does not affect another's events;
4. a pair cannot repeat by default;
5. a pair **can** repeat when the community allows it;
6. two pending completions for the same pair and challenge are refused **even
   when repeats are allowed**;
7. `requires_new_person` refuses a pair who have completed anything together
   before, in either direction;
8. `requires_new_person` allows a pair who have not;
9. a stranger cannot sync a community's set;
10. syncing an empty array returns the community to the default.
