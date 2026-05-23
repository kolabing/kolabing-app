# UI: Category Icon Illustration System

## Status
- Created: 2026-05-16 10:00
- Started: 2026-05-16 10:00
- Completed: 

## UI Requirements
Replace emoji-based category system with custom SVG illustration/icon system.
Crafted, premium, hand-drawn style. Kolabing palette only. No layout changes.

## Scope
- Primary: `type_selection_card.dart` (onboarding business/community type grid)
- Assets: `assets/icons/categories/category-<slug>.svg`
- New widget: `CategoryIcon` for reuse

## Design Specifications

### Style
- Hand-drawn, slightly imperfect strokes
- 2px stroke weight, rounded linecaps/joins
- Dark linework: #0D0D0D
- Yellow fill: #FFE28C (selective, not all icons)
- Purple accent: #7F77DD (micro-accents only)
- ViewBox: 0 0 64 64
- Works at 32/64/96/240px

### Color Rules
- Strokes: #0D0D0D
- Fills: #FFE28C (warm yellow, used sparingly)
- Accent: #7F77DD (1–2 elements max per icon)
- Background: transparent

## Implementation

### Files Created
- assets/icons/categories/category-cafe.svg
- assets/icons/categories/category-restaurant.svg
- assets/icons/categories/category-bar.svg
- assets/icons/categories/category-gym.svg
- assets/icons/categories/category-yoga.svg
- assets/icons/categories/category-running.svg
- assets/icons/categories/category-cycling.svg
- assets/icons/categories/category-music.svg
- assets/icons/categories/category-art.svg
- assets/icons/categories/category-sports.svg
- assets/icons/categories/category-wellness.svg
- assets/icons/categories/category-tech.svg
- assets/icons/categories/category-education.svg
- assets/icons/categories/category-gaming.svg
- assets/icons/categories/category-social.svg
- assets/icons/categories/category-fashion.svg
- assets/icons/categories/category-food.svg
- assets/icons/categories/category-outdoor.svg
- assets/icons/categories/category-travel.svg
- assets/icons/categories/category-coworking.svg
- assets/icons/categories/category-retail.svg
- assets/icons/categories/category-beauty.svg
- assets/icons/categories/category-health.svg
- assets/icons/categories/category-default.svg
- lib/widgets/category_icon.dart (new reusable widget)
- lib/features/onboarding/widgets/type_selection_card.dart (updated)

## Notes
- flutter_svg ^2.0.9 already in pubspec
- assets/icons/ already registered in pubspec.yaml assets
- Added assets/icons/categories/ subfolder
