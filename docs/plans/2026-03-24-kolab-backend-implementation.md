# Kolab Backend Implementation Plan

> **For:** Volkan Oluc (CTO) — Laravel backend implementation
> **Mobile app:** Already built. This doc defines the API contract the Flutter app expects.
> **Backend repo:** `../kolabing-v2` (Laravel)

**Goal:** Create the `kolabs` table and API endpoints that the new intent-driven kolab creation flow on mobile requires.

**Architecture:** New `kolabs` table (separate from `collab_opportunities`). New `Kolab` model, `KolabController`, `KolabService`, `KolabResource`, `CreateKolabRequest`, `UpdateKolabRequest`. Old `/opportunities` endpoints remain untouched for backward compatibility.

**Tech Stack:** Laravel 11, PostgreSQL, Sanctum auth, Stripe subscriptions (existing)

---

## 1. Database Migration

### New Table: `kolabs`

```php
// database/migrations/2026_03_24_create_kolabs_table.php

Schema::create('kolabs', function (Blueprint $table) {
    // Identity
    $table->uuid('id')->primary();
    $table->uuid('creator_profile_id');
    $table->foreign('creator_profile_id')->references('id')->on('profiles')->cascadeOnDelete();

    // Intent
    $table->string('intent_type', 30);          // community_seeking | venue_promotion | product_promotion
    $table->string('status', 20)->default('draft'); // draft | published | closed

    // Common
    $table->string('title', 255);
    $table->text('description');
    $table->string('preferred_city', 100);
    $table->string('area', 100)->nullable();
    $table->json('media')->nullable();           // [{url, type, sort_order}]

    // Availability
    $table->string('availability_mode', 20)->nullable(); // one_time | recurring | flexible
    $table->date('availability_start')->nullable();
    $table->date('availability_end')->nullable();
    $table->time('selected_time')->nullable();
    $table->json('recurring_days')->nullable();  // [1,3,5]

    // Community Seeking fields
    $table->json('needs')->nullable();           // ["venue","food_drink","sponsor"]
    $table->json('community_types')->nullable(); // ["Sports","Fitness"]
    $table->integer('community_size')->nullable();
    $table->integer('typical_attendance')->nullable();
    $table->json('offers_in_return')->nullable();// ["social_media","event_activation"]
    $table->string('venue_preference', 30)->nullable(); // business_provides | community_provides | no_venue

    // Venue Promotion fields
    $table->string('venue_name', 255)->nullable();
    $table->string('venue_type', 50)->nullable();  // restaurant | cafe | bar_lounge | ...
    $table->integer('capacity')->nullable();
    $table->text('venue_address')->nullable();

    // Product Promotion fields
    $table->string('product_name', 255)->nullable();
    $table->string('product_type', 50)->nullable();// food_product | beverage | ...

    // Business Targeting (venue + product)
    $table->json('offering')->nullable();         // ["venue","food_drink","discount"]
    $table->json('seeking_communities')->nullable(); // ["Sports","Wellness"]
    $table->integer('min_community_size')->nullable();
    $table->json('expects')->nullable();          // ["social_media","event_activation"]

    // Social Proof
    $table->json('past_events')->nullable();      // [{name, date, partner_name, photos:[]}]

    // Timestamps
    $table->timestamp('published_at')->nullable();
    $table->timestamps();
});

// Indexes
Schema::table('kolabs', function (Blueprint $table) {
    $table->index('creator_profile_id');
    $table->index(['intent_type', 'status']);
    $table->index('preferred_city');
    $table->index('status');
});
```

---

## 2. Enums

### IntentType
```php
// app/Enums/IntentType.php
enum IntentType: string {
    case CommunitySeeking = 'community_seeking';
    case VenuePromotion = 'venue_promotion';
    case ProductPromotion = 'product_promotion';
}
```

### KolabStatus
```php
// app/Enums/KolabStatus.php
enum KolabStatus: string {
    case Draft = 'draft';
    case Published = 'published';
    case Closed = 'closed';
}
```

