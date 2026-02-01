# Kolabing Mobile App - Full API Requirements

Base URL: `https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1`

## Status Overview

| Category | Implemented | Needed | Total |
|----------|------------|--------|-------|
| Auth | 6 | 0 | 6 |
| Onboarding/Lookup | 7 | 0 | 7 |
| User Profile | 9 | 0 | 9 |
| Dashboard | 1 | 0 | 1 |
| Opportunities | 8 | 0 | 8 |
| Applications | 11 | 0 | 11 |
| Gallery | 4 | 0 | 4 |
| Public Profile | 1 | 2 | 3 |
| **Total** | **47** | **2** | **49** |

---

## BACKEND'DEN BEKLENEN YENI ENDPOINT'LER

### 1. GET /api/v1/profiles/{profile_id}

Public profil bilgisi. Bir kullanici baska bir kullanicinin profilini goruntulediginde kullanilir.

**Auth:** Bearer token required

**Request:**
```
GET /api/v1/profiles/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer {token}
```

**Expected Response (200):**
```json
{
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "user_type": "community",
    "display_name": "Tech Kollab",
    "avatar_url": "https://storage.example.com/avatars/user123.jpg",
    "about": "We organize tech events, meetups and workshops...",
    "type": "Technology",
    "city_name": "Istanbul",
    "instagram": "techkollab",
    "tiktok": "techkollab",
    "website": "https://techkollab.com"
  }
}
```

**Response Fields:**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | No | Profile ID |
| user_type | string | No | `business` veya `community` |
| display_name | string | No | Gosterilecek isim |
| avatar_url | string | Yes | Profil fotografi URL |
| about | string | Yes | Biyografi / aciklama |
| type | string | Yes | Business type veya community type |
| city_name | string | Yes | Sehir ismi |
| instagram | string | Yes | Instagram kullanici adi (@ olmadan) |
| tiktok | string | Yes | TikTok kullanici adi (@ olmadan) |
| website | string | Yes | Website URL |

**Error Responses:**
- `401` - Unauthorized (token gecersiz)
- `404` - Profile bulunamadi

**Notes:**
- Bu endpoint herhangi bir kullanici tipinin (business/community) profilini dondurmelidir
- `type` alani `user_type=business` icin `business_type`, `user_type=community` icin `community_type` degerini tasimalidir
- Hassas bilgiler (email, telefon) donmemelidir - sadece public bilgi

---

### 2. GET /api/v1/profiles/{profile_id}/collaborations

Kullanicinin gecmis (tamamlanmis) is birlikleri. Profilinde deneyimini gostermek icin.

**Auth:** Bearer token required

**Request:**
```
GET /api/v1/profiles/550e8400-e29b-41d4-a716-446655440000/collaborations?page=1&per_page=10
Authorization: Bearer {token}
```

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | int | 1 | Sayfa numarasi |
| per_page | int | 10 | Sayfa basina kayit |

**Expected Response (200):**
```json
{
  "data": [
    {
      "id": "collab-uuid-1",
      "title": "Tech Meetup v4",
      "partner_name": "CafeX",
      "partner_avatar_url": "https://storage.example.com/avatars/cafex.jpg",
      "completed_at": "2025-01-15T10:30:00Z",
      "status": "completed"
    },
    {
      "id": "collab-uuid-2",
      "title": "Summer Networking Event",
      "partner_name": "CoWork Hub",
      "partner_avatar_url": null,
      "completed_at": "2024-08-22T14:00:00Z",
      "status": "completed"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 10,
    "total": 2
  }
}
```

**Response Fields (data array):**

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| id | string (UUID) | No | Collaboration ID |
| title | string | No | Is birligi/opportunity basligi |
| partner_name | string | No | Partner ismi |
| partner_avatar_url | string | Yes | Partner profil foto URL |
| completed_at | datetime (ISO 8601) | No | Tamamlanma tarihi |
| status | string | No | Her zaman `completed` |

**Error Responses:**
- `401` - Unauthorized
- `404` - Profile bulunamadi

**Notes:**
- Sadece `completed` statusundeki collaborationlar donmelidir
- En yeniden en eskiye siralanmali (`completed_at DESC`)
- `partner_name`: Eger profil sahibi business ise partner community ismi, tersi de gecerli
- Pagination destegi zorunlu degil ilk asamada, max 20 kayit donse yeterli

---

## MEVCUT ENDPOINT'LER (Referans)

