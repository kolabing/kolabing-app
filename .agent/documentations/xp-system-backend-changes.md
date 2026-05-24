# XP System — Backend Changes Required

**Date:** 2026-05-24  
**Author:** Claude Code (on behalf of product team)  
**Status:** Flutter implementation complete — backend changes pending  

---

## Context

The community rewards system was fully rebuilt on the Flutter side. The old model was a points-to-EUR wallet where users accumulated points toward a €375 withdrawal threshold. This has been replaced with an XP-based reputation system.

### New system summary

- **XP = community reputation.** It is not convertible to cash. It drives levels, badges, and identity.
- **Cash = separate referral bonus only.** €75 when a community user refers 3 businesses who subscribe to a 4-month plan.
- **5 community levels** (computed client-side from raw XP total):

| Level | Name | XP Range |
|-------|------|----------|
| 1 | New Community | 0 – 99 |
| 2 | Active Community | 100 – 249 |
| 3 | Trusted Community | 250 – 499 |
| 4 | Local Favorite | 500 – 999 |
| 5 | Local Legend | 1000+ |

- **XP economy (target values):**

| Action | XP |
|--------|-----|
| Complete a collaboration | +10 XP |
| Post a review | +10 XP |
| Share content (UGC) | +10 XP |
| Refer a business (any conversion) | +50 XP |

- **9 badges** across 3 categories (entry, growth, referral). See badge section below.

---

## What the Flutter app currently does

The Flutter app reads from the **existing API endpoints unchanged**. No new endpoints are required for the MVP.

| Endpoint | What Flutter reads | Notes |
|----------|--------------------|-------|
| `GET /api/v1/gamification/wallet` | `points` field → shown as total XP | EUR fields ignored |
| `GET /api/v1/gamification/ledger` | Same as before | Labels updated client-side |
| `GET /api/v1/gamification/badges` | Same slugs as before | Display names updated client-side |
| `GET /api/v1/gamification/referral-code` | `code`, `referral_link`, `total_conversions` | `total_conversions` used for 0/3 cash milestone |

The Flutter app **does not call** `POST /api/v1/gamification/withdrawal` unless the user navigates to the cash milestone screen and explicitly requests it. The withdrawal flow is no longer surfaced in the main navigation.

---

## Backend changes required

### Priority 1 — Critical (XP values are wrong without this)

#### 1.1 Award 10 XP per action (not 1)

**File:** `app/Services/GamificationWalletService.php`  
**Or wherever:** `PointEventType::defaultPoints()` is defined  

**Current behavior:** Every action awards 1 point.  
**Required behavior:**

```php
public static function defaultPoints(): int
{
    return match($this) {
        self::COLLABORATION_COMPLETE => 10,
        self::REVIEW_POSTED         => 10,
        self::UGC_POSTED            => 10,
        self::REFERRAL_CONVERSION   => 50, // unchanged
        self::WITHDRAWAL            => 0,
        default                     => 0,
    };
}
```

**Why this matters:** With 1 pt per action, a user needs 1000 collabs to reach Local Legend. The level thresholds (100 / 250 / 500 / 1000) are designed for 10 XP per action. Until this changes, the Flutter UI will show accurate levels but they will be nearly impossible to reach.

**Production data impact:** This only affects future point awards. Existing `points` balances in the `user_wallets` (or equivalent) table are not modified — historical records stay as-is. Users who already have points will simply have lower XP than they would have had under the new system. This is acceptable for a soft launch.

---

#### 1.2 Update badge unlock thresholds

**File:** `app/Services/GamificationWalletService.php` → `evaluateBadges()` or equivalent  

**`community_earner` badge** — unlock when user reaches 250 XP (was 100 points):

```php
// Old
case 'community_earner': return $user->total_points >= 100;

// New
case 'community_earner': return $user->total_points >= 250;
```

**`power_partner` badge** — unlock at 10 completed collaborations (was 5):

```php
// Old
case 'power_partner': return $completedCollabsCount >= 5;

// New
case 'power_partner': return $completedCollabsCount >= 10;
```

