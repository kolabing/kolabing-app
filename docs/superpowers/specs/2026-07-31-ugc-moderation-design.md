# Design — UGC moderation (App Review Guideline 1.2)

> Date: 2026-07-31 · Author: Volkan (with Claude) · Status: approved, building.
> Tickets: kolabing-app #99, kolabing-v2 #115. Repos: **kolabing-app** (Flutter) + **kolabing-v2** (Laravel).

## Problem
Apple rejected under Guideline 1.2 (User-Generated Content). Kolabing has UGC (profiles,
kolabs, chat, reviews, photos) but lacks the required precautions:
1. an EULA/terms with an explicit **zero-tolerance for objectionable content & abusive
   users** clause shown before register/login,
2. a mechanism to **flag/report** objectionable content,
3. a mechanism to **block** an abusive user — instantly removing their content from the
   viewer's feed **and notifying the developer**.

A Terms-acceptance flow already exists (`TermsConsentCheckbox` gating sign-up + `ReconsentGate`,
linking `kolabing.com/terms` / `/privacy`). No user/content-level report or block exists.

## Decisions (from brainstorming)
- **Surfaces:** block a **user** from their public profile + chat; **report** on a user's
  profile, a kolab/opportunity detail, a review, and a chat message.
- **Block enforcement:** backend persists blocks + returns blocked IDs; the app filters
  blocked users out of Explore/reviews/chats **client-side** for instant effect; backend
  also excludes them where cheap.
- **Notify developer:** backend emails a configured moderation address on report + block.
- **EULA:** reuse the existing consent checkbox + add an explicit no-tolerance line; the
  linked Terms page carries the clause.

## API contract (both repos build to this)
- `GET /me/blocks` → `{ "data": ["<profileId>", ...] }` (profile IDs the viewer has blocked).
- `POST /me/blocks/{profileId}` → 201/200 `{success:true}` (idempotent).
- `DELETE /me/blocks/{profileId}` → 200 `{success:true}`.
- `POST /reports` body `{ target_type: "profile"|"kolab"|"review"|"chat_message",
  target_id: string, reported_profile_id?: string, reason: string, note?: string }`
  → 201 `{success:true}`. `reason` ∈ `spam|harassment|inappropriate|other`.
- All Sanctum Bearer. App self-gates on 404 (feature dormant if backend not deployed).

## Backend (kolabing-v2)
- **Migrations:** `user_blocks` (`blocker_profile_id`, `blocked_profile_id`, unique pair,
  FKs → profiles, timestamps); `content_reports` (`reporter_profile_id`, `target_type`,
  `target_id`, `reported_profile_id` nullable, `reason`, `note` nullable, `status`
  default `open`, timestamps).
- **Models:** `UserBlock`, `ContentReport`.
- **Controllers:** `BlockController` (index/store/destroy), `ReportController` (store).
  Routes under the authenticated group; `store` validates via FormRequests
  (`BlockRequest` implicit, `StoreReportRequest`).
- **Service `ModerationService`:** `block/unblock/blockedIds`, `report`. On block + report,
  dispatch `ModerationAlertMail` (queued) to `config('mail.moderation_address')`
  (env `MODERATION_EMAIL`, fallback to `MAIL_FROM_ADDRESS`).
- **Enforcement:** `DiscoveryOpportunityService` excludes kolabs where
  `creator_profile_id` ∈ viewer's blocked set (and where the creator has blocked the
  viewer). Reviews listing excludes blocked authors.
- **Tests (Pest/PHPUnit):** block→listed; unblock→removed; duplicate block idempotent;
  report persists; `Mail::fake` asserts `ModerationAlertMail` sent on report + block;
  discovery excludes a blocked creator.

## App (kolabing-app) — `lib/features/moderation/`
- **`ModerationService`** (`report`, `block`, `unblock`, `blockedProfileIds`) — `package:http`
  + Bearer, built from `ApiConfig.baseUrl`; 404 → treat as feature-off (returns
  empty/no-op).
- **`blockedProfilesProvider`** (`Notifier<Set<String>>`): loads on first watch / after
  sign-in; `block(id)`/`unblock(id)` optimistic; invalidated on session reset (reuses the
  existing user-scoped invalidation pattern).
- **`ReportSheet`** (bottom sheet): reason chips (spam/harassment/inappropriate/other) +
  optional note → `ModerationService.report(...)` → success snackbar; error snackbar on
  failure.
- **`ModerationMenu` helper**: builds the overflow (⋮) items "Report" / "Block user"
  (+ confirm dialog for block) reused across surfaces.
- **Wiring:**
  - Public profile (`public_profile_screen`): overflow → Report user / Block user.
  - Chat thread (`chat_thread_screen`): app-bar overflow → Report / Block the counterpart.
  - Kolab detail (`explore_detail_sheet` / `community_offer_detail_screen`): Report this kolab.
  - Review row (`profile_reviews_screen`): Report this review.
- **Client filtering (instant):** watch `blockedProfilesProvider` and drop blocked
  creators from the Explore deck (`explore_screen` `_buildCardPageView`), blocked authors
  from reviews, and blocked participants' threads from the chats list.
- **EULA:** new ARB `authNoToleranceNotice` ("We have zero tolerance for objectionable
  content and abusive users.") rendered by/near `TermsConsentCheckbox`.
- **i18n:** en/es/ca for report reasons, sheet copy, block confirm/success, the notice.
- **Tests:** `blockedProfilesProvider` optimistic add/remove; `ReportSheet` submit; Explore
  deck excludes a blocked creator.

## Data flow (block)
Tap **Block** → confirm → `ModerationService.block(id)` → optimistic
`blockedProfilesProvider.add(id)` → Explore/reviews/chats providers filter → content
disappears instantly. Backend persists + emails the developer; later loads also exclude.

## Error handling
- Report/block network failure → snackbar; revert the optimistic block.
- Moderation endpoints self-gate on 404 so the app is safe if the backend lags deploy.

## Out of scope (follow-ups)
- Admin moderation dashboard / report triage queue (email-only for now).
- Auto-hiding reported content before review (report flags only).
- Rate-limiting / abuse of the report endpoint (basic throttle only).

## Delivery
- Backend PR `feat/ugc-moderation` (kolabing-v2 #115) — merge first (app self-gates until then).
- App PR `feat/ugc-moderation` (kolabing-app #99).
- Deliverable for App Review: device screen recording of EULA + report + block (content
  disappears) in the app-repo PR notes.
