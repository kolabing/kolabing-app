# Backend Spec: Availability Fields for Opportunities

**Date:** 2026-03-17
**Priority:** Required before next mobile release
**Affects:** `POST /api/v1/opportunities`, `PUT /api/v1/opportunities/{id}`, `GET` responses

---

## Summary

The mobile app now supports three distinct availability modes when communities create opportunities. Two **new fields** are being sent that the backend does not yet store or return.

---

## Current API Fields (already supported)

| Field | Type | Example |
|-------|------|---------|
| `availability_mode` | `enum: one_time, recurring, flexible` | `"recurring"` |
| `availability_start` | `date (YYYY-MM-DD)` | `"2026-03-24"` |
| `availability_end` | `date (YYYY-MM-DD)` | `"2026-04-23"` |

## New Fields to Add

### 1. `selected_time` (nullable string)

- **Type:** `string` or `TIME`, format `HH:mm` (24-hour)
- **Example:** `"10:00"`, `"20:30"`
- **Nullable:** Yes
- **Sent when:**
  - `availability_mode = "one_time"` (required)
  - `availability_mode = "recurring"` (required)
  - `availability_mode = "flexible"` (never sent / null)
- **Meaning:** The fixed time proposed by the community for the collaboration

### 2. `recurring_days` (nullable JSON array)

- **Type:** `JSON array of integers` or a dedicated pivot table
- **Values:** `1` = Monday, `2` = Tuesday, ... `7` = Sunday
- **Example:** `[1, 3, 5]` (Monday, Wednesday, Friday)
- **Nullable:** Yes (empty array = null)
- **Sent when:** `availability_mode = "recurring"` only
- **Meaning:** The days of the week when the community is available

---

## Database Migration

```sql
-- Add columns to opportunities table
ALTER TABLE opportunities
  ADD COLUMN selected_time TIME NULL AFTER availability_end,
  ADD COLUMN recurring_days JSON NULL AFTER selected_time;
```

If using Laravel:

```php
Schema::table('opportunities', function (Blueprint $table) {
    $table->time('selected_time')->nullable()->after('availability_end');
    $table->json('recurring_days')->nullable()->after('selected_time');
});
```

---

## Validation Rules

Update the store/update request validation:

```php
// Base rules
'selected_time' => 'nullable|date_format:H:i',
'recurring_days' => 'nullable|array',
'recurring_days.*' => 'integer|between:1,7',

// Conditional rules based on availability_mode:

// When mode = "one_time"
//   selected_time  -> required
//   recurring_days -> must be null/empty

// When mode = "recurring"
//   selected_time  -> required
//   recurring_days -> required, min:1 item

// When mode = "flexible"
//   selected_time  -> must be null
//   recurring_days -> must be null/empty
```

---

## JSON Payload Examples

### A) One Time (Date Range + Same Time)

```json
{
  "availability_mode": "one_time",
  "availability_start": "2026-03-24",
  "availability_end": "2026-04-06",
  "selected_time": "10:00",
  "recurring_days": null
}
```

*"Any day from March 24 to April 6 at 10:00 AM"*

### B) Recurring (Multi-day + Time)

```json
{
  "availability_mode": "recurring",
  "availability_start": null,
  "availability_end": null,
  "selected_time": "20:00",
  "recurring_days": [4, 6]
}
```

*"Every Thursday and Saturday at 8:00 PM"*

> **Note:** For recurring mode, `availability_start` and `availability_end` are not required from the mobile app. The backend should accept them as nullable for this mode.

### C) Flexible Window (Date Range, No Fixed Time)

```json
{
  "availability_mode": "flexible",
  "availability_start": "2026-03-24",
  "availability_end": "2026-04-08",
  "selected_time": null,
  "recurring_days": null
}
```

*"Any day between March 24 and April 8, any time"*

---

## GET Response

Both new fields must be returned in all opportunity GET responses:

```json
{
  "id": "abc-123",
  "title": "...",
  "availability_mode": "recurring",
  "availability_start": null,
  "availability_end": null,
  "selected_time": "20:00",
  "recurring_days": [4, 6],
  "venue_mode": "no_venue",
  ...
}
```

---

## Backward Compatibility

- The mobile app reads both `recurring_days` (new, array) and `recurring_day` (legacy, single int) from responses. Backend should only return `recurring_days`.
- If existing rows have no value for these columns, they default to `null` which the mobile app handles gracefully.
- No existing functionality breaks — the fields are additive.

---

## Checklist

- [ ] Add `selected_time` column (TIME, nullable)
- [ ] Add `recurring_days` column (JSON, nullable)
- [ ] Run migration
- [ ] Update `OpportunityController` store/update validation
- [ ] Update `OpportunityResource` to include both fields in responses
- [ ] Make `availability_start`/`availability_end` nullable when `availability_mode = "recurring"`
- [ ] Add tests for each mode's validation rules