### VenueType
```php
// app/Enums/VenueType.php
enum VenueType: string {
    case Restaurant = 'restaurant';
    case Cafe = 'cafe';
    case BarLounge = 'bar_lounge';
    case Hotel = 'hotel';
    case Coworking = 'coworking';
    case SportsFacility = 'sports_facility';
    case EventSpace = 'event_space';
    case Rooftop = 'rooftop';
    case BeachClub = 'beach_club';
    case RetailStore = 'retail_store';
    case Other = 'other';
}
```

### ProductType
```php
// app/Enums/ProductType.php
enum ProductType: string {
    case FoodProduct = 'food_product';
    case Beverage = 'beverage';
    case HealthBeauty = 'health_beauty';
    case SportsEquipment = 'sports_equipment';
    case Fashion = 'fashion';
    case TechGadget = 'tech_gadget';
    case ExperienceService = 'experience_service';
    case Other = 'other';
}
```

### VenuePreference
```php
// app/Enums/VenuePreference.php
enum VenuePreference: string {
    case BusinessProvides = 'business_provides';
    case CommunityProvides = 'community_provides';
    case NoVenue = 'no_venue';
}
```

---

## 3. Eloquent Model

```php
// app/Models/Kolab.php

class Kolab extends Model
{
    use HasUuids;

    protected $fillable = [
        'creator_profile_id', 'intent_type', 'status',
        'title', 'description', 'preferred_city', 'area', 'media',
        'availability_mode', 'availability_start', 'availability_end',
        'selected_time', 'recurring_days',
        'needs', 'community_types', 'community_size', 'typical_attendance',
        'offers_in_return', 'venue_preference',
        'venue_name', 'venue_type', 'capacity', 'venue_address',
        'product_name', 'product_type',
        'offering', 'seeking_communities', 'min_community_size', 'expects',
        'past_events', 'published_at',
    ];

    protected function casts(): array
    {
        return [
            'intent_type'     => IntentType::class,
            'status'          => KolabStatus::class,
            'media'           => 'array',
            'recurring_days'  => 'array',
            'needs'           => 'array',
            'community_types' => 'array',
            'offers_in_return'=> 'array',
            'offering'        => 'array',
            'seeking_communities' => 'array',
            'expects'         => 'array',
            'past_events'     => 'array',
            'availability_start' => 'date',
            'availability_end'   => 'date',
            'published_at'    => 'datetime',
        ];
    }

    // Relationships
    public function creatorProfile() { return $this->belongsTo(Profile::class, 'creator_profile_id'); }

    // Scopes
    public function scopePublished($q) { return $q->where('status', 'published'); }
    public function scopeForCity($q, $city) { return $q->where('preferred_city', $city); }
    public function scopeByIntent($q, $type) { return $q->where('intent_type', $type); }

    // Helpers
    public function isDraft(): bool { return $this->status === KolabStatus::Draft; }
    public function isPublished(): bool { return $this->status === KolabStatus::Published; }
}
```

---

## 4. API Endpoints

### Routes (`routes/api.php`)

```php
// Inside auth:sanctum middleware group
Route::prefix('kolabs')->group(function () {
    Route::get('/',          [KolabController::class, 'index']);     // Browse published
    Route::post('/',         [KolabController::class, 'store']);     // Create draft
    Route::get('/me',        [KolabController::class, 'myKolabs']); // My kolabs
    Route::get('/{kolab}',   [KolabController::class, 'show']);     // Detail
    Route::put('/{kolab}',   [KolabController::class, 'update']);   // Update
    Route::delete('/{kolab}',[KolabController::class, 'destroy']);  // Delete draft
    Route::post('/{kolab}/publish', [KolabController::class, 'publish']); // Publish
    Route::post('/{kolab}/close',   [KolabController::class, 'close']);   // Close
});
```

---

## 5. Validation Rules

