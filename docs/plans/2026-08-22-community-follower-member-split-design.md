# Community follower / member split — design

> Issue #138 · approved 2026-08-22 · supersedes nothing; additive to the
> community-members work (IF-7).
>
> Backend: `kolabing-v2` branch `feat/community-follower-split`.
> App: `kolabing-app` branch `feat/community-follower-member-split`.

---

## 1. The problem

Today there is exactly one relationship between a person and a community:
`community_members` (`community_id`, `profile_id`, `tier_id`, `can_manage`,
`status`, `joined_at`). With `join_policy: open` — the default the app creates —
becoming a member is **one tap**.

That one tap is the key to everything that matters:

| Gate | Enforced in |
|---|---|
| Community chat | `ChatService::isCommunityMemberOrOwner` |
| Member- and tier-gated events | `events.visibility` = `members` \| `tier` |
| Community points | `CommunityPointsService` |
| Badges | `CommunityBadgeService` |
| Leaderboard | `LeaderboardService` |
| Tier assignment | `TierAssignmentService` |
| Roster | `CommunityRosterQuery` |

A frictionless tap should not buy all of that, and a community needs to be able
to **ask something** before letting a person in. The visible symptom: the app's
Communities list shows the user as "Member" of every community they ever
touched.

## 2. The two relationships

| | **Follower** | **Member** |
|---|---|---|
| How | one tap, no approval | request + the leader's questions + approval |
| See the community profile | ✅ | ✅ |
| Sign up to a **public** event | ✅ | ✅ |
| QR check-in, challenges, **global** XP | ✅ | ✅ |
| Community chat | ❌ | ✅ |
| Member- / tier-gated events | ❌ | ✅ |
| Community points, badges, leaderboard | ❌ | ✅ |
| Tier | ❌ | ✅ |

The line is *turning up* versus *belonging*. A follower can come to a public
event and play the whole QR gamification loop — which matters, because that loop
is the funnel: making someone wait for approval before they can play would kill
it. Membership is the ongoing relationship.

## 3. Scope: most of this already works

Checked against the backend before designing, and it shrank the work
considerably:

- **`EventSignupService::signup` does not require membership.** Its only gates
  are "the event is upcoming" and, for events with no community, `visibility:
  public`. A follower can already sign up to a community's public event.
  → no change.
- **QR check-in, challenges and global XP** write to `attendee_profiles` and
  `point_ledger`, neither of which is community-scoped. → no change.
- **Chat, community points, badges, leaderboard and tiers** are already gated on
  `CommunityMember`. → no change.

So the work is: the follow relationship, and the questions-and-approval layer.

## 4. Data model

### The modelling decision: a separate table

`community_followers` as its own table, **not** a `kind: follower|member`
column on `community_members`.

The security-critical direction is *a follower must never get member access*.
With a separate table, every existing `community_members` query keeps its exact
meaning, and no query can begin including followers by accident. A `kind` column
fails the other way: the unfiltered query would include followers, so missing
one call site among the seven gates in §1 is a silent privilege leak. Failing
closed beats a smaller diff.

### New tables (three)

```
community_followers
  id            uuid pk
  community_id  uuid  → communities   cascadeOnDelete
  profile_id    uuid  → profiles      cascadeOnDelete
  followed_at   timestamp
  timestamps
  unique (community_id, profile_id)
  index (profile_id)

community_join_questions
  id            uuid pk
  community_id  uuid  → communities   cascadeOnDelete
  position      smallint         -- display order, 1..5
  prompt        string(280)
  required      boolean default true
  is_active     boolean default true  -- soft retire, keeps old answers readable
  timestamps
  index (community_id, position)

community_join_answers
  id                uuid pk
  join_request_id   uuid → community_join_requests  cascadeOnDelete
  question_id       uuid → community_join_questions cascadeOnDelete
  answer            text
  timestamps
  unique (join_request_id, question_id)
```

