# Task: Past Events Profile Section

## Status
- Created: 2026-02-05 10:30
- Started: 2026-02-05 10:35
- Completed: 2026-02-05 11:15

## Description
Business ve Community kullanıcılarının profil sayfalarında daha önce organize ettikleri etkinlikleri görüntüleyebilmeleri ve yeni etkinlik ekleyebilmeleri için bir "Past Events" bölümü eklenmesi gerekiyor.

### Gereksinimler
Her etkinlik için aşağıdaki bilgiler gösterilmeli:
- **Etkinlik adı** (Event name) ✅
- **Partner topluluk/işletme adı** (Collaborated with) ✅
- **Etkinlik tarihi** (Event date) ✅
- **Etkinlik fotoğrafları** (Event photos - carousel/gallery) ✅
- **Katılımcı sayısı** (Attendee count) ✅

### Kullanıcı Senaryoları
1. Business kullanıcı: Daha önce community'lerle yaptığı etkinlikleri gösterir ✅
2. Community kullanıcı: Daha önce business'larla yaptığı etkinlikleri gösterir ✅

## Related API Endpoints
Backend henüz hazır değil. Mock data ile tasarlandı ve aşağıdaki API spesifikasyonu backend ekibine iletilecek.

### Proposed API Endpoints

#### 1. GET /api/v1/events (List Past Events)
```json
Query Params:
- user_id: string (optional, defaults to current user)
- page: int
- limit: int

Response:
{
  "success": true,
  "data": {
    "events": [
      {
        "id": "uuid",
        "name": "Summer Music Festival",
        "partner": {
          "id": "uuid",
          "name": "Rock Community",
          "profile_photo": "url",
          "type": "community" | "business"
        },
        "date": "2025-08-15",
        "attendee_count": 250,
        "photos": [
          {
            "id": "uuid",
            "url": "https://...",
            "thumbnail_url": "https://..."
          }
        ],
        "created_at": "2025-08-20T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_count": 25
    }
  }
}
```

#### 2. POST /api/v1/events (Create Event)
```json
Request Body:
{
  "name": "Summer Music Festival",
  "partner_id": "uuid",
  "partner_type": "community" | "business",
  "date": "2025-08-15",
  "attendee_count": 250,
  "photos": ["base64_encoded_image_1", "base64_encoded_image_2"]
}

Response:
{
  "success": true,
  "data": {
    "event": { ...event_object }
  }
}
```

#### 3. PUT /api/v1/events/{id} (Update Event)
```json
Request Body: (same as POST, all fields optional)

Response:
{
  "success": true,
  "data": {
    "event": { ...updated_event_object }
  }
}
```

#### 4. DELETE /api/v1/events/{id} (Delete Event)
```json
Response:
{
  "success": true,
  "message": "Event deleted successfully"
}
```

## Assigned Agents
- [x] @ui-designer - Design the UI/UX for past events section
- [x] @flutter-expert - Implement the Flutter components

## Progress

### UX Design
**Status:** ✅ Completed

#### User Flow
1. User opens Profile screen ✅
2. Scrolls down to "Past Events" section ✅
3. Sees horizontal carousel of event cards (if events exist) ✅
4. Can tap "Add Event" button to add new event ✅
5. Can tap on event card to view full details ✅
6. Can edit/delete their own events ✅

#### UI Components

##### 1. PastEventsSection (Profile Page) ✅
- Section title: "Past Events" with event count badge
- "Add Event" button (top right of section)
- Horizontal scrolling list of EventCard widgets
- Empty state when no events

##### 2. EventCard (Compact) ✅
- Cover photo (first photo from gallery)
- Gradient overlay at bottom
- Event name (bold, white)
- Partner name with avatar
- Date badge (top right)
- Photo count badge (top left)
- Attendee count with icon

##### 3. AddEventModal (Bottom Sheet) ✅
- Form fields:
  - Event name (text input)
  - Partner name (text input)
  - Date picker
  - Attendee count (number input)
  - Photo gallery (multi-select, max 5)
- Save/Cancel buttons

##### 4. EventDetailScreen (Full Page) ✅
- Hero image carousel (swipeable)
- Event name (headline)
- Partner info row (avatar + name + type badge)
- Date with calendar icon
- Attendee count with people icon
- Photo gallery grid (thumbnails)
- Delete button

#### States ✅
- **Loading:** Shimmer placeholders for event cards
- **Empty:** Illustration + "No events yet" + "Add your first event" CTA
- **Error:** Error message + retry button
- **Success:** Event cards in horizontal list

### Flutter Implementation
**Status:** ✅ Completed

#### Files Created
- `lib/features/event/models/event.dart` - Event, EventPartner, EventPhoto, EventRequest models ✅
- `lib/features/event/providers/event_provider.dart` - Riverpod state management ✅
- `lib/features/event/services/event_service.dart` - API service with mock data ✅
- `lib/features/event/widgets/past_events_section.dart` - Section widget ✅
- `lib/features/event/widgets/event_card.dart` - Compact card widget ✅
- `lib/features/event/widgets/add_event_modal.dart` - Add event form modal ✅
- `lib/features/event/screens/event_detail_screen.dart` - Detail page ✅

#### Integration
- Added route `/event/:id` in `lib/config/routes/routes.dart` ✅
- Integrated `PastEventsSection` in `BusinessProfileScreen` ✅
- Integrated `PastEventsSection` in `CommunityProfileScreen` ✅

#### State Management
- Riverpod StateNotifier for events list ✅
- Form state managed locally in AddEventModal ✅

## Notes
- Mock data ile çalışıyor, API hazır olduğunda `EventService` güncellenmeli
- Fotoğraf yükleme için mevcut `image_picker` entegrasyonu kullanıldı
- Business ve Community profil ekranlarına aynı widget entegre edildi
- Partner seçimi şimdilik text input olarak yapıldı, API hazır olduğunda autocomplete/search eklenebilir
