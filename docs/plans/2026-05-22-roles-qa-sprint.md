# Kolabing — Roles QA Sprint Plan (2026-05-22)

**Contract:** every task obeys [`docs/ROLES-AND-PERMISSIONS.md`](../ROLES-AND-PERMISSIONS.md) + [`docs/ROLES-BACKEND-DB-MAP.md`](../ROLES-BACKEND-DB-MAP.md). Each agent must read both before coding.
**Repos:** `kolabing-app` (Flutter, branch `fix/kolabing-qa-followup`) + `kolabing-v2` (Laravel). ⚠️ `kolabing-v2` push is currently DENIED for `SerraWealth` — backend work commits locally until access is granted.

**Locked product decisions (2026-05-22):**
1. Source of truth = the new **`kolabs` / `/kolab/flow`** system. Route all NEW creation to kolabs and retire the legacy create screens. **Do NOT migrate** old `collab_opportunities` rows — leave existing ones readable/closable in place (two systems coexist for legacy rows only).
2. Free-business Explore = **blur the community logo image AND name** (visual blur), all Kolab details visible, reveal on subscribe. No hard block.
3. Account deletion = **free the email + close the user's open posts + cancel active/scheduled collaborations (in-app notify to counterparty) + keep completed collaborations**.
4. **Subscription lapse** = the lapsed business's ongoing collaboration/chat screens are **blurred + "Resubscribe to continue" prompt** until resubscribe; the community counterparty is never affected (canonical doc §2.8).
5. **Feedback forms** are built and **required to finish** a collaboration (both sides).
6. **Dashboard rich metrics are DEFERRED** (noted future required update): business revenue + IG-followers-gained, and community points/credits + progress are NOT built this sprint. The "home widget broken" fix only restores rendering of data that already exists (e.g. collab counts); the gamified/performance metrics are a follow-up that the feedback forms (decision 5) will eventually feed.
7. Minor: type tags formatted **server-side**; community location = neighbourhood/area (Google Places) + city; community photo picker = profile gallery + past-event photos; "notify" = in-app notification; UI terms: opportunity = community post, collaboration = accepted match.

---

## Execution model
Parallel agents per wave, **disjoint file ownership** (listed). Agents do NOT commit or run repo-wide formatters; the integrator (main session) verifies + commits per wave. Backend and client agents in the same wave touch different repos, so they parallelize cleanly. A wave is gated by `flutter analyze` (0 new errors) + `flutter test` (no new failures) + `php -l` on changed files.

---

## WAVE 1 — Critical correctness + visible breakage (parallel, independent of the post-system refactor)

**A1 · Backend role-gate hardening (kolabing-v2)** — fixes "communities blocked from creating".
- `KolabService::publish` (`app/Services/KolabService.php:171`): add `&& $creator->isBusiness()` to the subscription gate so a community can never be blocked.
- Audit `ApplicationController` apply path: a free business is gated (paywall/402), a community is **never** gated. Add an explicit `isBusiness()` guard if missing.
- Re-confirm `OpportunityService` gates are `isBusiness()`-guarded (they are) — no change unless a gap is found.
- Owns: `KolabService.php`, `ApplicationController.php` (+ApplicationService if present). Read-only ref: `Profile.php`.

**A2 · Backend account deletion (kolabing-v2)** — critical data integrity.
- `ProfileService::deleteProfile` (`:89`), in a transaction: free the email (scrub/rename, e.g. `deleted+{id}@kolabing.invalid`, or make the unique index `deleted_at`-aware), close the user's open `kolabs`/`collab_opportunities`, **cancel** their active/scheduled `collaborations` and send an **in-app notification** to the counterparty, leave `completed` collaborations intact.
- Migration only if the email-uniqueness approach needs it.
- Owns: `ProfileService.php`, `ProfileController.php` (`destroy`), one migration if needed. Disjoint from A1.

**A3 · Client Explore blur + community-block client check (kolabing-app)**
- Replace the free-business hard-block (`explore_screen.dart:96-108` paywall-as-gate) with: keep the user on Explore, **blur logo image + name** for community-authored cards, keep all details, gate ONLY the apply/create buttons (button → paywall sheet).
- Wire the already-computed `hideCreatorIdentity` (`explore_screen.dart:71`) into a real blur in `ExploreSwipeCard` + `community_offer_detail_screen.dart`. Reuse a small `BlurredIdentity` widget.
- Fix the role-string casing risk: `intent_selection_screen.dart:51-52` compares `userType?.name == 'community'/'business'` — make role resolution case-insensitive / enum-safe so a community is never misrouted into the business branch.
- Owns: `explore_screen.dart`, `explore_swipe_card.dart`, `explore_detail_sheet.dart`, `community_offer_detail_screen.dart`, `intent_selection_screen.dart`, new `lib/widgets/blurred_identity.dart`.

