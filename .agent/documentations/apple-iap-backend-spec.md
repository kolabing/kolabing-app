# Apple IAP Backend API Specification

> **For:** Volkan Oluc (Backend Implementation)
> **Date:** 2026-03-27
> **Status:** Ready for implementation
> **Context:** Apple rejects apps that use external payment (Stripe) for in-app subscriptions. iOS must use Apple IAP. Android keeps Stripe.

---

## Overview

Mobile app will send Apple IAP transaction data to backend for verification. Backend must:
1. Verify the transaction with Apple's App Store Server API
2. Create/update subscription record with `source = 'apple_iap'`
3. Listen for Apple Server Notifications V2 (renewals, cancellations, refunds)

**Existing endpoints stay untouched.** Stripe flow continues for Android users.

---

## Database Migration

### Alter `business_subscriptions` table

```sql
ALTER TABLE business_subscriptions
ADD COLUMN source VARCHAR(20) NOT NULL DEFAULT 'stripe',           -- 'stripe' | 'apple_iap'
ADD COLUMN apple_original_transaction_id VARCHAR(255) NULL,         -- Apple's original transaction ID
ADD COLUMN apple_transaction_id VARCHAR(255) NULL,                  -- Latest Apple transaction ID
ADD COLUMN apple_product_id VARCHAR(255) NULL;                      -- e.g. com.kolabing.app.subscription.monthly
```

**Backfill:** All existing rows get `source = 'stripe'` (the default).

---

## App Store Connect Setup

Before backend work, these must be configured in App Store Connect:

| Setting | Value |
|---------|-------|
| **Product ID** | `com.kolabing.app.subscription.monthly` |
| **Type** | Auto-Renewable Subscription |
| **Price** | 34.99 EUR (Tier 56 or closest) |
| **Subscription Group** | "Kolabing Premium" |
| **Server Notification URL** | `https://kolabing.com/api/v1/webhooks/apple` |
| **Server Notification Version** | V2 |
| **App Shared Secret** | Generate in App Store Connect → used for receipt verification |

---

## Endpoint 1: Verify Apple IAP Transaction

### `POST /api/v1/me/subscription/apple-verify`

**Purpose:** Mobile sends Apple transaction after successful purchase. Backend verifies with Apple, creates subscription record.

**Auth:** Bearer token required

### Request

```json
{
  "transaction_id": "2000000123456789",
  "original_transaction_id": "2000000123456789",
  "product_id": "com.kolabing.app.subscription.monthly"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `transaction_id` | string | yes | Apple's transaction ID from `PurchaseDetails.purchaseID` |
| `original_transaction_id` | string | yes | Original transaction ID (same for renewals) |
| `product_id` | string | yes | App Store product identifier |

### Response (200) — Success

```json
{
  "data": {
    "id": "sub_apple_9c3f7a1d",
    "status": "active",
    "status_label": "Active",
    "source": "apple_iap",
    "current_period_start": "2026-03-27T14:30:00.000000Z",
    "current_period_end": "2026-04-27T14:30:00.000000Z",
    "cancel_at_period_end": false,
    "is_active": true,
    "days_remaining": 30,
    "apple_product_id": "com.kolabing.app.subscription.monthly"
  }
}
```

### Response (400) — Invalid Transaction

```json
{
  "message": "Invalid transaction. Could not verify with Apple.",
  "error": "apple_verification_failed"
}
```

### Response (409) — Already Verified

```json
{
  "data": {
    "id": "sub_apple_9c3f7a1d",
    "status": "active",
    "...": "... existing subscription data"
  },
  "message": "Transaction already verified."
}
```

### Backend Logic

```
1. Receive transaction_id, original_transaction_id, product_id
2. Call Apple App Store Server API:
   GET https://api.storekit.itunes.apple.com/inApps/v1/transactions/{transaction_id}
   (Use signed JWT for auth — see Apple docs)
3. Verify response:
   - bundleId matches your app
   - productId matches
   - Transaction is not revoked
4. Check if subscription exists for this original_transaction_id:
   - If exists: update status, period dates, transaction_id
   - If not: create new business_subscriptions record
