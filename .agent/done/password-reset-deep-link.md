# Task: Password Reset Deep Link Routing

## Status
- Created: 2026-03-03 10:00
- Started: 2026-03-03 10:05
- Completed: 2026-03-03 10:10

## Description
The screens (ForgotPasswordScreen, ResetPasswordScreen) and API service methods
(forgotPassword, resetPassword) are already fully implemented. iOS and Android
URL scheme (`kolabing://`) is already registered.

The only missing piece is deep link routing. When the deep link
`kolabing://reset-password?token=TOKEN&email=EMAIL` arrives, GoRouter parses
`reset-password` as the URI host (not path), resulting in `uri.path = ''`.
GoRouter then routes to `/` (splash screen) with the query params instead of
`/auth/reset-password?token=...&email=...`.

Fix: Add a top-level `redirect` to the GoRouter config that detects the
presence of both `token` and `email` query params on the root path `/` and
redirects to `/auth/reset-password` with those params preserved.

## Related API Endpoints
- [x] POST /api/v1/auth/forgot-password
- [x] POST /api/v1/auth/reset-password

## Assigned Agents
- [x] @flutter-expert

## Progress

### Flutter Implementation
**Status:** Done
- File: lib/config/routes/routes.dart
- Change: Add `redirect` function to `kolabingRouter` GoRouter config

## Notes
- Screens already exist and are complete
- Service methods already exist and are complete
- iOS scheme: `kolabing` already in Info.plist CFBundleURLSchemes
- Android: `android:scheme="kolabing"` already in AndroidManifest.xml
