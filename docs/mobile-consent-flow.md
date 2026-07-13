# Mobile Consent Flow — Terms of Service + Privacy Policy

**Last updated:** 2026-07-13
**Status:** Authoritative. Mirrored from `kolabing-v2` (backend spec + PR #85 / issue #84). Keep the two copies identical.
**Scope:** All roles (Business, Community, Attendee). This is a legal requirement — App Store / Google Play submission and GDPR / LOPDGDD (Spain) provable-consent.

> The backend is **already shipped and merged** (`kolabing-v2` PR #85). This document is the contract the app implements against. See the app-side ticket `kolabing-app#67` (dup of `#65`).

---

## 1. Legal pages (link out — do NOT re-render the text in-app)

| Page    | English (default)              | Spanish                              |
| ------- | ------------------------------ | ------------------------------------ |
| Terms   | `https://kolabing.com/terms`   | `https://kolabing.com/es/terms`      |
| Privacy | `https://kolabing.com/privacy` | `https://kolabing.com/es/privacy`    |

Link to the locale matching the device language; **default to English** for every non-Spanish locale (including Catalan — there is no `/ca/` page). The links open the external marketing site.

App implementation: `lib/config/constants/legal.dart` (`LegalLinks.termsUrl` / `privacyUrl`).

---

## 2. Sign-up consent (all sign-up entry points)

A **mandatory** "I agree to the Terms of Service and Privacy Policy" checkbox with tappable links is shown on every sign-up path. The primary submit button (and the Google / Apple buttons where present) stays **disabled until the checkbox is checked**.

App implementation: `lib/features/auth/widgets/terms_consent_checkbox.dart`, wired into:
- `lib/features/auth/screens/attendee_register_screen.dart` (email + Google + Apple)
- `lib/features/onboarding/screens/business/business_final_screen.dart` (email)
- `lib/features/onboarding/screens/community/community_final_screen.dart` (email)

### Email / password
`POST /api/v1/auth/register/{business|community|attendee}` now require **`accepted_terms: true`** in the body. Missing or `false` → `422`:

```json
{ "success": false, "message": "Validation failed",
  "errors": { "accepted_terms": ["You must accept the Terms of Service and Privacy Policy"] } }
```

The button gate means this should not normally fire; if it does, the `422 accepted_terms` message is surfaced to the user. `accepted_terms` is **not** in the not-yet-migrated field-strip retry set, so it can never be silently dropped.

### OAuth (Google / Apple)
`POST /api/v1/auth/google` and `POST /api/v1/auth/apple` are **unchanged** — no new required field. When these create a new account, consent is recorded server-side automatically. The consent checkbox is still shown in the sign-up UI and still gates the buttons.

Already-signed-in social users completing business onboarding see a **passive consent notice** (consent was recorded at account creation) rather than a re-checkbox.

---

## 3. Current user / re-consent state

`GET /api/v1/auth/me` → `data.user` includes a `terms` block:

```json
"terms": {
  "current_version": "2026-07-12",
  "accepted_version": "2026-07-12",
  "accepted_at": "2026-07-12T16:00:00+00:00",
  "needs_acceptance": false
}
```

- **Never hardcode the version in the app** — always read `terms.current_version` from `/auth/me`.
- Older payloads without a `terms` block → treat `needs_acceptance` as `false`.

App implementation: `UserTerms` in `lib/features/auth/models/user_model.dart`; gate flag `AuthState.needsTermsConsent` in `lib/features/auth/providers/auth_provider.dart`.

---

## 4. Re-consent gate (blocking)

On app launch **and** on resume, after `/auth/me`, if `terms.needs_acceptance == true` the app shows a **blocking** full-screen re-consent gate (the user cannot proceed) with the legal links + an **Accept** action.

`POST /api/v1/me/consent` (authenticated, empty body) → records acceptance of the current version; returns the refreshed `terms` block with `needs_acceptance: false`. On success the app refreshes the user and the gate clears.

App implementation: `lib/features/auth/widgets/reconsent_gate.dart` (blocking `PopScope`), wired in `lib/main.dart` (`WidgetsBindingObserver` → `refreshUser()` on resume; `ReconsentGate` overlay when `needsTermsConsent`). Accept → `AuthService.acceptTerms()` (`POST /me/consent`) → `refreshUser()`.

---

## 5. Locale

EN by default; ES when the device language is Spanish — for both the links (`/es/…`) and the re-consent sheet copy. Consent + re-consent strings are localized in `app_en.arb`, `app_es.arb` (European Spanish) and `app_ca.arb` (Catalan), via `flutter gen-l10n`.

---

## 6. Acceptance criteria (app)

- [x] Consent checkbox on all sign-up paths (email, Google, Apple); primary button disabled until checked.
- [x] Email/password register sends `accepted_terms: true`; `422 accepted_terms` surfaced.
- [x] Google/Apple sign-up shows the checkbox, sends no extra field.
- [x] `terms` block parsed from `/auth/me`; version never hardcoded; absent block → no gate.
- [x] Blocking re-consent gate on launch + resume; Accept → `POST /me/consent` → refresh → gate clears.
- [x] EN default / ES for Spanish; strings in en/es/ca.