### CreateKolabRequest

```php
// app/Http/Requests/CreateKolabRequest.php

public function rules(): array
{
    return [
        // Always required
        'intent_type'    => 'required|in:community_seeking,venue_promotion,product_promotion',
        'title'          => 'required|string|max:255',
        'description'    => 'required|string|max:5000',
        'preferred_city' => 'required|string|max:100',
        'area'           => 'nullable|string|max:100',

        // Media
        'media'              => 'nullable|array|max:5',
        'media.*.url'        => 'required_with:media|url',
        'media.*.type'       => 'required_with:media|in:photo,video',
        'media.*.sort_order' => 'nullable|integer|min:0',

        // Availability
        'availability_mode'  => 'nullable|in:one_time,recurring,flexible',
        'availability_start' => 'nullable|date',
        'availability_end'   => 'nullable|date|after_or_equal:availability_start',
        'selected_time'      => 'nullable|date_format:H:i',
        'recurring_days'     => 'nullable|array',
        'recurring_days.*'   => 'integer|between:1,7',

        // Community Seeking
        'needs'              => 'required_if:intent_type,community_seeking|array|min:1',
        'needs.*'            => 'in:venue,food_drink,sponsor,products,discount,other',
        'community_types'    => 'required_if:intent_type,community_seeking|array|min:1|max:3',
        'community_types.*'  => 'string|max:50',
        'community_size'     => 'required_if:intent_type,community_seeking|integer|min:1',
        'typical_attendance' => 'required_if:intent_type,community_seeking|integer|min:1',
        'offers_in_return'   => 'required_if:intent_type,community_seeking|array|min:1',
        'offers_in_return.*' => 'in:social_media,event_activation,product_placement,community_reach,review_feedback',
        'venue_preference'   => 'required_if:intent_type,community_seeking|in:business_provides,community_provides,no_venue',

        // Venue Promotion
        'venue_name'    => 'required_if:intent_type,venue_promotion|string|max:255',
        'venue_type'    => 'required_if:intent_type,venue_promotion|in:restaurant,cafe,bar_lounge,hotel,coworking,sports_facility,event_space,rooftop,beach_club,retail_store,other',
        'capacity'      => 'required_if:intent_type,venue_promotion|integer|min:1',
        'venue_address' => 'required_if:intent_type,venue_promotion|string|max:500',

        // Product Promotion
        'product_name'  => 'required_if:intent_type,product_promotion|string|max:255',
        'product_type'  => 'required_if:intent_type,product_promotion|in:food_product,beverage,health_beauty,sports_equipment,fashion,tech_gadget,experience_service,other',

        // Business Targeting (venue + product)
        'offering'              => 'required_unless:intent_type,community_seeking|array|min:1',
        'offering.*'            => 'in:venue,food_drink,discount,products,social_media,content_creation,sponsorship,other',
        'seeking_communities'   => 'nullable|array|max:5',
        'seeking_communities.*' => 'string|max:50',
        'min_community_size'    => 'nullable|integer|min:1',
        'expects'               => 'nullable|array',
        'expects.*'             => 'in:social_media,event_activation,product_placement,community_reach,review_feedback',

        // Past Events
        'past_events'                => 'nullable|array|max:5',
        'past_events.*.name'         => 'required|string|max:255',
        'past_events.*.date'         => 'required|date',
        'past_events.*.partner_name' => 'nullable|string|max:255',
        'past_events.*.photos'       => 'nullable|array|max:3',
        'past_events.*.photos.*'     => 'url',
    ];
}
```

### UpdateKolabRequest
Same as CreateKolabRequest but all fields use `sometimes` instead of `required`.

---

## 6. API Resource

