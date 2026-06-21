# Mobile Migration Guide — `/opportunities/*` → `/kolabs/*`

> Tracking: **kolabing-app #20** (mobile) · **kolabing-v2 #30** (backend cleanup, merged via PR #32) · **kolabing-v2 #31** (backend follow-up: shim removal + parity + table drop)
> Source of truth: `CreateKolabRequest` (validation rules) and `KolabResource` in `kolabing-v2`, branch `chore/remove-legacy-collab-opportunities`.

## TL;DR

Two parts, very different risk:

- **SAFE** — URL changes only. Every endpoint already returns the same `KolabResource` body on both paths.
- **BREAKING** — the `create`/`update` **request body** is a different, intent-driven contract (not a rename).

The backend keeps the old `/opportunities/*` endpoints working until this ships, so you can migrate incrementally — but you must finish before backend **#31** removes the shim.

---

## 1 · Endpoint URL mapping — response unchanged

| Old | New |
|---|---|
| `GET /opportunities` | `GET /kolabs` |
| `GET /me/opportunities` | `GET /kolabs/me` |
| `GET /opportunities/{id}` | `GET /kolabs/{id}` |
| `POST /opportunities` | `POST /kolabs` ⚠️ **body change — see §2** |
| `PUT /opportunities/{id}` | `PUT /kolabs/{id}` ⚠️ **body change — see §2** |
| `DELETE /opportunities/{id}` | `DELETE /kolabs/{id}` |
| `POST /opportunities/{id}/publish` | `POST /kolabs/{id}/publish` |
| `POST /opportunities/{id}/close` | `POST /kolabs/{id}/close` |
| `GET /opportunities/{id}/applications` | `GET /kolabs/{id}/applications` (**new**) |
| `POST /opportunities/{id}/applications` | `POST /kolabs/{id}/applications` (**new**) |
| `GET /discovery/opportunities` | `GET /discovery/opportunities` (**no change**) |

Apply-flow request body is unchanged: `{ message, availability }` — `availability` is required, 20–500 chars.

---

## 2 · Create / update body — BREAKING (intent-driven)

The legacy flat model (`business_offer` / `community_deliverables` / `venue_mode`) is replaced by an **`intent_type`** that selects which fields apply. First pick the intent, then send that intent's fields.

### Step A — choose `intent_type`

| Old signal | New `intent_type` |
|---|---|
| Community account (any) | `community_seeking` |
| Business + `venue_mode: business_venue` | `venue_promotion` |
| Business + other | `product_promotion` |

> **Account rules (enforced server-side):** community accounts may ONLY create `community_seeking`. `venue_promotion` requires the business to have a `primary_venue` on its business profile, else the request is rejected (`422`, key `primary_venue`).

### Step B — field mapping

| Legacy field | New field(s) | Notes |
|---|---|---|
| `title`, `description` | `title`, `description` | unchanged (required) |
| `business_offer` | `offering` (business) / `needs` (community) | array of enum codes |
| `community_deliverables` | `expects` (business) / `offers_in_return` (community) | array of enum codes |
| `venue_mode` | `intent_type` + `venue_preference` | preference: `business_provides` / `community_provides` / `no_venue` (community_seeking only) |
| `address` | `venue_address` | max 500 |
| `offer_photo` (single URL) | `media[]` | `[{url, type:image\|video, thumbnail_url?, sort_order?}]`; required for `venue_promotion` |
| `categories` | `community_types` / `seeking_communities` | per intent; `community_types` now usually inherited from profile |
| `availability_*`, `selected_time`, `recurring_days` | same keys | `availability_mode` adds `specific_dates`; required only for `venue_promotion` |
| `preferred_city` | `preferred_city` | required *unless* `venue_promotion` |

### Intent-specific required fields (beyond `title`/`description`)

| `intent_type` | Required |
|---|---|
| `community_seeking` | `needs[]`, `offers_in_return[]`, `typical_attendance`, `preferred_city` |
| `venue_promotion` | `offering[]`, `media[]`, `availability_mode`, `availability_start` |
| `product_promotion` | `offering[]`, `product_name`, `product_type`, `preferred_city` |

> **Enum values are server-defined.** `offering`, `needs`, `offers_in_return`, `expects`, `venue_type`, `product_type` only accept codes from the backend `OfferOption` catalogue. Do **not** hardcode them — fetch the valid option lists from the API and send those codes.

---

## 3 · Response fields to stop reading — deprecating

Application/Collaboration responses currently include backward-compat aliases. They still work today but are removed with the shim in **#31**. Switch now:

| Stop reading | Read instead |
|---|---|
| `collab_opportunity_id` | `kolab_id` |
| `collab_opportunity` | `kolab` |
| `opportunity` | `kolab` |

---

## 4 · Backend parity delivered before shim removal (#31)

These exist only on the legacy path today; the backend will port them to `/kolabs` before removing `/opportunities`, so behaviour is preserved — just verify after the backend follow-up lands:

- **Freemium / paywall collaboration limit** on `POST /kolabs` — confirm the limit error still surfaces on create.
- **Creator `portfolio_photos`** in `GET /kolabs/{id}` (detail) — confirm detail screens still render photos.

---

## 5 · Migration checklist

- [ ] Repoint all 10 endpoints to `/kolabs/*` (§1); leave `discovery/opportunities`.
- [ ] Adopt `GET`/`POST /kolabs/{id}/applications` for the apply flow.
- [ ] Rebuild the create/edit form around `intent_type` (§2): map fields, fetch enum option lists from API.
- [ ] Handle the two server-side rules: community → `community_seeking` only; `venue_promotion` needs `primary_venue`.
- [ ] Read `kolab_id`/`kolab` in responses; drop `collab_opportunity*` / `opportunity` (§3).
- [ ] Regression-test create, publish, close, apply, list-applications, and detail (photos) end-to-end.
- [ ] Coordinate release with backend **#31** (don't ship after the shim is removed without this done).