5. Set fields:
   - source = 'apple_iap'
   - status = 'active'
   - apple_original_transaction_id = original_transaction_id
   - apple_transaction_id = transaction_id
   - apple_product_id = product_id
   - current_period_start = transaction.purchaseDate
   - current_period_end = transaction.expiresDate
6. Return subscription object in standard format
```

---

## Endpoint 2: Restore Apple Purchases

### `POST /api/v1/me/subscription/apple-restore`

**Purpose:** User taps "Restore Purchases" on iOS. Mobile sends all restorable transactions. Backend verifies and re-links.

**Auth:** Bearer token required

### Request

```json
{
  "transactions": [
    {
      "transaction_id": "2000000123456789",
      "original_transaction_id": "2000000123456789",
      "product_id": "com.kolabing.app.subscription.monthly"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `transactions` | array | yes | All restorable transactions from StoreKit |
| `transactions[].transaction_id` | string | yes | Transaction ID |
| `transactions[].original_transaction_id` | string | yes | Original transaction ID |
| `transactions[].product_id` | string | yes | Product identifier |

### Response (200) — Subscription Found & Restored

```json
{
  "data": {
    "id": "sub_apple_9c3f7a1d",
    "status": "active",
    "status_label": "Active",
    "source": "apple_iap",
    "current_period_start": "2026-03-27T14:30:00.000000Z",
    "current_period_end": "2026-04-27T14:30:00.000000Z",
    "cancel_at_period_end": false,
    "is_active": true,
    "days_remaining": 30,
    "apple_product_id": "com.kolabing.app.subscription.monthly"
  },
  "message": "Subscription restored successfully."
}
```

### Response (404) — No Active Subscription Found

```json
{
  "message": "No active subscription found for this Apple account.",
  "is_active": false
}
```

### Backend Logic

```
1. Receive transactions array
2. For each transaction, verify with Apple API (same as verify endpoint)
3. Find the most recent valid, non-expired transaction
4. Link to current user's profile:
   - Find or create business_subscriptions record
   - Update source = 'apple_iap', status based on Apple response
5. Return subscription or 404
```

---

## Endpoint 3: Apple Server Notifications V2 Webhook

### `POST /api/v1/webhooks/apple`

**Purpose:** Apple sends real-time notifications for subscription lifecycle events. No auth token — verify via Apple's signed JWT (JWS).

**Auth:** None (public endpoint). Verify Apple's signed payload (JWS) using Apple's public key.

### Request (from Apple)

Apple sends a JWS (JSON Web Signature) with this payload structure:

```json
{
  "notificationType": "DID_RENEW",
  "subtype": "",
  "data": {
    "signedTransactionInfo": "eyJ...<signed JWT>",
    "signedRenewalInfo": "eyJ...<signed JWT>"
  },
  "version": "2.0",
  "signedDate": 1711540200000
}
```

### Notification Types to Handle

| notificationType | Action |
|-----------------|--------|
| `SUBSCRIBED` | New subscription — activate |
| `DID_RENEW` | Auto-renewal succeeded — extend period |
| `DID_CHANGE_RENEWAL_STATUS` | User turned off auto-renew — set `cancel_at_period_end = true` |
| `DID_FAIL_TO_RENEW` | Payment failed — set status `past_due` |
| `EXPIRED` | Subscription expired — set status `inactive` |
| `GRACE_PERIOD_EXPIRED` | Grace period over — set status `inactive` |
| `REFUND` | Apple issued refund — set status `inactive` |
| `REVOKE` | Family sharing revoked — set status `inactive` |

### Response

```
HTTP 200 OK (empty body)
```

Apple expects 200 within 5 seconds. Any other status = Apple retries.

### Backend Logic

```
1. Receive JWS payload
2. Decode and verify JWS signature using Apple's public certificates
   (Fetch from: https://appleid.apple.com/auth/keys)
3. Decode signedTransactionInfo JWT → get originalTransactionId, productId, expiresDate
4. Find subscription by apple_original_transaction_id
5. Update based on notificationType:
   - DID_RENEW: status=active, extend current_period_end
   - DID_CHANGE_RENEWAL_STATUS: set cancel_at_period_end
   - EXPIRED/REFUND/REVOKE: status=inactive, is_active=false
   - DID_FAIL_TO_RENEW: status=past_due
6. Return 200
```

---

## Endpoint 4: Get Subscription (EXISTING — Minor Update)

### `GET /api/v1/me/subscription`

**No changes to the endpoint.** Just add `source` field to response.

### Updated Response

```json
{
  "data": {
    "id": "sub_stripe_abc123",
    "status": "active",
    "status_label": "Active",
    "source": "stripe",
    "current_period_start": "2026-03-01T00:00:00.000000Z",
    "current_period_end": "2026-04-01T00:00:00.000000Z",
    "cancel_at_period_end": false,
    "is_active": true,
    "days_remaining": 5
  }
}
```

**New field:**
| Field | Type | Description |
|-------|------|-------------|
| `source` | string | `stripe` or `apple_iap` |

Mobile app will use this to know which cancellation flow to show:
- `stripe` → open Stripe billing portal
- `apple_iap` → show "Manage in Settings" (iOS subscription management)

---

## Summary of All Endpoints

| Method | Path | Status | Purpose |
|--------|------|--------|---------|
| `POST` | `/api/v1/me/subscription/apple-verify` | **NEW** | Verify Apple IAP transaction |
| `POST` | `/api/v1/me/subscription/apple-restore` | **NEW** | Restore purchases |
| `POST` | `/api/v1/webhooks/apple` | **NEW** | Apple Server Notifications V2 |
| `GET` | `/api/v1/me/subscription` | **UPDATE** | Add `source` field to response |
| `POST` | `/api/v1/me/subscription/checkout` | No change | Stripe checkout (Android only) |
| `GET` | `/api/v1/me/subscription/portal` | No change | Stripe portal (Android only) |
| `POST` | `/api/v1/me/subscription/cancel` | No change | Stripe cancel (Android only) |
| `POST` | `/api/v1/me/subscription/reactivate` | No change | Stripe reactivate (Android only) |

---

## Laravel Files to Create/Modify

| Action | File | What |
|--------|------|------|
| Create | `database/migrations/..._add_apple_fields_to_subscriptions.php` | Add source, apple_* columns |
| Create | `app/Services/AppleIAPService.php` | Verify transactions, decode JWS |
| Create | `app/Http/Controllers/Api/V1/AppleIAPController.php` | verify + restore endpoints |
| Create | `app/Http/Controllers/Api/V1/AppleWebhookController.php` | Webhook handler |
| Modify | `app/Http/Resources/SubscriptionResource.php` | Add `source` field |
| Modify | `routes/api.php` | Add 3 new routes |
| Config | `.env` | Add `APPLE_SHARED_SECRET`, `APPLE_BUNDLE_ID`, `APPLE_ISSUER_ID`, `APPLE_KEY_ID` |

---

## Environment Variables Needed

```env
APPLE_BUNDLE_ID=com.serragcvc.kolabing
APPLE_SHARED_SECRET=<from App Store Connect>
APPLE_KEY_ID=<from App Store Connect → Keys>
APPLE_ISSUER_ID=<from App Store Connect → Keys>
APPLE_PRIVATE_KEY_PATH=storage/app/apple/AuthKey_XXXXX.p8
APPLE_IAP_ENVIRONMENT=sandbox  # sandbox | production
```

---

## Testing

### Sandbox Testing
1. Create sandbox tester in App Store Connect → Users → Sandbox Testers
2. On device: Settings → App Store → sign out → sign in with sandbox account
3. Mobile app → subscribe → Apple shows "[Environment: Sandbox]" dialog
4. Backend receives transaction → verify against sandbox API:
   - Sandbox: `https://api.storekit-sandbox.itunes.apple.com/...`
   - Production: `https://api.storekit.itunes.apple.com/...`

### Sandbox Renewal Schedule
Apple accelerates renewals in sandbox:

| Real Duration | Sandbox Duration |
|---------------|-----------------|
| 1 month | 5 minutes |
| 1 year | 1 hour |

So you can test full renewal cycle in minutes.