```php
// app/Http/Resources/KolabResource.php

public function toArray(Request $request): array
{
    return [
        'id'                  => $this->id,
        'intent_type'         => $this->intent_type,
        'status'              => $this->status,
        'title'               => $this->title,
        'description'         => $this->description,
        'preferred_city'      => $this->preferred_city,
        'area'                => $this->area,
        'media'               => $this->media ?? [],
        'availability_mode'   => $this->availability_mode,
        'availability_start'  => $this->availability_start?->format('Y-m-d'),
        'availability_end'    => $this->availability_end?->format('Y-m-d'),
        'selected_time'       => $this->selected_time,
        'recurring_days'      => $this->recurring_days ?? [],
        'needs'               => $this->needs ?? [],
        'community_types'     => $this->community_types ?? [],
        'community_size'      => $this->community_size,
        'typical_attendance'  => $this->typical_attendance,
        'offers_in_return'    => $this->offers_in_return ?? [],
        'venue_preference'    => $this->venue_preference,
        'venue_name'          => $this->venue_name,
        'venue_type'          => $this->venue_type,
        'capacity'            => $this->capacity,
        'venue_address'       => $this->venue_address,
        'product_name'        => $this->product_name,
        'product_type'        => $this->product_type,
        'offering'            => $this->offering ?? [],
        'seeking_communities' => $this->seeking_communities ?? [],
        'min_community_size'  => $this->min_community_size,
        'expects'             => $this->expects ?? [],
        'past_events'         => $this->past_events ?? [],
        'published_at'        => $this->published_at?->toIso8601String(),
        'created_at'          => $this->created_at?->toIso8601String(),
        'updated_at'          => $this->updated_at?->toIso8601String(),
        'creator_profile'     => new ProfileSummaryResource($this->whenLoaded('creatorProfile')),
    ];
}
```

---

## 7. Example Request / Response Payloads

### 7.1 Create Community Seeking Kolab (Draft)

**Request:**
```
POST /api/v1/kolabs
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "intent_type": "community_seeking",
  "title": "Post-Run Brunch Series",
  "description": "Our running community of 250 members is looking for a restaurant to host monthly brunch events after our Sunday runs. We can offer social media coverage and bring 40+ engaged foodies to your venue.",
  "preferred_city": "Barcelona",
  "area": "Eixample",
  "needs": ["venue", "food_drink"],
  "community_types": ["Sports", "Fitness", "Food & Drink"],
  "community_size": 250,
  "typical_attendance": 40,
  "offers_in_return": ["social_media", "event_activation", "community_reach"],
  "venue_preference": "business_provides",
  "availability_mode": "recurring",
  "availability_start": "2026-04-01",
  "availability_end": "2026-06-30",
  "selected_time": "11:00",
  "recurring_days": [7]
}
```

**Response (201):**
```json
{
  "data": {
    "id": "9c3f7a1d-2b8e-4c5f-a6d9-1e2f3a4b5c6d",
    "intent_type": "community_seeking",
    "status": "draft",
    "title": "Post-Run Brunch Series",
    "description": "Our running community of 250 members...",
    "preferred_city": "Barcelona",
    "area": "Eixample",
    "media": [],
    "needs": ["venue", "food_drink"],
    "community_types": ["Sports", "Fitness", "Food & Drink"],
    "community_size": 250,
    "typical_attendance": 40,
    "offers_in_return": ["social_media", "event_activation", "community_reach"],
    "venue_preference": "business_provides",
    "availability_mode": "recurring",
    "availability_start": "2026-04-01",
    "availability_end": "2026-06-30",
    "selected_time": "11:00",
    "recurring_days": [7],
    "venue_name": null,
    "venue_type": null,
    "capacity": null,
    "venue_address": null,
    "product_name": null,
    "product_type": null,
    "offering": [],
    "seeking_communities": [],
    "min_community_size": null,
    "expects": [],
    "past_events": [],
    "published_at": null,
    "created_at": "2026-03-24T14:30:00.000000Z",
    "updated_at": "2026-03-24T14:30:00.000000Z",
    "creator_profile": {
      "id": "...",
      "display_name": "BCN Running Club",
      "user_type": "community",
      "avatar_url": "https://..."
    }
  }
}
```

