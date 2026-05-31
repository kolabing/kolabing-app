# PROMPT — Admin: manage the XP / rewards economy (+ a config endpoint the app reads)

Hand this to the **admin-dashboard / backend agent** (`kolabing-v2`). Self-contained.

> **Companion to [`2026-06-01-admin-challenges-prompt.md`](./2026-06-01-admin-challenges-prompt.md).**
> That prompt makes the **challenge catalogue** admin-managed (per-challenge
> `points`, `audience`, defaults, per-collaboration bonuses). This prompt covers
> **everything else in the gamification economy** — XP levels, the per-action XP
> awards, badge requirements, and the referral/withdrawal economics — none of
> which has an admin surface, and **all of which the mobile app currently
> hardcodes client-side**. The two prompts together make the whole economy
> server-owned. No overlap: challenge points = the other prompt; global economy =
> this one.

## The core problem
The app ships the entire reward economy as **hardcoded constants** and, worse, in
some places those constants are independent copies of numbers the backend already
awards server-side — so they can silently disagree. Audited live in `kolabing-app`
on 2026-06-01:

| Economy rule | App hardcodes it at | Backend reality |
|---|---|---|
| 5-level XP ladder (`0/100/250/500/1000`, names, colours) | `lib/features/rewards/models/xp_level.dart` | no endpoint exposes thresholds |
| **A second, conflicting** 3-tier ladder (Trusted at `100`, not `250`) | `lib/features/rewards/utils/xp_tier.dart` | — (client bug; two ladders disagree) |
| Per-action XP: complete kolab `+10`, review `+10`, UGC `+10`, refer `+50` | `lib/features/rewards/screens/wallet_screen.dart:272-294`; nudge + review/completion sheets repeat `+10` | `point_ledger.event_type` awards exist server-side but the **amounts aren't exposed**, so the label is a guess |
| Badge requirements (`1 kolab / 3 reviews / 100 XP / 1 referral / 5 kolabs`) | `lib/features/rewards/models/reward_badge.dart:49-76` | `BadgeService` milestone thresholds exist server-side, not exposed |
| Referral milestone (`3` businesses) + cash (`€75`) | `wallet_screen.dart`, `withdrawal_request_screen.dart`, `referral_banner_card.dart` | withdrawal flow exists; the **rate/threshold aren't exposed** |
| Withdrawal economics: `€0.25/point`, `€75` threshold (per `ROLES-AND-PERMISSIONS.md §3.5`) | not even implemented as a rate — app just prints `€75` | — |

The user-facing risk: the app promises "+10 XP for a review", the server awards
something else, and nobody notices. **Single source of truth must be the backend,
admin-editable, and read by the app — not duplicated in Dart.**

## Goal
1. Make the XP/rewards economy **admin-managed** (maintainer CRUD under `/admin/*`).
2. Expose it to the app via **one read endpoint** `GET /api/v1/gamification/config`
   so the app deletes its hardcoded ladders/labels and renders from server values
   (with baked-in fallback defaults equal to today's constants, so an offline first
   paint still works).
3. Ensure the **same stored values both drive the server-side award AND populate
   the config payload** — so the displayed "+N XP" can never drift from the award.

## Build (matches the existing admin architecture)
Server-rendered **Blade + AdminLTE** inside Laravel 12, under `/admin/*`, behind the
`auth:admin + maintainer` guard; logic in services under `app/Services/Admin/`;
validation via FormRequests; **no JS chart/JS framework** (strict CSP —
`script-src 'self' 'unsafe-inline'` + Tailwind CDN only). New sidebar entries go
under the **"GAMIFICATION"** header in `config/adminlte.php` (the challenge prompt
creates that header; reuse it).

