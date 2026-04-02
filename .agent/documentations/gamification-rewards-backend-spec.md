# Gamification & Rewards — Backend API Specification

> **For:** Volkan Oluc (Backend Implementation)
> **Date:** 2026-03-30
> **Context:** Points engine, wallet, referrals, badges for Community + Business users. Mobile-first — backend deploys later.

---

## Database Schema (Laravel Migrations)

### Table: `wallets`
```php
Schema::create('wallets', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->uuid('profile_id')->unique();
    $table->foreign('profile_id')->references('id')->on('profiles')->cascadeOnDelete();
    $table->integer('points')->default(0);
    $table->integer('redeemed_points')->default(0);
    $table->boolean('pending_withdrawal')->default(false);
    $table->timestamps();
});
```

### Table: `point_ledger`
```php
Schema::create('point_ledger', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->uuid('profile_id');
    $table->foreign('profile_id')->references('id')->on('profiles')->cascadeOnDelete();
    $table->integer('points');  // positive = earned, negative = redeemed
    $table->string('event_type', 50);  // collaboration_complete|review_posted|ugc_posted|referral_1m|referral_4m|withdrawal
    $table->uuid('reference_id')->nullable();
    $table->string('description')->nullable();
    $table->timestamps();

    $table->index('profile_id');
    $table->index(['profile_id', 'event_type']);
});
```

### Table: `earned_badges`
```php
Schema::create('earned_badges', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->uuid('profile_id');
    $table->foreign('profile_id')->references('id')->on('profiles')->cascadeOnDelete();
    $table->string('badge_slug', 50);  // first_kolab|content_creator|community_earner|referral_pioneer|power_partner
    $table->timestamp('earned_at')->useCurrent();
    $table->timestamps();

    $table->unique(['profile_id', 'badge_slug']);
});
```

### Table: `referral_codes`
```php
Schema::create('referral_codes', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->uuid('profile_id')->unique();
    $table->foreign('profile_id')->references('id')->on('profiles')->cascadeOnDelete();
    $table->string('code', 20)->unique();  // e.g. KOLAB-A3X9
    $table->integer('total_conversions')->default(0);
    $table->integer('total_points_earned')->default(0);
    $table->timestamps();
});
```

### Table: `withdrawal_requests`
```php
Schema::create('withdrawal_requests', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->uuid('profile_id');
    $table->foreign('profile_id')->references('id')->on('profiles')->cascadeOnDelete();
    $table->integer('points');  // points being withdrawn
    $table->decimal('eur_amount', 10, 2);  // EUR equivalent
    $table->string('iban', 50);
    $table->string('account_holder', 255);
    $table->string('status', 20)->default('pending');  // pending|processing|completed|rejected
    $table->text('notes')->nullable();
    $table->timestamps();
});
```

---

## API Endpoints

### 1. GET /api/v1/gamification/wallet

**Auth:** Bearer token required

**Response 200:**
```json
{
  "data": {
    "points": 127,
    "redeemed_points": 0,
    "available_points": 127,
    "eur_value": 25.40,
    "progress": 0.3387,
    "can_withdraw": false,
    "pending_withdrawal": false,
    "withdrawal_threshold": 375
  }
}
```

**Response 404** (new user, no wallet yet — create one):
Backend should auto-create wallet on first access.

---

### 2. GET /api/v1/gamification/ledger

**Auth:** Bearer token required
**Query params:** `?page=1&per_page=20`

**Response 200:**
```json
{
  "data": [
    {
      "id": "uuid",
      "points": 1,
      "event_type": "collaboration_complete",
      "description": "Collaboration with Cafe Montjuic completed",
      "reference_id": "collab-uuid",
      "created_at": "2026-03-20T14:00:00.000000Z"
    },
    {
      "id": "uuid",
      "points": 1,
      "event_type": "review_posted",
      "description": "Review posted for Cafe Montjuic",
      "reference_id": "review-uuid",
      "created_at": "2026-03-20T15:30:00.000000Z"
    },
    {
      "id": "uuid",
      "points": 50,
      "event_type": "referral_1m",
      "description": "Referral: BCN Yoga Studio subscribed (1-month)",
      "reference_id": "referral-uuid",
      "created_at": "2026-03-18T10:00:00.000000Z"
    },
    {
      "id": "uuid",
      "points": -375,
      "event_type": "withdrawal",
      "description": "Withdrawal of €75.00",
      "reference_id": "withdrawal-uuid",
      "created_at": "2026-03-15T09:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 52
  }
}
```

---

### 3. GET /api/v1/gamification/badges

**Auth:** Bearer token required

Returns ALL 5 badge slugs, each marked earned or not.

**Response 200:**
```json
{
  "data": [
    {
      "slug": "first_kolab",
      "name": "First Kolab",
      "description": "Completed your first collaboration",
      "is_unlocked": true,
      "earned_at": "2026-02-10T12:00:00.000000Z"
    },
    {
      "slug": "content_creator",
      "name": "Content Creator",
      "description": "Posted 3 reviews or pieces of content",
      "is_unlocked": true,
      "earned_at": "2026-03-05T09:00:00.000000Z"
    },
    {
      "slug": "community_earner",
      "name": "Community Earner",
      "description": "Earned your first €20 in points",
      "is_unlocked": false,
      "earned_at": null
    },
    {
      "slug": "referral_pioneer",
      "name": "Referral Pioneer",
      "description": "Referred a business that converted",
      "is_unlocked": false,
      "earned_at": null
    },
    {
      "slug": "power_partner",
      "name": "Power Partner",
      "description": "Completed 5 collaborations",
      "is_unlocked": false,
      "earned_at": null
    }
  ]
}
```

