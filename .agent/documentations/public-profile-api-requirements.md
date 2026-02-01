# Public Profile API Requirements

## Overview
API endpoints needed for the public profile preview feature. These endpoints allow users to view another user's profile, gallery, and past collaborations.

## Endpoints

### 1. GET /api/v1/profiles/{profile_id}
**Purpose:** Fetch a user's public profile information

**Auth:** Bearer token required

**Response (200):**
```json
{
  "data": {
    "id": "uuid",
    "user_type": "community",
    "display_name": "Community Name",
    "avatar_url": "https://...",
    "about": "We organize tech events...",
    "type": "Technology",
    "city_name": "Istanbul",
    "instagram": "kolabing",
    "tiktok": "kolabing",
    "website": "https://kolabing.com"
  }
}
```

**Fields:**
| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | No | User profile ID |
| user_type | string | No | "business" or "community" |
| display_name | string | No | Public display name |
| avatar_url | string | Yes | Profile photo URL |
| about | string | Yes | Bio / description |
| type | string | Yes | business_type or community_type |
| city_name | string | Yes | City name |
| instagram | string | Yes | Instagram handle (without @) |
| tiktok | string | Yes | TikTok handle (without @) |
| website | string | Yes | Website URL |

---

### 2. GET /api/v1/profiles/{profile_id}/gallery
**Purpose:** Fetch a user's gallery photos (already implemented)

**Auth:** Bearer token required

**Response (200):**
```json
{
  "data": [
    {
      "id": "uuid",
      "url": "https://...",
      "caption": "Optional caption",
      "sort_order": 0,
      "created_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

---

### 3. GET /api/v1/profiles/{profile_id}/collaborations
**Purpose:** Fetch a user's past (completed) collaborations

**Auth:** Bearer token required

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | int | 1 | Page number |
| per_page | int | 10 | Items per page |
| status | string | "completed" | Filter by status |

**Response (200):**
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Tech Meetup v4",
      "partner_name": "CafeX",
      "partner_avatar_url": "https://...",
      "completed_at": "2025-01-15T10:30:00Z",
      "status": "completed"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "total": 3
  }
}
```

**Fields:**
| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | No | Collaboration ID |
| title | string | No | Collaboration/opportunity title |
| partner_name | string | No | Name of the collaboration partner |
| partner_avatar_url | string | Yes | Partner's avatar URL |
| completed_at | datetime | No | When the collaboration was completed |
| status | string | No | Always "completed" for this endpoint |

## Current Status
- **GET /api/v1/profiles/{id}/gallery** - Already implemented in backend
- **GET /api/v1/profiles/{id}** - Needs backend implementation
- **GET /api/v1/profiles/{id}/collaborations** - Needs backend implementation

## Mobile Implementation
The mobile app currently uses mock data for profile info and past collaborations. The gallery is fetched from the real API. When the backend endpoints are ready, update `PublicProfileService` in `lib/features/profile/services/public_profile_service.dart` to call the real API instead of returning mock data.