---

### 7.2 Create Venue Promotion Kolab (Draft)

**Request:**
```
POST /api/v1/kolabs
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "intent_type": "venue_promotion",
  "title": "Cafe Montjuic — Community Events Welcome",
  "description": "Beautiful rooftop cafe with panoramic views of Barcelona. We're looking for fitness, sports, and wellness communities to host events at our venue. We provide the space, food, and drinks.",
  "preferred_city": "Barcelona",
  "venue_name": "Cafe Montjuic",
  "venue_type": "cafe",
  "capacity": 80,
  "venue_address": "Carrer de Montjuic 42, Barcelona",
  "media": [
    {"url": "https://storage.kolabing.com/kolabs/img1.jpg", "type": "photo", "sort_order": 0},
    {"url": "https://storage.kolabing.com/kolabs/img2.jpg", "type": "photo", "sort_order": 1}
  ],
  "offering": ["venue", "food_drink", "discount"],
  "seeking_communities": ["Sports", "Fitness", "Wellness"],
  "min_community_size": 100,
  "expects": ["social_media", "event_activation"],
  "past_events": [
    {
      "name": "Summer Yoga Morning",
      "date": "2025-08-15",
      "partner_name": "BCN Yoga Club",
      "photos": ["https://storage.kolabing.com/events/yoga1.jpg"]
    }
  ],
  "availability_mode": "recurring",
  "availability_start": "2026-04-01",
  "availability_end": "2026-06-30",
  "selected_time": "10:00",
  "recurring_days": [6, 7]
}
```

**Response (201):**
```json
{
  "data": {
    "id": "8b2e6f9d-1a7c-4d3e-b5f8-0c9d8e7f6a5b",
    "intent_type": "venue_promotion",
    "status": "draft",
    "title": "Cafe Montjuic — Community Events Welcome",
    "description": "Beautiful rooftop cafe...",
    "preferred_city": "Barcelona",
    "area": null,
    "media": [
      {"url": "https://storage.kolabing.com/kolabs/img1.jpg", "type": "photo", "sort_order": 0},
      {"url": "https://storage.kolabing.com/kolabs/img2.jpg", "type": "photo", "sort_order": 1}
    ],
    "venue_name": "Cafe Montjuic",
    "venue_type": "cafe",
    "capacity": 80,
    "venue_address": "Carrer de Montjuic 42, Barcelona",
    "offering": ["venue", "food_drink", "discount"],
    "seeking_communities": ["Sports", "Fitness", "Wellness"],
    "min_community_size": 100,
    "expects": ["social_media", "event_activation"],
    "past_events": [
      {
        "name": "Summer Yoga Morning",
        "date": "2025-08-15",
        "partner_name": "BCN Yoga Club",
        "photos": ["https://storage.kolabing.com/events/yoga1.jpg"]
      }
    ],
    "needs": [],
    "community_types": [],
    "community_size": null,
    "typical_attendance": null,
    "offers_in_return": [],
    "venue_preference": null,
    "product_name": null,
    "product_type": null,
    "availability_mode": "recurring",
    "availability_start": "2026-04-01",
    "availability_end": "2026-06-30",
    "selected_time": "10:00",
    "recurring_days": [6, 7],
    "published_at": null,
    "created_at": "2026-03-24T15:00:00.000000Z",
    "updated_at": "2026-03-24T15:00:00.000000Z",
    "creator_profile": {
      "id": "...",
      "display_name": "Cafe Montjuic",
      "user_type": "business",
      "avatar_url": "https://..."
    }
  }
}
```

---

### 7.3 Create Product Promotion Kolab (Draft)