### Badge Unlock Conditions (backend logic)

| Badge | Condition | Query |
|-------|-----------|-------|
| first_kolab | 1+ completed collab | `point_ledger WHERE event_type = 'collaboration_complete' COUNT >= 1` |
| content_creator | 3+ UGC/reviews | `point_ledger WHERE event_type IN ('review_posted','ugc_posted') COUNT >= 3` |
| community_earner | 100+ points | `wallets.points >= 100` |
| referral_pioneer | 1+ referral | `point_ledger WHERE event_type IN ('referral_1m','referral_4m') COUNT >= 1` |
| power_partner | 5+ collabs | `point_ledger WHERE event_type = 'collaboration_complete' COUNT >= 5` |

**When to evaluate:** After every `award_points()` call. Insert badge if condition met + not already earned.

---

### 4. GET /api/v1/gamification/referral-code

**Auth:** Bearer token required

Returns existing code or creates one.

**Response 200:**
```json
{
  "data": {
    "code": "KOLAB-A3X9",
    "referral_link": "https://kolabing.com/ref/KOLAB-A3X9",
    "total_conversions": 2,
    "total_points_earned": 150
  }
}
```

---

### 5. POST /api/v1/gamification/withdrawal

**Auth:** Bearer token required

**Request:**
```json
{
  "iban": "ES7921000813610123456789",
  "account_holder": "BCN Running Club SL"
}
```

**Response 201:**
```json
{
  "data": {
    "id": "uuid",
    "points": 375,
    "eur_amount": 75.00,
    "iban": "ES79****6789",
    "account_holder": "BCN Running Club SL",
    "status": "pending",
    "created_at": "2026-03-30T10:00:00.000000Z"
  },
  "message": "Withdrawal request submitted. Processing within 5-7 business days."
}
```

**Backend logic:**
1. Check `available_points >= 375`
2. Check `pending_withdrawal == false`
3. Create `withdrawal_requests` row
4. Create `point_ledger` entry with `points: -375, event_type: 'withdrawal'`
5. Update `wallets`: `redeemed_points += 375`, `pending_withdrawal = true`
6. Return masked IBAN

**Error 400:**
```json
{ "message": "Insufficient points. Need 375, have 120." }
```

**Error 409:**
```json
{ "message": "A withdrawal is already pending." }
```

---

### 6. Point Awarding (Backend Triggers — NOT mobile-initiated)

These are NOT API endpoints the mobile calls. These happen server-side when events occur:

| Trigger | Points | Event Type | When |
|---------|--------|------------|------|
| Collaboration completed | +1 | collaboration_complete | Both parties confirm completion |
| Review posted | +1 | review_posted | `POST /reviews` succeeds |
| UGC submitted | +1 | ugc_posted | `POST /collaborations/:id/content` succeeds |
| Referral 1-month | +50 | referral_1m | Referred business subscribes (1-month plan) |
| Referral 4-month | +100 | referral_4m | Referred business subscribes (4-month plan) |

**Backend function (pseudo):**
```php
function awardPoints($profileId, $points, $eventType, $referenceId, $description) {
    DB::transaction(function() {
        PointLedger::create([...]);
        Wallet::updateOrCreate(
            ['profile_id' => $profileId],
            ['points' => DB::raw("points + $points")]
        );
        $this->evaluateBadges($profileId);
    });
}
```

---

## Endpoint Summary

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/gamification/wallet` | Get wallet balance + progress |
| GET | `/api/v1/gamification/ledger?page=1&per_page=20` | Points history |
| GET | `/api/v1/gamification/badges` | All 5 badges with earned status |
| GET | `/api/v1/gamification/referral-code` | Get/create referral code |
| POST | `/api/v1/gamification/withdrawal` | Request cash withdrawal |

---

## Laravel Files to Create

| Action | File |
|--------|------|
| Create | `database/migrations/..._create_wallets_table.php` |
| Create | `database/migrations/..._create_point_ledger_table.php` |
| Create | `database/migrations/..._create_earned_badges_table.php` |
| Create | `database/migrations/..._create_referral_codes_table.php` |
| Create | `database/migrations/..._create_withdrawal_requests_table.php` |
| Create | `app/Models/Wallet.php` |
| Create | `app/Models/PointLedger.php` |
| Create | `app/Models/EarnedBadge.php` |
| Create | `app/Models/ReferralCode.php` |
| Create | `app/Models/WithdrawalRequest.php` |
| Create | `app/Services/GamificationService.php` (award_points, evaluate_badges) |
| Create | `app/Http/Controllers/Api/V1/GamificationController.php` |
| Create | `app/Http/Resources/WalletResource.php` |
| Create | `app/Http/Resources/LedgerResource.php` |
| Create | `app/Http/Resources/BadgeResource.php` |
| Create | `app/Http/Requests/WithdrawalRequest.php` |
| Modify | `routes/api.php` — add gamification routes |
| Modify | Controllers that handle collaboration completion, review posting, UGC — add `awardPoints()` calls |
