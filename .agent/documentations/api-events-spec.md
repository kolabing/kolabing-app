# Events API Specification

Bu döküman, mobil uygulamadaki "Past Events" özelliği için gerekli backend API'lerini tanımlar.

## Overview

Business ve Community kullanıcıları geçmişte organize ettikleri etkinlikleri profillerinde sergileyebilir. Her etkinlik bir partner (karşı taraf) ile gerçekleştirilmiş işbirliğini temsil eder.

## Data Model

### Event
```typescript
interface Event {
  id: string;                    // UUID
  user_id: string;               // Owner UUID
  name: string;                  // Event name
  partner_id: string;            // Partner user UUID
  partner_type: 'business' | 'community';
  date: string;                  // ISO date (YYYY-MM-DD)
  attendee_count: number;        // Number of attendees
  photos: EventPhoto[];          // Array of photos (max 5)
  created_at: string;            // ISO timestamp
  updated_at: string;            // ISO timestamp
}

interface EventPhoto {
  id: string;                    // UUID
  url: string;                   // Full-size image URL
  thumbnail_url?: string;        // Optional thumbnail URL
}

interface EventPartner {
  id: string;
  name: string;
  profile_photo?: string;
  type: 'business' | 'community';
}
```

## Endpoints

### 1. List Events
**GET** `/api/v1/events`

Kullanıcının geçmiş etkinliklerini listeler.

#### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user_id | string | No | User UUID. Defaults to current authenticated user |
| page | int | No | Page number (default: 1) |
| limit | int | No | Items per page (default: 10, max: 50) |

#### Response
```json
{
  "success": true,
  "data": {
    "events": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Summer Music Festival",
        "partner": {
          "id": "550e8400-e29b-41d4-a716-446655440001",
          "name": "Rock Community Istanbul",
          "profile_photo": "https://storage.example.com/avatars/partner1.jpg",
          "type": "community"
        },
        "date": "2025-08-15",
        "attendee_count": 1250,
        "photos": [
          {
            "id": "photo_1",
            "url": "https://storage.example.com/events/photo1.jpg",
            "thumbnail_url": "https://storage.example.com/events/photo1_thumb.jpg"
          }
        ],
        "created_at": "2025-08-20T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_count": 25,
      "per_page": 10
    }
  }
}
```

#### Error Response
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

---

### 2. Get Single Event
**GET** `/api/v1/events/{id}`

Tek bir etkinliğin detaylarını getirir.

#### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | Event UUID |

#### Response
```json
{
  "success": true,
  "data": {
    "event": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Summer Music Festival",
      "partner": {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "name": "Rock Community Istanbul",
        "profile_photo": "https://storage.example.com/avatars/partner1.jpg",
        "type": "community"
      },
      "date": "2025-08-15",
      "attendee_count": 1250,
      "photos": [
        {
          "id": "photo_1",
          "url": "https://storage.example.com/events/photo1.jpg",
          "thumbnail_url": "https://storage.example.com/events/photo1_thumb.jpg"
        }
      ],
      "created_at": "2025-08-20T10:00:00Z",
      "updated_at": "2025-08-20T10:00:00Z"
    }
  }
}
```

---

### 3. Create Event
**POST** `/api/v1/events`

Yeni bir etkinlik oluşturur.

#### Request Body
```json
{
  "name": "Summer Music Festival",
  "partner_id": "550e8400-e29b-41d4-a716-446655440001",
  "partner_type": "community",
  "date": "2025-08-15",
  "attendee_count": 1250,
  "photos": [
    "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
    "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
  ]
}
```

#### Validation Rules
| Field | Rules |
|-------|-------|
| name | Required, min: 3, max: 100 characters |
| partner_id | Required, valid UUID, must exist in users table |
| partner_type | Required, enum: 'business' or 'community' |
| date | Required, ISO date format, cannot be in future |
| attendee_count | Required, integer, min: 1 |
| photos | Required, array, min: 1, max: 5 items |

#### Response
```json
{
  "success": true,
  "data": {
    "event": {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "name": "Summer Music Festival",
      "partner": {
        "id": "550e8400-e29b-41d4-a716-446655440001",
        "name": "Rock Community Istanbul",
        "profile_photo": "https://storage.example.com/avatars/partner1.jpg",
        "type": "community"
      },
      "date": "2025-08-15",
      "attendee_count": 1250,
      "photos": [
        {
          "id": "photo_new_1",
          "url": "https://storage.example.com/events/photo_new_1.jpg",
          "thumbnail_url": "https://storage.example.com/events/photo_new_1_thumb.jpg"
        }
      ],
      "created_at": "2025-08-20T10:00:00Z",
      "updated_at": "2025-08-20T10:00:00Z"
    }
  }
}
```

#### Error Response (Validation)
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "name": ["Name is required"],
      "photos": ["At least one photo is required"]
    }
  }
}
```

---

### 4. Update Event
**PUT** `/api/v1/events/{id}`

Mevcut bir etkinliği günceller. Sadece etkinlik sahibi güncelleyebilir.

#### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | Event UUID |

#### Request Body
Tüm alanlar opsiyoneldir. Sadece gönderilen alanlar güncellenir.

```json
{
  "name": "Updated Festival Name",
  "attendee_count": 1500
}
```

#### Response
```json
{
  "success": true,
  "data": {
    "event": { ... }
  }
}
```

---

### 5. Delete Event
**DELETE** `/api/v1/events/{id}`

Bir etkinliği siler. Sadece etkinlik sahibi silebilir.

#### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | Event UUID |

#### Response
```json
{
  "success": true,
  "message": "Event deleted successfully"
}
```

#### Error Response
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "You are not authorized to delete this event"
  }
}
```

---

## Database Schema (Supabase)

```sql
-- Events table
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  partner_id UUID NOT NULL REFERENCES users(id),
  partner_type VARCHAR(20) NOT NULL CHECK (partner_type IN ('business', 'community')),
  event_date DATE NOT NULL,
  attendee_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Event photos table
CREATE TABLE event_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_partner_id ON events(partner_id);
CREATE INDEX idx_event_photos_event_id ON event_photos(event_id);

-- RLS Policies
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Users can read all events (for public profiles)
CREATE POLICY "Events are viewable by everyone" ON events
  FOR SELECT USING (true);

-- Users can only insert their own events
CREATE POLICY "Users can create their own events" ON events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own events
CREATE POLICY "Users can update their own events" ON events
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own events
CREATE POLICY "Users can delete their own events" ON events
  FOR DELETE USING (auth.uid() = user_id);
```

---

## Notes

1. **Photo Storage**: Fotoğraflar Supabase Storage'da `events/{user_id}/{event_id}/` klasöründe saklanmalı
2. **Thumbnail Generation**: Fotoğraf yüklendiğinde otomatik olarak 200x200 thumbnail oluşturulmalı
3. **Partner Validation**: partner_id'nin gerçek bir kullanıcı olup olmadığı kontrol edilmeli
4. **Date Validation**: Etkinlik tarihi gelecekte olamaz (geçmiş etkinlikler için)
5. **Photo Limit**: Maksimum 5 fotoğraf per event

## Mobile Implementation Status

✅ Flutter'da mock data ile implementasyon tamamlandı:
- `lib/features/event/` klasörü altında tüm dosyalar mevcut
- Business ve Community profil ekranlarına entegre edildi
- Route `/event/:id` eklendi

API hazır olduğunda `EventService` sınıfındaki mock fonksiyonlar gerçek API çağrılarıyla değiştirilecek.
