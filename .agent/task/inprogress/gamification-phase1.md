# Task: Gamification Phase 1 - Mobile Implementation

## Status
- Created: 2026-02-06 16:30
- Started:
- Completed:

## Description
Implement the Gamification Phase 1 system for Kolabing mobile app. This includes:
1. Attendee user type with registration
2. QR-based event check-in system
3. Challenge system (list, create, update, delete)
4. Peer-to-peer challenge completion flow (initiate, verify, reject)
5. Challenge completions history

## API Endpoints to Integrate

### Authentication
- [x] `POST /api/v1/auth/register/attendee` - Register attendee account
- [x] `POST /api/v1/auth/login` - Login (existing - supports attendee)

### Check-in System
- [ ] `POST /api/v1/events/{event}/generate-qr` - Generate QR token (organizer)
- [ ] `POST /api/v1/checkin` - Check in via QR token (attendee)
- [ ] `GET /api/v1/events/{event}/checkins` - List event check-ins

### Challenge Management
- [ ] `GET /api/v1/events/{event}/challenges` - List challenges for event
- [ ] `POST /api/v1/events/{event}/challenges` - Create custom challenge (organizer)
- [ ] `PUT /api/v1/challenges/{challenge}` - Update custom challenge (organizer)
- [ ] `DELETE /api/v1/challenges/{challenge}` - Delete custom challenge (organizer)

### Challenge Completion
- [ ] `POST /api/v1/challenges/initiate` - Initiate peer-to-peer challenge
- [ ] `POST /api/v1/challenge-completions/{id}/verify` - Verify challenge
- [ ] `POST /api/v1/challenge-completions/{id}/reject` - Reject challenge
- [ ] `GET /api/v1/me/challenge-completions` - List my completions

## Assigned Agents
- [ ] @ui-designer - UX Design & Component Specs
- [ ] @flutter-expert - Implementation

---

## Implementation Plan

### Phase 1A: Foundation (Models & Auth)

#### 1. Data Models
Create new models in `lib/features/gamification/models/`:

```
models/
├── attendee_profile.dart      # AttendeeProfile stats model
├── event_checkin.dart         # EventCheckin model
├── challenge.dart             # Challenge model with difficulty enum
├── challenge_completion.dart  # ChallengeCompletion with status enum
└── models.dart                # Barrel file
```

#### 2. Update User Model
- Add `attendee` to `UserType` enum
- Add `attendeeProfile` property to `UserModel`
- Update `fromJson` parsing

#### 3. Attendee Registration
- Add `registerAttendee()` method to `AuthService`
- Create attendee registration screen
- Update user type selection to include "Attendee" option

### Phase 1B: Check-in System

#### 4. QR Code Generation (Organizer)
Screen: `EventQRCodeScreen`
- Generate QR button that calls API
- Display QR code using `qr_flutter` package
- Regenerate button with confirmation
- Full-screen QR display option

#### 5. QR Code Scanning (Attendee)
Screen: `QRScannerScreen`
- Camera permission handling
- QR scanning using `mobile_scanner` package
- Parse token from QR data (JSON format)
- Call checkin API
- Success/error feedback

### Phase 1C: Challenge System

#### 6. Challenge List Screen
Screen: `EventChallengesScreen`
- List system + custom challenges
- Filter by difficulty
- Challenge card with: name, description, difficulty badge, points
- For organizer: show CRUD options for custom challenges
- For attendee: show "Initiate" option

#### 7. Challenge Management (Organizer)
Screens:
- `CreateChallengeScreen` - Create custom challenge form
- `EditChallengeScreen` - Edit existing custom challenge
- Difficulty picker (easy/medium/hard)
- Points input (or auto based on difficulty)
- Validation per API specs

### Phase 1D: Challenge Completion Flow

#### 8. Initiate Challenge Flow
Screen: `InitiateChallengeScreen`
- Select challenge from list
- Select verifier from checked-in attendees
- Confirmation dialog
- Submit and show pending status

#### 9. Verify/Reject Challenge
Screen: `PendingVerificationsScreen`
- List of challenges waiting for my verification
- Challenge details card
- Verify / Reject buttons
- Confirmation dialogs

#### 10. My Challenge Completions
Screen: `MyChallengeCompletionsScreen`
- Tab: As Challenger / As Verifier
- List all my completions
- Status badges (pending/verified/rejected)
- Points earned display

