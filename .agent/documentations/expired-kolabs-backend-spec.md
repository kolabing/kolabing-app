# Backend Spec: Auto-Expire Past-Date Kolabs

## Problem
Kolabs whose `availability_end` date has passed remain with `status = published` in the database. They appear in the Explore feed, leading users to dead ends when they try to apply.

## Current Client-Side Workaround
The Flutter app now filters out expired kolabs client-side in `explore_screen.dart` by checking `availabilityEnd < today`. This is a temporary fix.

## Required Backend Changes

### Option A: Cron Job (Recommended)
Run a daily scheduled task (e.g., via Laravel scheduler or Supabase pg_cron) that transitions expired kolabs:

```sql
UPDATE opportunities
SET status = 'closed',
    updated_at = NOW()
WHERE status = 'published'
  AND availability_end < CURRENT_DATE;
```

**Schedule:** Run daily at 00:05 UTC.

### Option B: On-Read Filter
Add a server-side `WHERE` clause to the browse/explore API endpoint:

```sql
WHERE status = 'published'
  AND availability_end >= CURRENT_DATE
```

This keeps old data in the DB but hides it from browse results.

### Option C: Both (Recommended)
- Cron job transitions status to `closed` daily
- API also filters by date as a safety net
- This handles edge cases where cron hasn't run yet today

## API Changes Needed

### GET /api/opportunities (browse endpoint)
Add filter: `availability_end >= CURRENT_DATE` for published opportunities.

### New status value (optional)
Consider adding an `expired` status distinct from `closed` (user-initiated close vs auto-expiry). This allows different UI treatment:
- `closed`: "This opportunity was closed by the creator"
- `expired`: "This opportunity has ended"

## Priority
**High** - Users currently hit dead ends trying to apply to expired kolabs.
