# Free Tier Limit — API Spesifikasyonu

**Konu:** Business kullanıcılar için ücretsiz 1 kollab hakkı, sonrası için abonelik zorunluluğu
**Tarih:** 2026-03-03
**Mobil uygulama versiyonu:** 1.2.0+3

---

## Kural Özeti

| Durum | Davranış |
|-------|----------|
| Aktif abonelik var | Sınırsız kollab oluşturabilir |
| Abonelik yok, 0 kollab var | 1 kollab oluşturabilir (ücretsiz) |
| Abonelik yok, ≥1 kollab var | `POST /opportunities` engellenir, `requires_subscription: true` döner |
| Mevcut kollab düzenleme (PUT) | Her zaman izin verilir |
| Mevcut kollab yayınlama (publish) | Her zaman izin verilir |

---

## Etkilenen Endpoint'ler

### 1. `POST /api/v1/opportunities` — Kollab Oluşturma

Mevcut endpoint. Free tier kontrolü eklenmesi gerekiyor.

**Auth:** `Authorization: Bearer {token}` (zorunlu)

**Request Headers:**
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Request Body:**
```json
{
  "title": "Restaurant Week Promotion",
  "description": "We are looking for a community partner for our annual Restaurant Week event.",
  "categories": ["Food & Drink", "Culture"],
  "availability_mode": "one_time",
  "availability_start": "2026-04-15",
  "availability_end": "2026-04-16",
  "venue_mode": "business_venue",
  "address": "Calle Gran Vía 32, Madrid",
  "preferred_city": "Madrid",
  "offer_photo": null,
  "status": "draft",
  "business_offer": {
    "venue": true,
    "food_drink": true,
    "social_media_exposure": false,
    "content_creation": false,
    "discount": {
      "enabled": true,
      "percentage": 20
    },
    "products": [],
    "other": null
  },
  "community_deliverables": {
    "social_media_content": true,
    "event_activation": false,
    "product_placement": false,
    "community_reach": true,
    "review_feedback": false,
    "other": null
  }
}
```

**availability_mode değerleri:** `one_time` | `recurring` | `flexible`
**venue_mode değerleri:** `business_venue` | `community_venue` | `no_venue`
**status değerleri:** `draft` | `published`

---

#### Response: 201 Created — Başarılı

```json
{
  "data": {
    "id": "abc123",
    "title": "Restaurant Week Promotion",
    "description": "We are looking for a community partner...",
    "categories": ["Food & Drink", "Culture"],
    "availability_mode": "one_time",
    "availability_start": "2026-04-15",
    "availability_end": "2026-04-16",
    "venue_mode": "business_venue",
    "address": "Calle Gran Vía 32, Madrid",
    "preferred_city": "Madrid",
    "offer_photo": null,
    "status": "draft",
    "business_offer": {
      "venue": true,
      "food_drink": true,
      "social_media_exposure": false,
      "content_creation": false,
      "discount": { "enabled": true, "percentage": 20 },
      "products": [],
      "other": null
    },
    "community_deliverables": {
      "social_media_content": true,
      "event_activation": false,
      "product_placement": false,
      "community_reach": true,
      "review_feedback": false,
      "other": null
    },
    "applications_count": 0,
    "is_own": true,
    "created_at": "2026-03-03T14:22:00Z",
    "updated_at": "2026-03-03T14:22:00Z",
    "published_at": null
  }
}
```

---

#### Response: 402 Payment Required — Free Tier Sınırı Aşıldı ⚠️ YENİ

**Koşul:** Kullanıcının aktif aboneliği yoktur VE daha önce en az 1 kollab oluşturmuştur.

**HTTP Status:** `402 Payment Required`

```json
{
  "message": "You've used your 1 free kollab request. Subscribe to create unlimited requests.",
  "requires_subscription": true
}
```

> **Mobil uygulamadaki davranış:** `requires_subscription: true` alanını görünce
> `opportunityFormProvider.requiresSubscription` flag'i `true` yapılır ve
> `SubscriptionPaywall` modal'ı otomatik olarak gösterilir. Bu alan **zorunludur**,
> yoksa paywall açılmaz.

---

#### Response: 422 Unprocessable Entity — Validasyon Hatası

```json
{
  "message": "The given data was invalid.",
  "requires_subscription": false,
  "errors": {
    "title": ["The title field is required."],
    "categories": ["Select at least 1 category."]
  }
}
```

---

#### Response: 401 Unauthorized

```json
{
  "message": "Unauthenticated."
}
```

---

### 2. `PUT /api/v1/opportunities/{id}` — Kollab Düzenleme

Mevcut kollab'ı günceller. **Free tier kontrolü uygulanmaz** — mevcut kollab her zaman düzenlenebilir.

**Auth:** `Authorization: Bearer {token}` (zorunlu)

**Request:** POST ile aynı body formatı.

**Response: 200 OK — Başarılı**

```json
{
  "data": {
    "id": "abc123",
    "title": "Updated Title",
    "status": "draft",
    "...": "..."
  }
}
```

**Response: 403 Forbidden** — Kullanıcı bu kollab'ın sahibi değil

```json
{
  "message": "You are not authorized to edit this opportunity."
}
```

---

### 3. `POST /api/v1/opportunities/{id}/publish` — Kollab Yayınlama

Mevcut draft kollab'ı publish eder. **Free tier kontrolü uygulanmaz** — 1. kollab yayınlanabilir.

**Auth:** `Authorization: Bearer {token}` (zorunlu)

**Request Body:** Yok (body gerekmez)

