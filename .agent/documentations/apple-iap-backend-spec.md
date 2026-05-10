# Apple IAP + Referral Backend API Specification

> **For:** Kolabing mobile app
> **Date:** 2026-05-09
> **Status:** Implemented on backend
> **Context:** Paid subscriptions are now Apple-only in backend. Stripe subscription endpoints are removed.

---

## Overview

Mobile app should treat subscription purchase as an Apple IAP flow for iOS:

1. optionally validate referral code
2. complete native Apple purchase
3. verify transaction with backend
4. read final subscription state from `GET /api/v1/me/subscription`

Backend also processes App Store Server Notifications V2 to keep subscription state synchronized over time.

---

## Endpoint 1: Read Current Subscription

### `GET /api/v1/me/subscription`

**Auth:** Bearer token required

### Success

```json
{
  "success": true,
  "data": {
    "id": "subscription-uuid",
    "status": "active",
    "status_label": "Active",
    "source": "apple_iap",
    "current_period_start": "2026-05-09T12:00:00Z",
    "current_period_end": "2026-06-09T12:00:00Z",
    "cancel_at_period_end": false,
    "is_active": true,
    "days_remaining": 30,
    "apple_product_id": "com.kolabing.app.subscription.monthly"
  }
}
```

### No subscription yet

```json
{
  "success": true,
  "data": null,
  "message": "No subscription found"
}
```

---

## Endpoint 2: Validate Referral Code

### `POST /api/v1/referrals/validate`

**Auth:** Bearer token required

### Request

```json
{
  "referral_code": "KOLAB-IRSC"
}
```

### Success

```json
{
  "success": true,
  "data": {
    "referral_code": "KOLAB-IRSC"
  }
}
```

### Validation failure

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "referral_code": ["The selected referral code is invalid."]
  }
}
```

### Backend rules

- `trim + uppercase` normalization
- rejects invalid, expired, self-referral, and already-used codes

---

## Endpoint 3: Verify Apple Purchase

### `POST /api/v1/me/subscription/apple-verify`

**Auth:** Bearer token required

### Request

```json
{
  "transaction_id": "2000000123456789",
  "original_transaction_id": "2000000123456789",
  "product_id": "com.kolabing.app.subscription.monthly",
  "referral_code": "KOLAB-IRSC"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `transaction_id` | string | yes | Apple transaction ID |
| `original_transaction_id` | string | yes | Original transaction ID |
| `product_id` | string | yes | StoreKit product ID |
| `referral_code` | string | no | Optional referral code |

### Success

```json
{
  "success": true,
  "data": {
    "id": "subscription-uuid",
    "status": "active",
    "status_label": "Active",
    "source": "apple_iap",
    "current_period_start": "2026-05-09T12:00:00Z",
    "current_period_end": "2026-06-09T12:00:00Z",
    "cancel_at_period_end": false,
    "is_active": true,
    "days_remaining": 30,
    "apple_product_id": "com.kolabing.app.subscription.monthly"
  }
}
```

### Apple verification failure

```json
{
  "success": false,
  "message": "Invalid transaction. Could not verify with Apple.",
  "error": "apple_verification_failed",
  "transaction_id": "2000000123456789"
}
```

### Referral validation failure

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "referral_code": ["The selected referral code is invalid."]
  }
}
```

### Backend behavior

- Verifies transaction with Apple App Store Server API
- Cross-checks request payload against Apple payload
- Upgrades existing inactive subscription row in place
- Idempotent for repeated `transaction_id`
- If referral code is valid, grants reward only on the first successful paid subscription

---

## Endpoint 4: Restore Purchases

### `POST /api/v1/me/subscription/apple-restore`

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

### Success

```json
{
  "success": true,
  "data": {
    "id": "subscription-uuid",
    "status": "active",
    "status_label": "Active",
    "source": "apple_iap",
    "current_period_start": "2026-05-09T12:00:00Z",
    "current_period_end": "2026-06-09T12:00:00Z",
    "cancel_at_period_end": false,
    "is_active": true,
    "days_remaining": 30,
    "apple_product_id": "com.kolabing.app.subscription.monthly"
  },
  "message": "Subscription restored successfully."
}
```

### No valid subscription found

```json
{
  "success": false,
  "message": "No active subscription found for this Apple account.",
  "is_active": false
}
```

---

## Webhook-Driven State Changes

Apple notifications update the same subscription record.

| Notification | Result |
|-------------|--------|
| `SUBSCRIBED` | activate subscription |
| `DID_RENEW` | extend subscription period |
| `DID_CHANGE_RENEWAL_STATUS` + `AUTO_RENEW_DISABLED` | set `cancel_at_period_end = true` |
| `DID_FAIL_TO_RENEW` + `GRACE_PERIOD` | keep `status = active` until grace end |
| `DID_FAIL_TO_RENEW` without grace | set `status = past_due` |
| `EXPIRED` | set `status = inactive` |
| `GRACE_PERIOD_EXPIRED` | set `status = inactive` |
| `REFUND` | set `status = inactive` |
| `REVOKE` | set `status = inactive` |

This means mobile should always trust `GET /api/v1/me/subscription` for the latest state instead of assuming local purchase state is final.

---

## Referral Reward Semantics

- Referrer receives the reward.
- Referred purchaser does not receive a separate bonus.
- Reward happens only on the first successful paid subscription.
- Current reward:
  - `50` points
  - approximately `€10` of wallet value

---

## Removed Endpoints

Do not call these from mobile anymore:

- `POST /api/v1/me/subscription/checkout`
- `GET /api/v1/me/subscription/portal`
- `POST /api/v1/me/subscription/cancel`
- `POST /api/v1/me/subscription/reactivate`
- `POST /api/v1/webhooks/stripe`

---

## Product Constraint

Backend currently supports **Apple-only paid subscriptions**.

- iOS: use Apple IAP flow above
- Android: no native paid purchase endpoint is available yet

If Android purchase is needed later, product needs a separate decision such as informational-only UI or a web purchase strategy.
