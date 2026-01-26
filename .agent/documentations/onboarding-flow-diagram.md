# Onboarding Flow Diagram

## Complete User Journey

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NEW USER REGISTRATION                       │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  SCREEN 1: User Type Selection                                     │
│                                                                     │
│  ┌───────────────────┐      ┌───────────────────┐                  │
│  │   🏢 BUSINESS    │      │  👥 COMMUNITY    │                  │
│  │                   │  OR  │                   │                  │
│  │  Find communities │      │  Find businesses  │                  │
│  └───────────────────┘      └───────────────────┘                  │
│                                                                     │
│  [CONTINUE] ────────────────────────────────────────────────┐       │
│                                                             │       │
└─────────────────────────────────────────────────────────────┼───────┘
                                                              │
                    ┌─────────────────────────────────────────┤
                    │                                         │
                    ▼                                         ▼
    ┌───────────────────────────────────┐   ┌───────────────────────────────────┐
    │   BUSINESS ONBOARDING FLOW        │   │   COMMUNITY ONBOARDING FLOW       │
    └───────────────────────────────────┘   └───────────────────────────────────┘
                    │                                         │
                    ▼                                         ▼


┌─────────────────────────────────────┐   ┌─────────────────────────────────────┐
│  BUSINESS STEP 1: Basics            │   │  COMMUNITY STEP 1: Basics           │
│                                     │   │                                     │
│  ├─ Progress: ●━━━○━━━○━━━○         │   │  ├─ Progress: ●━━━○━━━○━━━○         │
│  ├─ Profile Photo (optional)        │   │  ├─ Profile Photo (optional)        │
│  └─ Business Name (required) *      │   │  └─ Display Name (required) *       │
│                                     │   │                                     │
│  Validation:                        │   │  Validation:                        │
│  • Name: min 3, max 255 chars       │   │  • Name: min 3, max 255 chars       │
│  • Photo: max 5MB, jpg/png/webp     │   │  • Photo: max 5MB, jpg/png/webp     │
│                                     │   │                                     │
│  [CONTINUE] ──────────────────┐     │   │  [CONTINUE] ──────────────────┐     │
└─────────────────────────────────────┘   └─────────────────────────────────────┘
                                │                                         │
                                ▼                                         ▼
┌─────────────────────────────────────┐   ┌─────────────────────────────────────┐
│  BUSINESS STEP 2: Type Selection    │   │  COMMUNITY STEP 2: Type Selection   │
│                                     │   │                                     │
│  ├─ Progress: ●━━━●━━━○━━━○         │   │  ├─ Progress: ●━━━●━━━○━━━○         │
│  └─ Select Business Type *          │   │  └─ Select Community Type *         │
│                                     │   │                                     │
│  Options (Grid 3x4):                │   │  Options (Grid 3x4):                │
│  ☕️ Café          🍽️ Restaurant     │   │  🍔 Food Blogger  ✨ Lifestyle      │
│  🍺 Bar           🥐 Bakery         │   │  💪 Fitness       ✈️ Travel         │
│  💼 Coworking     💪 Gym            │   │  📸 Photographer  🗺️ Local Explorer │
│  💇 Salon         🛍️ Retail         │   │  🎓 Student       💼 Professional   │
│  🏨 Hotel         📦 Other          │   │  🎉 Organizer     📦 Other          │
│                                     │   │                                     │
│  Data: GET /lookup/business-types   │   │  Data: GET /lookup/community-types  │
│                                     │   │                                     │
│  [CONTINUE] ──────────────────┐     │   │  [CONTINUE] ──────────────────┐     │
└─────────────────────────────────────┘   └─────────────────────────────────────┘
                                │                                         │
                                ▼                                         ▼
┌─────────────────────────────────────┐   ┌─────────────────────────────────────┐
│  BUSINESS STEP 3: City              │   │  COMMUNITY STEP 3: City             │
│                                     │   │                                     │
│  ├─ Progress: ●━━━●━━━●━━━○         │   │  ├─ Progress: ●━━━●━━━●━━━○         │
│  ├─ Search bar                      │   │  ├─ Search bar                      │
│  └─ Select City *                   │   │  └─ Select City *                   │
│                                     │   │                                     │
│  Cities (scrollable list):          │   │  Cities (scrollable list):          │
│  📍 Barcelona, Spain                │   │  📍 Barcelona, Spain                │
│  📍 Madrid, Spain                   │   │  📍 Madrid, Spain                   │
│  📍 Valencia, Spain                 │   │  📍 Valencia, Spain                 │
│  ... (more cities)                  │   │  ... (more cities)                  │
│                                     │   │                                     │
│  Data: GET /cities                  │   │  Data: GET /cities                  │
│                                     │   │                                     │
│  [CONTINUE] ──────────────────┐     │   │  [CONTINUE] ──────────────────┐     │
└─────────────────────────────────────┘   └─────────────────────────────────────┘
                                │                                         │
                                ▼                                         ▼
