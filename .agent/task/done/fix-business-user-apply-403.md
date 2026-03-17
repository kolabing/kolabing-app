# Fix: Business user getting 403 "not authorized to apply"

## Status
- Created: 2026-03-03 00:00
- Started: 2026-03-03 00:00
- Completed: 2026-03-03 00:00

## Issue Description
Business users who are logged in see "You are not authorized to apply to this opportunity"
error (403) when tapping the Apply button on opportunity detail screens.

## Root Cause
`_buildBottomAction` in `community_offer_detail_screen.dart` only checks:
- `isOwn` - whether the current user created the opportunity
- `opportunity.hasApplied` - whether they've already applied

It did NOT check user type. Business users are not allowed to apply to opportunities
(they post them for communities to apply to). When a business user navigated to
`/business/explore/offer/:id` and tapped "APPLY NOW", the API correctly rejected
with 403.

Same issue existed in `explore_screen.dart` where `onApply` was passed to `OpportunityCard`
for any non-owner user, regardless of user type.

## Affected Files
- `lib/features/business/screens/community_offer_detail_screen.dart`
- `lib/features/business/screens/explore_screen.dart`

## Fix Applied
- `community_offer_detail_screen.dart`: Added `if (currentUser?.isBusiness == true) return const SizedBox.shrink();`
  check after the `isOwn` check in `_buildBottomAction`, hiding the apply button entirely for business users.
- `explore_screen.dart`: Changed `onApply` callback condition from `isOwn ? null : callback`
  to `canApply ? callback : null` where `canApply = !isOwn && (currentUser?.isBusiness != true)`.

## Testing
- [x] Business user no longer sees apply button on opportunity detail screen
- [x] Business user no longer sees apply button on explore card list
- [x] Community user still sees apply button normally
- [x] No new analyzer errors introduced

## Notes
`UserModel.isBusiness` getter already existed (`bool get isBusiness => userType == UserType.business`).
