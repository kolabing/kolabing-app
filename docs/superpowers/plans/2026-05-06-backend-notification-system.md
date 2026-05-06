# Kolabing Backend Notification System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-safe backend notification system that powers in-app notifications plus FCM push for Kolabing's transactional flows and selected growth/engagement campaigns.

**Architecture:** Use a Laravel notification domain with four core pieces: device-token registry, persisted in-app notification records, queued FCM delivery fan-out, and domain event producers. Every notification is created once in the database with a stable `dedupe_key`, then delivered asynchronously to all active device tokens for the recipient user. Transactional notifications bypass quiet hours; growth notifications respect preferences, rate limits, and quiet hours.

**Tech Stack:** Laravel 10/11, MySQL or PostgreSQL, Redis queues, Laravel Scheduler, `kreait/firebase-php`, Firebase Cloud Messaging, structured logging and metrics

---

## Assumptions

- This plan assumes the backend is Laravel-based because the current mobile contract and existing docs already use Laravel response patterns and `kreait/firebase-php`.
- File paths below are recommended Laravel paths. If the backend repo uses different naming, keep the same boundaries and responsibilities.
- Current Flutter app state on `2026-05-06` already understands these push `type` values:
  - `new_message`
  - `application_received`
  - `application_accepted`
  - `application_declined`
  - `badge_awarded`
  - `challenge_verified`
  - `reward_won`
- For `badge_awarded`, `challenge_verified`, and `reward_won`, explicit tap-routing is not fully productized yet. Until that app update ships, backend should send `deeplink: /notifications`.
- New types proposed in this plan should still be sent with a `deeplink` fallback. Until the next mobile update ships, unsupported types should safely open `/notifications`.

## Mandatory Product Rules

- `new_message` push is mandatory on every message creation.
- Message push goes only to the other participant in the chat, never to the sender.
- A user can have multiple active device tokens; push should fan out to all active tokens.
- Every push-worthy event must also create an in-app notification record, even if FCM delivery fails.
- All producers must be idempotent. Retries must not create duplicate notification rows.
- `GET /api/v1/me/unread-messages-count` remains message-specific.
- `GET /api/v1/me/notifications/unread-count` remains notification-specific.
- Transactional notifications in v1 are on by default. Growth notifications are opt-in.

## Canonical Notification Catalog

| Type | Phase | Trigger | Recipient | Deeplink | Push Priority | Notes |
|---|---|---|---|---|---|---|
| `new_message` | P1 | New chat message created | Other application-chat participant | `/application/{application_id}/chat` | high | Must always push, no batching |
| `application_received` | P1 | New application submitted | Opportunity owner | `/application/{application_id}` | high | Owner reviews application |
| `application_accepted` | P1 | Application accepted | Applicant | `/application/{application_id}` | high | Chat and collaboration now unlocked |
| `application_declined` | P1 | Application declined | Applicant | `/application/{application_id}` | high | Include decline reason if available |
| `collaboration_scheduled` | P2 | Collaboration created with schedule | Both parties | `/collaboration/{collaboration_id}` | high | Usually emitted after accept flow |
| `collaboration_rescheduled` | P2 | Scheduled date or time changed | Both parties except actor optional | `/collaboration/{collaboration_id}` | high | Send only when values actually changed |
| `collaboration_cancelled` | P2 | Collaboration cancelled | Both parties | `/collaboration/{collaboration_id}` | high | Include short reason if present |
| `collaboration_reminder_24h` | P2 | Scheduler finds start time in 24h window | Both parties | `/collaboration/{collaboration_id}` | normal | Transactional reminder |
| `collaboration_reminder_same_day` | P2 | Scheduler finds same-day event window | Both parties | `/collaboration/{collaboration_id}` | normal | Recommended at 2h before start |
| `challenge_verification_requested` | P2 | Attendee initiates peer challenge | Verifier attendee | `/notifications` | high | Mobile needs explicit route later |
| `challenge_verified` | P1 | Verifier approves challenge | Challenger attendee | `/notifications` | high | Current mobile already knows this type |
| `challenge_rejected` | P2 | Verifier rejects challenge | Challenger attendee | `/notifications` | normal | Mobile route follow-up needed |
| `reward_won` | P1 | Spin or reward allocation succeeds | Reward winner | `/notifications` | high | Current mobile already knows this type |
| `badge_awarded` | P1 | Badge unlock granted | Badge recipient | `/notifications` | normal | Current mobile already knows this type |
| `withdrawal_approved` | P2 | Withdrawal status becomes approved | Withdrawal owner | `/community/wallet` | normal | Community wallet screen exists |
| `withdrawal_rejected` | P2 | Withdrawal status becomes rejected | Withdrawal owner | `/community/wallet` | high | Include rejection reason if any |
| `withdrawal_paid` | P2 | Withdrawal payout completed | Withdrawal owner | `/community/wallet` | normal | Final payout confirmation |
| `referral_reward_earned` | P2 | Referral reward granted | Referrer | `/community/referrals` or `/business/referrals` | normal | Deeplink depends on user type |
| `pending_application_nudge` | P3 | Owner still has stale pending applications | Opportunity owner | `/business` or `/community` | low | Growth notification, opt-in |
| `opportunity_match` | P3 | Matching new kolab/opportunity published | Matching users by city/category | `/business/browse` or `/community/offers` | low | Growth notification, opt-in |
| `nearby_event_match` | P3 | Nearby attendee event discovered | Attendee users with recent location consent | `/attendee` | low | Growth notification, opt-in |
| `wallet_threshold_reached` | P3 | User crosses withdrawal threshold | Wallet owner | `/community/wallet` | low | Growth notification, opt-in |
| `dormant_user_reactivation` | P3 | User inactive for configured period | Target inactive cohort | `/notifications` | low | Growth notification, opt-in |

