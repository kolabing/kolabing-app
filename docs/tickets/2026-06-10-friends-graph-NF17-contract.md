# Friends graph (NF-17 Phase 2) — shared contract

> Authoritative contract for the member-to-member friend graph. Backend
> (`kolabing-v2`) and app (`kolabing-app`) are built against THIS doc so they
> reconcile. Gates the friends UI on the member profile and NF-14 DMs. App
> self-gates: every endpoint degrades gracefully (treat 404/未deployed as
> "feature off") until the backend deploys.

## Data model — `friendships`
- `id` uuid (pk)
- `requester_profile_id` uuid → `profiles.id` (the sender)
- `addressee_profile_id` uuid → `profiles.id` (the recipient)
- `status` varchar: **`pending` | `accepted` | `blocked`**
- `created_at` / `updated_at`
- **Unique** on the unordered pair (enforce one row per pair — e.g. unique
  index on `(requester_profile_id, addressee_profile_id)` PLUS app-level guard
  against the reverse pair, or store as least/greatest). Index both FKs + status.
- A friendship is **accepted** ⇒ the two are friends (direction no longer matters
  for "are they friends"). Direction only matters for pending (who asked whom).

## Endpoints (all Sanctum `auth:sanctum`, viewer = `$request->user()`)
| Verb | Path | Action |
|---|---|---|
| POST | `/friends/{profile}` | Send request: create `pending` (requester=me, addressee={profile}). 422 `already_friends` / `request_exists` / `cannot_friend_self`. If a reverse pending exists, **auto-accept** (mutual). |
| POST | `/friends/{profile}/accept` | Accept incoming pending (me = addressee) → `accepted`. 404 if none. |
| POST | `/friends/{profile}/decline` | Decline incoming pending (delete row). |
| DELETE | `/friends/{profile}` | Remove friend OR cancel my outgoing request (delete row). |
| GET | `/me/friends` | Paginated accepted friends. Each item: `{ profile_id, name, avatar_url, user_type }`. |
| GET | `/me/friend-requests` | Incoming pending requests: `{ data: [{profile_id,name,avatar_url,user_type}], count }`. |

## `friend_status` on profile payloads
Add to **`PublicProfileResource`** and the **game-card** profile object a
`friend_status` (string) + `friends_count` (int):
- **`self`** — viewing your own profile
- **`none`** — no relationship
- **`pending_outgoing`** — I sent a request (show "Pending", allow cancel)
- **`pending_incoming`** — they sent me a request (show "Accept / Decline")
- **`friends`** — accepted
Computed for `$request->user()` vs the viewed profile.

## App surfaces
- **Member profile header** (`public_profile_screen.dart` `_MemberProfileContent`):
  a CTA driven by `friend_status`: **Add friend** (none) · **Pending ▾** (cancel) ·
  **Accept / Decline** (incoming) · **Friends ▾** (remove). Optimistic update.
- **Friends list** screen (self): from `GET /me/friends`; **Requests** section/badge
  from `GET /me/friend-requests`.
- `FriendshipService` + providers (`friendsProvider`, `friendRequestsProvider`,
  per-profile status from the profile payload). i18n en/es/ca, design tokens only.
- **Self-gating:** if any endpoint 404s (not deployed), hide the friends UI / treat
  as `none` — never crash, never block the profile.

## Notifications (optional, can defer)
Friend request received → a notification (reuse NotificationService). Out of scope
for the first cut if it complicates the deploy.

## Out of scope here
DMs (NF-14, friend-gated, separate). Block/unblock UI (the `blocked` status exists
in the model for later).
