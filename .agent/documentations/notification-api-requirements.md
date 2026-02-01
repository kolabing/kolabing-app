# Notification API Requirements

## Overview
Backend endpoints needed for the in-app notification system. Notifications are triggered by application messages and collab request events.

## Notification Types

| Type | Trigger | Recipient |
|------|---------|-----------|
| `new_message` | New chat message in application | Other party in the application |
| `application_received` | Someone applies to your opportunity | Opportunity owner |
| `application_accepted` | Your application is accepted | Applicant |
| `application_declined` | Your application is declined | Applicant |

---

## Endpoints

### 1. GET /api/v1/me/notifications
**Purpose:** List user's notifications (paginated, newest first)

**Auth:** Bearer token required

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | int | 1 | Page number |
| per_page | int | 20 | Items per page |

**Response (200):**
```json
{
  "data": [
    {
      "id": "notif-uuid-1",
      "type": "new_message",
      "title": "New Message",
      "body": "Hey! I'd love to discuss the details for the upcoming event.",
      "is_read": false,
      "read_at": null,
      "created_at": "2025-06-15T10:30:00Z",
      "actor_name": "CafeX Istanbul",
      "actor_avatar_url": "https://storage.example.com/avatars/cafex.jpg",
      "target_id": "app-uuid-1",
      "target_type": "application"
    },
    {
      "id": "notif-uuid-2",
      "type": "application_received",
      "title": "New Application",
      "body": "RunClub applied to your \"Summer Networking Event\" opportunity.",
      "is_read": true,
      "read_at": "2025-06-15T08:00:00Z",
      "created_at": "2025-06-15T06:30:00Z",
      "actor_name": "RunClub",
      "actor_avatar_url": null,
      "target_id": "app-uuid-2",
      "target_type": "application"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 45
  }
}
```

**Response Fields (data array):**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | No | Notification ID |
| type | string | No | One of: `new_message`, `application_received`, `application_accepted`, `application_declined` |
| title | string | No | Short notification title |
| body | string | No | Notification message body |
| is_read | boolean | No | Whether user has read the notification |
| read_at | datetime (ISO 8601) | Yes | When the notification was read |
| created_at | datetime (ISO 8601) | No | When the notification was created |
| actor_name | string | Yes | Name of the person who triggered the notification |
| actor_avatar_url | string | Yes | Avatar URL of the actor |
| target_id | string | Yes | ID of the related entity (application ID, etc.) |
| target_type | string | Yes | Type of the related entity (`application`) |

**Error Responses:**
- `401` - Unauthorized (token invalid)

---

### 2. GET /api/v1/me/notifications/unread-count
**Purpose:** Get total unread notification count (for badge display)

**Auth:** Bearer token required

**Response (200):**
```json
{
  "data": {
    "count": 5
  }
}
```

**Notes:**
- This is a lightweight endpoint that should be called frequently (on app start, after actions)
- Should be fast / cacheable

---

### 3. POST /api/v1/me/notifications/{notification_id}/read
**Purpose:** Mark a single notification as read

**Auth:** Bearer token required

**Request:**
```
POST /api/v1/me/notifications/notif-uuid-1/read
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "data": {
    "id": "notif-uuid-1",
    "is_read": true,
    "read_at": "2025-06-15T12:00:00Z"
  }
}
```

**Error Responses:**
- `401` - Unauthorized
- `404` - Notification not found

---

### 4. POST /api/v1/me/notifications/read-all
**Purpose:** Mark all notifications as read

**Auth:** Bearer token required

**Request:**
```
POST /api/v1/me/notifications/read-all
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "data": {
    "updated_count": 5
  }
}
```

**Error Responses:**
- `401` - Unauthorized

---

## Notification Creation Rules

### When to create notifications:

1. **`new_message`** - When a new chat message is sent in an application
   - Recipient: The other party (not the sender)
   - `actor_name`: Sender's display name
   - `actor_avatar_url`: Sender's avatar
   - `target_id`: Application ID
   - `target_type`: "application"
   - `body`: Message content (truncated to ~100 chars)

2. **`application_received`** - When a new application is submitted
   - Recipient: Opportunity owner
   - `actor_name`: Applicant's display name
   - `actor_avatar_url`: Applicant's avatar
   - `target_id`: Application ID
   - `target_type`: "application"
   - `body`: "{actor_name} applied to your \"{opportunity_title}\" opportunity."

3. **`application_accepted`** - When an application is accepted
   - Recipient: Applicant
   - `actor_name`: Opportunity owner's display name
   - `actor_avatar_url`: Owner's avatar
   - `target_id`: Application ID
   - `target_type`: "application"
   - `body`: "Your application for \"{opportunity_title}\" has been accepted!"

4. **`application_declined`** - When an application is declined
   - Recipient: Applicant
   - `actor_name`: Opportunity owner's display name
   - `actor_avatar_url`: Owner's avatar
   - `target_id`: Application ID
   - `target_type`: "application"
   - `body`: "Your application for \"{opportunity_title}\" was declined."

---

## Mobile Implementation

The mobile app currently uses mock data for notifications. When backend endpoints are ready, update `NotificationService` in:
```
lib/features/notification/services/notification_service.dart
```

### Integration points on mobile:
- **Badge**: `NotificationBell` widget shown on Dashboard and Explore headers (top-right)
- **Screen**: `NotificationsScreen` at route `/notifications`
- **Provider**: `notificationProvider` (Riverpod `NotifierProvider`)
- **Auto-load**: Unread count loads when provider is first accessed

### Existing related endpoint:
- `GET /api/v1/me/unread-messages-count` - Already exists for chat unread counts. The notification system is separate but complementary.
