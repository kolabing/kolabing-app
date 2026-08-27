# BACKEND SCHEMA — Kolabing (Laravel + Postgres)

> **MUST READ before any change that touches data, models, API payloads, or DB.**
> CLAUDE.md requires reading this every session. It documents the **real
> production Postgres schema** (verified live, 2026-05-31) so changes respect the
> actual structure and never invent columns, tables, or values.
>
> **The mobile app is Flutter; it NEVER talks to Postgres directly.** It calls the
> Laravel REST API (`ApiConfig.baseUrl` = `https://kolabing.com/api/v1`, Sanctum
> Bearer). This document describes the backend the API sits on — use it to know
> what fields exist, what the API can return, and what is impossible without a
> backend change. The backend lives in the separate repo `kolabing-v2`.

---

## Golden rules (do not violate)

1. **Never invent columns/tables/enum values.** If a field isn't listed here, it
   does not exist — confirm against the live schema before relying on it. (Real
   mistakes made during this work: assuming `city_id`, `flow_type`,
   `scheduled_date`/`recipient_profile_id` on `applications`, `business_id` on
   `collaborations`, `seeded`/`collaboration_status` on `collab_opportunities` —
   none of those exist.)
2. **Never hardcode** IDs, emails, city names, categories, or sample records in app
   code. Fetch from the API. Test data is `[TEST]`-prefixed and DB-seeded, not
   shipped in the app.
3. **Identity = `profiles`.** The `users` table is NOT the app's users — it holds a
   single maintainer/admin account (`admin@kolabing.com`, `is_maintainer`). All app
   accounts are rows in `profiles`, each with a 1:1 detail row in
   `business_profiles` / `community_profiles` / `attendee_profiles`.
4. **Two databases exist on the server: `main` (PRODUCTION) and `laravel` (empty).**
   Always use `main`. Identify it by populated `collaborations`/`profiles`.
5. **The API is viewer-scoped.** `GET /collaborations` returns only collaborations
   the authenticated profile is part of — so DB total ≠ API total. This is correct
   behaviour, not a bug.
6. **The paywall is real and backend-enforced.** A business without an active
   `business_subscriptions` row gets `403 "An active subscription is required to
   apply to this opportunity."` Communities are never paywalled. Never bypass it
   from the client.
7. **Postgres ≠ SQLite — green tests are NOT proof.** Production is **Postgres**;
   tests + local run **SQLite** (`phpunit.xml` / `.env`: `sqlite :memory:`). Behaviours
   diverge, so a query can pass 100% of tests and 500 on every prod request. **Never
   `lockForUpdate()` on an aggregate** (`->count()`/`->max()`/`->sum()`): Postgres
   forbids `SELECT … FOR UPDATE` with aggregates, SQLite allows it — this exact bug
   took down **all** event sign-ups (2026-06-10; ticket
   `docs/tickets/2026-06-10-backend-signup-500-postgres-lock.md`). To serialize a
   transaction, lock a single **row** (`Model::whereKey($id)->lockForUpdate()->first()`)
   then aggregate **without** a lock. Before merging, grep new code for
   `lockForUpdate()->(count|max|sum|avg)`, and validate anything touching locks, JSON
   operators, `ILIKE`, `RETURNING`, or transactions against **Postgres**, not just
   green SQLite tests. (Ideally add a Postgres CI lane.)

---

## Identity model

```
profiles (id uuid PK)
  ├─ email, phone_number, user_type ('business'|'community'|'attendee'),
  │  google_id, apple_id, avatar_url, password, email_verified_at,
  │  device_token, device_platform, is_test_user, deleted_at, created_at, updated_at
  ├─ business_profiles   (id PK, profile_id → profiles, name, about, business_type,
  │                       city_id → cities, city_name, city_country, instagram,
  │                       website, profile_photo, primary_venue json, categories json)
  ├─ community_profiles  (id PK, profile_id → profiles, name, about, community_type,
  │                       city_id → cities, instagram, tiktok, website,
  │                       profile_photo, is_featured)
  └─ attendee_profiles   (id PK, profile_id → profiles)
```

**Important:** `profiles.id` ≠ `business_profiles.id` ≠ `community_profiles.id`.
The collaboration table references BOTH levels — `creator_profile_id` /
`applicant_profile_id` point at `profiles.id`, while `business_profile_id` /
`community_profile_id` point at the sub-profile tables' own `id`. Neither
sub-profile has a `display_name` column — the name lives in `business_profiles.name`
/ `community_profiles.name`.

---

## The kolab lifecycle (the core flow)

```
collab_opportunities  ──1:N──►  applications  ──1:1──►  collaborations
   (the "kolab"/offer)            (someone applies)        (formed on accept)
                                                               │
                                                  collaboration_reviews (per party)
                                                  collaboration_feedback (per party)
```

