# Onboarding update — consolidated plan (LOCAL, not pushed)

> Status: design/plan only. Build held until the kolab-table migration (below) is decided.
> Keep this branch/doc local until the update is ready.

## 1. Business onboarding redesign (goal-based)
- **S1 Goal:** "Fill my venue" (`has_venue=true`) vs "Promote a product/service" (`has_venue=false`).
- **Venue path:** Goal → Venue lookup via Google Places (pulls name, **category from `place_types`** (editable), venue_type, city, address, photos, hours, capacity) → venue photos → about/contact → login → auto-offer.
- **Product path:** Goal → Identity (name + category pills + logo) → **multi-select cities (≤3 free / unlimited Premium)** (+ optional "what you offer" + photos) → about/contact → login → auto-offer.
- **Backend:** `business_profiles.has_venue` (bool, default true); `primary_venue` `required_if:has_venue,true`; require city when no venue; accept `target_city_ids[]`. Discovery already null-safe on `primary_venue`.

## 2. Community onboarding additions
- Add **community size** (stable) to onboarding.
- **typical_attendance** stays per-kolab (varies Tue–Sun) but **pre-fills from the last kolab** as a template.
- Remove the self-describing fields (community type/size) from the kolab/opportunity creation flow (inherit from profile); city defaults from profile.

## 3. Auto-first-offer (free visibility, premium depth)
- On finishing onboarding, **auto-create one real kolab** from the profile (server-side, composed via the validated mapping: intent, `offering[]`, deliverables, community_types, city, venue_type/product_type, media, availability defaults). **Publish live immediately.**
- **Free tier = exactly one auto-offer, non-editable.** Premium unlocks the normal create/edit modal + more offers + commission comp + >3 cities. (Backend-enforced, reuses the Business paywall; communities stay free.)
- Mapping table validated against `CreateKolabRequest` (offering/deliverable/need slugs). See chat 2026-06-16.

## 4. Admin-editable offer taxonomy (IN PROGRESS on `feat/admin-offer-taxonomy`)
- `offer_options` table keyed by `kind` (offering|deliverable|need) + admin CRUD + lookup endpoints; app pickers fetch dynamically with hardcoded fallback.
- Done: business "what you offer", community needs ("what are you looking for"), community deliverables (event_details).
- Deferred: `create_opportunity_screen` (legacy Opportunity boolean model — needs the migration below); review chips still use enum `displayName`.

## 5. NEW — Community verification (added 2026-06-16, Daniel; refined)
**What:** Communities submit **proof-of-realness links during onboarding** — alongside the existing Instagram: **Strava** (club), **WhatsApp group invite link**, website/TikTok (+room for Meetup/Discord/Eventbrite). These are the community's **"sources of truth."**
**Where verification happens (refined):** **NOT** an automated/queue flow — it's a **manual admin action from the admin dashboard**: an admin opens a **community's profile** in the admin panel, opens a **"Verify" modal**, which **displays the sources of truth the community submitted at onboarding** (the links), and the admin marks them **Verified** (or rejects). Copy to the community: after a few days, real communities get a **Verified badge that businesses see**.
**Why:** businesses need to trust a community is real before collaborating; Verified is a trust signal + differentiator.
**Scope:**
- **Onboarding UI (app):** a "Verify your community" section collecting the links (Instagram [existing], Strava, WhatsApp group, website/TikTok). All optional but encouraged; copy explains the few-days review → Verified badge.
- **Community profile (app):** show the submitted sources of truth + the Verified badge once granted.
- **Backend (`community_profiles`):** link fields (`strava`, `whatsapp_group_url`, … or a generic `links` JSON) + `verification_status` (`unverified | pending | verified | rejected`) + `verified_at` + who verified.
- **Admin dashboard:** on the community profile page, a **Verify modal** rendering the submitted links (clickable to check) + a Verify/Reject action that sets `verification_status`. Mirror the existing admin Blade modal patterns.
- **Business-facing:** expose `is_verified`/badge on community profiles, Explore cards, applications/collaborations.
- **Lifecycle:** onboarding submit → `pending` (or `unverified` until reviewed); admin Verify modal → `verified`; badge appears to businesses.
- i18n en/es/ca for all new app strings.
- **[VERIFY with Daniel]:** exact v1 link set; badge visual + placement.

## 6. DECISION — kolab is the full source of truth (2026-06-16, Daniel)
Chosen over the quick app-only fix. Migrate applications/collaborations/dashboard/lists off `collab_opportunities` onto `kolabs`. See `docs/plans/2026-06-16-kolab-source-of-truth-migration.md`. The auto-offer (#3), create_opportunity taxonomy wiring (#4), and the Offers list/edit fixes all sit on top of this migration.

## Dependencies / sequencing
- The kolab-table migration (kolabs vs collab_opportunities) should land before/with the auto-offer + create_opportunity taxonomy wiring (those touch the offer create/list paths).
- Verification (#5) is independent and can ship on its own.
