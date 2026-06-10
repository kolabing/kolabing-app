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

## ⚠️ The `CommunityType` trap (two symbols, same name)

There are **two** things called `CommunityType`:
1. ✅ **`onboarding/models/community_type.dart`** — a **class** (`id/name/slug`) populated from `GET /community-types`. This is what a community actually picks at sign-up (`community_step2_screen`). **Use this for any type logic.**
2. ❌ **`community/models/community.dart`** — an **enum** `{greek, fitness, running, business, other}`. A launch-era placeholder. `Community.type` parses the backend slug into it and **maps every unrecognized slug to `other`** — so filtering/matching/ranking on this enum is lossy and wrong.

**Rule:** never branch on the placeholder enum's values, never present them as "the community types", and never hardcode a type/interest list from them. For interest matching, discovery ranking, filters, or pickers, read `/community-types`.

## General rule (mirrors CLAUDE.md "Do NOT hardcode")

- No hardcoded city / category / business-type / community-type lists in logic or UI.
  Fetch from the endpoints above. `_mock*` fallbacks stay behind an off-by-default
  flag and must never shadow a successful API call.
- A list a USER PICKS (types/cities/categories/interests) is backend-owned → fetch it.
- If you think you need a hardcoded taxonomy, you're about to ship a placeholder. Stop
  and wire the provider.