┌─────────────────────────────────────┐   ┌─────────────────────────────────────┐
│  BUSINESS STEP 4: Details           │   │  COMMUNITY STEP 4: Details          │
│                                     │   │                                     │
│  ├─ Progress: ●━━━●━━━●━━━●         │   │  ├─ Progress: ●━━━●━━━●━━━●         │
│  ├─ About (max 1000 chars)          │   │  ├─ About/Bio (max 1000 chars)      │
│  ├─ Phone Number (+34...)           │   │  ├─ Instagram (@username)           │
│  ├─ Instagram (@username)           │   │  ├─ TikTok (@username)              │
│  └─ Website (https://)              │   │  └─ Website (https://)              │
│                                     │   │                                     │
│  ALL FIELDS OPTIONAL                │   │  ALL FIELDS OPTIONAL                │
│                                     │   │                                     │
│  [Skip →]  [CONTINUE] ────────┐     │   │  [Skip →]  [CONTINUE] ────────┐     │
└─────────────────────────────────────┘   └─────────────────────────────────────┘
                                │                                         │
                                ▼                                         ▼
┌─────────────────────────────────────┐   ┌─────────────────────────────────────┐
│  BUSINESS FINAL REVIEW              │   │  COMMUNITY FINAL REVIEW             │
│                                     │   │                                     │
│  ┌───────────────────────────────┐  │   │  ┌───────────────────────────────┐  │
│  │  SUMMARY CARD                 │  │   │  │  SUMMARY CARD                 │  │
│  │                               │  │   │  │                               │  │
│  │  ┌────┐  Café Barcelona       │  │   │  │  ┌────┐  Maria García        │  │
│  │  │ 📷 │  Café • Barcelona     │  │   │  │  │ 📷 │  Food Blogger •      │  │
│  │  └────┘                       │  │   │  │  └────┘  Barcelona           │  │
│  │                               │  │   │  │                               │  │
│  │  "Artisan coffee shop..."     │  │   │  │  "Food blogger and coffee..." │  │
│  │                               │  │   │  │                               │  │
│  │  📱 +34 612 345 678           │  │   │  │  📷 @maria_food               │  │
│  │  📷 @cafebarcelona            │  │   │  │  🎵 @maria_food               │  │
│  │  🌐 cafebarcelona.com         │  │   │  │  🌐 mariafood.com             │  │
│  └───────────────────────────────┘  │   │  └───────────────────────────────┘  │
│                                     │   │                                     │
│  [← Edit]                           │   │  [← Edit]                           │
│                                     │   │                                     │
│  ┌───────────────────────────────┐  │   │  ┌───────────────────────────────┐  │
│  │ 🌐 COMPLETE WITH GOOGLE      │  │   │  │ 🌐 COMPLETE WITH GOOGLE      │  │
│  └───────────────────────────────┘  │   │  └───────────────────────────────┘  │
│                                     │   │                                     │
│  Terms & Privacy Policy             │   │  Terms & Privacy Policy             │
└─────────────────────────────────────┘   └─────────────────────────────────────┘
                                │                                         │
                                └─────────────┬───────────────────────────┘
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │    GOOGLE OAUTH FLOW                    │
                        │                                         │
                        │  1. User signs in with Google           │
                        │  2. App receives ID token               │
                        │  3. Loading overlay shown               │
                        └─────────────────────────────────────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │    API CALLS                            │
                        │                                         │
                        │  POST /auth/google                      │
                        │  {                                      │
                        │    "id_token": "eyJhbGc...",            │
                        │    "user_type": "business"              │
                        │  }                                      │
                        │                                         │
                        │  Response:                              │
                        │  {                                      │
                        │    "token": "1|abc...",                 │
                        │    "user": {...},                       │
                        │    "is_new_user": true                  │
                        │  }                                      │
                        └─────────────────────────────────────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │    STORE AUTH TOKEN                     │
                        │    (Keychain / EncryptedSharedPrefs)    │
                        └─────────────────────────────────────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │    PUT /onboarding/business             │
                        │    OR                                   │
                        │    PUT /onboarding/community            │
                        │                                         │
                        │    With collected data:                 │
                        │    {                                    │
                        │      "name": "...",                     │
                        │      "business_type": "cafe",           │
                        │      "city_id": "uuid",                 │
                        │      "about": "...",                    │
                        │      ...                                │
                        │    }                                    │
                        └─────────────────────────────────────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │    NAVIGATE TO DASHBOARD                │
                        │                                         │
                        │    Business → /business/dashboard       │
                        │    Community → /community/dashboard     │
                        │                                         │
                        │    Remove all previous routes           │
                        └─────────────────────────────────────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │         ONBOARDING COMPLETE ✓           │
                        └─────────────────────────────────────────┘
```

---

## Error Flows

### Google Sign In Cancelled

```
Final Review Screen
    │
    ▼
[COMPLETE WITH GOOGLE] clicked
    │
    ▼
Google OAuth Dialog
    │
    ▼ [User cancels]
    │
    ▼
Return to Final Review
    │
    ▼
Show message: "Sign in cancelled. Try again when ready."
```

### API Error

```
PUT /onboarding/business
    │
    ▼ [Error 422]
    │
    ▼
Parse field errors
    │
    ▼
Navigate back to error step
    │
    ▼
Highlight error fields
    │
    ▼
Show error messages
```

### Network Error

```
API Call
    │
    ▼ [Network timeout]
    │
    ▼
Show error dialog
    │
    ▼
"Something went wrong. Check your connection."
    │
    ▼
[TRY AGAIN] → Retry API call
[CANCEL] → Stay on current screen
```

---

## Back Navigation Flow

```
Step 4 → [Back] → Step 3 (data preserved)
Step 3 → [Back] → Step 2 (data preserved)
Step 2 → [Back] → Step 1 (data preserved)
Step 1 → [Back] → User Type Selection
User Type → [Back] → Exit onboarding (confirm dialog)
```

---

## Skip Flow

```
Step 4 (all fields empty)
    │
    ▼
[Skip →] clicked
    │
    ▼
Go to Final Review
    │
    ▼
Summary shows only required fields
```

---

## Data Persistence

### Local State (Riverpod)

```dart
OnboardingData {
  userType: 'business'        // Set at user type selection
  name: 'Café Barcelona'      // Step 1
  profilePhoto: 'base64...'   // Step 1 (optional)
  type: 'cafe'                // Step 2
  cityId: 'uuid...'           // Step 3
  about: 'Artisan...'         // Step 4 (optional)
  phoneNumber: '+34...'       // Step 4 (optional)
  instagram: 'cafebarcelona'  // Step 4 (optional)
  website: 'https://...'      // Step 4 (optional)
  currentStep: 4              // Track progress
}
```

**Data Flow:**
1. User fills Step 1 → Update state
2. Navigate to Step 2 → State preserved
3. User goes back → State preserved
4. User skips Step 4 → State preserved (fields null)
5. Final review → Read from state
6. Google Sign In → Send state to API
7. Success → Clear state

---

## Key Design Decisions

### Why Google Sign In at the End?

1. **Better UX**: Collect data before authentication
2. **Lower Barrier**: Users can start without Google account
3. **Higher Completion**: Users invested after filling form
4. **Data Quality**: Users think about profile before committing

### Why 4 Steps?

1. **Progressive Disclosure**: One concept per screen
2. **Reduces Cognitive Load**: Not overwhelming
3. **Clear Progress**: Visual indicator shows completion
4. **Easy to Abandon/Resume**: Clear checkpoints

### Why Skip Only on Step 4?

1. **Required Data First**: Steps 1-3 are essential
2. **Optional Enhancement**: Step 4 improves profile but not required
3. **User Choice**: Let users complete profile later

---

## Success Criteria

- [ ] User can complete onboarding in < 2 minutes
- [ ] Drop-off rate < 15% per step
- [ ] Error rate < 5%
- [ ] 80%+ completion rate
- [ ] Back navigation preserves data
- [ ] Google Sign In succeeds on first try
- [ ] API errors handled gracefully

---

**Flow Version:** 2.0
**Last Updated:** 2026-01-25
**Status:** Ready for Implementation
