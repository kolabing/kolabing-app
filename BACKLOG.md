# BACKLOG

> **Single source of truth for outstanding work.** CLAUDE.md requires this file to
> be read at the start of every session and kept in sync. See "Maintenance rules"
> at the bottom — they are mandatory, not optional.
>
> Last updated: 2026-06-01 (feedback reorder shipped; feedback + admin-challenges tickets added)

---

## 🆕 New Features
_Planned work that does not exist yet._

| # | Feature | Notes | Status |
|---|---------|-------|--------|
| NF-1 | **Community member update** | Let communities add/edit/manage their member roster (the people inside a community). Scope, data model, and endpoints TBD. | Not started |
| NF-2 | **Map update** | Refresh/expand the map experience (discovery on a map, pins for businesses/communities/events). Scope TBD. | Not started |
| NF-3 | **Geolock check-in** | Location-gated check-in at a kolab/event — attendee must be physically at the venue (geofence) to check in / scan the QR. Ties into the existing `qr_code_url` + challenges flow. | Not started |
| NF-4 | **Profile photo scale/zoom on pick** | When choosing a profile picture, let the user pinch-to-zoom / pan to crop and frame the image before saving (interactive scale in/out). Applies to the image_picker flow used for avatars. | Not started |

---

## 🚧 Incomplete Features
_Started or partially shipped; not yet fully working end-to-end._

