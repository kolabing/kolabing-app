# BACKLOG

> **Single source of truth for outstanding work.** CLAUDE.md requires this file to
> be read at the start of every session and kept in sync. See "Maintenance rules"
> at the bottom — they are mandatory, not optional.
>
> Last updated: 2026-05-31 (NF-4 added)

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
| IF-4 | **Test data seeding (6 kolabs)** | RECOMMEND server-side artisan seeder. Live-API path investigated: both logins work; `GET /collaborations` confirmed (Active/Finished read from it). Creating an opportunity via `POST /opportunities` requires a full payload — `title, description, business_offer, community_deliverables, categories, preferred_city, availability_mode` (objects, not just strings). Reconstructing that contract against PRODUCTION to drive create→apply→accept ×6 is risky/error-prone. The business-apply paywall was NOT cleanly tested (an earlier "403" was a Cloudflare 1010 false positive against urllib, not the API). The robust path is the existing artisan `kolabing:seed-test-collaboration` on the Laravel host (`kolabing-v2`) — it made the existing `[TEST] Finish-flow collaboration` and bypasses billing/validation legitimately for test data. Need: dates 2026-05-31 / 2026-05-30 / 2026-06-01 (×2 each), business=Eixample46, community=Real Run Club, status accepted→scheduled (no feedback). `scheduled_date` is date-only. | Recommend artisan seeder |

---

## 🐛 Fixes
_Bugs to fix. Add when detected; move to a struck-through "confirmed fixed" line (or delete) once verified._

| # | Bug | Status |
|---|-----|--------|
| FX-1 | ~~Accepted applications wrongly appeared under Requests → Sent~~ — accepted items now filtered out of Requests (Sent + Received); they belong in Active. | ✅ Fixed 2026-05-31 (pending device re-verify) |
| FX-2 | ~~"Collab"/"collaboration" shown in user-facing copy~~ — renamed to "Kolab" across 61 visible strings; backend contract strings deliberately untouched. | ✅ Fixed 2026-05-31 |
| FX-3 | ~~Bottom nav RenderFlex overflow~~ (pre-existing, commit 846dcac). | ✅ Fixed |

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
