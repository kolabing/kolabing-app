# Attendee Google + Apple login — design

> Date: 2026-06-11 · Owner: Volkan · Status: approved, implementing
> Branch: `feat/attendee-social-login`

## Goal

Let users **sign up / sign in as an attendee** (`user_type='attendee'`) via **Google** and
**Apple**, reusing the existing social-login widgets and auth methods. A brand-new social
attendee flows into the existing **4-step attendee onboarding** (You · City · Interests ·
Join) with their name **prefilled** from the provider; they still choose a unique `@handle`.

- **Google works against the live backend today** — `POST /auth/google` already accepts and
  honors `user_type` (incl. `'attendee'`) and auto-creates the `attendee_profiles` row. The
  client simply never passes `user_type='attendee'` from an attendee surface yet.
- **Apple needs a backend change** — `POST /auth/apple` does **not** accept `user_type`. The
  Apple path is implemented end-to-end on the client but kept **behind an off-by-default
  feature flag** on the attendee surface until the backend honors `user_type`. A backend
  ticket is filed in `kolabing-v2`.

## Decisions (locked, from brainstorming 2026-06-11)

1. **New social attendee → attendee onboarding** (4-step), name prefilled from the provider,
   `@handle` still required. (Not "step 1 only", not "skip onboarding".)
2. **Google now, Apple flag-gated.** Ship Google attendee immediately. Implement Apple
   client-side but gate the Apple button on the attendee surface behind
   `attendeeAppleSignupEnabled` (default **false**); flip on once the backend deploys. File a
   backend ticket for the `/auth/apple` `user_type` change.
3. **Placement: attendee register screen.** Add Google + Apple buttons below the
   email/password form on `attendee_register_screen.dart` (mirroring `login_screen`).
   Returning attendees already sign in via the shared `login_screen`.

## Current state (from research, cite-checked)

- Widgets already exist and are reusable:
  `lib/features/auth/widgets/google_sign_in_button.dart`,
  `lib/features/auth/widgets/apple_sign_in_button.dart` (both take a `buttonText` param).
- Used today on `lib/features/auth/screens/login_screen.dart` (Google + Apple) and
  `sign_in_screen.dart` (Google only) — for returning users of any role.
- `auth_service.dart`: `loginWithGoogle()` / `_authenticateWithGoogle()` already send an
  optional `user_type`; `loginWithApple()` / `_authenticateWithApple()` send only
  `identity_token` + optional `name` (no `user_type`).
- `auth_provider.dart`: `signInWithGoogle()` / `signInWithApple()` exist (login only); no
  `userTypeHint`.
- `auth_navigation.dart` `resolveAuthDestination()`: attendees always route to the attendee
  dashboard with **no onboarding** today.
- Attendee email/password registration (`registerAttendee` → `/auth/register/attendee`)
  routes to `/onboarding/attendee/step1` on success. Onboarding lives in
  `lib/features/onboarding/screens/attendee/attendee_step1..4_screen.dart` +
  `attendee_onboarding_provider.dart` (`AttendeeOnboardingData`: name, handle, cityId,
  interests, communityIds, photoBase64).
- Native config present: iOS Google URL scheme + `GoogleService-Info.plist`, Apple Sign-In
  entitlement (`Runner.entitlements` / `Runner.Debug.entitlements`), `google_sign_in 6.2.1`,
  `sign_in_with_apple 7.0.1`.
- i18n: `signInWithGoogle` exists in en/es/ca; **no `signInWithApple` key** (button text is
  hardcoded today).

## Architecture / changes (layered)

### 1. Auth service — `lib/features/auth/services/auth_service.dart`
- Add an optional `UserType? userType` to `loginWithApple(...)` and
  `_authenticateWithApple(...)`; when non-null, include `'user_type': userType.toApiValue()`
  in the `/auth/apple` request body (mirrors the Google path). Backend ignores it until the
  ticket lands — harmless for non-attendee callers (they pass nothing).
- Confirm `loginWithGoogle(...)` forwards an explicit `userType` (it already supports it);
  ensure the attendee value is passed through rather than only resolved from a stored user.

### 2. Auth provider — `lib/features/auth/providers/auth_provider.dart`
- `signInWithGoogle({UserType? userTypeHint})` and `signInWithApple({UserType? userTypeHint})`
  — default `null` preserves existing login behavior; the attendee surface passes
  `UserType.attendee`.
- After a successful social auth, route via `resolveAuthDestination(user, isNewUser:
  response.isNewUser)` (existing helper) — see §3.