### Auth (6 endpoint)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register/business` | Business kayit |
| POST | `/auth/register/community` | Community kayit |
| POST | `/auth/login` | Email/password giris |
| POST | `/auth/google` | Google ile giris |
| GET | `/auth/me` | Mevcut kullanici bilgisi |
| POST | `/auth/logout` | Cikis |

### Onboarding & Lookup (7 endpoint)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/business-types` | Business tipleri listesi |
| GET | `/lookup/business-types` | Business tipleri (fallback) |
| GET | `/community-types` | Community tipleri listesi |
| GET | `/lookup/community-types` | Community tipleri (fallback) |
| GET | `/cities` | Sehir listesi |
| POST | `/onboarding/business` | Business onboarding tamamla |
| POST | `/onboarding/community` | Community onboarding tamamla |

### User Profile (9 endpoint)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/me/profile` | Kendi profilini getir |
| PUT | `/me/profile` | Profilini guncelle |
| DELETE | `/me/account` | Hesap sil |
| GET | `/me/notification-preferences` | Bildirim tercihleri |
| PUT | `/me/notification-preferences` | Bildirim tercihleri guncelle |
| GET | `/me/subscription` | Abonelik durumu |
| POST | `/me/subscription/checkout` | Stripe checkout olustur |
| GET | `/me/subscription/portal` | Stripe portal URL |
| POST | `/me/subscription/cancel` | Abonelik iptal |

### Dashboard (1 endpoint)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/me/dashboard` | Dashboard verileri |

### Opportunities (8 endpoint)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/opportunities` | Firsatlari listele (filtreli, sayfalı) |
| GET | `/opportunities/{id}` | Firsat detayi |
| POST | `/opportunities` | Yeni firsat olustur |
| PUT | `/opportunities/{id}` | Firsati guncelle |
| POST | `/opportunities/{id}/publish` | Firsati yayinla |
| POST | `/opportunities/{id}/close` | Firsati kapat |
| DELETE | `/opportunities/{id}` | Firsati sil |
| GET | `/cities` | Sehir listesi (shared) |

### Applications (11 endpoint)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/opportunities/{id}/applications` | Basvuru yap |
| GET | `/me/applications` | Gonderdiklerim |
| GET | `/me/received-applications` | Gelen basvurular |
| GET | `/applications/{id}` | Basvuru detayi + mesajlar |
| POST | `/applications/{id}/accept` | Basvuru kabul |
| POST | `/applications/{id}/decline` | Basvuru reddet |
| POST | `/applications/{id}/withdraw` | Basvuru geri cek |
| GET | `/applications/{id}/messages` | Chat mesajlari |
| POST | `/applications/{id}/messages` | Mesaj gonder |
| POST | `/applications/{id}/messages/read` | Mesajlari okundu isaretle |
| GET | `/me/unread-messages-count` | Okunmamis mesaj sayisi |

### Gallery (4 endpoint)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/me/gallery` | Kendi galeri fotolari |
| POST | `/me/gallery` | Foto yukle (multipart/form-data) |
| DELETE | `/me/gallery/{photo_id}` | Foto sil |
| GET | `/profiles/{profile_id}/gallery` | Baska kullanicinin galerisi |

---

## Mobile Tarafta Kullanilan Servis Dosyalari

| Servis | Dosya Yolu |
|--------|-----------|
| AuthService | `lib/features/auth/services/auth_service.dart` |
| OnboardingService | `lib/features/onboarding/services/onboarding_service.dart` |
| ProfileService | `lib/features/business/services/profile_service.dart` |
| DashboardService | `lib/features/dashboard/services/dashboard_service.dart` |
| OpportunityService | `lib/features/opportunity/services/opportunity_service.dart` |
| ApplicationService | `lib/features/application/services/application_service.dart` |
| GalleryService | `lib/features/profile/services/gallery_service.dart` |
| PublicProfileService | `lib/features/profile/services/public_profile_service.dart` (MOCK) |

---

## Entegrasyon Notlari

1. **Auth Pattern:** Tum endpoint'ler `Authorization: Bearer {token}` header'i bekler (register/login haric)
2. **Response Format:** Tum response'lar `{ "data": ... }` wrapper'i icerisinde
3. **Pagination:** `page`, `per_page` query params + response'ta `meta.current_page`, `meta.last_page`, `meta.total`
4. **Error Format:** `{ "message": "...", "errors": { "field": ["error msg"] } }` + HTTP status code
5. **Multipart Upload:** Gallery foto yukleme `multipart/form-data` kullanir, alan adi: `photo`
6. **ID Format:** Tum ID'ler UUID string olarak beklenir, integer donerse `.toString()` ile ceviriyoruz
