# Ticket — Post an event (or recurring series) as a Kolab

> Status: **designed, not built.** Own slice after recurring events Phase 1 lands.
> Branch: `community-member-flow`. Repos: `kolabing-v2` (backend) + `kolabing-app`.

## Goal
Let a community turn an event into a **Kolab** (a `collab_opportunity` businesses
can apply to). Admin chooses the scope at post time:
- **Whole series as ONE Kolab** — a single recurring opportunity (the
  `collab_opportunities` table already has `recurring_days`, `selected_time`,
  `availability_start/end`). A business sponsors the whole run.
- **Each occurrence as its OWN Kolab** — one opportunity per event; a business
  sponsors a single date.

Once a business is accepted → a `collaboration` is created and linked back to the
event via the existing `events.collaboration_id` (event detail can then show
"Sponsored by …").

## ⚠️ Paywall / ROLES — verify FIRST (docs/ROLES-AND-PERMISSIONS.md + ROLES-BACKEND-DB-MAP.md)
- Communities are **never** paywalled — creating the opportunity is free.
- The business paywall lives on the *consuming* side: a free business sees the
  blurred community name+logo on Explore and the **apply** action is gated. The
  bridge MUST NOT change that gating — it only feeds the existing opportunity →
  application flow. Do not bypass or re-implement the paywall.
- "Opportunity" (community-created) and "collaboration" (business-created) stay
  distinct — do not merge them.

## Backend (kolabing-v2)
- Confirm `OpportunityService::create` contract + `StoreOpportunityRequest` required
  fields (creator_profile_id, title/desc, availability, recurring_days, etc.).
- New endpoints (community manager only — `$profile->can('manage', $community)`):
  - `POST /events/{event}/opportunity` → one opportunity from a single occurrence.
  - `POST /event-series/{series}/opportunity` → one recurring opportunity for the
    series (map series.byweekday → `recurring_days`, time_of_day → `selected_time`,
    starts_on/ends_on → `availability_start/end`).
  - (scope = each → loop occurrences; scope = series → single opportunity.)
- Add a link column if needed: `collab_opportunities.event_id` /
  `event_series_id` (nullable) so we can show "already posted as Kolab" and avoid
  duplicates. Check schema before adding (docs/BACKEND-SCHEMA.md).
- Tests: manager-only; series → recurring opportunity fields mapped; each → N
  opportunities; opportunity is applyable through the normal (paywalled) flow.

## App (kolabing-app)
- On `EventHubScreen` (leader) and/or the series view: a "Post as Kolab" action →
  a scope chooser (Whole series / Each event) when the event is part of a series,
  else a single confirm. Calls the new endpoint(s).
- Surface "Posted as Kolab" state on the event/series once linked.
- All strings translation-ready (en/es/ca) per CLAUDE.md i18n rule.

## Open questions
- Dedup: block re-posting an already-posted event/series, or allow multiple?
- For "each occurrence", create all opportunities up front or lazily per occurrence?
- Does an accepted sponsorship on the series apply to every occurrence's
  `collaboration_id`, or only the ones in the accepted window?
