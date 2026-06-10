# Canonical lists (taxonomies) — fetch dynamic, never the placeholders

> **Read this before writing ANY logic that filters, matches, ranks, or displays
> a community type, business type, city, or category.** These lists are
> **backend-owned and dynamic**. Several hardcoded enums exist in the app as
> early-launch placeholders — they do **not** match what the backend actually
> serves and silently collapse unknown values. Using them for logic (e.g.
> interest/type matching) is a bug. Always fetch from the endpoint / provider
> below.

## The lists

| Taxonomy | Dynamic endpoint (source of truth) | App provider | Dynamic model | ⚠️ Placeholder to AVOID for logic |
|---|---|---|---|---|
| **Community types** | `GET /community-types` (fallback `GET /lookup/community-types`) | `communityTypesProvider` (`lib/features/onboarding/providers/onboarding_provider.dart:33`) | `class CommunityType {id,name,slug,icon}` (`lib/features/onboarding/models/community_type.dart`) | `enum CommunityType {greek,fitness,running,business,other}` in `lib/features/community/models/community.dart` |
| **Business types** | `GET /business-types` (fallback `GET /lookup/business-types`) | `businessTypesProvider` (`onboarding_provider.dart:25`) | `BusinessType` (`lib/features/onboarding/models/business_type.dart`) | — |
| **Cities** | `GET /cities` | `citiesProvider` (`onboarding_provider.dart:41` and `opportunity_provider.dart:28`) | `OnboardingCity` (`lib/features/onboarding/models/city.dart`) | — |
| **Categories** | API-driven (verify the exact endpoint before relying on it) | — | — | — |

## ⚠️ The `CommunityType` trap — placeholders on BOTH sides

The REAL community-type vocabulary is the **17 underscore slugs** (`run_club`,
`fitness_community`, `wellness_community`, … `other`) — what a community **picks at
sign-up**. Always fetch it from `GET /lookup/community-types`. Decided 2026-06-10
(Daniel): *unify on it, never use a placeholder again.*

**Source of truth = the DB TABLES** `community_types` / `business_types` (so admins
can add/edit/deactivate types + upload SVG icons at runtime), served by
`/lookup/community-types` + `/lookup/business-types`. The PHP constants
`CommunityOnboardingRequest::COMMUNITY_TYPES` / `BUSINESS_TYPES` are **`@deprecated`**
(seeded into the tables with identical slugs; kept, never deleted). Backend
validation reads `exists:*_types,slug`. See
`kolabing-v2/docs/plans/2026-06-10-type-source-of-truth-DECISION.md`. **App: always
fetch via the endpoint/provider — never the const, never the enum.**

Two **placeholder** `CommunityType` definitions exist — never use either for
validation / matching / ranking / interests:
- ❌ **app** `community/models/community.dart` — `enum {greek,fitness,running,business,other}`. `Community.type` collapses unknown slugs to `other`. (Use the raw `Community.typeSlug` for any logic; the enum is display-fallback only and should be retired.)
- ❌ **backend** `App\Enums\CommunityType` `{greek,fitness,running,business,other}` — was the cast on `communities.type`. As of 2026-06-10 `communities.type` is unified onto the 17-slug list; a community group inherits its type from the owner's `community_profiles.community_type`.

✅ The DYNAMIC ones to use:
- app: `onboarding/models/community_type.dart` (class `{id,name,slug}`) via `communityTypesProvider`.
- backend: validate against `COMMUNITY_TYPES`; `communities.type` now stores those slugs.

### Two "community type" fields (historically diverged, now unified)
- `community_profiles.community_type` — the **marketplace identity** a community
  picks at sign-up (17-slug). The source of truth.
- `communities.type` — the **joinable NF-6 group**. Was a 5-value placeholder;
  **unified onto the 17-slug** vocabulary (inherits from the community profile),
  so discover interest-matching (`interests ∩ communities.type`) is meaningful.

**Rule:** never branch on either placeholder enum, never present its 5 values as
"the community types", never hardcode a type/interest list. Interests, discovery
ranking, filters, pickers → the 17-slug `/community-types`.

## General rule (mirrors CLAUDE.md "Do NOT hardcode")

- No hardcoded city / category / business-type / community-type lists in logic or UI.
  Fetch from the endpoints above. `_mock*` fallbacks stay behind an off-by-default
  flag and must never shadow a successful API call.
- A list a USER PICKS (types/cities/categories/interests) is backend-owned → fetch it.
- If you think you need a hardcoded taxonomy, you're about to ship a placeholder. Stop
  and wire the provider.