## Title and Body Templates

| Type | Title Template | Body Template |
|---|---|---|
| `new_message` | `{actor_name} sent a message` | `{message_preview}` |
| `application_received` | `New application received` | `{actor_name} applied to {opportunity_title}` |
| `application_accepted` | `Application accepted` | `{opportunity_title} has been accepted` |
| `application_declined` | `Application update` | `Your application for {opportunity_title} was declined` |
| `collaboration_scheduled` | `Collaboration scheduled` | `{partner_name} confirmed {scheduled_date}` |
| `collaboration_rescheduled` | `Collaboration updated` | `New date: {scheduled_date}` |
| `collaboration_cancelled` | `Collaboration cancelled` | `{partner_name} cancelled this collaboration` |
| `collaboration_reminder_24h` | `Reminder: collaboration tomorrow` | `{opportunity_title} starts on {scheduled_date}` |
| `collaboration_reminder_same_day` | `Reminder: collaboration today` | `{opportunity_title} starts at {scheduled_time}` |
| `challenge_verification_requested` | `Challenge verification needed` | `{actor_name} needs your verification` |
| `challenge_verified` | `Challenge verified` | `Your challenge was approved` |
| `challenge_rejected` | `Challenge update` | `Your challenge was rejected` |
| `reward_won` | `You won a reward` | `{reward_name}` |
| `badge_awarded` | `New badge unlocked` | `{badge_name}` |
| `withdrawal_approved` | `Withdrawal approved` | `Your withdrawal is approved and queued for payout` |
| `withdrawal_rejected` | `Withdrawal rejected` | `{reason_or_generic_copy}` |
| `withdrawal_paid` | `Withdrawal paid` | `Your payout has been completed` |
| `referral_reward_earned` | `Referral reward earned` | `You earned a reward from referral code {code}` |

## Payload Contract