### `collab_opportunities` — the offer/kolab a profile publishes
NOT NULL (no default): `id, creator_profile_id, creator_profile_type, title, description`.
Other columns: `status` ('draft'|'published'|'closed'), `business_offer` json,
`community_deliverables` json, `categories` json, `availability_mode`,
`availability_start` date, `availability_end` date, `venue_mode`, `address`,
`preferred_city` (varchar — a city NAME, not an id), `offer_photo`, `published_at`,
`selected_time` (**time** — cast text like `'13:00'::time`), `recurring_days` json,
`recipient_community_id` → profiles, `offer_headline`, `base_offer`,
`negotiation_triggers` json.
- `creator_profile_id` → `profiles`; `creator_profile_type` = 'business'|'community'.
- "Opportunity" (community-created) vs "collaboration offer" (business-created) are
  distinct concepts — never merge them (see ROLES-AND-PERMISSIONS).

### `applications` — a profile applies to an opportunity
NOT NULL (no default): `id, collab_opportunity_id, applicant_profile_id, applicant_profile_type, status`.
Other columns: `message`, `availability` (free text; **API create validation
requires ≥20 chars**), `created_at`, `updated_at`.
- `status` ∈ {`pending`, `accepted`, `declined`} (app model also knows `withdrawn`).
- FKs: `collab_opportunity_id` → collab_opportunities, `applicant_profile_id` → profiles.
- **No `scheduled_date`/`scheduled_time`/`flow_type`/`recipient_profile_id` here** —
  the accept date is stored on the collaboration, not the application.

### `collaborations` — created when an application is accepted
NOT NULL (no default): `id, application_id, collab_opportunity_id, creator_profile_id, applicant_profile_id`.
Other columns: `business_profile_id` → business_profiles, `community_profile_id` →
community_profiles, `status` (DEFAULT `'scheduled'`), `scheduled_date` date,
`completed_at` timestamp, `contact_methods` json, `event_id` → events,
`qr_code_url`.
- **`status` in production today: `scheduled`, `completed`.** The app model also
  recognizes `active`/`in_progress`, `pending_confirmation`, `cancelled`. The app's
  `GET /collaborations?status=` accepts a SINGLE value (comma lists are ignored).
- **My Kolabs hub mapping (app side):** Active = scheduled / active /
  pending_confirmation; Finished = completed / cancelled.
- Lifecycle endpoints: `POST /collaborations/{id}/complete`,
  `POST /collaborations/{id}/review`, `PATCH /collaborations/{id}` (reschedule —
  contract still unconfirmed; see TODO in `collaboration_detail_provider.dart`).

### `collaboration_reviews` — lightweight rating per party
`id, collaboration_id → collaborations, reviewer_profile_id → profiles,
reviewer_role, rating smallint, note, reviewed_profile_id → profiles, body,
would_collaborate_again bool`.

Optional 5-star review format (2026-06-28, PR 2 of the Kolab completion flow):
`communication_rating, reliability_rating, fit_rating, value_rating,
repeat_rating` (all smallint 1–5, nullable — null until a reviewer submits the
new format), `public_comment text` (nullable, max 2000 chars, intended for
display on the reviewed profile — distinct from the internal `note`/`body`).
The model exposes an `overall_rating` accessor: average of the five rating
columns when all are present, otherwise falls back to the legacy `rating`
column. Submitting a review is optional and only available after a profile
has confirmed completion as `yes`; each side may leave at most one review per
collaboration (unique on `collaboration_id` + `reviewer_profile_id`) and earns
`ReviewPosted` XP once per submission, independently of the other side.

### `collaboration_feedback` — richer post-kolab feedback
`id, collaboration_id, reviewer_profile_id, reviewer_type, reviewer_role,
rating (NN), posts_reels, expectation_match bool (NN), would_recommend bool (NN),
stories_posted, revenue numeric, benefits text`.

A collaboration is "complete with no feedback" when it has a normal `status` but
**no** `collaboration_reviews` / `collaboration_feedback` rows — that is the state
used to test the completion/feedback flow.

---

## Subscriptions / paywall

`business_subscriptions` (id, `profile_id` → profiles, `status` NN, `source` NN,
stripe_customer_id, stripe_subscription_id, current_period_start/end,
cancel_at_period_end NN, apple_original_transaction_id, apple_transaction_id,
apple_product_id).
- `status='active'` with a future `current_period_end` = subscribed. `source` can be
  `apple`, `stripe`, `maintainer` (admin-granted), etc.
- The app activates a sub ONLY by verifying a real Apple StoreKit transaction
  (`verifyApplePurchase` in the profile service). There is **no API endpoint to
  grant a subscription**; granting one for testing = insert/adjust a
  `business_subscriptions` row in the DB.
- Paywall gates exactly two business actions: create-collaboration and apply-to-kolab.

---

## Foreign-key map (authoritative)

```
collab_opportunities.creator_profile_id      → profiles
collab_opportunities.recipient_community_id  → profiles
applications.collab_opportunity_id           → collab_opportunities
applications.applicant_profile_id            → profiles
collaborations.application_id                → applications
collaborations.collab_opportunity_id         → collab_opportunities
collaborations.creator_profile_id            → profiles
collaborations.applicant_profile_id          → profiles
collaborations.business_profile_id           → business_profiles
collaborations.community_profile_id          → community_profiles
collaborations.event_id                      → events
collaboration_reviews.collaboration_id       → collaborations
collaboration_reviews.reviewer_profile_id    → profiles
collaboration_reviews.reviewed_profile_id    → profiles
business_profiles.profile_id / city_id       → profiles / cities
community_profiles.profile_id / city_id      → profiles / cities
business_subscriptions.profile_id            → profiles
```

