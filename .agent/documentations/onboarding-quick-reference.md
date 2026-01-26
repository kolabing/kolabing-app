# Onboarding Quick Reference

**Last Updated:** 2026-01-25
**For:** Developer Quick Lookup

---

## TL;DR

Google Sign In happens AFTER data collection, not before.

```
User Type → 4 Steps → Review → Google → API → Dashboard
```

---

## Screens Count

| Flow | Screens | Required Steps | Optional Steps |
|------|---------|----------------|----------------|
| Business | 6 total | 3 (Steps 1-3) | 1 (Step 4) |
| Community | 6 total | 3 (Steps 1-3) | 1 (Step 4) |

**Both:**
- 1 User Type Selection
- 4 Onboarding Steps
- 1 Final Review

---

## Required Fields

### Business
1. Business Name (Step 1)
2. Business Type (Step 2)
3. City (Step 3)

### Community
1. Display Name (Step 1)
2. Community Type (Step 2)
3. City (Step 3)

**All other fields are optional**

---

## Screen Specs

| Screen | Background | Header | Footer |
|--------|------------|--------|--------|
| All Onboarding | #F7F8FA | Progress (Steps 1-4) | Continue Button |
| Final Review | #F7F8FA | Back only | Google Button |

---

## Component Sizes

| Component | Height | Radius | Notes |
|-----------|--------|--------|-------|
| Continue Button | 52dp | 12dp | Yellow, full width |
| Input Field | 52dp | 8dp | Light gray bg |
| Selection Card | 96dp+ | 12dp | Grid 3 cols |
| Photo Upload | 80x80dp | Circle | Dashed border when empty |
| Progress Circle | 12dp | Circle | Yellow when active |
| Progress Line | 2dp | - | 24dp spacing |

---

## Color Quick Ref

| Element | Color | Hex |
|---------|-------|-----|
| Primary (Yellow) | Button, Border | #FFD861 |
| Selected Card Bg | Soft Yellow | #FFF6D8 |
| Background | Light Gray | #F7F8FA |
| Input Bg | Gray | #F5F6F8 |
| Text Primary | Black | #232323 |
| Text Secondary | Gray | #606060 |
| Error | Red | #E14D76 |

---

## Validation Limits

| Field | Max Length | Format |
|-------|------------|--------|
| name | 255 chars | Text |
| about | 1000 chars | Multiline |
| profile_photo | 5MB | jpg/png/webp |
| phone_number | - | +34... (E.164) |
| instagram | - | No @ prefix |
| tiktok | - | No @ prefix |
| website | - | https:// |

---

## API Calls

### 1. Load Dropdown Data (Once, Cache)

```
GET /lookup/business-types    → Business Step 2
GET /lookup/community-types   → Community Step 2
GET /cities                   → Step 3 (both)
```

### 2. Complete Onboarding (After Google)

```
POST /auth/google
  Body: { id_token, user_type }
  Response: { token, user, is_new_user }

PUT /onboarding/business OR PUT /onboarding/community
  Headers: { Authorization: Bearer {token} }
  Body: { name, type, city_id, about, ... }
```

---

## Navigation Routes

```
/onboarding/user-type

/onboarding/business/step1
/onboarding/business/step2
/onboarding/business/step3
/onboarding/business/step4
/onboarding/business/final

/onboarding/community/step1
/onboarding/community/step2
/onboarding/community/step3
/onboarding/community/step4
/onboarding/community/final
```

---

## State Management

**Provider:** `onboardingProvider` (Riverpod)

**Methods:**
- `setUserType(type)`
- `updateField(key, value)`
- `nextStep()`
- `previousStep()`
- `canProceedFromStep(step)`
- `toBusinessPayload()` / `toCommunityPayload()`

**State:**
```dart
{
  userType: 'business' | 'community',
  name: String?,
  profilePhoto: String?,
  type: String?,
  cityId: String?,
  about: String?,
  phoneNumber: String?,
  instagram: String?,
  tiktok: String?, // community only
  website: String?,
  currentStep: int
}
```

---

## Common Patterns

### Form Field with Label
```dart
Text('Field Name *', style: KolabingTextStyles.labelMedium),
SizedBox(height: 8),
TextFormField(
  decoration: InputDecoration(
    hintText: 'Enter...',
    filled: true,
    fillColor: KolabingColors.surfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
  style: KolabingTextStyles.bodyLarge,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
  onChanged: (value) => ref.read(onboardingProvider.notifier).updateField('key', value),
)
```

### Selection Card Grid
```dart
GridView.count(
  crossAxisCount: 3,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.9,
  children: types.map((type) => SelectionCard(
    icon: type.icon,
    label: type.label,
    isSelected: selectedType == type.value,
    onTap: () => ref.read(onboardingProvider.notifier).updateField('type', type.value),
  )).toList(),
)
```

### Progress Header
```dart
OnboardingHeader(
  onBack: () => Navigator.pop(context),
  onSkip: currentStep == 4 ? () => Navigator.pushNamed(context, '/final') : null,
  currentStep: currentStep,
  totalSteps: 4,
)
```

---

## Error Handling

### Field Validation
```dart
validator: (value) {
  if (value == null || value.isEmpty) return 'Required';
  if (value.length < 3) return 'Too short';
  if (value.length > 255) return 'Too long';
  return null;
}
```

### API Error
```dart
try {
  await completeOnboarding();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Photo Size Check
```dart
if (imageBytes.length > 5 * 1024 * 1024) {
  throw Exception('Photo must be under 5MB');
}
```

---

## Testing Checklist

**Navigation:**
- [ ] User type selection works
- [ ] Forward navigation proceeds
- [ ] Back button preserves data
- [ ] Skip goes to final review

**Validation:**
- [ ] Required fields block proceed
- [ ] Optional fields allow skip
- [ ] Character counters update
- [ ] Error messages show

**Integration:**
- [ ] Google Sign In triggers
- [ ] Token stored securely
- [ ] API calls succeed
- [ ] Dashboard navigation works

**Edge Cases:**
- [ ] Back from Step 1 goes to user type
- [ ] Cancelled Google Sign In returns to review
- [ ] API errors show messages
- [ ] Network errors allow retry

---

## Performance

**Load Times:**
- Step load: < 100ms
- Google Sign In: < 3s
- API calls: < 2s each
- Total flow: < 2 minutes

**Optimizations:**
- Cache lookup data (cities, types)
- Compress profile photo before upload
- Show loading states immediately
- Preload next step assets

---

## Accessibility

**Touch:**
- Min 48x48dp touch targets
- Full card tappable for selections
- Buttons 52dp height

**Screen Reader:**
- "Step X of 4" announced
- "Required field" announced
- "Optional" announced

**Keyboard:**
- Tab order logical
- Enter proceeds
- Escape goes back

---

## Design Files

- [Wireframes](./onboarding-flow-update.md) - Detailed wireframes
- [UX Design](./onboarding-ux-design.md) - Full design doc
- [Flow Diagram](./onboarding-flow-diagram.md) - Visual flow
- [Implementation Guide](./onboarding-implementation-guide.md) - Code examples

---

## Contact

- Design Questions: @ux-designer
- Implementation Help: @flutter-expert
- Business Logic: Product Team

---

**Status:** Ready for Implementation ✓
