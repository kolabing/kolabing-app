# Kolabing Mobile Notification Contract

**Source of truth:** backend branch `feat/notification-system`  
**Last updated:** 2026-05-09

This document explains how `kolabing-app` should integrate with the new backend notification system.

## Summary

Backend now supports:

- persisted in-app notifications
- multi-device FCM fan-out
- device-token upsert and logout removal
- notification preferences and quiet hours
- transactional notifications
- growth notifications behind feature flags

Current mobile-safe rollout:

- supported now:
  - `new_message`
  - `application_received`
  - `application_accepted`
  - `application_declined`
  - `badge_awarded`
  - `challenge_verified`
  - `reward_won`
- backend-gated until mobile routing/UI is ready:
  - all `collaboration_*`
  - `challenge_verification_requested`
  - `challenge_rejected`
  - all `withdrawal_*`
  - `referral_reward_earned`
  - all growth types

## Important Mobile Gap

Current app model only knows:

- `new_message`
- `application_received`
- `application_accepted`
- `application_declined`

Relevant files:

- [app_notification.dart](/Users/volkanoluc/Projects/kolabing-app/lib/features/notification/models/app_notification.dart:1)
- [notification_service.dart](/Users/volkanoluc/Projects/kolabing-app/lib/features/notification/services/notification_service.dart:1)

Mobile should be updated so unknown notification types do **not** map to `new_message`. Preferred behavior:

1. keep raw backend `type`
2. read `deeplink`
3. if type is unsupported, open `deeplink`
4. if deeplink is missing or unsupported, fallback to `/notifications`

## Push Payload

Backend FCM `data` payload:

```json
{
  "notification_id": "uuid",
  "type": "new_message",
  "id": "application_uuid",
  "target_type": "application",
  "target_id": "application_uuid",
  "deeplink": "/application/application_uuid/chat",
  "actor_id": "profile_uuid",
  "actor_name": "Ayse",
  "title": "Ayse sent a message",
  "body": "Are we good for Friday?",
  "image_url": "",
  "priority": "high",
  "dedupe_key": "message:message_uuid",
  "sent_at": "2026-05-06T15:30:00Z"
}
```

Rules:

- `type` and `id` are still present for backward compatibility.
- `deeplink` is the new routing source of truth.
- `notification_id` is the in-app notification row id.
- `body` is already user-facing text. Mobile should not template it.

## Deeplink Map

| Type | Deeplink |
| --- | --- |
| `new_message` | `/application/{application_id}/chat` |
| `application_received` | `/application/{application_id}` |
| `application_accepted` | `/application/{application_id}` |
| `application_declined` | `/application/{application_id}` |
| `collaboration_scheduled` | `/collaboration/{collaboration_id}` |
| `collaboration_rescheduled` | `/collaboration/{collaboration_id}` |
| `collaboration_cancelled` | `/collaboration/{collaboration_id}` |
| `collaboration_reminder_24h` | `/collaboration/{collaboration_id}` |
| `collaboration_reminder_same_day` | `/collaboration/{collaboration_id}` |
| `badge_awarded` | `/notifications` |
| `challenge_verified` | `/notifications` |
| `challenge_verification_requested` | `/notifications` |
| `challenge_rejected` | `/notifications` |
| `reward_won` | `/notifications` |
| `withdrawal_approved` | `/community/wallet` |
| `withdrawal_rejected` | `/community/wallet` |
| `withdrawal_paid` | `/community/wallet` |
| `referral_reward_earned` | `/business/referrals` or `/community/referrals` |
| `pending_application_nudge` | `/business` or `/community` |
| `opportunity_match` | `/business/browse` or `/community/offers` |
| `nearby_event_match` | `/attendee` |
| `wallet_threshold_reached` | `/community/wallet` |
| `dormant_user_reactivation` | `/notifications` |

## In-App Notification API

### `GET /api/v1/me/notifications`

Response item shape:

```json
{
  "id": "notification_uuid",
  "notification_id": "notification_uuid",
  "type": "application_received",
  "title": "New application received",
  "body": "Ayse applied to Sunset Rooftop Campaign",
  "deeplink": "/application/application_uuid",
  "priority": "high",
  "is_read": false,
  "read_at": null,
  "created_at": "2026-05-09T10:20:30Z",
  "actor_name": "Ayse",
  "actor_avatar_url": "https://...",
  "target_id": "application_uuid",
  "target_type": "application"
}
```

Mobile should persist or at least parse:

- `id`
- `notification_id`
- `type`
- `title`
- `body`
- `deeplink`
- `priority`
- `is_read`
- `read_at`
- `created_at`
- `actor_name`
- `actor_avatar_url`
- `target_id`
- `target_type`

## Unread Count APIs

These remain separate:

- `GET /api/v1/me/unread-messages-count`
- `GET /api/v1/me/notifications/unread-count`

Do not merge them in the app state layer.

## Mark Read APIs

- `POST /api/v1/me/notifications/{id}/read`
- `POST /api/v1/me/notifications/read-all`

These only change notification unread state. They do not affect chat unread counts.

## Device Token API

### Register / refresh token

`POST /api/v1/me/device-token`

```json
{
  "token": "fcm_device_token_here",
  "platform": "ios",
  "app_version": "1.4.0",
  "locale": "tr",
  "timezone": "Europe/Istanbul",
  "last_location_lat": 41.3874,
  "last_location_lng": 2.1686,
  "location_permission_granted_at": "2026-05-09T10:00:00Z"
}
```

Notes:

- only `token` and `platform` are mandatory
- location fields are optional
- location fields should only be sent after explicit permission
- backend upserts by raw token string

### Remove token on logout

`DELETE /api/v1/me/device-token`

```json
{
  "token": "fcm_device_token_here"
}
```

Mobile should call this during logout and manual device disconnect flows.

## Notification Preferences API

### `GET /api/v1/me/notification-preferences`

Example:

```json
{
  "email_notifications": true,
  "whatsapp_notifications": true,
  "new_application_alerts": true,
  "collaboration_updates": true,
  "marketing_tips": false,
  "messages_enabled": true,
  "applications_enabled": true,
  "collaborations_enabled": true,
  "rewards_enabled": true,
  "marketing_enabled": false,
  "quiet_hours_start": null,
  "quiet_hours_end": null,
  "timezone": null
}
```

### `PUT /api/v1/me/notification-preferences`

Supports partial updates for:

- `messages_enabled`
- `applications_enabled`
- `collaborations_enabled`
- `rewards_enabled`
- `marketing_enabled`
- `quiet_hours_start`
- `quiet_hours_end`
- `timezone`

## Referral Input Changes

The following auth endpoints now accept optional `referral_code`:

- `POST /api/v1/auth/google`
- `POST /api/v1/auth/register/business`
- `POST /api/v1/auth/register/community`
- `POST /api/v1/auth/register/attendee`

Example:

```json
{
  "id_token": "google_id_token",
  "user_type": "community",
  "referral_code": "KOLAB-ABCD"
}
```

## Recommended Mobile Changes

1. Extend `AppNotification` with:
   - `notificationId`
   - `deeplink`
   - `priority`
   - raw `type` or an `unknown` enum case
2. Update notification tap handling to prefer `deeplink`.
3. Keep a safe fallback route to `/notifications`.
4. Register richer device-token metadata when available.
5. Call token delete endpoint on logout.
6. Add UI wiring for notification preferences before enabling growth campaigns in production.
