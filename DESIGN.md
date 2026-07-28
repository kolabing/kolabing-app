---
design:
  name: Kolabing
  description: Community marketing platform connecting brands with real communities for authentic experiences and growth.
  platform: mobile
  theme: light-primary / dark-auth

colors:
  # Source of truth: lib/config/theme/colors.dart (KolabingColors). Update there first.
  brand:
    primary: "#FFE28C"
    primary-dark: "#F5D070"
    primary-soft: "#FFF1C6"
    primary-soft-border: "#F9E9AC"
    on-primary: "#19150F"

  background:
    default: "#FAF5EA"
    surface: "#FFFFFF"
    surface-variant: "#F5EFE3"

  text:
    primary: "#1C1C16"
    secondary: "#3F3A32"
    tertiary: "#8C8474"
    on-dark: "#FFFFFF"

  dark-theme:
    background: "#000000"
    surface: "#222222"
    border: "#444444"

  border:
    default: "#EBEBEB"
    focus: "#E8D7A0"
    error: "#FF6B6B"

  semantic:
    success: "#56624D"
    warning: "#FBC02D"
    error: "#BA1A1A"
    info: "#2196F3"

  accent:
    orange-bg: "#FFDDAC"
    orange-text: "#D8910B"

  status:
    pending-bg: "#FFDDAC"
    pending-text: "#D8910B"
    active-bg: "#D4EDDA"
    active-text: "#155724"
    completed-bg: "#E8E8E8"
    completed-text: "#666666"
    declined-bg: "#F8D7DA"
    declined-text: "#721C24"

  gradient:
    primary-start: "#FFE28C"
    primary-end: "#FFF1C6"
    primary-direction: top-left to bottom-right

# Source of truth: lib/config/theme/typography.dart (loaded via google_fonts).
typography:
  families:
    display: "Anton"
    body: "Inter"
    label: "Inter"
    fallback: "Inter"

  scale:
    display-large:
      family: Anton
      size: 32
      weight: 800
      letter-spacing: 1.5
      line-height: 1.2
    display-medium:
      family: Anton
      size: 28
      weight: 800
      letter-spacing: 1.2
      line-height: 1.2
    display-small:
      family: Anton
      size: 24
      weight: 700
      letter-spacing: 1.0
      line-height: 1.2
    headline-large:
      family: Anton
      size: 22
      weight: 700
      line-height: 1.3
    headline-medium:
      family: Anton
      size: 20
      weight: 600
      line-height: 1.3
    headline-small:
      family: Anton
      size: 18
      weight: 600
      line-height: 1.3
    title-large:
      family: Inter
      size: 18
      weight: 700
      line-height: 1.4
    title-medium:
      family: Inter
      size: 16
      weight: 600
      line-height: 1.4
    title-small:
      family: Inter
      size: 14
      weight: 600
      line-height: 1.4
    body-large:
      family: Inter
      size: 16
      weight: 400
      line-height: 1.5
    body-medium:
      family: Inter
      size: 14
      weight: 400
      line-height: 1.5
    body-small:
      family: Inter
      size: 12
      weight: 400
      line-height: 1.5
    label-large:
      family: Inter
      size: 16
      weight: 600
      letter-spacing: 0.5
      line-height: 1.2
    label-medium:
      family: Inter
      size: 14
      weight: 500
      letter-spacing: 0.4
      line-height: 1.2
    label-small:
      family: Inter
      size: 12
      weight: 500
      letter-spacing: 0.4
      line-height: 1.2
    button:
      family: Inter
      size: 16
      weight: 600
      letter-spacing: 1.0
      line-height: 1.2
    button-small:
      family: Inter
      size: 14
      weight: 600
      letter-spacing: 0.8
      line-height: 1.2

spacing:
  unit: 4
  scale:
    xxxs: 2
    xxs: 4
    xs: 8
    sm: 12
    md: 16
    lg: 24
    xl: 32
    xxl: 48
    xxxl: 64

radii:
  xs: 4
  sm: 8
  md: 12
  lg: 16
  xl: 20
  xxl: 24
  pill: 999