**Response: 200 OK — Başarılı**

```json
{
  "data": {
    "id": "abc123",
    "status": "published",
    "published_at": "2026-03-03T15:00:00Z",
    "...": "..."
  }
}
```

**Response: 403 Forbidden** — Yetersiz izin (sahibi değil)

```json
{
  "message": "You are not authorized to publish this opportunity."
}
```

**Response: 402 Payment Required** — Eğer backend publish'de de kontrol etmek istiyorsa *(opsiyonel)*

> Not: Mobil uygulama bu senaryoyu zaten destekler. Ancak free tier mantığında
> publish için ek kısıtlama önerilmez — kullanıcı zaten kollab oluşturdu, yayınlamaya izin verilmeli.

---

### 4. `GET /api/v1/me/opportunities` — Kendi Kollablarım

Bu endpoint **total sayısını doğru döndürmeli**. Mobil uygulama free tier kontrolü için bu sayıyı kullanır.

**Auth:** `Authorization: Bearer {token}` (zorunlu)

**Query Parameters:**

| Param | Tip | Açıklama |
|-------|-----|----------|
| `page` | integer | Sayfa numarası (default: 1) |
| `per_page` | integer | Sayfa başı kayıt (default: 15) |
| `status` | string | Filtre: `draft` \| `published` \| `closed` \| `completed` |

**Örnek Request:**
```
GET /api/v1/me/opportunities?page=1&per_page=15
```

**Response: 200 OK**

```json
{
  "data": [
    {
      "id": "abc123",
      "title": "Restaurant Week Promotion",
      "status": "draft",
      "categories": ["Food & Drink"],
      "availability_start": "2026-04-15",
      "availability_end": "2026-04-16",
      "preferred_city": "Madrid",
      "applications_count": 0,
      "is_own": true,
      "created_at": "2026-03-03T14:22:00Z",
      "updated_at": "2026-03-03T14:22:00Z",
      "published_at": null
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 1
  }
}
```

> **ÖNEMLİ:** `meta.total` alanı **tüm statuslardaki toplam kollab sayısını** döndürmeli.
> Filtre uygulanmış olsa bile (örn. `?status=published`), `total` sadece o filtredeki
> değil **genel toplam** olmalıdır. Mobil uygulama bu değeri free tier kontrolü için kullanır.

**Alternatif:** `meta.total` her zaman filtresiz toplam ise ve `status` filtreli count ayrı
gösterilmek isteniyorsa `filtered_total` alanı eklenebilir:

```json
{
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 3,
    "filtered_total": 1
  }
}
```

---

### 5. `GET /api/v1/me/subscription` — Abonelik Durumu

Mevcut endpoint. Mobil uygulama bu endpoint'i `profileProvider` üzerinden çağırır ve
`subscription.isActive` alanını free tier kararında kullanır.

**Auth:** `Authorization: Bearer {token}` (zorunlu)

**Response: 200 OK — Aktif abonelik**

```json
{
  "data": {
    "id": "sub_1abc123",
    "status": "active",
    "status_label": "Active",
    "current_period_start": "2026-02-03",
    "current_period_end": "2026-03-03",
    "cancel_at_period_end": false
  }
}
```

**Response: 200 OK — Abonelik yok**

```json
{
  "data": null
}
```

veya

```json
{
  "data": {
    "id": null,
    "status": "inactive",
    "status_label": "No Subscription",
    "current_period_start": null,
    "current_period_end": null,
    "cancel_at_period_end": false
  }
}
```

> **Mobil kontrol:** `subscription?.isActive` → `status == "active"` ise `true`.

---

## Free Tier Kontrol Akışı

```
POST /api/v1/opportunities isteği geldi
        │
        ▼
Kullanıcının aktif aboneliği var mı?
        │
  EVET  │  HAYIR
        │     │
        │     ▼
        │  Kullanıcının kaç kollabu var?
        │  (tüm statuslar dahil: draft + published + closed + completed)
        │     │
        │  0  │  ≥ 1
        │     │      │
        ▼     ▼      ▼
     Devam  Devam  402 + requires_subscription: true
     (oluştur) (ücretsiz)
```

---

## Hata Response Formatı — Genel Kural

Mobil uygulama her hata response'unda şu alanları bekler:

```json
{
  "message": "string — kullanıcıya gösterilecek mesaj",
  "requires_subscription": false,
  "errors": {
    "field_name": ["hata mesajı 1", "hata mesajı 2"]
  }
}
```

| Alan | Tip | Zorunlu | Açıklama |
|------|-----|---------|----------|
| `message` | string | Evet | Ana hata mesajı |
| `requires_subscription` | boolean | Hayır (default: false) | **Bu `true` olunca paywall açılır** |
| `errors` | object | Hayır | Field-level validasyon hataları |

---

## Mobil Uygulama Entegrasyon Notu

Mobil uygulama **çift katmanlı** koruma yapar:

1. **Client-side (proaktif):** "Create Kollab" butonuna basılınca
   `profileProvider.subscription?.isActive` + `myOpportunitiesProvider.total`
   kontrol edilir. Abonelik yoksa ve total ≥ 1 ise, API'ya hiç istek atmadan
   direkt paywall gösterilir.

2. **API-side (fallback):** Eğer kullanıcı client kontrolünü bypass etse
   (deep link vb.), `POST /api/v1/opportunities` isteğinde `requires_subscription: true`
   döndüğünde form ekranında paywall otomatik açılır.

**Her iki durumda da `SubscriptionPaywall` modal'ı gösterilir. Backend kontrolü zorunludur.**
