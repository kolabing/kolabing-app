# Task: Apple Subscription Referral Mobile Documentation

## Status
- Created: 2026-05-09 14:55
- Started: 2026-05-09 14:55
- Completed: 2026-05-09 14:55

## Description
Document the final mobile integration contract for Apple-only subscriptions and referral validation after backend implementation.

## Related API Endpoints
- [x] `GET /api/v1/me/subscription`
- [x] `POST /api/v1/referrals/validate`
- [x] `POST /api/v1/me/subscription/apple-verify`
- [x] `POST /api/v1/me/subscription/apple-restore`
- [x] `POST /api/v1/webhooks/apple`

## Assigned Agents
- [x] @flutter-expert

## Progress

### Documentation
**Status:** Completed
- Updated referral integration contract to reflect Apple-only purchase flow
- Updated Apple IAP backend spec to reflect final implemented backend behavior
- Documented removed Stripe endpoints and Android limitation

## Notes
- Mobile should preflight referral codes before purchase.
- Repeated `apple-verify` calls are idempotent and must not create duplicate rewards.
- Android currently has no paid subscription purchase backend path.