### 1. XP earn rules (the award amounts) — `xp_earn_rules`
The authoritative per-action XP award. These must be what `point_ledger` actually
writes, not a parallel table.
- Migration `xp_earn_rules`: `id`, `event_type` (string, matches the
  `point_ledger.event_type` enum exactly: `CollaborationComplete`, `FirstKolabBonus`,
  `ReviewPosted`, `UgcPosted`, `ReferralConversion`, …), `points` int, `label`
  varchar (display copy, e.g. "Complete a kolab"), `is_active` bool, `position` int,
  unique `event_type`. Seed with today's values (`+10`, `+10`, `+10`, `+50`).
- **Wire the award path to read this table.** Everywhere the code currently awards a
  literal XP amount to `point_ledger` (`CheckinService`, `ChallengeCompletionService`,
  review submission, referral conversion, first-kolab bonus), replace the literal
  with `XpEarnRuleService::pointsFor($eventType)`. This is the change that kills the
  drift. Keep a constant fallback if a row is missing.
- Admin: `GET /admin/gamification/earn-rules` (+ edit) — `ChallengeController`-style
  controller `Admin\XpEarnRuleController`, `app/Services/Admin/XpEarnRuleService.php`.

### 2. XP levels — `xp_levels`
Replace the app's two conflicting Dart ladders with one server ladder.
- Migration `xp_levels`: `id`, `number` int unique, `title` varchar, `min_xp` int,
  `max_xp` int nullable (null = top level, no cap), `color` varchar (hex, e.g.
  `#FFD861`), `position` int. Seed with the current 5: New Community `0–99`, Active
  Community `100–249`, Trusted Community `250–499`, Local Favorite `500–999`, Local
  Legend `1000+`. (Use the **5-level** values from `xp_level.dart`; the 3-tier
  `xp_tier.dart` ladder is the buggy duplicate — it is **dropped**, not migrated.)
- Validation: contiguous, non-overlapping bands (each `min_xp` == previous
  `max_xp + 1`; exactly one open-ended top level). Reject gaps/overlaps in the
  FormRequest.
- Admin: `GET /admin/gamification/levels` (+ reorder/edit) —
  `Admin\XpLevelController`, `app/Services/Admin/XpLevelService.php`.

### 3. Badge requirements — extend the existing badge milestone definitions
Badges are already awarded by `BadgeService` on `BadgeMilestoneType` thresholds
(`milestone_value`) per the backend map §11. Surface and edit them:
- If thresholds are an enum/config today, add a `badges` (or `badge_milestones`)
  table row per badge: `slug`, `title`, `description`, `milestone_type`
  (`kolabs_completed` | `reviews_posted` | `xp_total` | `referrals` | …),
  `milestone_value` int, `is_active`, `position`. Seed from
  `reward_badge.dart`: firstKolab `kolabs_completed=1`, contentCreator
  `reviews_posted=3`, communityEarner `xp_total=100`, referralPioneer
  `referrals=1`, powerPartner `kolabs_completed=5`.
- Point `BadgeService` at the table (single source) and include `title`,
  `description`, `requirement_label`, `milestone_type`, `milestone_value` in the
  existing `GET /gamification/badges` payload so the app stops hardcoding
  `reward_badge.dart`.
- Admin: `GET /admin/gamification/badges` (+ edit) — `Admin\BadgeController`,
  `app/Services/Admin/BadgeMilestoneService.php`.

### 4. Referral & withdrawal economics — `reward_economics` (single-row settings)
- Migration `reward_economics` (one row; settings-style): `referral_goal` int
  (default `3`), `referral_cash_reward_cents` int (default `7500`),
  `euro_cents_per_point` int (default `25` → €0.25/point), `withdrawal_threshold_cents`
  int (default `7500` → €75), `currency` varchar (default `EUR`).
- Wire the **withdrawal flow** (`RewardWalletController` / withdrawal service) to
  compute payouts from `euro_cents_per_point` and gate on
  `withdrawal_threshold_cents` instead of any literal. Per `ROLES §3.5` this is the
  **community** withdrawal model; attendee withdrawal is still **[VERIFY] with
  Daniel** (backend map §11) — do not silently enable attendee cash-out here.
