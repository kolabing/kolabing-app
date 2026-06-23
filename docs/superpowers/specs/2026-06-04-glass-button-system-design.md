# Glass Button System — Design Spec
_Last updated: 2026-06-04_

## Goal
Replace solid CTA buttons with a translucent "clear glass" button system and re-layout the My Kolabs card action row into one primary pill + round icon-only secondary buttons.

## Scope (Phase A)
- Two new shared widgets: `GlassButton`, `GlassIconButton`
- New colour tokens in `KolabingColors`
- Card action rows: `my_kolab_card.dart`, `my_opportunity_card.dart`
- Explore card: `opportunity_card.dart` (VIEW + APPLY)
- Dashboard quick-action buttons: `business_dashboard_screen.dart`, `community_dashboard_screen.dart`
- Referral banner: `referral_banner_card.dart`
- Profile action buttons (Find a kolab, Share referral, Sign out): `business_profile_screen.dart`, `community_profile_screen.dart`

Phase B (future): remaining 50+ screens — auth, onboarding, modals, collaboration, gamification.

---

## New Colour Tokens

Add to `lib/config/theme/colors.dart`:

```dart
/// Glass button ink — shared across all glass button intents
static const Color glassInk = Color(0xFF57534B);

/// Glass destructive ink
static const Color glassDestructiveInk = Color(0xFF9B3B3B);
```

---

## Archetype A — `GlassButton`

**File:** `lib/widgets/glass_button.dart`

### API
```dart
GlassButton({
  required String label,
  required VoidCallback? onPressed,
  GlassButtonIntent intent = GlassButtonIntent.primary,
  IconData? icon,           // optional leading icon
})
```

### Enum
```dart
enum GlassButtonIntent { primary, neutral, destructive }
```

### Geometry
- Shape: `StadiumBorder` (fully rounded pill)
- Height: `48`, horizontal padding: `22`
- Stack: `ClipRRect(stadium)` → `BackdropFilter(blur 8/8)` → `Container(fill + border + shadow + top gradient)`

### Fill / border / ink per intent
| Intent | Fill | Border | Ink |
|---|---|---|---|
| primary | `Color(0xFFFFF4C2).withOpacity(0.34)` | `Colors.white.withOpacity(0.78)` | `glassInk` |
| neutral | `Colors.white.withOpacity(0.30)` | `Colors.white.withOpacity(0.78)` | `glassInk` |
| destructive | `Color(0xFF9B3B3B).withOpacity(0.10)` | `Color(0xFF9B3B3B).withOpacity(0.35)` | `glassDestructiveInk` |

### Shadow
```
BoxShadow(color: Color(0x1A96781E), blurRadius: 14, offset: Offset(0, 5))
```

### Top sheen (optional visual polish)
A `LinearGradient` from `Colors.white.withOpacity(0.18)` to transparent, 6px tall, clipped at top inside the pill.

### Typography
- Font: Inter (already the body font via `KolabingTypography.fontBody`)
- Size: `14.5`, weight: `w600`, letterSpacing: `0`
- Label is **forced lowercase** in the widget (`label.toLowerCase()`)
- Icon: `17px`, same ink colour, `8px` gap before label

---

## Archetype B — `GlassIconButton`

**File:** `lib/widgets/glass_icon_button.dart`

### API
```dart
GlassIconButton({
  required IconData icon,
  required VoidCallback? onPressed,
  required String tooltip,
  String? semanticsLabel,   // defaults to tooltip
})
```

### Geometry
- Size: `46 × 46`, circle (`BoxShape.circle`)
- Glass: `ClipRRect(circle)` + `BackdropFilter(blur 8/8)`
- Fill: `Colors.white.withOpacity(0.30)`
- Border: `1px Colors.white.withOpacity(0.78)`
- Shadow: `BoxShadow(color: Color(0x14785A28), blurRadius: 10, offset: Offset(0, 4))`
- Icon: `18px`, `KolabingColors.glassInk`, rendered with `LucideIcons`

### Accessibility
Wrapped in `Tooltip(message: tooltip)` + `Semantics(label: semanticsLabel ?? tooltip, button: true)`.

---

## My Kolabs Card — `my_kolab_card.dart`

### New action row layout
```
Row(mainAxisAlignment: start, children: [
  Expanded(child: GlassButton(primary, label: …, icon: …)),
  SizedBox(width: 9),
  GlassIconButton(…),
  SizedBox(width: 9),
  GlassIconButton(…),   // if applicable
])
```
Row height ≈ 46 (was 36).

### Published state
- Pill: `view` (LucideIcons.eye)
- Icons: edit (LucideIcons.edit, tooltip: 'Edit'), close (LucideIcons.xCircle, tooltip: 'Close')

### Draft state (canEdit)
- Pill: `edit` (LucideIcons.edit)
- Icons: publish (LucideIcons.upload, tooltip: 'Publish')

### canDelete (no applications)
- Pill: `delete` intent=destructive (LucideIcons.trash2) — no secondary icons needed

All `onPressed` handlers preserved exactly as-is. The private `_ActionBtn` class is removed and replaced by the shared widgets.

Same layout applies to `my_opportunity_card.dart` (community card — identical button structure).

---

## Explore Card — `opportunity_card.dart`

Replace `_buildActionButtons`:
- VIEW → `GlassButton(intent: neutral, label: 'view', icon: LucideIcons.eye, onPressed: onView)`
- APPLY → `GlassButton(intent: primary, label: 'apply', icon: LucideIcons.send, onPressed: onApply)`

Both remain `Expanded` in the same Row.

---

## Dashboard Quick Actions

### `business_dashboard_screen.dart`
Identify the "Find a Kolab" / quick-action `ElevatedButton` rows and replace with `GlassButton(primary)`.

### `community_dashboard_screen.dart`
Same — replace primary CTA buttons with `GlassButton(primary)`.

---

## Referral Banner — `referral_banner_card.dart`
- Primary CTA (e.g. "Share referral code") → `GlassButton(primary)`
- Secondary CTA (e.g. "My applications") → `GlassButton(neutral)`

---

## Profile Actions

### `business_profile_screen.dart` + `community_profile_screen.dart`
- "Find a kolab" / "Browse opportunities" → `GlassButton(primary)`
- "Share referral code" → `GlassButton(neutral)`
- "Sign out" → `GlassButton(destructive)`

---

## What Does NOT Change
- All `onPressed` handlers, providers, models, services, routes, navigation
- Paywall / FAB logic
- Auth screens, onboarding, modals (Phase B)
- Card content above the action row (badge, title, chips, image)
- Any layout outside the button/action row areas

---

## Delivery Order
1. Add colour tokens to `colors.dart`
2. Create `lib/widgets/glass_button.dart`
3. Create `lib/widgets/glass_icon_button.dart`
4. Update `my_kolab_card.dart`
5. Update `my_opportunity_card.dart`
6. Update `opportunity_card.dart`
7. Update `business_dashboard_screen.dart`
8. Update `community_dashboard_screen.dart`
9. Update `referral_banner_card.dart`
10. Update `business_profile_screen.dart`
11. Update `community_profile_screen.dart`