shadows:
  card:
    color: "rgba(55, 73, 87, 0.10)"
    blur: 8
    offset-y: 1.5
  card-hover:
    color: "rgba(55, 73, 87, 0.12)"
    blur: 16
    offset-y: 4
  button:
    color: "rgba(55, 73, 87, 0.11)"
    blur: 4
    offset-y: 1.5
  bottom-nav:
    color: "rgba(0, 0, 0, 0.08)"
    blur: 20
    offset-y: -4
  focus-ring:
    color: "rgba(255, 246, 216, 0.4)"
    spread: 3

motion:
  curves:
    default: easeInOut
    modal: easeOut
  durations:
    page-transition: 300
    modal: 250
    tab-switch: 200
    quick: 100
    shimmer: 1500

components:
  button-primary:
    height: 52
    radius: 12
    font: button
    background: "#FFE28C"
    color: "#000000"
  button-secondary:
    height: 48
    radius: 12
    font: button
  input-light:
    height: 48
    radius: 8
    fill: "#F5EFE3"
    border-width: 1.5
    padding-x: 16
    padding-y: 14
    focus-border-width: 2
    focus-border-color: "#E8D7A0"
  input-dark:
    height: 52
    radius: 12
    fill: "#222222"
    border-width: 1.5
    padding-x: 16
    padding-y: 14
    focus-border-width: 2
  card:
    radius: 16
    elevation: 0
    border-width: 1
    border-color: "#EBEBEB"
    padding: 16
  bottom-nav:
    height: 80
    icon-size: 24
    label-size: 10
    label-weight-active: 600
    label-weight-inactive: 400
  chip:
    radius: 12
    padding-x: 12
    padding-y: 4
  bottom-sheet:
    radius-top: 20
    drag-handle: true
  dialog:
    radius: 16
  snackbar:
    radius: 8
    behavior: floating
  fab:
    shape: circle
    elevation: 6
    highlight-elevation: 12
    icon-size: 28
  touch-target-min: 48

layout:
  screen-padding-x: 16
  screen-padding: 16
  max-content-width: 600
  list-item-spacing: 12
  grid-spacing: 16
  bottom-nav-height: 80
  bottom-safe-area: 16
  card-padding: 16
  card-padding-large: 24
  icon-sm: 20
  icon-md: 24
  icon-lg: 32
---

# Kolabing Design Language

## Design Philosophy

Kolabing is a community marketing platform built for a mobile-first audience. The design is minimal, direct, and energetic — avoiding corporate polish in favour of warmth, clarity, and motion. The visual identity draws from Apple and Linear: generous whitespace, strong typography, subtle animation. Nothing decorative that doesn't serve a purpose.

The yellow (`#FFE28C`) is the single expressive element. Everything else — backgrounds, text, borders — is intentionally neutral, letting the primary colour do all the emotional lifting. Black text always sits on yellow. Never reverse this.

## Two Modes: Light App / Dark Auth

The app runs in **two visual contexts** that must never bleed into each other:

**Auth screens** (splash, welcome, login, registration, onboarding): pure black backgrounds (`#000000`), white or yellow text, dark input fields (`#222222`), 12dp input radius. This creates a premium, focused feeling at first touch.

**Main app screens** (dashboards, explore, offers, applications): light background (`#FAF5EA`), white cards, dark text, 8dp input radius. Feels clean and airy once the user is inside the product.

The transition between the two contexts — when the user successfully authenticates and reaches their dashboard — should feel like stepping into a brighter space.

## Typography

Headings always use **Anton**, bold and slightly tracked. It's strong without being aggressive. Use uppercase for display-level text (hero headlines, splash screens).

Body and UI copy uses **Inter**. Readable, neutral, trustworthy.

Buttons and labels use **Inter**. Slightly technical feel, good at small sizes, tracks nicely at higher letter-spacing.

Never mix Anton with Inter at the same visual level — they serve different hierarchical roles.

## Color

The palette is deliberately restrained:

- **Yellow (`#FFE28C`)** — primary action, selection state, brand accent, CTAs. Only use with black (`#000000`) text.
- **Black (`#000000`)** — auth screens only; creates drama and focus.
- **Light gray (`#FAF5EA`)** — app background. Not white. The slight warmth reduces eye strain.
- **White (`#FFFFFF`)** — card surfaces, elevated content.
- **Text (`#1C1C16 / #3F3A32 / #8C8474`)** — three levels of text hierarchy on light backgrounds.

