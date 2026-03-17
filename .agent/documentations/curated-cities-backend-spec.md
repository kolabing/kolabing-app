# Backend Spec: Curated City Selector

## Problem
The city picker loads 200+ Spanish cities from an unfiltered list. Users scroll through cities where Kolabing has zero presence. Not searchable, not curated.

## Required Backend Changes

### 1. Add `is_active` column to cities table

```sql
ALTER TABLE cities ADD COLUMN is_active BOOLEAN DEFAULT false;
ALTER TABLE cities ADD COLUMN sort_order INTEGER DEFAULT 0;
```

### 2. Seed initial active cities

```sql
UPDATE cities SET is_active = true, sort_order = 1 WHERE name = 'Barcelona';
UPDATE cities SET is_active = true, sort_order = 2 WHERE name = 'Madrid';
UPDATE cities SET is_active = true, sort_order = 3 WHERE name = 'Valencia';
```

### 3. Update GET /api/cities endpoint

Return only active cities by default, ordered by `sort_order`:

```sql
SELECT id, name, country
FROM cities
WHERE is_active = true
ORDER BY sort_order ASC, name ASC;
```

Optional query param `?all=true` for admin use to see full list.

### 4. Add "Other / Suggest a city" flow

**Option A (Simple):** Add a special entry in the API response:
```json
{ "id": "other", "name": "Other / Suggest a city", "country": "ES" }
```

When selected, the app shows a text input for the user to type their city. This gets stored as `preferred_city` free text.

**Option B (Better):** Backend receives city suggestions and stores them in a `city_suggestions` table for admin review:
```sql
CREATE TABLE city_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  suggested_by UUID REFERENCES profiles(id),
  city_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 5. Frontend Changes (after backend is ready)

- Make city dropdown searchable (use `SearchableDropdown` or `Autocomplete`)
- Show only active cities from the API
- Add "Other" option at the bottom
- When "Other" selected, show free-text input

## Priority
**High** - Current list is unusable at scale. Start with 3 active cities, expand based on demand.
