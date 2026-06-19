# Plan — `/opportunities/*` → `/kolabs/*` mobile migration (kolabing-app #20)

Source of truth: `docs/api/legacy_migration.md`.

## Discovered state (before)

- **§2 create/update (BREAKING) is ALREADY DONE.** Creation is fully on `/kolab/flow`
  (`KolabService` → `POST/PUT /kolabs`, body = `kolab.toJson()` incl. `intent_type`;
  publish/close/delete via `my_kolabs_provider` → `KolabService`). OfferOption enum
  catalogue fetched from `/lookup/*` (`offer_option_provider.dart`). Routes hard-redirect
  legacy create → kolab flow. ⇒ **no create-form rebuild needed.**
- Explore/browse uses `DiscoveryService` → `/discovery/opportunities` (**unchanged** — leave).
- **Still legacy / to fix:**
  1. Apply flow: `application_service.submitApplication` → `POST /opportunities/{id}/applications`.
  2. `OpportunityService` reads/lifecycle on `/opportunities` — of these, **`getOpportunity`
     is live** (`opportunityDetailProvider` → `community_offer_detail_screen` + `/opportunity/:id`).
  3. Models still read `collab_opportunity*` / `opportunity`.

## Changes

### A. Apply flow (`lib/features/application/services/application_service.dart`)
- `submitApplication`: URL `/opportunities/{id}/applications` → `/kolabs/{id}/applications`.
  Body (`{message, availability}`) unchanged. Id is the kolab id.

### B. Legacy reads/lifecycle (`lib/features/opportunity/services/opportunity_service.dart`)
Repoint to `/kolabs` (response is identical `KolabResource` on both paths):
- `getOpportunity` `/opportunities/{id}` → `/kolabs/{id}` **(live)**
- `getOpportunities` `/opportunities` → `/kolabs`
- `getMyOpportunities` `/me/opportunities` → `/kolabs/me`
- `publishOpportunity` `/opportunities/{id}/publish` → `/kolabs/{id}/publish`
- `_publishViaStatusUpdate` `/opportunities/{id}` → `/kolabs/{id}`
- `closeOpportunity` `/opportunities/{id}/close` → `/kolabs/{id}/close`
- `deleteOpportunity` `/opportunities/{id}` → `/kolabs/{id}`
- **LEAVE `createOpportunity` / `updateOpportunity` on `/opportunities`** — they send the
  legacy flat body and are dead (kolab flow is the active path). Repointing them without a
  body rebuild would 422. Add a deprecation note.

### C. Response fields — kolab-first, legacy fallback (§3, survives #31 shim removal)
- `application/models/application.dart`: `opportunityId` ← `kolab_id` ?? `collab_opportunity_id`
  ?? `opportunity_id`; nested object ← `kolab` ?? `collab_opportunity`.
- `collaboration/models/collaboration.dart`: nested ← `kolab` ?? `opportunity`.
- `dashboard/models/dashboard_model.dart`: nested ← `kolab` ?? `opportunity`.
- `collaboration/providers/collaboration_detail_provider.dart`: ← `kolab` ?? `collab_opportunity`.
- `discovery/models/discovery_item.dart`: add `kolab_id` (direct keys) and `kolab` (nested
  candidates) to the FRONT of the existing resolver lists.

## Out of scope / verify-after-backend (#31, §4)
- Paywall limit on `POST /kolabs` (KolabService already handles 402/`ApiException`).
- Creator `portfolio_photos` on `GET /kolabs/{id}` detail.

## Automated verification (done)
- `flutter analyze` clean on the 7 changed files (no new errors/warnings).
- 27 tests pass across `application`, `discovery`, `dashboard`, `opportunity`.
- Adversarial 3-agent workflow: **PASS** — no missed `/opportunities` API call site; apply id is
  the kolab id; response fallbacks null-safe; kolab create flow untouched.

## Manual verification (simulator) — how to check this case

> Tip: every migrated call logs its URL. Watch the `flutter run` console — you should see
> `…/kolabs/…` and **never** `…/opportunities/…` (except `discovery/opportunities`, which is
> intentionally unchanged). Filter the console for `KolabService:`, `OpportunityService:`,
> `ApplicationService:`.

1. **Apply to a Kolab (the headline fix).** As a **Community** account, open Explore → tap a
   business Kolab → **Apply**, fill availability (20–500 chars) → submit.
   - ✅ Expect success; console shows `ApplicationService: POST …/kolabs/<id>/applications`
     (NOT `/opportunities/...`). The application appears under My Kolabs → Requests.

2. **Kolab/offer detail.** Open a Kolab detail (`/opportunity/:id` route, e.g. business tapping a
   community offer on Explore, or opening one of your own).
   - ✅ Detail loads with title/description/photos; console shows
     `OpportunityService: GET …/kolabs/<id>`.

3. **Manage your Kolabs (business & community).** My Kolabs → Offers: open one and
   **Publish**, then **Close**, then **Delete** a draft.
   - ✅ Each succeeds; console shows `…/kolabs/<id>/publish`, `…/kolabs/<id>/close`,
     `DELETE …/kolabs/<id>`. My Kolabs list (`/kolabs/me`) refreshes correctly.

4. **Create a Kolab (regression — should be unchanged).** FAB → choose an intent
   (community-seeking / venue / product) → complete the steps → publish.
   - ✅ Still works; console shows `KolabService: POST …/kolabs` with an `intent_type` body.

5. **Collaboration detail & dashboard.** Open an active/finished collaboration; open the Home
   dashboard with an upcoming collaboration.
   - ✅ The linked Kolab info (title) renders. These now read the `kolab` field first and fall
     back to the legacy `opportunity` field, so they render whether the backend sends the new or
     old key.

6. **Explore feed (regression — intentionally unchanged).** Browse Explore as both roles.
   - ✅ Feed loads via `DiscoveryService: GET …/discovery/opportunities` (this path is correct
     and must stay on `/discovery/opportunities`).

### After backend #31 lands (shim removal) — re-verify (§4)
- Paywall: a free business hitting its collaboration limit on create still gets the limit message
  (KolabService handles `402`).
- Detail photos: creator `portfolio_photos` still render on `GET /kolabs/{id}`.