**Request:**
```
POST /api/v1/kolabs
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "intent_type": "product_promotion",
  "title": "Organic Cold Brew — Perfect for Community Events",
  "description": "Our organic cold brew line is perfect for active communities. We provide free samples, branded merch, and social media cross-promotion.",
  "preferred_city": "Barcelona",
  "product_name": "Organic Cold Brew Line",
  "product_type": "beverage",
  "media": [
    {"url": "https://storage.kolabing.com/kolabs/brew1.jpg", "type": "photo", "sort_order": 0}
  ],
  "offering": ["products", "social_media", "discount"],
  "seeking_communities": ["Sports", "Fitness", "Food & Drink", "Wellness"],
  "min_community_size": 50,
  "expects": ["social_media", "product_placement"],
  "availability_mode": "flexible"
}
```

**Response (201):** Same structure as venue, with product fields populated and venue fields null.

---

### 7.4 Publish a Kolab

**Request:**
```
POST /api/v1/kolabs/{id}/publish
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "data": {
    "id": "9c3f7a1d-...",
    "status": "published",
    "published_at": "2026-03-24T15:30:00.000000Z",
    "...": "... all other fields same as create response"
  }
}
```

**Error (402) — Subscription Required:**
```json
{
  "message": "Subscription required to publish.",
  "requires_subscription": true
}
```

---

### 7.5 Get My Kolabs

**Request:**
```
GET /api/v1/kolabs/me?status=draft&page=1&per_page=10
Authorization: Bearer {token}
```

**Response (200):**
```json
{
  "data": [
    { "id": "...", "intent_type": "community_seeking", "title": "...", "status": "draft", "..." : "..." },
    { "id": "...", "intent_type": "venue_promotion", "title": "...", "status": "published", "..." : "..." }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 10,
    "total": 2
  }
}
```

---

### 7.6 Browse Published Kolabs (Explore)

**Request:**
```
GET /api/v1/kolabs?intent_type=venue_promotion&city=Barcelona&page=1
Authorization: Bearer {token}
```

Supported filters:
- `intent_type` — community_seeking, venue_promotion, product_promotion
- `city` — exact match on preferred_city
- `venue_type` — for venue promotions
- `product_type` — for product promotions
- `needs[]` — for community seeking (has any of these needs)
- `community_types[]` — for filtering by community type
- `search` — full-text search on title + description

**Response (200):**
```json
{
  "data": [
    {
      "id": "...",
      "intent_type": "venue_promotion",
      "status": "published",
      "title": "Cafe Montjuic...",
      "...": "...",
      "creator_profile": {
        "id": "...",
        "display_name": "Cafe Montjuic",
        "user_type": "business",
        "avatar_url": "https://..."
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 15,
    "total": 42
  }
}
```

---

### 7.7 Update a Kolab

**Request:**
```
PUT /api/v1/kolabs/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

```json
{
  "title": "Updated Post-Run Brunch Series",
  "community_size": 300,
  "needs": ["venue", "food_drink", "sponsor"]
}
```

**Response (200):** Full updated kolab resource.

---

### 7.8 Delete a Draft Kolab

**Request:**
```
DELETE /api/v1/kolabs/{id}
Authorization: Bearer {token}
```

**Response (204):** No content.

**Error (403):** Cannot delete published kolabs.

---

### 7.9 Close a Published Kolab

**Request:**
```
POST /api/v1/kolabs/{id}/close
Authorization: Bearer {token}
```

**Response (200):** Kolab with status "closed".

---

## 8. Business Logic / Authorization

### Subscription Check on Publish

```php
// KolabService::publish()

// Community users creating venue_promotion or product_promotion need subscription
// Business users always need subscription
// Community users creating community_seeking = FREE (no subscription needed)

if ($kolab->intent_type !== IntentType::CommunitySeeking) {
    if (!$profile->hasActiveSubscription()) {
        throw new SubscriptionRequiredException();
    }
}
```

### Authorization Policy

```php
// KolabPolicy.php

public function view(Profile $user, Kolab $kolab): bool {
    return $kolab->isPublished() || $kolab->creator_profile_id === $user->id;
}

public function update(Profile $user, Kolab $kolab): bool {
    return $kolab->creator_profile_id === $user->id;
}