There are **no triggers or rules** on these tables — inserts do not auto-mutate
other rows. Forming a collaboration = manually inserting opportunity → application
(accepted) → collaboration, exactly as the API does internally.

---

## Other tables (reference, not exhaustive)

`cities, city_suggestions, business_types, community_types` (lookups — fetch via
API, never hardcode); `kolabs`; `events, event_checkins, event_photos,
event_rewards`; `chat_messages`; `challenges, challenge_completions,
collaboration_challenges, encounters`; `badges, badge_awards, earned_badges`; gamification
(`point_ledger, wallets, reward_claims, withdrawal_requests, referral_codes,
referral_redemptions`); `notifications, notification_preferences,
notification_reminders`; `personal_access_tokens` (Sanctum); Laravel internals
(`cache, cache_locks, jobs, job_batches, failed_jobs, sessions, migrations,
password_reset_tokens`).

---

## `encounters` — the People Layer (kolabing-v2#244)

The ledger of **people**, next to `challenge_completions`' ledger of **actions**.
Written from `ChallengeCompletionService::verify`.

```
encounters
  id · profile_id → profiles · other_profile_id → profiles (NULL while a ghost)
  ghost_name · community_id → communities · event_id → events
  met_at · times_met · proof_photo_url · claimed_at
  challenge_id · ghost_claim_token (UNIQUE) · ghost_contact · pending_points · expires_at
  UNIQUE (profile_id, other_profile_id, event_id) WHERE other_profile_id IS NOT NULL
```

Three things about it that are easy to get wrong:

1. **One row per pair per EVENT, and each row is frozen.** A row means *at this
   event these two met, and it was their Nth time*. `times_met` is written once
   and never updated — the row from the third event says 3 forever. The current
   count for a pair is the `times_met` of its most recent row.
2. **A meeting is an event, not a challenge.** Ten challenges with the same
   person in one night is one row. The partial unique index enforces it, so this
   is a schema guarantee, not a service rule that can be forgotten.
3. **An encounter is not a friendship.** Nothing writes `friendships` from here.
   The app offers "Add friend" on the reveal and the person decides.

The pair ladder lives in backend config (`gamification.pair_ladder`), never in
the app: crossing a rung pays a one-time bonus to **both** sides. Levels do not
decay and there are no streaks.

`ChallengeCompletionResource` carries an additive `pair_level`
(`times_met`, `key`, `next_at`, `just_levelled_up`, `bonus_awarded`) on the
response that settled a challenge. `key` is a slug, not a display string — the
app localizes it in three languages.

### Ghost invites (kolabing-v2#246)

A row whose `other_profile_id` is null is a **ghost**: someone met at an event
who does not have the app. `POST /encounters/ghost` writes one and hands back a
claim code; `POST /encounters/claim` fills it in, writes the reverse row and
releases `pending_points` to **both** sides.

- **Nothing is paid at invite time.** `pending_points` is frozen when the invite
  is written, so the number promised on the inviter's screen survives an admin
  later retuning what the challenge is worth.
- **The invite URL is on the app host** (`app.kolabing.com/i/{code}`), not the
  marketing domain: the association files live there and only paths on that host
  are handed to an installed app.
- **The claim code is the half a Universal Link cannot do.** A link carries no
  state through the App Store, and the whole point of a ghost is someone who has
  to go through it — so `GET /i/{code}` is a real page that shows the code to
  retype.
- Refusals carry a machine-readable `error`: `not_checked_in`,
  `ghost_limit_reached` (3 unclaimed per attendee per event), `invalid_claim_code`,
  `claim_expired` (30 days), `claim_requires_new_account`, `claim_self`.
- A claim **does not** create a `ChallengeCompletion`. Nobody verified anything
  and the two were never checked in together; a fake completion would put
  something that did not happen into challenge stats and mission progress.

---

## How to connect (read-first, then write in a transaction)

Creds live OUTSIDE the repo at `~/.kolabing_db.env` (never committed). Client:
`/opt/homebrew/opt/libpq/bin/psql`. **Always `sslmode=require`**, db `main`.
Workflow for ANY write: (1) read schema, (2) dry-run inside `BEGIN; … ROLLBACK;`,
(3) show the plan, (4) `COMMIT` only after a clean dry-run, (5) verify via SQL AND
the live API. Never write to production without a green dry-run. Cast types
explicitly (`'13:00'::time`, `'2026-05-31'::date`).

### Reference: the test-seed chain (what a valid collaboration looks like)
The 6 `[TEST]` collaborations (Real Run Club community ↔ Eixample 46 business) were
created as: `collab_opportunities` (status=published, creator=community) →
`applications` (status=accepted, applicant=business) → `collaborations`
(status=scheduled, with both `business_profile_id` + `community_profile_id`). No
review/feedback rows → "completed-but-no-feedback" test state.
