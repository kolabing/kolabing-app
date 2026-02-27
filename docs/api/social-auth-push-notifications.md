# Backend API Spec: Apple Auth + FCM Token

> Bu endpoint'leri backend'de implement etmen gerekiyor.

---

## POST /api/v1/auth/apple

**Amaç:** Apple Sign In identity token ile kullanıcı girişi.

### Request

```
POST /api/v1/auth/apple
Content-Type: application/json
```

```json
{
  "identity_token": "eyJhbGci...",
  "name": "John Doe"
}
```

| Alan | Tip | Zorunlu | Açıklama |
|------|-----|---------|----------|
| `identity_token` | string | YES | Apple JWT identity token |
| `name` | string | NO | Sadece ilk giriste gelir, max 255 |

### Backend Steps
1. identity_token Apple public keys ile dogrula: https://appleid.apple.com/auth/keys
2. Token'dan sub (Apple user ID) ve email cikart
3. sub VEYA email ile kullanici bul
4. Bulunmazsa 404 don
5. Bearer token don (Google endpoint ile ayni format)

### Response 200/201
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "66|bearertoken...",
    "token_type": "Bearer",
    "is_new_user": false,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "user_type": "business",
      "avatar_url": null,
      "email_verified_at": "2026-01-01T00:00:00Z",
      "onboarding_completed": true,
      "created_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-01T00:00:00Z"
    }
  }
}
```

### Response 404
```json
{
  "success": false,
  "message": "No account found with this Apple ID. Please register first.",
  "errors": null
}
```

### Response 422
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "identity_token": ["The identity token field is required."]
  }
}
```

---

## POST /api/v1/me/device-token

**Amac:** Login sonrasi FCM token'i kaydet/guncelle.

### Request
```
POST /api/v1/me/device-token
Content-Type: application/json
Authorization: Bearer {user_token}
```

```json
{
  "token": "fcm_device_token_here",
  "platform": "ios"
}
```

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `token` | string | YES | FCM device token |
| `platform` | string | YES | ios veya android |

### Response 200
```json
{
  "success": true,
  "message": "Device token registered successfully"
}
```

---

## Backend'den Push Gondermek (Laravel)

```bash
composer require kreait/firebase-php
```

```php
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

$message = CloudMessage::withTarget('token', $user->device_token)
    ->withNotification(Notification::create($title, $body))
    ->withData([
        'type' => 'application', // application | message | collaboration
        'id'   => $entity->id,
    ]);

app('firebase.messaging')->send($message);
```

### Flutter Navigation Data Payload

| type | Route |
|------|-------|
| application | /application/{id} |
| message | /chat/{id} |
| collaboration | /collaboration/{id} |
