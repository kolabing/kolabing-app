# Task: FCM Push Notifications System

## Status
- Created: 2026-02-27
- Started: 2026-02-27
- Completed: 2026-02-27

## Description
Implement Firebase Cloud Messaging (FCM) push notification system for Kolabing Flutter app.
Connect FCM to GoRouter for deep-link navigation on notification tap.

## Related API Endpoints
- [x] POST /api/v1/me/device-token

## Assigned Agents
- [x] @flutter-expert

## Progress

### Flutter Implementation
**Status:** Completed

#### Files Modified

**lib/services/notification_service.dart** — Complete rewrite
- Added `connectRouter(navigate)` method to wire navigation callback
- Background message handler promoted to top-level `firebaseMessagingBackgroundHandler`
- Foreground messages now include `type|id` payload for deep-link on tap
- `_onLocalNotificationTap` navigates via `_onNotificationTap` callback
- Added `deleteToken()` for logout cleanup
- Added `requestPermission()` public method
- Channel renamed to `kolabing_default` (matches AndroidManifest meta-data)

**lib/config/routes/routes.dart**
- Added `kolabingNavigatorKey` GlobalKey for programmatic navigation
- Added `connectNotificationRouter()` — maps FCM `type` to GoRouter push calls
- Router now uses `navigatorKey: kolabingNavigatorKey`
- Notification type → route mapping:
  - `new_message` → `/application/:id/chat`
  - `application_received/accepted/declined` → `/application/:id`

**lib/main.dart**
- Added `connectNotificationRouter()` call after FCM init

**lib/features/auth/providers/auth_provider.dart**
- `logout()` now calls `NotificationService.instance.deleteToken()` before logging out

**ios/Runner/AppDelegate.swift**
- Added `FirebaseApp.configure()` call

**ios/Runner/Info.plist**
- Added `UIBackgroundModes` with `remote-notification`
- Added `NSUserNotificationsUsageDescription`

**android/app/src/main/AndroidManifest.xml**
- Added `com.google.firebase.messaging.default_notification_channel_id` meta-data
- Added `com.google.firebase.messaging.default_notification_icon` meta-data

**android/settings.gradle.kts**
- Added `com.google.gms.google-services` plugin declaration

**android/app/build.gradle.kts**
- Added `id("com.google.gms.google-services")` plugin

### ⚠️ Manual Steps Required

1. **Android `google-services.json`** — Download from Firebase Console → Project Settings → Android app → download `google-services.json` → place in `android/app/google-services.json`

2. **iOS Xcode capabilities** — Open `ios/Runner.xcworkspace` in Xcode:
   - Runner target → Signing & Capabilities → + Capability → Push Notifications
   - + Capability → Background Modes → check "Remote notifications"

3. **FCM Token test** — After building, check console for `[FCM] Token: <token>` log to confirm Firebase is working.

## Notes
- `dart analyze` passes with 0 errors (only pre-existing style infos in routes.dart)
- iOS simulator cannot receive FCM push notifications — test on real device
- Backend already handles FCM dispatch — Flutter only needs token registration
