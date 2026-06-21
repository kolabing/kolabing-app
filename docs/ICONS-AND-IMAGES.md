# Icons & images — how they actually work (read before any icon/taxonomy work)

> Written 2026-06-17 after a mistake: a generic **Lucide** icon gallery was built
> for the admin taxonomies. WRONG. The app renders **personalised illustrated
> SVGs** for categories/taxonomies. Lucide is only for incidental UI chrome.
> Never build a Lucide picker for a user-facing taxonomy.

## 1. Category / taxonomy icons = personalised SVGs (the important one)

Source of truth in the app: `lib/widgets/category_icon.dart` → `CategoryIcon`.

**Resolution order (first match wins):**
1. **`iconUrl`** — an admin-uploaded SVG served over the network. TOP priority.
   `SvgPicture.network(iconUrl)`, with the bundled asset as the load-failure placeholder.
2. **`assetPath`** — explicit bundled asset override.
3. **keyword match on `name`** via `categoryIconAsset(name)` → `assets/icons/categories/category-<key>.svg`.
4. fallback `assets/icons/categories/category-default.svg`.

**Bundled set (24 SVGs)** in `assets/icons/categories/` (declared in `pubspec.yaml`):
art, bar, beauty, cafe, coworking, cycling, default, education, fashion, food,
gaming, gym, health, music, outdoor, restaurant, retail, running, social, sports,
tech, travel, wellness, yoga. `categoryIconAsset` is a case-insensitive partial
keyword map (e.g. "run"/"marathon"→running, "yoga"/"pilates"→yoga, "coffee"→cafe).

**Consequence:** because `iconUrl` wins, **any icon the admin assigns to a taxonomy
row renders in the app with NO app change.** Use `CategoryIcon(name: label, iconUrl: option.iconUrl)`
for every taxonomy picker (offering, needs, deliverables, product_type, venue_type,
business types, community types). `TypeSelectionCard` already wraps `CategoryIcon`.

## 2. The admin personalised-icon library (backend-managed)

- `icons` table + SVG files in `storage/app/public/category-icons/` (served via
  `php artisan storage:link`). Seeded from the 24 app SVGs above; **admins can
  upload more** from the admin "Icons" page.
- Each taxonomy row (`offer_options`, and the type tables) stores **`icon_url`**
  (the chosen library icon's public URL). `icon` (a Lucide name) may remain as a
  legacy/optional fallback but is NOT the personalised icon.
- Every `/lookup/*` endpoint returns `icon_url` alongside `value,label,icon,is_active,sort_order`.
- Deploy-safe: files live in public storage; production runs `composer install` +
  `php artisan storage:link`. No external CDN.

## 3. When Lucide IS fine

Lucide (`lucide_icons` in the app) is fine for **incidental UI chrome** — buttons,
nav, inline affordances, decorative glyphs in screens. It is NOT the system for
**category/business/community/offer taxonomies** — those are personalised SVGs (§1–2).
(The admin had a transient Lucide gallery via `blade-lucide-icons`; it was replaced
by the personalised library. `blade-lucide-icons` may still serve admin chrome.)

## 4. Other media / image handling (so URLs don't break)

- **Relative → absolute URLs:** backend sometimes returns relative media paths.
  The app normalises them with `normalizeRemoteMediaUrl(raw)`. Apply it to any
  remote media field before rendering (e.g. `UserModel.profilePhotoUrl` getter
  normalises; `Kolab.offerPhoto`/`media` are normalised in `fromJson`).
- **Kolab thumbnails:** a kolab's image resolves as offer photo → media → owner
  profile photo → owner gallery (`my_kolab_card.dart`). `offer_photo` lives on
  `collab_opportunities.offer_photo` (exposed by `OpportunityResource`) AND is now
  on `KolabResource` — both must expose it or thumbnails fall back.
- **Profile photos:** `profiles`/`business_profiles`/`community_profiles` photo URLs;
  render via normalised URL.
- **Brand/app icon & favicon:** the canonical brand mark is
  `assets/brand/favicon/icon-512.png` — use it for ALL favicons/app icons.

## 5. The rule
Taxonomy/category icon work — admin OR app — goes through the **personalised SVG
library + `icon_url` + `CategoryIcon`**. Never add a Lucide picker for a taxonomy,
never hardcode an icon list in app code, never assume the app uses Lucide for
categories. See also `docs/CANONICAL-LISTS.md` and `docs/ADMIN-TAXONOMIES-ROADMAP.md`
(backend repo).
