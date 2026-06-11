# HANDOFF — `fixes-attendee` branch (resume here in a fresh conversation)

> Written 2026-06-10 because the chat hit an **image-processing error** (sim
> screenshots are 1206×**2622**px; the 2622 height exceeds the 2000px API limit, and
> accumulated images compounded it). **Workaround next session:** never `Read` a raw
> sim screenshot — downscale first: `xcrun simctl io booted screenshot /tmp/s.png &&
> sips -Z 1200 /tmp/s.png --out /tmp/s_small.png` and read the small one (or skip
> screenshots and verify via shell/API).

## Where things are
- **Branch:** `fixes-attendee`, cut from `origin/master` (`35cf301`, v1.4.0+13).
- **api.dart:** production (`https://kolabing.com/api/v1`). *(The parallel session's
  local `127.0.0.1:8000` pointer is only on `feat/recurring-followups`, not here.)*
- **Committed on `fixes-attendee`:**
  - `f229741` — signup-500 backend ticket + `BACKEND-SCHEMA.md` Golden Rule 7 (Postgres).
  - `4fcbef1` — paywall business-only fix (bug #2 below).
- **Test data (production):** leader `realrunclub@gmail.com` / `test1234`; attendee
  `daniel@testcom.com` / `test1234`; community `019e91a3-554f-7235-8f1d-a74e884b2153`
  (Real Run Club). daniel IS a member.

## Reported bugs → status

| # | Bug | Status | Where / next |
|---|---|---|---|
| 1 | Attendee "I'm going" → **Server error** | ✅ root-caused, ❌ not fixed | **Backend P0.** `lockForUpdate()->count()` is Postgres-illegal (aggregate+FOR UPDATE); SQLite tests passed, prod 500s every signup. Exact fix in `docs/tickets/2026-06-10-backend-signup-500-postgres-lock.md`. **Backend agent must apply (1-line, `kolabing-v2` `EventSignupService::signup`) + deploy.** |
| 2 | Community accounts **blocked from posting / asked for premium** | ✅ **FIXED** (`4fcbef1`) | `SubscriptionPaywall.checkAndShow` didn't role-gate → paywalled non-subscribed communities. Added business-only gate. **Optional cleanup:** delete the now-no-op `checkAndShow` call in `community_main_screen.dart` `_onFabPressed` (+ its import). Verify on sim: community FAB → create flow opens, no premium sheet. |
| 3 | **Gallery & Past Events not live** | ❌ pending | I shipped the community **Details** tab's gallery/past-events as a placeholder (`community_detail_screen.dart` `_DetailsTab`). Wire to `GET /events?community_id=&time=past` (returns past events + `event_photos`). |
| 4 | **Not all chats appear available** (attendee) | ❌ pending | Diagnose chat **tier-gating** visibility. Backend gates custom chats by `community_tiers.permissions.chat_channels` / `ChatThreadResource.slug`. Compare what `GET /chats` returns for the attendee vs what should be visible for their tier. |
| 5 | **Creating a community from a community profile wipes the profile picture** | ❌ pending | `create_community_screen.dart` `createCommunity(...)` passes **no avatar**, and may overwrite the `community_profiles` photo. Trace `CommunityService.createCommunity` + the backend `POST /communities` — it should **inherit** the community profile's existing picture, not null it. |
| 6 | **Profile sections entirely broken** | ❌ pending (severe) | Likely a **Wave-1 merge regression** in the attendee profile (this branch is off latest master which merged community-social Wave 1/2). Start at `lib/features/gamification/screens/attendee_profile_screen.dart` (renders from `authProvider.user`); check what each section reads + whether a provider/endpoint errors. Reproduce on sim as daniel → Profile (via app-bar avatar). |
| 7 | **New logo not showing** | ❌ pending — reconcile | `feat/new-logos` (+1 ahead, **unmerged**) holds `assets/brand/kolabing-*` wordmarks + app icon. Also the home app bar uses the **"KOLABING" text** wordmark (`KolabingAppBar`), not an image. **Task:** merge `feat/new-logos` → master (assets-only, low conflict), then (if intended) wire the image wordmark into `KolabingAppBar`. |
| 8 | **Add backlog items for community attendees** | ❌ pending | Add NF/IF entries to `BACKLOG.md` for the community-attendee features (friends; social-hub profile NF-13; DMs NF-14; languages NF-9). |
| 9 | **Attendee sign-up / onboarding not reachable** | ❌ pending (fix) | Everything exists but isn't wired: `AttendeeRegisterScreen` (`lib/features/auth/screens/attendee_register_screen.dart`), route `KolabingRoutes.attendeeRegister` = `/auth/register/attendee`, and backend `POST /auth/register/attendee` (`AuthService.registerAttendee`, verified **201** on local). The blocker is `lib/features/auth/screens/user_type_selection_screen.dart`: the Attendee `SelectionCard` is hard-gated `isEnabled: false` + `badgeLabel: 'COMING SOON'` (~L235-243), **and** `_handleCardTap` **returns early for attendee** (L122-124) + its `switch` case returns (L140-141). So tapping does nothing. **Fix:** (a) remove `isEnabled:false` + `badgeLabel` + `descriptionOverride` from the Attendee card (make it a normal enabled card with `isSelected:`); (b) in `_handleCardTap`, route attendee → `context.push(KolabingRoutes.attendeeRegister)` (drop the early `return` + the empty switch case). Then verify on sim: Sign up → Attendee → register screen → creates account. ⚠️ The richer attendee onboarding also lives on `feat/nf16-events-attendee-app`; coordinate so this wiring doesn't diverge from that branch's version. |

## Preventive-measures framework (user-requested: "never make the same mistake twice")
For **every** bug: root cause → fix → **one durable entry** in the right doc:
- **DB / query / Postgres** → `docs/BACKEND-SCHEMA.md` Golden Rules. *(Done for #1: Rule 7 — Postgres≠SQLite, never lock an aggregate, validate on Postgres.)*
- **Role / paywall / profile / chat-gating** → `docs/ROLES-BACKEND-DB-MAP.md` "Mistakes-to-fix checklist". *(TODO for #2: add "never call the business paywall from a community/attendee path; the paywall helper must role-gate.")*
- **Process** (placeholder shipped as done, untested surface) → `CLAUDE.md` / verify rule. *(TODO for #3.)*
- Plus a **Fixes** entry in `BACKLOG.md` per bug.

## Branch reconciliation context (from Phase 0 earlier)
- Deleted 9 fully-merged branches. **Active lanes kept:** `community-member-fixes` (+7, Wave-2 attendee profile/friends/public-events/chat — overlaps master, reconcile carefully), `feat/new-logos` (+1, merge — bug #7), `feat/posthog-analytics` (+1), `feat/night-mode-full-migration` (+6, **IGNORE per Daniel**), `feat/community-atmospheric-editorial` (+44, **IGNORE**), `feat/recurring-followups` (recurring, has the local-`api.dart` WIP), `fix/kolabing-qa-followup` (+15 stale), docs/marketing branches.
- **Kept worktree:** `kolabing-app-wt/chat-mgmt` (`feat/chat-management`, has uncommitted chat work — don't delete).

## Resume checklist (fresh conversation)
1. `git checkout fixes-attendee` (it's pushed? if not, `git push -u origin fixes-attendee`).
2. Verify #2 on sim (downscaled screenshots only), then do optional cleanup.
3. Work #3→#6 + **#9 (attendee sign-up/onboarding wiring)** (each: root cause → fix → preventive doc entry → BACKLOG Fixes).
4. #7: merge `feat/new-logos` → master.
5. #8: backlog entries.
6. Hand the #1 backend ticket to the `kolabing-v2` agent to apply + deploy.