**A4 · Profile breakage (kolabing-v2 + kolabing-app)** — logo, past events, view-profile, type tags.
- Backend: `PublicProfileResource` returns the logo from the correct column (`business_profiles.profile_photo`/`community_profiles.profile_photo`, fallback `profiles.avatar_url`) as an **absolute** URL; ensure `profileCollaborations` eager-loads `event` and `completed_at` is populated on finish.
- Client: render the logo; fix Past Events section; "View business/creator profile" must navigate with a **`profiles.id`** (trace the collaboration→profile link and fix the id passed); align type-tag formatting to one side.
- Owns (backend): `PublicProfileResource.php`, `ProfileController.php`. Owns (client): `public_profile*` screens/models, the collaboration→profile nav call, `profile_type_formatter.dart`. Coordinate the id contract.

> Wave 1 gate: analyze/test/lint clean; manual smoke on simulator (community can create; free business sees blur not block; a profile logo loads).

---

## WAVE 2 — Foundational refactor + feature builds (after Wave 1 verified)

**B1 · Standardize on kolabs; retire legacy create (kolabing-v2 + kolabing-app)** — sequenced, highest risk.
- Confirm the live apply→collaboration wiring runs on the `kolabs` system; ensure all NEW applies/collaborations target kolabs.
- **No migration of old `collab_opportunities` rows.** Leave existing legacy rows readable/closable in place; just stop creating new ones there.
- Client: route community "My Opportunities → Create" and business legacy create to `/kolab/flow`; redirect/remove `create_opportunity_screen` + `create_collab_request_screen` (the LEGACY-banner screens).
- Do as a focused design → review → implement; gate before dependent UI work.

**B2 · Home widget breakage fix only — rich metrics DEFERRED (kolabing-app, light backend)**
- In scope: fix whatever makes the home widget "broken" on both sides so it renders the data that ALREADY exists (collab counts, application stats) — likely a JSON-key / enum / `scheduled_date` parsing mismatch between `DashboardService` and the client `BusinessDashboard`/`CommunityDashboard` models.
- DEFERRED (future required update, noted): business revenue + IG-followers-gained aggregation, and community points/credits + €75 progress + next-goal CTA. The feedback forms (B5) capture the inputs now; the dashboard consumption ships later.

**B3 · Community Kolab creation cleanup (kolabing-app)**
- On `/kolab/flow` communitySeeking: remove any venue ask; add **preferred neighbourhood/area** field (Google Places) alongside city; wire the photo step to pick from the community's **profile gallery + past-event photos** (not upload-only).
- Owns: `lib/features/kolab/screens/community/*`.

**B4 · Auth session on logout→login (kolabing-app, +backend verify)**
- Fully clear cached auth/profile/Riverpod state on logout so a fresh login can't read a stale session ("auth session experience error"). Verify token revoke on the backend logout endpoint.

**B5 · Feedback forms (kolabing-v2 + kolabing-app) — REQUIRED to finish**
- Two-way completion feedback per the doc §4 (business: stars, stories, posts/reels, revenue, expectation match, recommend; community: stars, benefits, posts/reels, expectation match, recommend).
- **Required to finish a collaboration** — both sides must submit before the collaboration closes. Persist the captured fields (they feed the deferred dashboard metrics in B2).

**B6 · Subscription-lapse re-gate (kolabing-v2 + kolabing-app)** — per canonical doc §2.8.
- When a business's subscription is inactive but it has ongoing collaborations/chats, the business sees those screens **blurred with a "Resubscribe to continue" prompt** (cannot read/act) until it resubscribes. The community counterparty is NEVER affected.
- Backend exposes the lapse state; client blurs the business-side ongoing collaboration/chat surfaces only.

**B7 · Onboarding — render Google Maps imported photos (kolabing-app, +backend verify)** — per canonical doc §2.2.
- On business venue onboarding (the Google Maps lookup step), the API pre-populates name/photos/details. The imported **photos must render in a preview**, and the user must be able to **delete individual imported photos**.
- Currently the imported photos don't render. Likely the same image-URL handling as the gallery (ensure the Google-sourced photo URLs are absolute/usable) + a preview grid with per-photo delete. Confirm the backend returns usable photo URLs from the Places import; fix client preview + delete.
- Owns (client): `lib/features/onboarding/screens/business/*` (the venue/Places step). Verify backend Places-import photo URLs.

---

## WAVE 3 — Polish + section-4 items + test pass

- Offer-display styling on the business side to match the cleaner community styling.
- Kolab creation flow stability (no close-and-reopen needed to load).
- Edit a collaboration's date/time; Finish a collaboration; dates-available constraint on apply; name of counterparty shown in chat; neighbourhood shown on community Explore; "Community reach" → "Minimum amount of people"; type chip formatting ("Run_Club" → "Run Club"); Google-photos preview on business onboarding.
- Full QA test pass across both roles on the simulator.

---

## Cross-cutting guardrails (every wave)
- Communities are NEVER paywalled/blocked. The paywall is Business-only, on exactly two actions.
- Free business = blur, never hard block.
- Keep "opportunity" (community post) and "collaboration" (accepted match) distinct in labels.
- Touch attendee code only if explicitly asked.
- Backend changes commit locally until `kolabing-v2` push access is restored.
