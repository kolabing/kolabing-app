# API Spec: Collaboration Detail & Event Management

Bu dokuman, collaboration detail ekrani icin gerekli backend API gelistirmelerini tanimlar.

---

## 1. GET /api/collaborations/{id}

Collaboration detaylarini getirir. Accept edildikten sonra her iki taraf (business + community) icin goruntulenir.

### Response Body

```json
{
  "id": "uuid",
  "status": "scheduled|in_progress|completed|cancelled",
  "scheduled_date": "2026-03-15",
  "scheduled_time": "14:00 - 18:00",
  "business_partner": {
    "id": "uuid",
    "name": "Nomad Coffee Roasters",
    "profile_photo": "https://...",
    "category": "Food & Drink",
    "city": "Barcelona",
    "user_type": "business"
  },
  "community_partner": {
    "id": "uuid",
    "name": "Barcelona Runners Club",
    "profile_photo": "https://...",
    "category": "Sports & Fitness",
    "city": "Barcelona",
    "user_type": "community"
  },
  "opportunity": {
    "id": "uuid",
    "title": "Coffee Tasting Event Partnership",
    "description": "...",
    "availability_mode": "one_time",
    "availability_start": "2026-03-01",
    "availability_end": "2026-03-31"
  },
  "contact_methods": {
    "whatsapp": "+34612345678",
    "email": "contact@nomadcoffee.com",
    "instagram": "@nomadcoffee"
  },
  "business_offer": {
    "venue": true,
    "food_drink": true,
    "social_media_exposure": true,
    "content_creation": false,
    "discount": {
      "enabled": true,
      "percentage": 15
    },
    "products": ["Specialty Coffee Tasting Kit"],
    "other": "Exclusive use of our rooftop terrace"
  },
  "community_deliverables": {
    "instagram_post": true,
    "instagram_story": true,
    "tiktok_video": false,
    "event_mention": true,
    "attendee_count": 50,
    "other": "Post-run group photo with branding"
  },
  "event_id": "uuid|null",
  "qr_code_url": "https://...|null",
  "challenges": [
    {
      "id": "uuid",
      "name": "Check-in at Venue",
      "description": "Scan the QR code when you arrive",
      "difficulty": "easy|medium|hard",
      "points": 5,
      "is_system": true,
      "event_id": "uuid|null",
      "created_at": "2026-03-10T10:00:00Z",
      "updated_at": "2026-03-10T10:00:00Z"
    }
  ],
  "selected_challenge_ids": ["uuid1", "uuid3"],
  "created_at": "2026-03-10T10:00:00Z",
  "updated_at": "2026-03-10T12:00:00Z"
}
```

### Status Codes
- `200` - Basarili
- `401` - Unauthorized
- `403` - Bu collaboration'a erisim yetkisi yok
- `404` - Collaboration bulunamadi

---

## 2. PUT /api/collaborations/{id}/challenges

Collaboration icin secilen challenge'lari gunceller.

### Request Body

```json
{
  "selected_challenge_ids": ["uuid1", "uuid3", "uuid5"]
}
```

### Response

```json
{
  "message": "Challenges updated successfully",
  "selected_challenge_ids": ["uuid1", "uuid3", "uuid5"]
}
```

### Status Codes
- `200` - Basarili
- `401` - Unauthorized
- `403` - Bu collaboration'i duzenleme yetkisi yok
- `404` - Collaboration bulunamadi
- `422` - Gecersiz challenge ID'leri

---

## 3. POST /api/collaborations/{id}/challenges

Collaboration'a ozel yeni bir custom challenge olusturur.

### Request Body

```json
{
  "name": "Try 3 Different Brews",
  "description": "Taste at least 3 different coffee brews during the event",
  "difficulty": "medium",
  "points": 20
}
```

### Response

```json
{
  "id": "uuid",
  "name": "Try 3 Different Brews",
  "description": "Taste at least 3 different coffee brews during the event",
  "difficulty": "medium",
  "points": 20,
  "is_system": false,
  "event_id": "uuid",
  "created_at": "2026-03-10T10:00:00Z",
  "updated_at": "2026-03-10T10:00:00Z"
}
```

### Validation
- `name`: required, min 3 chars, max 100 chars
- `difficulty`: required, enum (easy, medium, hard)
- `points`: optional, default = difficulty defaultPoints (5/15/30), min 1, max 100

---

## 4. GET /api/challenges/system

Sistem tarafindan tanimlanan default challenge listesi.
Bu challenge'lar her collaboration icin kullanilabilir.

### Response

```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Check-in at Venue",
      "description": "Scan the QR code when you arrive at the event",
      "difficulty": "easy",
      "points": 5,
      "is_system": true,
      "event_id": null,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

---

## 5. POST /api/collaborations/{id}/qr-code

Collaboration icin event QR kodu olusturur veya gunceller.

### Request Body

```json
{}
```
(QR code otomatik olarak collaboration + event bilgisinden uretilir)

### Response

```json
{
  "qr_code_url": "https://storage.example.com/qr/collaboration-uuid.png",
  "event_id": "uuid"
}
```

---

## 6. PATCH /api/collaborations/{id}/status

Collaboration durumunu gunceller.

### Request Body

```json
{
  "status": "in_progress|completed|cancelled"
}
```

### Response

```json
{
  "id": "uuid",
  "status": "in_progress",
  "updated_at": "2026-03-15T14:00:00Z"
}
```

### Business Rules
- `scheduled` -> `in_progress`: Sadece scheduled_date geldiginde
- `in_progress` -> `completed`: Her iki taraf onayladiginda
- Herhangi bir aktif durum -> `cancelled`: Her iki taraf iptal edebilir

---

## Veritabani Gereksinimleri

### `collaborations` tablosu (yeni veya guncelleme)

```sql
-- Eger mevcut degilse olustur
CREATE TABLE collaborations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES applications(id),
  status VARCHAR(20) DEFAULT 'scheduled',
  scheduled_date DATE NOT NULL,
  scheduled_time VARCHAR(50),
  business_profile_id UUID REFERENCES profiles(id),
  community_profile_id UUID REFERENCES profiles(id),
  opportunity_id UUID REFERENCES opportunities(id),
  contact_methods JSONB DEFAULT '{}',
  event_id UUID REFERENCES events(id),
  qr_code_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `collaboration_challenges` tablosu (pivot)

```sql
CREATE TABLE collaboration_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collaboration_id UUID REFERENCES collaborations(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  is_selected BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(collaboration_id, challenge_id)
);
```

### `challenges` tablosu guncellemesi

`challenges` tablosuna eger yoksa `collaboration_id` veya `event_id` eklenmeli.
System challenges `is_system = true` ile isaretlenip tum collaboration'larda kullanilabilir olmali.

---

## Onemli Notlar

1. **Her iki taraf ayni ekrani gorur** - `business_partner` ve `community_partner` ayri ayri doner, frontend kullanicinin tipine gore "partner" bilgisini gosterir
2. **Challenge secimi kaydedilmeli** - Kullanici challenge secip ciktiginda secimler persist etmeli
3. **QR Code uretimi** - Collaboration accept edildikten sonra otomatik uretilmeli veya event gunu uretilmeli
4. **Gamification entegrasyonu** - Secilen challenge'lar attendee app'inde event'e check-in yapildiktan sonra gorunmeli
5. **Contact methods** - Accept formundan gelen veriler burada gosterilir (whatsapp, email, instagram)
