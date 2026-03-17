# Fix: Input Placeholder & Label Visibility (Whole App)

## Status
- Created: 2026-02-27 15:35
- Started: 2026-02-27 15:35
- Completed: 2026-02-27 15:38

## Issue Description
Input fields throughout the app show invisible/unreadable labels and placeholder texts when displayed on white/light backgrounds. The floating label turns yellow (#FFD861 - primary color) which is nearly invisible on white/light backgrounds.

## Root Cause
`floatingLabelStyle` not set in `InputDecorationTheme` → Material 3 defaults to `colorScheme.primary` (#FFD861 yellow) for floating labels → yellow on white = invisible.

## Affected Files
- lib/config/theme/theme.dart (PRIMARY - global fix)
- All screens with inputs inherit this fix via Flutter's InputDecoration.applyDefaults()

## Fix Applied
1. Add `floatingLabelStyle` with textSecondary (#606060) to light theme InputDecorationTheme
2. Add `floatingLabelStyle` with textOnDark (white) to dark theme InputDecorationTheme
3. Improve `hintStyle` color from textTertiary (#888888) to textSecondary (#606060) for better contrast on light backgrounds

## Testing
- [ ] Labels visible on light background screens
- [ ] Labels visible on dark background screens
- [ ] Hint text readable in all input states
- [ ] No side effects introduced
- [ ] Code compiles

## Notes
Flutter merges InputDecoration with InputDecorationTheme - fixing theme.dart fixes ALL screens globally.