Backend should preserve the current mobile-compatible fields and add forward-compatible fields.

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
  "image_url": null,
  "priority": "high",
  "dedupe_key": "message:message_uuid",
  "sent_at": "2026-05-06T15:30:00Z"
}
```

### Payload Rules

- `type` and `id` must remain present for current Flutter compatibility.
- `id` should point to the primary entity used by the mobile router today:
  - message notifications: `application_id`
  - application notifications: `application_id`
  - collaboration notifications: `collaboration_id`
- `deeplink` is the new source of truth for future mobile routing.
- `body` should already be human-readable. Mobile should not need to template it.
- `dedupe_key` should be unique per recipient and event occurrence.

## Recommended Data Model

### 1. `device_tokens`

Recommended columns:

- `id`
- `user_id`
- `token`
- `platform` (`ios`, `android`)
- `app_version`
- `locale`
- `timezone`
- `is_active`
- `last_seen_at`
- `last_delivered_at`
- `invalidated_at`
- `invalid_reason`
- `created_at`
- `updated_at`

Recommended constraints:

- unique index on `token`
- index on `user_id, is_active`
- index on `last_seen_at`

### 2. `notifications`

Recommended columns:

- `id` (UUID)
- `user_id`
- `actor_id` nullable
- `type`
- `title`
- `body`
- `target_type`
- `target_id`
- `deeplink`
- `image_url` nullable
- `data` JSON
- `priority`
- `channel_mask` or booleans for `in_app`, `push`
- `dedupe_key`
- `queued_at`
- `read_at`
- `created_at`
- `updated_at`

Recommended constraints:

- unique index on `user_id, dedupe_key`
- index on `user_id, read_at, created_at`
- index on `type, created_at`

### 3. `notification_deliveries`

Recommended columns:

- `id`
- `notification_id`
- `device_token_id`
- `provider` (`fcm`)
- `provider_message_id` nullable
- `status` (`queued`, `sent`, `failed`, `invalid_token`, `skipped`)
- `attempt_count`
- `last_error_code` nullable
- `last_error_message` nullable
- `delivered_at` nullable
- `created_at`
- `updated_at`

### 4. `notification_preferences`

Recommended columns:

- `user_id`
- `messages_enabled`
- `applications_enabled`
- `collaborations_enabled`
- `rewards_enabled`
- `marketing_enabled`
- `quiet_hours_start`
- `quiet_hours_end`
- `timezone`
- `created_at`
- `updated_at`

V1 defaults:

- `messages_enabled = true`
- `applications_enabled = true`
- `collaborations_enabled = true`
- `rewards_enabled = true`
- `marketing_enabled = false`

## Recommended Service Boundaries

Recommended Laravel units:

- `app/Enums/NotificationType.php`
- `app/Enums/NotificationPriority.php`
- `app/Models/DeviceToken.php`
- `app/Models/Notification.php`
- `app/Models/NotificationDelivery.php`
- `app/Models/NotificationPreference.php`
- `app/Services/Notifications/NotificationOrchestrator.php`
- `app/Services/Notifications/NotificationPayloadFactory.php`
- `app/Services/Notifications/FcmClient.php`
- `app/Jobs/Notifications/SendPushNotificationJob.php`
- `app/Jobs/Notifications/SendScheduledNotificationJob.php`
- `app/Jobs/Notifications/RetryFailedNotificationDeliveriesJob.php`
- `app/Listeners/Messages/CreateNewMessageNotification.php`
- `app/Listeners/Applications/CreateApplicationNotifications.php`
- `app/Listeners/Collaborations/CreateCollaborationNotifications.php`
- `app/Listeners/Gamification/CreateGamificationNotifications.php`
- `app/Listeners/Withdrawals/CreateWithdrawalNotifications.php`

## Delivery Flow

```text
Domain event happens
-> producer builds canonical payload
-> NotificationOrchestrator upserts notification row by (user_id, dedupe_key)
-> queue SendPushNotificationJob(notification_id)
-> job loads all active device tokens for recipient
-> per token send via FCM
-> write notification_deliveries rows
-> invalid token responses deactivate token
-> transient failures retry with backoff
```

### Retry Rules

- Retry network and provider `5xx` failures up to 3 times with exponential backoff.
- Do not retry `unregistered`, `invalid-argument`, or permanently invalid token errors.
- If all device tokens fail, keep the in-app notification record intact.

### Quiet Hours

- Transactional types ignore quiet hours:
  - `new_message`
  - `application_received`
  - `application_accepted`
  - `application_declined`
  - all `collaboration_*`
  - `challenge_verification_requested`
- Reward and growth notifications should respect quiet hours.

## API Contract

### Existing endpoints to keep compatible

- `POST /api/v1/me/device-token`
- `GET /api/v1/me/notifications`
- `GET /api/v1/me/notifications/unread-count`
- `POST /api/v1/me/notifications/{id}/read`
- `POST /api/v1/me/notifications/read-all`
- `GET /api/v1/me/unread-messages-count`
- `POST /api/v1/applications/{id}/messages/read`

### Recommended additions

#### `DELETE /api/v1/me/device-token`

Use on logout or manual device disconnect.

```json
{
  "token": "fcm_device_token_here"
}
```

#### `GET /api/v1/me/notification-preferences`

Returns current preference flags and quiet-hours config.

#### `PUT /api/v1/me/notification-preferences`

Allows updating `marketing_enabled`, `rewards_enabled`, quiet hours, locale, timezone.

### Device Token Upsert Rules

- Upsert by `token`, not by `(user_id, token)`.
- If the same token appears for a different user, move ownership to the new authenticated user and deactivate the old relation.
- Update `platform`, `app_version`, `locale`, `timezone`, and `last_seen_at` on every registration.

## Event Producer Requirements

### Messaging

- Source event: message row created successfully
- Producer dedupe key: `message:{message_id}`
- Recipient selection: all chat participants except sender
- Message preview should be trimmed to 120 chars
- Push must be sent even if recipient currently has the app open

### Applications

- Source events:
  - application created
  - application accepted
  - application declined
- Dedupe keys:
  - `application_received:{application_id}`
  - `application_accepted:{application_id}`
  - `application_declined:{application_id}`

### Collaborations

- Source events:
  - collaboration created with confirmed schedule
  - schedule changed
  - status changed to cancelled
- Reminder scheduler keys:
  - `collaboration_reminder_24h:{collaboration_id}:{date}`
  - `collaboration_reminder_same_day:{collaboration_id}:{date}`
- Reminders must be skipped if collaboration is cancelled before send time

### Challenges and Rewards

- Source events:
  - challenge completion initiated
  - challenge verified
  - challenge rejected
  - reward granted
  - badge granted
- If reward and badge are triggered by the same action, they should produce separate notifications with separate dedupe keys

### Withdrawals

- Source events:
  - withdrawal approved
  - withdrawal rejected
  - withdrawal marked paid
- Do not send duplicate pushes if accounting retries the same status write

### Referral Rewards

- Source event: referral reward grant committed
- Deeplink chosen by recipient `user_type`

## Growth and Engagement Rules

P3 growth types are opt-in and should not launch until P1 and P2 are stable.

### Audience Filters

- `pending_application_nudge`
  - user has pending applications older than 24h
  - user has not been nudged for same cohort in last 24h
- `opportunity_match`
  - new published kolab/opportunity matches city and category affinity
  - exclude author
- `nearby_event_match`
  - attendee granted location permission recently
  - event within configured radius
- `wallet_threshold_reached`
  - user crosses withdrawal threshold for first time after last reset
- `dormant_user_reactivation`
  - no app activity for 7 or 14 days

### Growth Safeguards

- max 1 growth push per user per 24h
- max 3 growth pushes per user per 7d
- respect quiet hours
- respect `marketing_enabled`

## Frontend Compatibility Notes

The current Flutter app already has screens for:

- `/application/{id}`
- `/application/{id}/chat`
- `/collaboration/{id}`
- `/community/wallet`
- `/community/referrals`
- `/business/referrals`
- `/notifications`

Current mobile-safe launch plan:

- Enable immediately with native route:
  - `new_message`
  - `application_received`
  - `application_accepted`
  - `application_declined`
- Enable immediately with `/notifications` fallback deeplink:
  - `badge_awarded`
  - `challenge_verified`
  - `reward_won`
- Enable after next mobile update adds explicit routing support:
  - all `collaboration_*`
  - `challenge_rejected`
  - all `withdrawal_*`
  - `referral_reward_earned`
  - all P3 growth types

If backend must start earlier, unsupported types should push with:

```json
{
  "type": "collaboration_scheduled",
  "id": "collaboration_uuid",
  "deeplink": "/notifications"
}
```

## Acceptance Tests

- Message from User A to User B creates one notification for User B, zero for User A, increments unread message counts for User B, and pushes to all active tokens of User B.
- New application creates one owner notification with deeplink `/application/{application_id}`.
- Accepting an application creates one applicant notification and does not duplicate on retry.
- Changing collaboration schedule emits exactly one `collaboration_rescheduled` per recipient even if the save endpoint is retried.
- Daily reminder jobs do not send for cancelled collaborations.
- Invalid FCM token response deactivates the token and future sends skip it.
- `mark read` changes only notification unread counters, not message unread counters.
- Growth notifications respect `marketing_enabled`, quiet hours, and 24h frequency caps.

## Rollout Plan

### Phase P1: Foundation plus current mobile-safe transactional types

- `new_message`
- `application_received`
- `application_accepted`
- `application_declined`
- `badge_awarded` with `/notifications` deeplink
- `challenge_verified` with `/notifications` deeplink
- `reward_won` with `/notifications` deeplink

### Phase P2: Collaboration, withdrawal, referral, and remaining gamification types

- all `collaboration_*`
- `challenge_verification_requested`
- `challenge_rejected`
- all `withdrawal_*`
- `referral_reward_earned`

### Phase P3: Growth and engagement

- `pending_application_nudge`
- `opportunity_match`
- `nearby_event_match`
- `wallet_threshold_reached`
- `dormant_user_reactivation`

## Task 1: Freeze the notification contract

**Recommended files:**
- Create: `app/Enums/NotificationType.php`
- Create: `app/Enums/NotificationPriority.php`
- Create: `app/Data/Notifications/NotificationTargetData.php`
- Create: `docs/backend/notification-contract.md`

- [ ] Copy the canonical notification catalog from this plan into the backend repo as the single source of truth.
- [ ] Define enum values exactly as listed above; avoid ad hoc string literals in listeners and jobs.
- [ ] Freeze the payload keys `type`, `id`, `target_type`, `target_id`, and `deeplink`.
- [ ] Review with mobile team before any producer code ships.

## Task 2: Create persistence layer and migrations

**Recommended files:**
- Create: `database/migrations/*_create_device_tokens_table.php`
- Create: `database/migrations/*_create_notifications_table.php`
- Create: `database/migrations/*_create_notification_deliveries_table.php`
- Create: `database/migrations/*_create_notification_preferences_table.php`
- Create: `app/Models/DeviceToken.php`
- Create: `app/Models/Notification.php`
- Create: `app/Models/NotificationDelivery.php`
- Create: `app/Models/NotificationPreference.php`

- [ ] Add the four tables from the data model section with the listed indexes.
- [ ] Add the unique `(user_id, dedupe_key)` guard on `notifications`.
- [ ] Seed default preferences for existing users with transactional enabled and marketing disabled.
- [ ] Add model casts for JSON and timestamps.

## Task 3: Implement device token lifecycle

**Recommended files:**
- Modify: `routes/api.php`
- Modify: `app/Http/Controllers/Api/Me/DeviceTokenController.php`
- Create: `app/Http/Requests/RegisterDeviceTokenRequest.php`
- Create: `app/Http/Requests/DeleteDeviceTokenRequest.php`
- Create: `app/Services/Notifications/DeviceTokenService.php`

- [ ] Keep `POST /api/v1/me/device-token` backward compatible with the current Flutter request shape.
- [ ] Make token registration an upsert by raw token string.
- [ ] Add `DELETE /api/v1/me/device-token` for logout cleanup.
- [ ] Update token metadata on every successful app open or login.

## Task 4: Implement notification orchestration and FCM delivery

**Recommended files:**
- Create: `app/Services/Notifications/NotificationOrchestrator.php`
- Create: `app/Services/Notifications/NotificationPayloadFactory.php`
- Create: `app/Services/Notifications/FcmClient.php`
- Create: `app/Jobs/Notifications/SendPushNotificationJob.php`
- Create: `config/notifications.php`

- [ ] Build one service that accepts recipients, type, actor, target, title, body, and `dedupe_key`.
- [ ] Persist the in-app notification row before queuing any push work.
- [ ] Fan out queued deliveries to all active tokens for the recipient.
- [ ] Capture per-token send results in `notification_deliveries`.
- [ ] Deactivate invalid tokens automatically.

## Task 5: Add transactional producers for messaging and applications

**Recommended files:**
- Create: `app/Events/Messages/MessageCreated.php`
- Create: `app/Listeners/Messages/CreateNewMessageNotification.php`
- Create: `app/Events/Applications/ApplicationCreated.php`
- Create: `app/Events/Applications/ApplicationAccepted.php`
- Create: `app/Events/Applications/ApplicationDeclined.php`
- Create: `app/Listeners/Applications/CreateApplicationNotifications.php`

- [ ] Emit `new_message` only after message commit succeeds.
- [ ] Emit `application_received` after application create commit succeeds.
- [ ] Emit `application_accepted` and `application_declined` after status transitions succeed.
- [ ] Use event IDs or entity IDs in `dedupe_key` generation.

## Task 6: Add collaboration notifications and reminders

**Recommended files:**
- Create: `app/Events/Collaborations/CollaborationScheduled.php`
- Create: `app/Events/Collaborations/CollaborationRescheduled.php`
- Create: `app/Events/Collaborations/CollaborationCancelled.php`
- Create: `app/Listeners/Collaborations/CreateCollaborationNotifications.php`
- Create: `app/Jobs/Notifications/SendScheduledNotificationJob.php`
- Modify: `app/Console/Kernel.php`

- [ ] Emit schedule and cancellation events only when meaningful state changes occur.
- [ ] Add scheduler jobs for 24h and same-day reminders.
- [ ] Ensure reminders skip cancelled or already-finished collaborations.
- [ ] Roll these types behind a feature flag until the next mobile update is ready.

## Task 7: Add gamification, rewards, withdrawal, and referral producers

**Recommended files:**
- Create: `app/Events/Gamification/ChallengeVerificationRequested.php`
- Create: `app/Events/Gamification/ChallengeVerified.php`
- Create: `app/Events/Gamification/ChallengeRejected.php`
- Create: `app/Events/Gamification/RewardWon.php`
- Create: `app/Events/Gamification/BadgeAwarded.php`
- Create: `app/Events/Withdrawals/WithdrawalApproved.php`
- Create: `app/Events/Withdrawals/WithdrawalRejected.php`
- Create: `app/Events/Withdrawals/WithdrawalPaid.php`
- Create: `app/Events/Referrals/ReferralRewardEarned.php`
- Create: `app/Listeners/Gamification/CreateGamificationNotifications.php`
- Create: `app/Listeners/Withdrawals/CreateWithdrawalNotifications.php`
- Create: `app/Listeners/Referrals/CreateReferralNotifications.php`

- [ ] Keep `badge_awarded`, `challenge_verified`, and `reward_won` enabled in P1 because current mobile already recognizes them.
- [ ] Gate `challenge_rejected`, `withdrawal_*`, and `referral_reward_earned` behind a feature flag until the routing update ships.
- [ ] Use explicit deeplink generation per user type for referral notifications.

## Task 8: Add notification read APIs and unread counters

**Recommended files:**
- Modify: `routes/api.php`
- Modify: `app/Http/Controllers/Api/Me/NotificationController.php`
- Create: `app/Queries/Notifications/ListUserNotificationsQuery.php`
- Create: `app/Queries/Notifications/GetUnreadNotificationCountQuery.php`

- [ ] Keep pagination shape compatible with the Flutter `NotificationService`.
- [ ] Make `mark read` and `read all` update only `notifications.read_at`.
- [ ] Do not change message unread logic in chat tables or endpoints.
- [ ] Return `actor_name`, `actor_avatar_url`, `target_id`, and `target_type` in list responses.

## Task 9: Add P3 growth scheduler and rate limiting

**Recommended files:**
- Create: `app/Services/Notifications/GrowthAudienceService.php`
- Create: `app/Services/Notifications/GrowthRateLimitService.php`
- Create: `app/Jobs/Notifications/SendGrowthCampaignNotificationsJob.php`
- Modify: `app/Console/Kernel.php`

- [ ] Implement audience filters for the five P3 types.
- [ ] Enforce 24h and 7d caps before notification creation.
- [ ] Respect marketing opt-in and quiet hours.
- [ ] Launch P3 only after P1 and P2 delivery metrics stabilize.

## Task 10: Add tests, metrics, and rollout controls

**Recommended files:**
- Create: `tests/Feature/Notifications/*`
- Create: `tests/Unit/Notifications/*`
- Create: `app/Support/Notifications/NotificationMetrics.php`
- Modify: `config/feature-flags.php` or equivalent

- [ ] Add unit tests for dedupe-key generation, payload factory, and quiet-hours decisions.
- [ ] Add feature tests for message, application, collaboration, and reward notification flows.
- [ ] Add queue-job tests for invalid token deactivation and retry behavior.
- [ ] Add feature flags per phase and per notification type.
- [ ] Add dashboards or logs for send success, send failure, inactive token count, and unread notification growth.

## Backend Handoff Checklist

- [ ] Contract approved by mobile team
- [ ] Migration plan approved
- [ ] Phase P1 feature flags ready
- [ ] Staging FCM credentials configured
- [ ] Invalid-token cleanup verified
- [ ] Read/unread APIs smoke tested with current app build
- [ ] P2 launch blocked until mobile routing update is confirmed
- [ ] P3 launch blocked until preference UI and growth caps are verified
