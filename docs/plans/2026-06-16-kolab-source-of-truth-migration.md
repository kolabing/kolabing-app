# Kolab as the single source of truth — migration plan (LOCAL)

> Decision (Daniel, 2026-06-16): make `kolabs` the canonical opportunity entity.
> Retire `collab_opportunities` as a storage layer; keep its API shape only as a
> read compatibility view until the app fully moves over. Build on branches, local.

## Why
- Create / Explore / Discovery / edit already run on `kolabs`. `kolabs` is the richer,
  intent-based model (venue/product/community, offering[], deliverables, availability).
- `collab_opportunities` only exists because `applications` + `collaborations` FK to it,
  and it is materialized lazily by `LegacyOpportunityBridgeService` **only on first apply**.
- Net effect of the split: a freshly created kolab is invisible to the Offers list and the
  dashboard (they read `collab_opportunities`), and edits can mismatch. This is the bug
  Daniel hit ("kolab shows in admin but not in published offers; can't edit image").

## Current wiring (verified 2026-06-16, kolabing-v2)
- `applications.collab_opportunity_id` → `collab_opportunities.id` (unique with applicant).
- `collaborations.collab_opportunity_id` → `collab_opportunities.id`; `application_id` unique.
- Apply: `ApplicationController.store()` → bridge `resolveOrFail($id, persist=true)` →
  persists a `collab_opportunities` row **with id = kolab.id** → `ApplicationService.apply()`
  writes `collab_opportunity_id = kolab.id`. **So the FK value already equals the kolab id.**
- Dashboard (`DashboardService`) + `/me/opportunities` (`OpportunityController.myOpportunities`)
  read `collab_opportunities`. Discovery (`DiscoveryOpportunityService`) reads `kolabs`.
- KEY: because the bridge persists with `id = kolab.id`, `collab_opportunity_id` is already a
  kolab id for every kolab-originated row. The migration is mostly **re-pointing reads** + a
  backfill for any legacy rows whose id is NOT a kolab.

## Target end state
- `applications.kolab_id` → `kolabs.id`; `collaborations.kolab_id` → `kolabs.id`.
- All reads (Offers list, dashboard, applications, collaborations) come from `kolabs`.
- `collab_opportunities` table dropped; the `/opportunities*` endpoints either alias to
  kolabs server-side or are removed once the app stops calling them.

## Phases (each independently shippable, backward-compatible until Phase 4)

### Phase 1 — additive foundation (backend, branch `feat/kolab-sot-phase1`) ← START HERE
Backward-compatible, no drops, no app change required to keep working.
1. Migration: add nullable `kolab_id` (uuid, FK→kolabs, indexed) to `applications` and
   `collaborations`. Keep `collab_opportunity_id` for now.
2. Backfill: `UPDATE ... SET kolab_id = collab_opportunity_id WHERE collab_opportunity_id IN (SELECT id FROM kolabs)`.
   (Safe because the bridge persisted with id = kolab.id.) Log/flag any rows where
   `collab_opportunity_id` is NOT a kolab id (true legacy opportunities) — these need a
   one-off `kolabs` row created from the opportunity (inverse bridge) before they can be re-pointed.
3. Dual-write: in `ApplicationService.apply()` and `createCollaboration()`, set BOTH
   `kolab_id` and `collab_opportunity_id`.
4. Eloquent: add `kolab()` BelongsTo on Application + Collaboration; add `applications()` /
   `collaborations()` HasMany on `Kolab` (keyed on `kolab_id`).
5. Add an **inverse bridge** path: ensure a `kolab` exists for any apply target (if the
   target id is a legacy collab_opportunity with no kolab, create the kolab from it). Going
   forward, prefer creating against kolabs.
   Tests: apply→accept→collaborate produces matching `kolab_id` on both tables.

### Phase 2 — re-point reads (backend, branch `feat/kolab-sot-phase2`)
6. `OpportunityController.myOpportunities` (/me/opportunities): UNION/return kolabs for the
   viewer (so newly created kolabs list immediately). Keep response shape identical
   (OpportunityResource fields) so the app needs no change.
7. `DashboardService`: count/query off `kolabs` + `applications.kolab_id` +
   `collaborations.kolab_id` instead of `collab_opportunities`.
8. Application/Collaboration resources: source opportunity sub-object from `kolab` when present.
   ALSO fixes the dashboard parse bug surfaced separately (verify /me/dashboard payload).

### Phase 3 — app moves to kolab endpoints (app, branch `feat/kolab-sot-app`)
9. Community + business Offers list/edit → `/kolabs/me` + `/kolabs/{id}` (business already does).
10. create_opportunity_screen → kolab create model (retire the legacy Opportunity boolean
    model: discount %, products[], "other" text → map into kolab needs/offering/deliverables).
    This also unblocks the deferred admin-taxonomy wiring (#4 in onboarding plan).

### Phase 4 — drop legacy (backend, branch `feat/kolab-sot-cleanup`)
11. Remove dual-write; make `kolab_id` non-null; drop `collab_opportunity_id` + the table;
    convert `/opportunities*` to thin aliases over kolabs or remove. Update BACKEND-SCHEMA.md.

## Risks / guards
- Legacy collab_opportunities whose id is NOT a kolab (pre-bridge rows): must create kolabs
  for them in Phase 1 backfill or they orphan. Count them first.
- Keep API response shapes stable through Phase 2 so the app keeps working unchanged.
- Each phase behind tests; no destructive step before Phase 4.
