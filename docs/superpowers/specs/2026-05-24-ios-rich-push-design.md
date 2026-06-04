# iOS Rich Push Design

**Goal:** upgrade iOS push notifications from basic system banners to grouped, action-enabled, rich push notifications with consistent foreground and background behavior.

## Scope

- keep OneSignal as the primary transactional delivery path
- keep FCM compatibility for token management and fallback message handling
- remove duplicate foreground banners
- support subtitle, thread grouping, category-based action buttons, interruption level, badge, and rich media attachments
- add an iOS Notification Service Extension for background rich media

## App-side decisions

### Unified presentation

- foreground system banners are suppressed on iOS
- foreground push notifications are re-rendered through `flutter_local_notifications`
- OneSignal foreground notifications and FCM foreground notifications go through the same presenter

### Registered iOS categories

- `kolabing_messages`
- `kolabing_applications`
- `kolabing_general`

### Registered iOS action ids

- `open_message_thread`
- `view_application`
- `open_app`
- `open_notifications`

### Deeplink handling

- action button taps resolve through `action_deeplinks` when provided
- otherwise the app falls back to deterministic route defaults derived from `type` and `id`
- canonical message route is `/application/{id}/chat`

### Rich media

- background and lock-screen rich media use a Notification Service Extension with `OneSignalExtension`
- foreground rich media downloads the attachment URL and renders it through a local iOS notification attachment

## Native iOS requirements

- app target and notification service extension share the same App Group
- app group id used in repo: `group.com.kolabing.kolabingapp.lpfnq76gb6.onesignal`
- both targets declare `OneSignal_app_groups_key`

## Backend dependency

Backend must send richer OneSignal metadata for best results:

- `ios_category`
- `subtitle`
- `thread_id`
- `buttons`
- `action_deeplinks`
- optional `ios_attachments`
- optional badge/interruption metadata

Detailed backend contract lives in:

- `../kolabing-v2/docs/superpowers/specs/2026-05-24-ios-rich-push-backend-contract.md`