public function delete(Profile $user, Kolab $kolab): bool {
    return $kolab->creator_profile_id === $user->id && $kolab->isDraft();
}

public function publish(Profile $user, Kolab $kolab): bool {
    return $kolab->creator_profile_id === $user->id && $kolab->isDraft();
}

public function close(Profile $user, Kolab $kolab): bool {
    return $kolab->creator_profile_id === $user->id && $kolab->isPublished();
}
```

---

## 9. Enum Value Reference (for validation `in:` rules)

| Field | Allowed Values |
|-------|---------------|
| intent_type | `community_seeking`, `venue_promotion`, `product_promotion` |
| status | `draft`, `published`, `closed` |
| needs.* | `venue`, `food_drink`, `sponsor`, `products`, `discount`, `other` |
| offers_in_return.* | `social_media`, `event_activation`, `product_placement`, `community_reach`, `review_feedback` |
| expects.* | `social_media`, `event_activation`, `product_placement`, `community_reach`, `review_feedback` |
| venue_type | `restaurant`, `cafe`, `bar_lounge`, `hotel`, `coworking`, `sports_facility`, `event_space`, `rooftop`, `beach_club`, `retail_store`, `other` |
| product_type | `food_product`, `beverage`, `health_beauty`, `sports_equipment`, `fashion`, `tech_gadget`, `experience_service`, `other` |
| venue_preference | `business_provides`, `community_provides`, `no_venue` |
| availability_mode | `one_time`, `recurring`, `flexible` |
| offering.* | `venue`, `food_drink`, `discount`, `products`, `social_media`, `content_creation`, `sponsorship`, `other` |
| recurring_days.* | `1`-`7` (Mon=1, Sun=7) |
| media.*.type | `photo`, `video` |

---

## 10. Files to Create / Modify in kolabing-v2

| Action | File | What |
|--------|------|------|
| Create | `database/migrations/2026_03_24_create_kolabs_table.php` | New table |
| Create | `app/Enums/IntentType.php` | Enum |
| Create | `app/Enums/KolabStatus.php` | Enum |
| Create | `app/Enums/VenueType.php` | Enum |
| Create | `app/Enums/ProductType.php` | Enum |
| Create | `app/Enums/VenuePreference.php` | Enum |
| Create | `app/Models/Kolab.php` | Eloquent model |
| Create | `app/Http/Requests/CreateKolabRequest.php` | Validation |
| Create | `app/Http/Requests/UpdateKolabRequest.php` | Validation |
| Create | `app/Http/Resources/KolabResource.php` | JSON response |
| Create | `app/Http/Resources/KolabCollection.php` | Paginated |
| Create | `app/Services/KolabService.php` | CRUD + business logic |
| Create | `app/Http/Controllers/Api/V1/KolabController.php` | REST controller |
| Create | `app/Policies/KolabPolicy.php` | Authorization |
| Modify | `routes/api.php` | Add kolab routes |
| Modify | `app/Providers/AuthServiceProvider.php` | Register policy |

---

## 11. Migration Path for Existing Data

Once kolabs are working, existing `collab_opportunities` can be migrated:

```php
// php artisan kolabs:migrate-legacy

CollabOpportunity::chunk(100, function ($opportunities) {
    foreach ($opportunities as $opp) {
        Kolab::create([
            'creator_profile_id' => $opp->creator_profile_id,
            'intent_type' => $opp->creator_profile_type === 'community'
                ? 'community_seeking' : 'venue_promotion',
            'status' => $opp->status === 'published' ? 'published' : $opp->status,
            'title' => $opp->title,
            'description' => $opp->description,
            'preferred_city' => $opp->preferred_city ?? '',
            // Map business_offer JSON → offering array
            // Map community_deliverables JSON → offers_in_return array
            // Map venue_mode → venue_preference
            // etc.
        ]);
    }
});
```

This is optional and can be done when old endpoints are deprecated.
