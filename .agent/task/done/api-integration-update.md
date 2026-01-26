# Task: API Integration Update - Lookup Tables & Onboarding

## Status
- Created: 2026-01-25 21:15
- Started:
- Completed:

## Description
Integration Guide'a gore API entegrasyonunu guncelle:

### 1. Lookup API Endpoint Degisiklikleri
**Eski → Yeni:**
- `/lookup/business-types` → `/business-types`
- `/lookup/community-types` → `/community-types`
- `/cities` (ayni)

**Response Format Degisikligi:**
```json
// Eski format (lookup):
{ "value": "cafe", "label": "Cafe" }

// Yeni format:
{ "id": "uuid", "name": "Restaurante", "slug": "restaurante", "icon": "utensils" }
```

### 2. Model Guncellemeleri
- **BusinessType**: `id` (UUID), `name`, `slug`, `icon`
- **CommunityType**: `id` (UUID), `name`, `slug`, `icon`
- **OnboardingCity**: `id` (UUID), `name`, `country`

### 3. Onboarding API Degisiklikleri
- PUT → POST metoduna gecis
- Field names:
  - `business_type` (slug kullan)
  - `community_type` (slug kullan)
  - `city_id` (UUID)
  - `profile_photo` (data URI format: `data:image/jpeg;base64,...`)

### 4. Photo Upload Format
```dart
// Dogru format:
"profile_photo": "data:image/jpeg;base64,/9j/4AAQ..."
```

## Assigned Agents
- [x] @flutter-expert

## Technical Changes

### Models to Update:
1. `business_type.dart` - id, name, slug, icon
2. `community_type.dart` - id, name, slug, icon
3. `city.dart` - id, name, country (already correct)

### Services to Update:
1. `onboarding_service.dart`:
   - Change endpoint URLs
   - Change HTTP methods (PUT → POST)
   - Update payload format

### Provider to Update:
1. `onboarding_provider.dart`:
   - Photo format with data URI prefix

## API Endpoints

### GET /api/v1/cities
```json
{
  "data": [
    { "id": "uuid", "name": "Barcelona", "country": "Spain" }
  ]
}
```

### GET /api/v1/business-types
```json
{
  "data": [
    { "id": "uuid", "name": "Restaurante", "slug": "restaurante", "icon": "utensils" }
  ]
}
```

### GET /api/v1/community-types
```json
{
  "data": [
    { "id": "uuid", "name": "Running Club", "slug": "running-club", "icon": "running" }
  ]
}
```

### POST /api/v1/onboarding/business
```json
{
  "name": "Mi Restaurante",
  "about": "...",
  "business_type": "restaurante",  // slug
  "city_id": "uuid",
  "phone_number": "+34612345678",
  "instagram": "handle",
  "website": "https://...",
  "profile_photo": "data:image/jpeg;base64,..."
}
```

### POST /api/v1/onboarding/community
```json
{
  "name": "Barcelona Runners",
  "about": "...",
  "community_type": "running-club",  // slug
  "city_id": "uuid",
  "phone_number": "+34612345678",
  "instagram": "handle",
  "tiktok": "handle",
  "website": "https://...",
  "profile_photo": "data:image/jpeg;base64,..."
}
```

## Notes
- Max photo size: 5MB
- Supported formats: JPEG, PNG, GIF, WEBP
- Cache lookup data for 24 hours
