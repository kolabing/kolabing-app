# Backend addendum — invite community member by email (NF-6)

> ✅ **DONE 2026-06-04** in `kolabing-v2` — `StoreCommunityMemberRequest` (email/profile_id/tier_id),
> `CommunityMemberController@store` (email→Profile resolve, 404 `profile_not_found`, foreign-tier 422),
> `CommunityMemberService::addMember($community,$profileId,$tierId)`. 5 feature tests added in
> `CommunityEndpointsTest` (all green: existing email→201, unknown→404, initial tier, foreign-tier→422,
> email-or-profile_id required). profile_id back-compat retained.

> **Target repo:** `kolabing-v2`. Small change to the existing
> `POST /communities/{community}/members` endpoint. The app now invites by
> **email** instead of profile UUID (no searchable picker).

## Why
The roster invite UI was a raw `profile_id` UUID field (placeholder). Per
product, it's now an **email** field — a leader invites someone by the email on
their Kolabing account. There is no email→profile lookup endpoint today, so the
member-add endpoint must accept an email and resolve it.

## Change
`StoreCommunityMemberRequest` — accept **`email`** (and keep `profile_id`
optional for backward-compat):
```php
'email'      => ['required_without:profile_id', 'email'],
'profile_id' => ['required_without:email', 'uuid', 'exists:profiles,id'],
'tier_id'    => ['nullable', 'uuid', 'exists:community_tiers,id'], // optional initial tier
```

`CommunityMemberController@store` / `CommunityMemberService::addMember`:
- If `email` given, resolve `Profile::where('email', $email)->first()`.
  - No match → **404** `{"success":false,"error":"profile_not_found","message":"…"}`.
  - Match → add that profile as a member (same path as profile_id).
- Reuse the existing add logic (default tier, UNIQUE guard, etc.).
- Optional `tier_id` to set the initial tier on add.

## App contract (already shipped on `community-member-flow`)
- App sends: `POST /communities/{id}/members` body `{ "email": "name@example.com" }` (lowercased, trimmed).
- App reads the **404 `error: profile_not_found`** → shows "No Kolabing account found for that email".
- Success → 201 `CommunityMemberResource` (unchanged shape).

## Acceptance
1. Invite by an existing account's email → 201, member added, appears in roster.
2. Invite by an unknown email → 404 `profile_not_found`.
3. Existing `profile_id` callers still work.
4. Duplicate (already a member) → existing UNIQUE/validation behaviour.

## Future (not now)
Real invitations to non-members (email an invite link to someone without a
Kolabing account) — out of scope; this only adds existing accounts by email.