Status colours (success green, error red, warning orange) are used only in badges and inline feedback — never as background fills or decorative elements.

The primary gradient (`#FFE28C` → `#FFF1C6`) is used sparingly — FAB backgrounds, highlighted cards, promotional banners. Never apply it to text or icons.

## Spacing

The spacing system is based on a **4px grid**. All spacing decisions should land on multiples of 4. The canonical screen padding is **16px horizontal**. Cards have **16px internal padding**, large content areas use **24px**.

List items are spaced **12px apart**. Grid gutters are **16px**.

## Elevation and Depth

The app is intentionally flat. Cards have **no elevation** (elevation: 0) and use a **1px `#EBEBEB` border** instead of shadow to define boundaries. This keeps the interface clean on both light and dark backgrounds.

Shadows exist only for interactive or floating elements:
- Cards on hover/focus get a soft `rgba(55, 73, 87, 0.12)` shadow at 16px blur
- The bottom navigation uses an upward shadow (`rgba(0, 0, 0, 0.08)`, 20px blur) to separate it from content
- The FAB uses elevation 6 (system default shadow)

## Components

### Buttons
Primary buttons are 52dp tall, 12dp radius, yellow fill, black text, Inter semi-bold with 1.0 letter-spacing. Full-width on most screens.

Secondary buttons are 48dp tall, same radius, either outlined or surface-fill. Never use grey backgrounds for secondary actions — use outlined instead.

### Inputs
**Dark theme (auth):** 52dp, 12dp radius, `#222222` fill, `#444444` border, white text.  
**Light theme (app):** 48dp, 8dp radius, `#F5EFE3` fill, `#EBEBEB` border, `#1C1C16` text. On focus, border becomes `#E8D7A0` (a warm yellow-tinted border, not the full primary yellow).

### Cards
16dp radius, 1px border (`#EBEBEB`), white surface, 0 elevation, 16px padding. Cards never have coloured fills unless they are status badges or promotional banners.

### Chips and Badges
12dp radius, 12px horizontal padding, 4px vertical. Status badges follow a paired bg/text colour system (pending = orange tones, active = green tones, completed = grey tones, declined = red tones). Badge font: Inter 11px medium.

### Bottom Navigation
80dp total height (including safe area). 5 tabs for Business and Community users, 3 tabs for Attendees. Active tab: yellow icon + Inter semi-bold label. Inactive: `#8C8474` icon + regular label. Badge: yellow dot or numbered pill on Applications tab.

### FAB (Floating Action Button)
Circle, yellow fill, black icon, 28dp icon size, elevation 6. Always positioned bottom-right. Used as the primary creation entry point on main screens.

### Bottom Sheets
20dp radius on top corners only. Always includes a drag handle at top. Used for filters, explore details, and confirmations.

### Swipe Cards (Explore)
20dp radius, white surface with card shadow. Large name in Anton 22px bold. Category and type as small Inter chips below. Description in Inter 14px. Day availability shown as small circles (36dp). Dot pagination indicator at bottom.

## Motion

All transitions default to **300ms easeInOut**. Modal and bottom sheet entries use **250ms easeOut** for a snappier feel. Tab switches are **200ms** — fast enough to feel instant but still perceptible. Button press feedback is **100ms** (micro-interaction only).

Loading states use **shimmer animation at 1500ms** loop — never spinners on content areas, only on actions (button loading states).

Selection cards (user type, intent selection) animate at **200ms** with a **1.02 scale** on press, giving a tactile feel.

## Imagery and Media

Profile photos and gallery images use 16dp radius clip masks. No harsh square crops anywhere in the UI.

Media upload placeholders use the surface-variant fill (`#F5EFE3`) with a dashed border and a centred upload icon. Empty states use the same pattern — neutral background, icon, short message, and a single action button.

## Accessibility

Minimum touch target is **48×48dp** on all interactive elements. Text on yellow (`#FFE28C`) must always be black (`#000000`) — this is the only combination that meets contrast requirements for that background. Never use yellow text on white or light backgrounds.

Text hierarchy must be maintained at all times: primary (`#1C1C16`), secondary (`#3F3A32`), tertiary (`#8C8474`). Do not use tertiary text for interactive elements.