### Phase 1E: Attendee Home & Navigation

#### 11. Attendee Navigation
- Create `AttendeeMainScreen` with bottom nav
- Tabs: Home, Scan QR, My Challenges, Profile

#### 12. Attendee Home Screen
Screen: `AttendeeHomeScreen`
- Stats summary (points, challenges, events)
- Recent activity
- Current event (if checked in)
- Quick action: Scan QR

#### 13. Attendee Profile Screen
Screen: `AttendeeProfileScreen`
- Avatar, name, email
- Total points
- Total challenges completed
- Total events attended
- Global rank (placeholder for Phase 2)

---

## File Structure

```
lib/features/gamification/
├── models/
│   ├── models.dart
│   ├── attendee_profile.dart
│   ├── event_checkin.dart
│   ├── challenge.dart
│   └── challenge_completion.dart
├── services/
│   ├── services.dart
│   ├── checkin_service.dart
│   └── challenge_service.dart
├── providers/
│   ├── providers.dart
│   ├── checkin_provider.dart
│   ├── challenge_provider.dart
│   └── challenge_completion_provider.dart
├── screens/
│   ├── screens.dart
│   ├── attendee_main_screen.dart
│   ├── attendee_home_screen.dart
│   ├── attendee_profile_screen.dart
│   ├── qr_scanner_screen.dart
│   ├── event_qr_code_screen.dart
│   ├── event_challenges_screen.dart
│   ├── create_challenge_screen.dart
│   ├── edit_challenge_screen.dart
│   ├── initiate_challenge_screen.dart
│   ├── pending_verifications_screen.dart
│   └── my_challenge_completions_screen.dart
└── widgets/
    ├── widgets.dart
    ├── challenge_card.dart
    ├── challenge_completion_card.dart
    ├── difficulty_badge.dart
    ├── points_badge.dart
    ├── checkin_status_chip.dart
    └── attendee_stats_card.dart
```

---

## UI States

### All Screens
- [ ] Loading state (shimmer)
- [ ] Empty state (with illustration)
- [ ] Error state (with retry)
- [ ] Success state

### QR Scanner
- [ ] Scanning state
- [ ] Processing state (after scan)
- [ ] Success state (check-in confirmed)
- [ ] Error state (invalid token, already checked in, etc.)

### Challenge Initiation
- [ ] Select challenge state
- [ ] Select verifier state
- [ ] Confirmation state
- [ ] Success state (challenge pending)

### Verification
- [ ] Pending items state
- [ ] Confirm verify dialog
- [ ] Confirm reject dialog
- [ ] Success feedback

---

## Dependencies to Add

```yaml
dependencies:
  qr_flutter: ^4.1.0        # QR code generation
  mobile_scanner: ^5.2.0     # QR code scanning
```

---

## Progress

### UX Design
**Status:** Pending

### Flutter Implementation
**Status:** Pending

---

## Sub-Tasks Breakdown

1. **[Models]** Create gamification data models
2. **[Auth]** Update UserType enum and add attendee registration
3. **[Service]** Create CheckinService
4. **[Service]** Create ChallengeService
5. **[Provider]** Create CheckinProvider
6. **[Provider]** Create ChallengeProvider
7. **[Provider]** Create ChallengeCompletionProvider
8. **[Screen]** Attendee registration screen
9. **[Screen]** Attendee main screen with navigation
10. **[Screen]** Attendee home screen
11. **[Screen]** Attendee profile screen
12. **[Screen]** QR scanner screen (attendee)
13. **[Screen]** Event QR code screen (organizer)
14. **[Screen]** Event challenges screen
15. **[Screen]** Create challenge screen (organizer)
16. **[Screen]** Edit challenge screen (organizer)
17. **[Screen]** Initiate challenge screen
18. **[Screen]** Pending verifications screen
19. **[Screen]** My challenge completions screen
20. **[Route]** Add gamification routes
21. **[Test]** Manual testing & bug fixes

## Notes
- QR format: `{"type": "kolabing_checkin", "token": "...64-char..."}`
- Difficulty default points: easy=5, medium=15, hard=30
- Both challenger and verifier must be checked in to same event
- Max challenges per attendee enforced by backend
