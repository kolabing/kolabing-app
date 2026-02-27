# Task: Create Collaboration Request Form

## Status
- Created: 2026-01-26 16:00
- Started: 2026-01-26 16:00
- Completed:

## Description
Design and implement a multi-step form for Community users to create collaboration requests (opportunities) that Businesses can browse and apply to.

## User Flow
```
Community Dashboard / My Opportunities
  → Tap "Create New" button
  → Step 1: Basic Info (Title, Type, Description)
  → Step 2: Event Details (Location, Dates, Attendees)
  → Step 3: Offer Details (Reward, Requirements, Budget)
  → Review & Submit
  → Success → Navigate to My Opportunities
```

## Form Fields (Based on CollabRequest Model)

### Step 1: Basic Information
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| title | text | Yes | Max 255 chars |
| collabType | select | Yes | event/partnership/campaign |
| description | textarea | Yes | Max 2000 chars |

### Step 2: Event Details
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| city_id | dropdown | Yes | From /cities API |
| startDate | date picker | Yes | Future date |
| endDate | date picker | No | After start date |
| expectedAttendees | number | No | Min 1 |

### Step 3: Offer Details
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| hasReward | toggle | No | Default false |
| rewardDescription | textarea | Conditional | If hasReward=true, max 500 chars |
| budget | text | No | Free text |
| requirements | textarea | No | Max 1000 chars |

## API Endpoint (Expected)
```
POST /api/v1/opportunities

Request:
{
  "title": "Restaurant Week Promotion",
  "type": "event",
  "description": "Looking for restaurants...",
  "city_id": "uuid",
  "start_date": "2026-03-15",
  "end_date": "2026-03-22",
  "expected_attendees": 5000,
  "has_reward": true,
  "reward_description": "Featured spotlight...",
  "budget": "500-1000 EUR",
  "requirements": "Must have Instagram presence..."
}

Response:
{
  "success": true,
  "message": "Opportunity created successfully",
  "data": { ...opportunity }
}
```

## Design Requirements
- Multi-step wizard with progress indicator
- Yellow accent for active step
- Clean white form cards
- Inline validation with error messages
- Review step before submission
- Loading state during submission
- Success animation/feedback

## Files to Create
1. lib/features/community/screens/create_opportunity_screen.dart
2. lib/features/community/providers/opportunity_provider.dart
3. lib/features/community/services/opportunity_service.dart
4. lib/features/community/widgets/opportunity_form_step1.dart
5. lib/features/community/widgets/opportunity_form_step2.dart
6. lib/features/community/widgets/opportunity_form_step3.dart
7. lib/features/community/widgets/opportunity_review.dart

## Assigned Agents
- [ ] @ui-designer - Form UX/UI specifications
- [ ] @flutter-expert - Implementation

## Definition of Done
- [ ] Multi-step form implemented
- [ ] All fields with proper validation
- [ ] City dropdown from API
- [ ] Date pickers working
- [ ] Review step shows all entered data
- [ ] API integration (or mock if endpoint missing)
- [ ] Success/Error states handled
- [ ] Code compiles without errors
