# Referral Subscription Contract

## Goal

Referral codes are now supported in the **Apple subscription flow** for business users.

The production-safe mobile flow is:

1. User enters a referral code on the subscription paywall.
2. App pre-validates the code with `POST /api/v1/referrals/validate`.
3. If purchase succeeds on iOS, app sends the same code to `POST /api/v1/me/subscription/apple-verify`.
4. Backend grants the reward **once**, on the first successful paid subscription.

## Supported Endpoints

### `POST /api/v1/referrals/validate`

Use this before starting Apple purchase.

Request:

```json
{
  "referral_code": "KOLAB-IRSC"
}
```

Success:

```json
{
  "success": true,
  "data": {
    "referral_code": "KOLAB-IRSC"
  }
}
```

Validation failure:

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "referral_code": ["The selected referral code is invalid."]
  }
}
```

The backend normalizes the code with `trim + uppercase` and rejects:

- invalid code
- expired code
- self-referral
- already-used code

### `POST /api/v1/me/subscription/apple-verify`

Request:

```json
{
  "transaction_id": "1000000123456789",
  "original_transaction_id": "1000000123456789",
  "product_id": "com.kolabing.app.subscription.monthly",
  "referral_code": "KOLAB-IRSC"
}
```

Notes:

- `referral_code` is optional.
- If present, send the same normalized code that passed `referrals/validate`.
- The endpoint is idempotent. Re-sending the same transaction must not create duplicate rewards.

Success:

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

Apple verification failure:

```json
{
  "success": false,
  "message": "Invalid transaction. Could not verify with Apple.",
  "error": "apple_verification_failed",
  "transaction_id": "1000000123456789"
}
```

Referral validation failure during verify:

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "referral_code": ["The selected referral code is invalid."]
  }
}
```

## Reward Behavior

- The **referral code owner** receives the reward.
- Reward is granted only on the **first successful paid subscription** for the referred business profile.
- Reward is granted only once, even if:
  - app retries `apple-verify`
  - Apple replays notifications
  - user restores purchases later
- Current reward value is:
  - `50` points
  - roughly `€10` wallet value at the current gamification conversion
- The purchaser does **not** receive a separate referral bonus.

## Mobile Constraints

- This backend is **Apple-only for paid subscriptions**.
- Do **not** use old Stripe endpoints from mobile:
  - `POST /api/v1/me/subscription/checkout`
  - `GET /api/v1/me/subscription/portal`
  - `POST /api/v1/me/subscription/cancel`
  - `POST /api/v1/me/subscription/reactivate`
- Android currently has no native paid subscription purchase path in backend. Treat Android as informational-only until a separate strategy is defined.

## Recommended Mobile UX

### iOS Subscription Flow

1. User opens paywall.
2. User enters referral code.
3. App calls `POST /api/v1/referrals/validate`.
4. If valid, show “Referral code applied.”
5. Start native Apple purchase.
6. On purchase success, call `POST /api/v1/me/subscription/apple-verify`.
7. Refresh `GET /api/v1/me/subscription`.

### Restore Flow

Use `POST /api/v1/me/subscription/apple-restore` if you keep a separate restore button, or rely on idempotent `apple-verify` if your restore UX reuses the same purchased transaction.