**Production data impact:** Users who previously earned these badges keep them — badge records are not deleted. The threshold only affects future evaluations. Users who unlocked `community_earner` at 100 pts (old threshold) will not lose the badge.

---

### Priority 2 — Medium (referral cash milestone display)

#### 2.1 Confirm `total_conversions` is returned by the referral-code endpoint

**File:** `app/Http/Resources/Api/V1/ReferralCodeResource.php`

The Flutter app reads `total_conversions` from `GET /api/v1/gamification/referral-code` to display the 0/3 cash milestone progress bar.

**Verify this field exists in the response:**

```php
return [
    'code'               => $this->code,
    'referral_link'      => $this->referral_link,
    'total_conversions'  => $this->total_conversions ?? 0, // ← must exist
    'total_points_earned'=> $this->total_points_earned ?? 0,
];
```

**Important clarification needed:** The €75 cash milestone requires 3 businesses on a **4-month plan** specifically. If `total_conversions` counts all referrals (including 1-month), you may want a separate field:

```php
'qualified_conversions' => $this->qualified_4month_conversions ?? 0,
```

And then tell the mobile team to switch the Flutter field read from `total_conversions` to `qualified_conversions`. This is a one-line Flutter change once the field exists.

---

### Priority 3 — Low / Future (new badge slugs)

The Flutter app handles unknown badge slugs gracefully (they fall back silently). These can be added in a future sprint without breaking the current app.

**File:** `app/Enums/GamificationBadgeSlug.php`

Add the following new enum cases:

```php
case STORYTELLER      = 'storyteller';       // Unlock: 5 reviews posted
case TRUSTED_VOICE    = 'trusted_voice';     // Unlock: reach 50 XP
case LOCAL_LEGEND_B   = 'local_legend';      // Unlock: reach 1000 XP (Local Legend level)
case GROWTH_CATALYST  = 'growth_catalyst';   // Unlock: 3 qualified business referrals
```

Also add the corresponding badge conditions in `evaluateBadges()` for each slug.

**Note:** The Flutter badge display names are now:
| Slug (PHP — do not change) | Flutter display name |
|---------------------------|----------------------|
| `first_kolab` | First Kolab |
| `content_creator` | Storyteller |
| `community_earner` | Community Builder |
| `referral_pioneer` | Plugged In |
| `power_partner` | Momentum Club |

**The slug strings must never change.** Only display names live in Flutter.

---

## What does NOT need to change in the backend

- The `withdrawal` endpoint (`POST /api/v1/gamification/withdrawal`) — keep as-is. The IBAN/account holder form still works, it's just surfaced differently in the app now.
- The `ledger` endpoint — keep as-is. The Flutter app maps old string values (`referral_1m`, `referral_4m`) to the new `referralConversion` type client-side.
- The `wallet` endpoint — keep as-is. Flutter reads `points` as XP total. EUR-related fields in the response are ignored by the app.
- The `badges` endpoint — keep as-is. The 5 existing slugs all still work.

---

## Rollback notes

All Flutter changes are in `git` and can be reverted with `git checkout`. No backend files were modified in this session. No database migrations were run.

The backend changes above are additive:
- Changing `defaultPoints()` is a code-only change, no migration needed.
- Changing badge thresholds is a code-only change, no migration needed.
- Adding new badge slugs requires an enum extension + badge condition logic, no table migration needed (assuming badges are evaluated dynamically, not pre-seeded rows).

If the `user_wallets` table has a `eur_value` or `withdrawal_threshold` column, those can be left in place — the Flutter app simply ignores them now.

---

## Questions for the backend developer to answer before deploying

1. Does `GET /api/v1/gamification/referral-code` already return `total_conversions`? If yes, does it count all referrals or only 4-month qualified ones?
2. Are badge conditions evaluated dynamically on each API call, or are they cached/stored at award time?
3. Is there a way to retroactively recalculate points for existing users if we want to give them 10x their current balance to match the new economy? (Optional, but worth discussing.)