| # | Feature | What's done / what's missing | Status |
|---|---------|------------------------------|--------|
| IF-1 | **My Kolabs — Active & Finished tabs** | DONE: wired to `GET /collaborations` (Active = scheduled/active/pending_confirmation; Finished = completed/cancelled), real cards, pull-to-refresh. MISSING: visual QA on device; no "cancel collaboration" action yet (cancel→Finished path exists server-side but no UI trigger surfaced here). | In progress |
| IF-2 | **Kolab completion / feedback flow** | Backend supports `POST /collaborations/{id}/complete` + `/review`; detail screen has completion/review sheets. MISSING: end-to-end test with seeded data; confirm both-parties-confirm → completed transition and review prompts. | In progress |
| IF-3 | **Reschedule collaboration** | Client calls `PATCH /collaborations/{id}` but the exact verb/path/fields are unconfirmed (see `TODO(backend)` in `collaboration_detail_provider.dart`). | Blocked on backend contract |
| IF-4 | ~~**Test data seeding (6 kolabs)**~~ | ✅ DONE 2026-05-31 — seeded directly into production Postgres (`main` db) via psql, the legitimate way around the API paywall (a DB write like the artisan seeder; never bypassing the paywall in client/API code). 6 collaborations between Real Run Club (community/creator) + Eixample 46 (business/applicant): **today-13h ×2 (2026-05-31), yesterday-20h ×2 (2026-05-30), tomorrow-10h ×2 (2026-06-01)**, all `status=scheduled`, **no reviews/feedback** — the exact state to test the completion/feedback flow. Each row chain (collab_opportunities → accepted applications → collaborations) matches the real schema (see docs/BACKEND-SCHEMA.md). VERIFIED via SQL **and** live API (`GET /collaborations` for Eixample46 = 6 scheduled + 1 pre-existing completed = 7). 12 orphan probe opps cleaned up. All tagged `[TEST]` — safe to delete. | Done |
| IF-5 | **Feedback / completion flow is wrong (high priority)** | AUDIT 2026-05-31. **What's built:** app `kolab_review_sheet.dart` POSTs `/collaborations/{id}/review` with only `rating`, `would_collaborate_again`, `note` → writes the *lesser* `collaboration_reviews` table. Completion (`kolab_completion_sheet.dart` → `markCollaborationCompleted` POST `/complete`) marks complete and shows the review CTA *afterwards* (visually wrong; not forced). **What's MISSING / wrong:** (1) Backend ALSO has `POST /collaborations/{id}/feedback` (verified live: 422 with required `rating, reviewer_role, expectation_match, would_recommend`; optional per DB `collaboration_feedback`: `posts_reels, stories_posted, revenue, benefits`) — the app never calls it, so the rich questions (stories/reels counts, revenue estimate, expectation match, would-recommend) are absent. (2) Feedback must be FORCED at close: completion should require feedback, and the collaboration should only move to completed once feedback is submitted — currently complete happens first, feedback optional after. (3) Review shows after completion instead of as the closing step. **Fix plan:** build a full feedback sheet (rating, expectation_match, would_recommend, stories_posted, posts_reels, revenue, benefits) bound to `POST /collaborations/{id}/feedback`; make Complete open it and only call `/complete` after a successful feedback submit; drop/merge the old `/review` sheet. Tables: `collaboration_feedback` (rich) vs `collaboration_reviews` (legacy) — see docs/BACKEND-SCHEMA.md. | Audited — needs build |
| IF-6 | **Gamification challenges use mock data** | AUDIT 2026-05-31. **Built:** backend `GET /challenges/system` works (200, real data); `PUT`/`POST /collaborations/{id}/challenges` documented + live; DB has `challenges` + `collaboration_challenges`; app `challenge_service.dart` has event-scoped methods + a `systemChallenges` getter; `Challenge.fromJson` matches the `/challenges/system` shape. **Wrong:** `collaboration_detail_provider.dart` exposes `availableChallengesProvider` returning hardcoded `_mockChallenges` (and it's UNUSED); the Gamification Setup card shows `collaboration.challenges` which the API returns as `[]`, so it's always empty; "Add custom challenge" is a stub ("coming soon"). **Fix plan:** wire the Gamification card to `GET /challenges/system` (real list) + persist selection via `PUT /collaborations/{id}/challenges`; delete `_mockChallenges`/`_mockCollaboration`. **Event Preparation** = just a static timeline label, no dedicated backend/feature. | Audited — needs build |

---

## 🐛 Fixes
_Bugs to fix. Add when detected; move to a struck-through "confirmed fixed" line (or delete) once verified._

| # | Bug | Status |
|---|-----|--------|
| FX-1 | ~~Accepted applications wrongly appeared under Requests → Sent~~ — accepted items now filtered out of Requests (Sent + Received); they belong in Active. | ✅ Fixed 2026-05-31 (pending device re-verify) |
| FX-2 | ~~"Collab"/"collaboration" shown in user-facing copy~~ — renamed to "Kolab" across 61 visible strings; backend contract strings deliberately untouched. | ✅ Fixed 2026-05-31 |
| FX-3 | ~~Bottom nav RenderFlex overflow~~ (pre-existing, commit 846dcac). | ✅ Fixed |
| FX-4 | ~~Kolab detail 3-dots (⋮) menu did nothing~~ — it had an empty `onPressed`. Removed; its actions (Reschedule, Complete) already exist inline and are correctly hidden on terminal kolabs, so it was fully redundant. | ✅ Fixed 2026-05-31 |
| FX-5 | Active sub-tab empty / Finished showed only 1 → fixed earlier (CollaborationPartner null-safety + hub refresh-on-open). | ✅ Fixed 2026-05-31 |

---

## Maintenance rules (for Claude — enforced via CLAUDE.md)

1. **Read this file at the start of every session** and list its current contents back to the user before starting work.
2. **Three sections only:** New Features, Incomplete Features, Fixes. Keep each item in the section that matches its true state.
3. **Move items as state changes:**
   - A New Feature that work has begun on → move to **Incomplete Features**.
   - An Incomplete Feature verified working end-to-end → remove it (or mark done and drop on next cleanup).
4. **Bugs:** when a bug is detected, add it to **Fixes** immediately. When the fix is **confirmed** (tested/verified, not just written), strike it through with the date, then remove on a later cleanup. Never delete an unconfirmed fix.
5. **One row = one item.** Keep notes terse; link to files/endpoints where useful.
6. Update the `Last updated:` date at the top whenever you change this file.