### 3. Routing — `lib/features/auth/utils/auth_navigation.dart`
- `resolveAuthDestination`: for `isNewUser && user.isAttendee` → `/onboarding/attendee/step1`
  (today attendees skip onboarding). Existing attendees (`isNewUser == false`) →
  attendee dashboard (unchanged). Business/community branches unchanged.

### 4. Attendee register screen — `lib/features/auth/screens/attendee_register_screen.dart`
- Below the email/password form add an "or" divider + a social section reusing
  `GoogleSignInButton` and `AppleSignInButton` (same layout as `login_screen`).
- **Google** always shown. **Apple** shown only when
  `Platform.isIOS && FeatureFlags.attendeeAppleSignupEnabled`.
- On tap: `ref.read(authProvider.notifier).signInWithGoogle(userTypeHint: UserType.attendee)`
  / `...signInWithApple(userTypeHint: UserType.attendee)`. New user → onboarding (via §3);
  reuse existing loading/success/error handling and the friendly type-mismatch error pattern
  already used in `login_screen`.

### 5. Name prefill into onboarding
- Seed `attendeeOnboardingProvider` with the provider's display name (Google `displayName`;
  Apple `givenName` + `familyName`, available only on first authorization). `@handle` stays
  user-entered (live availability via the existing `HandleField`). Prefill is best-effort —
  if the provider returns no name, step 1 simply starts empty.

### 6. Feature flag
- `attendeeAppleSignupEnabled = false` in `lib/config/constants/feature_flags.dart`
  (create if absent, else add the const). One line to flip when the backend ships.

### 7. i18n — `lib/l10n/app_{en,es,ca}.arb` + `flutter gen-l10n`
- Add `signInWithApple` — en "Sign in with Apple" / es "Iniciar sesión con Apple" /
  ca "Inicia sessió amb Apple".
- Add a divider key (e.g. `authOrDivider`) — en "or" / es "o" / ca "o" — if not present.
- In passing (per the mandatory-i18n rule): replace the hardcoded `'Google'` / `'Apple'`
  `buttonText` literals on `login_screen.dart` with `signInWithGoogle` / `signInWithApple`.

### 8. Backend ticket — `kolabing-v2`
- File `/Users/volkanoluc/Projects/kolabing-v2/docs/tickets/2026-06-11-attendee-apple-social-usertype.md`:
  `POST /auth/apple` should accept an optional `user_type` (`business|community|attendee`)
  and honor it on new-user creation, mirroring `POST /auth/google`; auto-create
  `attendee_profiles`; return `is_new_user`; define `onboarding_completed` semantics for a
  fresh social attendee (expected `false` so the app runs onboarding). Reference the Google
  controller as the implementation template.

## Edge cases / error handling
- Apple returns name only on the **first** authorization and may use a private-relay email →
  prefill is best-effort; never block on a missing name.
- Email / user_type collision (email already registered under a different role): backend
  returns 409 (documented for Google) → surface the existing friendly error used on
  `login_screen`; do not silently switch roles.
- Apple button is **iOS-only** (`Platform.isIOS`) in addition to the flag.
- User cancels the native sheet → existing `AuthCancelledException` handling (no error toast).

## Testing
- **Unit (service):** `_authenticateWithApple` includes `user_type` in the body when
  `userType` is provided, and omits it when null; Google path forwards `attendee`.
- **Unit (routing):** `resolveAuthDestination(attendee, isNewUser: true)` →
  attendee onboarding step1; `isNewUser: false` → attendee dashboard.
- **Widget:** attendee register screen renders Google always; Apple only when
  `Platform.isIOS && attendeeAppleSignupEnabled` (test both flag states).
- Keep the existing suite green (177 tests at baseline).

## Out of scope
- Business / community social flows (untouched).
- Provider-avatar import — onboarding photo stays a manual upload.
- The backend `/auth/apple` implementation itself (ticket only; client is ready + flag-gated).

## Verify (not code)
- Android `google-services.json` present for Google on Android.
- Apple Sign-In capability provisioned for `com.kolabing.kolabingApp` in the Apple Developer
  portal.

## Acceptance criteria
- New user taps **Continue with Google** on the attendee register screen → account created as
  `attendee` → lands in attendee onboarding step 1 with name prefilled → completes onboarding
  → attendee dashboard.
- Returning attendee taps Google → straight to attendee dashboard.
- Apple button hidden on the attendee screen while `attendeeAppleSignupEnabled == false`;
  when flipped on (post-backend), Apple mirrors the Google flow.
- `flutter analyze` 0 errors; full test suite green; no new hardcoded user-facing strings.
- Backend ticket committed in `kolabing-v2`.