`community_members` and `community_join_requests` are **structurally
unchanged**.

### Rules

- **Membership and following are separate axes.** A member does not need a
  follower row. The UI shows "Member", never "Following", when both exist. An
  existing follower row is left alone on approval — harmless, and deleting it
  would lose the `followed_at` history.
- **Questions are versioned by retirement, not deletion.** `is_active: false`
  retires a question while its past answers stay readable.
- **And the wording is snapshotted onto the answer.** Retirement alone is not
  enough: a leader can *reword* a live question, which would silently re-render
  an old application under wording its author never saw.
  `community_join_answers.prompt_snapshot` records what was asked.
- **Position is not unique, so ordering is `(position, created_at)`.** A retired
  question keeps its number, and a replacement goes past the highest **live**
  position rather than to `count + 1`, so it cannot land on top of one.
- **Max 5 active questions per community**, enforced in the service, not just
  the UI.
- **`join_policy` keeps its two values and gains a clearer meaning**, with one
  correction found while planning: today
  `CommunityJoinRequestController::store` **refuses** a request to an `open`
  community outright (`DomainException` → "This community is open. You can join
  directly."), so open communities do not use the request path at all. The rule
  becomes: an `open` community accepts a request **only when it has active
  questions**, and auto-approves it in the same transaction; with no questions it
  keeps refusing exactly as today, so the existing `/communities/{id}/join` path
  is untouched. `invite_only` → a leader decides, as now.

  This is what keeps the change production-safe: no community has questions
  until a leader creates one, so on the day of deploy every community behaves
  precisely as it does today.

## 5. Endpoints

Mostly new. The last four **already exist** — `CommunityJoinRequestController`
has carried `store`/`index`/`approve`/`decline` since the invite-only work — and
`store`/`index` are *extended* here, additively: `store` accepts an `answers`
key, `index` gains an `answers` array. Nothing is removed or retyped.

| Method | Path | Who | Does |
|---|---|---|---|
| `POST` | `/communities/{id}/follow` | any signed-in profile | follow (idempotent) |
| `DELETE` | `/communities/{id}/follow` | follower | unfollow (idempotent) |
| `GET` | `/communities/{id}/join-questions` | any signed-in profile | the active question set, ordered |
| `POST` | `/communities/{id}/join-questions` | leader | create (max 5 active) |
| `PATCH` | `/communities/{id}/join-questions/{qid}` | leader | edit prompt / required / position |
| `DELETE` | `/communities/{id}/join-questions/{qid}` | leader | retire (`is_active: false`) |
| `POST` | `/communities/{id}/join-requests` | non-member | apply, with answers |
| `GET` | `/communities/{id}/join-requests` | leader | pending queue, answers included |
| `POST` | `/join-requests/{id}/approve` | leader | → `CommunityMemberService` (default tier) |
| `POST` | `/join-requests/{id}/decline` | leader | decline |

**`GET /me/memberships` is not touched at all.** It returns `data` as a bare
list and the shipped app casts it straight to `List<dynamic>`
(`community_service.dart` `_asList`), so turning `data` into
`{memberships: […], following: […]}` would throw in every installed build and
break My Communities. The follows list is therefore its **own endpoint**,
`GET /me/community-follows`.

## 6. Flows

**Follow** — one tap, instant, reversible. No notification to the leader (a
follow is not a request).

**Apply**
1. `GET /communities/{id}/join-questions` → 0..5 prompts.
2. Applicant answers the required ones.
3. `POST /communities/{id}/join-requests` with the answers → a
   `CommunityJoinRequest` (`pending`) plus its `community_join_answers`.
4. `join_policy: open` **and the community has active questions** → approved
   immediately in the same transaction. An open community with **no** questions
   still refuses the request path, exactly as today (see §4) — the guard that
   makes this deployable, so do not implement step 4 without it.
   `invite_only` → stays pending, the leader is notified.

**Decide** — the leader lists pending requests with their answers and approves
or declines. Approval calls the existing `CommunityMemberService` so the member
row, default tier and main-chat access come out exactly as they do today.

**Zero questions** degrades cleanly to plain request-and-approve.

## 7. Not breaking production

1. **Additive migrations only.** Three new tables. No column altered, renamed or
   dropped. Every migration reversible by dropping only what it created.
2. **No existing endpoint changes its contract.** Every app version already
   installed keeps working untouched.
3. **No existing row is written.** Current members stay members, with their
   tiers, chats, points and badges intact, and need to do nothing.
4. **`open` communities keep behaving identically for existing members.** The
   reinterpretation of `join_policy` only affects *new* applications.
5. **Deploy order:** backend first, app after. Until the app ships, the new
   endpoints are simply unused — nothing regresses.
6. **Self-gating cannot use the join-request endpoints** — they already exist,
   so a pre-deploy backend answers 200/422 there, never 404. The app should
   probe a genuinely new route: `GET /me/community-follows` 404s until this
   deploys, and that is the capability signal. (`GET .../join-questions` will
   not do: it also 404s for a community the viewer cannot see.)
7. **Required answers are enforced only when the client sends an `answers`
   key.** The shipped app posts an empty body, so enforcing unconditionally
   would 422 every installed build the moment a leader added a required
   question.

## 8. Testing

- **Migrations**: up and down on a copy; assert no existing table is altered.
- **Follow**: idempotent follow/unfollow; unique constraint holds; a follower
  gets no chat, no member-only event, no community points.
- **Questions**: the 5-active cap; retiring one keeps old answers readable;
  position ordering.
- **Apply**: required answers enforced; `open` auto-approves; `invite_only`
  stays pending; a member cannot apply again; approval produces the same member
  row as today's join.
- **Authorization**: only a leader may read the queue, decide, or manage
  questions — the roster endpoint's 403 is the pattern to match.
- **Regression**: an existing member's access is unchanged after the migration
  (the important one).

## 9. Open items

- The app's Communities list needs a third state. Today every row reads
  "Member"; it needs Member / Following / neither.
- Whether a leader should see a follower list is left for later — the count is
  enough to start.
- Notifications for approve/decline reuse the existing `NotificationService`
  types if a suitable one exists; otherwise the decision is surfaced in-app only
  for v1 rather than inventing a notification type here.

## 10. Out of scope

- Reworking tiers, points or badges.
- Follower-only content or feeds.
- Migrating any existing member down to follower.

---

## 11. Two things the code review surfaced that are still open

Both are product decisions, and neither is answered by what has been built.

### 11.1 A follower can sign up to a **member-only** event

§2 claims a follower cannot attend member- or tier-gated events. That is not
what the backend does. `EventSignupService::signup` checks `visibility` only for
events with **no** community; for a community's event it does not check at all,
so anyone signed in who has the event id can sign up to a `members`-visibility
event. The app only hides those client-side via `can_access`.

This predates the split — not a regression — but the design should not claim a
gate that does not exist. Either add a membership check to `EventSignupService`
(a behaviour change with real blast radius: it would start refusing sign-ups
that succeed today), or narrow §2 to say the gate is client-side only.
**Not decided.**

### 11.2 For `open` communities, `/join` bypasses the questions entirely

`open` is the default the app creates, and every current join CTA calls
`POST /communities/{id}/join` whenever `join_policy` allows self-join. That
endpoint is deliberately untouched here — so an open community can define five
required questions and still receive one-tap members through `/join`.

As shipped, the questions gate is effective for `invite_only` communities and
cosmetic for open ones. Closing it means making `/join` refuse when active
questions exist: a real contract change with an app-side dependency, which would
break one-tap join for any community that adopts questions. **Not decided** —
worth settling before the app work, because it decides whether the Follow/Apply
UI applies to open communities at all.
