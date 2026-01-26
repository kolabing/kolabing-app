# Refactor: Phone Number Real-Time Validation

## Status
- Created: 2026-01-26
- Started: 2026-01-26
- Completed: 2026-01-26

## Refactoring Scope
Add real-time validation to phone number input in business_step4_screen.dart.
User should see error message immediately when typing invalid phone format (before form submit).

## Current State
- Phone field at line 189-220 in `business_step4_screen.dart`
- No validation logic exists
- Uses simple TextField with TextInputType.phone
- Field is optional (part of step 4 which is skippable)

## Proposed Changes
1. Add phone validation state variable (_phoneError)
2. Add validation function that checks phone format on each change
3. Add error text decoration to TextField
4. Show error state with red border when invalid
5. Allow empty (since optional) but validate if user enters something

## Validation Rules
- Allows: digits, +, spaces, dashes, parentheses
- Minimum: 9 digits (Spanish mobile format)
- Maximum: 15 digits (E.164 international standard)
- Empty is valid (field is optional)

## Affected Files
- `lib/features/onboarding/screens/business/business_step4_screen.dart`

## Changes Made
1. Added `_phoneError` state variable (line 27)
2. Added `_validatePhone()` method (lines 89-123) with:
   - Empty check (valid if empty)
   - Invalid character check (only digits, +, -, (), spaces)
   - Minimum 9 digits check
   - Maximum 15 digits check
3. Updated TextField decoration (lines 191-256):
   - Added `onChanged: _validatePhone`
   - Icon color changes to error color when invalid
   - Background tints red when error
   - Added enabledBorder and focusedBorder for error state
   - Added errorText and errorStyle for error message display

## Verification
- [x] All functionality preserved
- [x] No API changes
- [x] Code compiles without errors
- [x] Validation shows in real-time as user types

## Notes
- Field remains optional
- Error only appears after user types invalid input
- Visual feedback: red border, red icon, red background tint, error message below field
