# Task: phase1-5-fix-auth-session-login

## Status
- Created: 2026-05-18 15:55
- Started: 2026-05-18 15:55
- Completed:

## Description
- **B2**: Login with correct credentials routes to "page not found." No session persistence on app restart.
- **B4**: Test seed account hits `AuthException('Session expired')` on uploads.
- **B8**: Fresh sign-in throws "auth expired" on multiple screens within seconds of login.

Daniel flagged these as likely sharing one root cause.

## Codebase audit findings

- `auth_service.dart` already implements: cached token, persisted refresh token, single-flight `refreshSession()` mutex, `restoreSessionUser` that falls back to stored user on transient refresh failure. **The plumbing is largely correct.**
- Every per-domain service (`kolab_service`, `opportunity_service`, `upload_service`, etc.) repeats this pattern:
  ```
  if (401) {
    if (allowRetry) { refreshSession(); retry(allowRetry:false); }
    else throw AuthException('Session expired');
  }
  ```
  → Works, but raw `AuthException` with no field context is what surfaces in UI as a snackbar that disappears in 4s.
- `errorBuilder` in `routes.dart:757` is a dead-end placeholder: shows "Page Not Found" + URL but no recovery action. When B2 fires, user is stranded.
- `resolveAuthDestination` (auth_navigation.dart) has a hidden default: if `user.isBusiness == false && user.isCommunity == false && !user.isAttendee && !isNewUser`, it returns `KolabingRoutes.communityDashboard` (the ternary default). For a user with an unexpected `userType` this routes to `/community` which may bounce. The "page not found" Daniel saw might actually be a downstream redirect failure.

## Changes applied

### 1. Auth-aware error page (B2 stranded-user fix)
- `lib/config/routes/routes.dart`: replace `_PlaceholderScreen` with a smarter error screen that:
  - Shows the failed URL.
  - If `authProvider` is authenticated: offers "Go to dashboard" (resolves destination by user type) and "Sign out".
  - If not authenticated: offers "Back to login".
  - Logs `[B2]` with the URL + auth state so the next QA captures the exact landing.

### 2. Defensive userType routing
- `lib/features/auth/utils/auth_navigation.dart`: explicit branches for unknown user types. Log `[B2]` + route to `/welcome` rather than guessing.

### 3. Token-lifecycle logging
- `lib/features/auth/services/auth_service.dart`: `[AUTH]` log on every refresh attempt with token-issued-at, refresh-token-prefix (last 6 chars only — security), response status, and elapsed time. This makes B8 ("just signed in, immediately expired") visible in terminal.

### 4. Login screen — debug instrumentation
- `lib/features/auth/screens/login_screen.dart`: `[B2]` log around `_handleSignIn` capturing each branch (`success`, `isNetworkError`, generic error) + the resolved destination URL right before `context.go`.

## Out of scope (deferred)

- Centralizing the per-service `401 → refresh → retry` pattern into a single `AuthorizedHttpClient`. The current per-service code works; centralizing is a cleanup, not a bug fix. Will revisit after Daniel's next QA captures the actual failure point — at that point we'll know whether the issue is the retry, the refresh response, or something deeper.
- Persistent error banner on login screen (we already added one for business signup; same pattern applies but pulls login_screen up to ~1200 lines if added now). Deferred — the `[B2]` log + improved error page should already make the cause visible.

## Verification
1. `flutter analyze` clean on touched files.
2. `flutter test test/features/auth/` (or full suite) passes.
3. Manual: deliberately navigate to `/does-not-exist` → see the new error page with recovery actions.
4. Manual: log in with valid credentials → terminal shows `[B2] destination=/business`.
5. Manual: sign in then trigger a 401 on an upload → terminal shows `[AUTH] refresh attempt` + result.

## Files touched
- `lib/config/routes/routes.dart`
- `lib/features/auth/utils/auth_navigation.dart`
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/screens/login_screen.dart`