- Admin: `GET /admin/gamification/economics` (single edit form) —
  `Admin\RewardEconomicsController`, `app/Services/Admin/RewardEconomicsService.php`.

### 5. The read endpoint — `GET /api/v1/gamification/config`
One authenticated endpoint returning the whole economy so the app renders from it:
```json
{
  "data": {
    "xp_levels": [
      {"number":1,"title":"New Community","min_xp":0,"max_xp":99,"color":"#BDBDBD"},
      ... 
    ],
    "earn_rules": [
      {"event_type":"CollaborationComplete","points":10,"label":"Complete a kolab"},
      {"event_type":"ReviewPosted","points":10,"label":"Post a review"},
      {"event_type":"UgcPosted","points":10,"label":"Share content (UGC)"},
      {"event_type":"ReferralConversion","points":50,"label":"Refer a business"}
    ],
    "badges": [
      {"slug":"first_kolab","title":"First Kolab","milestone_type":"kolabs_completed","milestone_value":1,"requirement_label":"1 kolab needed"},
      ...
    ],
    "economics": {
      "referral_goal":3,"referral_cash_reward_cents":7500,
      "euro_cents_per_point":25,"withdrawal_threshold_cents":7500,"currency":"EUR"
    }
  }
}
```
- Cache it (it changes rarely) — e.g. `Cache::remember('gamification.config', …)`,
  busted on any admin write above.
- Stable, additive shape (the app must tolerate new keys).

## Acceptance
- Maintainers can edit XP levels, per-action XP awards, badge requirements, and
  referral/withdrawal economics from `/admin/gamification/*` (403 non-maintainer,
  302 to login when unauthenticated).
- The **award path reads `xp_earn_rules`** — changing "review" to `+15` in admin
  changes both what `point_ledger` writes AND the number `GET /gamification/config`
  returns (prove with a test: edit rule → assert ledger entry + config payload match).
- `GET /gamification/config` returns levels, earn rules, badges, and economics in the
  shape above; cached and busted on write.
- Withdrawal payout/threshold are computed from `reward_economics`, not literals.
- XP level bands validated contiguous/non-overlapping; exactly one open-ended top.
- No CSP carve-outs; no JS lib; tests cover route gating + award-reads-rule +
  config shape + economics-drives-withdrawal.

## Guardrails
- **Don't double-store award amounts.** `xp_earn_rules.points` must be the *only*
  source the award path uses — the whole point is to end the app↔server drift.
- Keep `point_ledger.event_type` values byte-identical to the existing enum; the
  earn-rule rows key off them.
- Don't break `GET /gamification/wallet|ledger|badges|referral-code|withdrawal`
  (the app depends on their current shapes) — only **add** fields to `/badges`.
- Withdrawal cash-out stays **community-only** unless Daniel confirms attendees
  (backend map §11 / `ROLES §3.5`).
- The 3-tier `xp_tier.dart` ladder is a client bug (it disagrees with the 5-level
  one) — the server ladder in §2 is canonical; the app deletes both Dart ladders.

## After this ships (app-side follow-up — separate task in `kolabing-app`)
- Add a `GamificationConfigService` reading `GET /gamification/config` at startup,
  cached, with fallback defaults = today's constants.
- Delete `xp_level.dart` + `xp_tier.dart` hardcoded ladders; render levels from config.
- Replace hardcoded `+10/+50` mission labels (`wallet_screen.dart`), the completion
  nudge, `kolab_review_sheet.dart`, and `kolab_completion_sheet.dart`'s `_baseXp`
  with the matching `earn_rules` value (and ideally the **actual** awarded amount
  echoed back by `/complete` / `/review` responses).
- Replace hardcoded badge requirements (`reward_badge.dart`) with the `/badges`
  fields. Replace `3` / `€75` / per-point literals with `economics`.
