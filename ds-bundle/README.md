# Kolabing — design conventions

## ⚠️ This project holds TWO design systems. Pick one per design.

Kolabing ships two products with genuinely different visual languages. Both are
here, side by side, and they are **not** meant to be reconciled — mixing them
produces something that is neither.

| | **Mobile app** | **Marketing web** |
|---|---|---|
| Namespace | `--kolabing-*` | `--kb-*` |
| Entry point | `styles.css` | `styles.marketing.css` |
| Docs | this file | `guidelines/*.md` |
| Product | the Flutter iOS/Android app | kolabing.com + web app |

**Never use both namespaces in one screen.** Decide which product you are
designing for, load that entry point, and stay inside its vocabulary.

Where they openly disagree — each is correct *for its own product*:

- **Primary CTA.** App: yellow ground, dark ink. Marketing: **dark ground, yellow
  text** (inverted on purpose).
- **Dark theme.** App: a full night palette, 87 tokens. Marketing: no dark theme
  at all — it uses dark *bands* on a light page.
- **Page ground.** App: warm parchment `#faf5ea`. Marketing: white / cool `#f7f8fa`.
- **Corners.** App: cards 24, inputs 16, pills for chips. Marketing: everything pill.
- **Fonts.** Both use Anton + Inter; marketing additionally uses Caveat, DM Sans,
  Montserrat and Playfair Display.

If the request doesn't say which product, **ask** — or default to the mobile app,
since that is what the rest of this file documents.

---

# The mobile app system (`--kolabing-*`)

**This is a token-only design system. There is no component library here.** No
`_ds_bundle.js`, no importable React components, nothing on `window.*`. Kolabing's
real components are Flutter widgets (`lib/` in `kolabing/kolabing-app`) and cannot be
rendered on the web. So: **build your own markup, and style every part of it with the
tokens below.** Do not reach for a component you were not given, and do not invent
color/spacing values — if you need a value, there is a token for it.

Kolabing is a **mobile app** (iOS/Android): design at phone width. Content caps at
`var(--kolabing-size-max-content-width)` (600px).

## Setup

Link the stylesheet once; every token comes with it.

```html
<link rel="stylesheet" href="./styles.css" />
```

Theme is automatic: light is the default, and the night palette applies under
`prefers-color-scheme: dark`. To pin a theme, set `data-theme="dark"` or
`data-theme="light"` on `<html>`. Never hardcode a hex — the same token name carries
both themes, so `var(--kolabing-color-surface)` repaints for free and a literal does not.

## The idiom: CSS custom properties + text classes

Everything is a `var(--kolabing-<group>-<name>)`. The groups:

| Group | Pattern | Examples |
|---|---|---|
| Color | `--kolabing-color-*` | `-primary` `-on-primary` `-app-background` `-surface` `-surface-container` `-on-surface` `-on-surface-variant` `-outline-variant` `-hairline` `-divider` `-muted` `-secondary` `-tertiary` `-error` |
| Spacing | `--kolabing-space-*` | `-xxs` (4) `-xs` (8) `-sm` (12) `-md` (16) `-lg` (24) `-xl` (32) `-margin-mobile` (20) |
| Radius | `--kolabing-radius-*` | `-sm` (8) `-md` (12) `-card` (24) `-input` (16) `-pill` (9999) |
| Size | `--kolabing-size-*` | `-button-height` (56) `-min-touch-target` (48) `-icon-size` (24) `-max-content-width` (600) |
| Shadow | `--kolabing-shadow-*` | `-card` `-button` `-ambient` `-bottom-nav` |
| Duration | `--kolabing-duration-*` | `-default` (300ms) `-modal` (250ms) `-tab` (200ms) `-quick` (100ms) `-shimmer` (1500ms) |
| Easing | `--kolabing-ease-*` | `-default` `-modal` — those two only |
| Font | `--kolabing-font-*` | `-display` (Anton) `-body` (Inter) |

For text, **use the ready-made classes** rather than reassembling font properties:
`.kolabing-display-title` · `.kolabing-section-heading-large` · `.kolabing-card-title-large`
· `.kolabing-body-lg` · `.kolabing-body-md` · `.kolabing-body-sm` · `.kolabing-label-large`
· `.kolabing-button` · `.kolabing-meta-label` · `.kolabing-name-bold` · `.kolabing-chip-label`

## Brand rules that are easy to get wrong

- **Anton is the display face and is always uppercase.** The `.kolabing-*` display
  classes already apply `text-transform: uppercase` — don't fight it, and don't set
  Anton on body copy. Everything that isn't a headline is Inter.
- **Yellow (`--kolabing-color-primary`) always takes dark ink on top** —
  `--kolabing-color-on-primary`. White text on the yellow CTA is wrong and unreadable.
- **The page is warm parchment, not white.** `--kolabing-color-app-background` is the
  page; `--kolabing-color-surface` is a card sitting on it.
- **Elevation is minimal by design.** Cards use a 1px `--kolabing-color-outline-variant`
  border and at most `--kolabing-shadow-card`. Buttons are flat. There are no glows.
- **Touch targets are ≥ `--kolabing-size-min-touch-target`** (48px). `styles.css`
  already enforces this on `button`.

## Where the truth lives

Read the real files before styling — they beat this summary:
`styles.css` (entry point) → `tokens/color.css`, `tokens/typography.css`,
`tokens/space.css`, `tokens/radius.css`, `tokens/size.css`, `tokens/shadow.css`,
`tokens/motion.css`. The `components/Foundations/` cards render every color swatch,
text style and scale step live.

## Idiomatic snippet

```html
<article class="k-card">
  <p class="kolabing-meta-label">SPONSORSHIP</p>
  <h3 class="kolabing-card-title-large">Summer run series</h3>
  <p class="kolabing-body-md">Real Run Club · Barcelona</p>
  <button class="k-cta kolabing-button">Apply now</button>
</article>

<style>
  .k-card {
    background: var(--kolabing-color-surface);
    border: 1px solid var(--kolabing-color-outline-variant);
    border-radius: var(--kolabing-radius-card);
    box-shadow: var(--kolabing-shadow-card);
    padding: var(--kolabing-space-md);
    display: grid;
    gap: var(--kolabing-space-xs);
  }
  .k-card .kolabing-body-md { color: var(--kolabing-color-on-surface-variant); }
  .k-cta {
    margin-top: var(--kolabing-space-sm);
    height: var(--kolabing-size-button-height);
    border: none;
    border-radius: var(--kolabing-radius-pill);
    background: var(--kolabing-color-primary);
    color: var(--kolabing-color-on-primary);
    transition: opacity var(--kolabing-duration-quick) var(--kolabing-ease-default);
  }
</style>
```


---

# Token index

Generated from the Flutter sources by `scripts/design_tokens_to_css.py`.
Everything below is reachable from `styles.css`'s `@import` closure.

| Group | Count | File |
|---|---|---|
| Colors | 92 (87 redefined in dark) | `tokens/color.css` |
| Text styles | 35 (28 current, 7 deprecated) | `tokens/typography.css` |
| Spacing | 11 | `tokens/space.css` |
| Radii | 12 | `tokens/radius.css` |
| Component sizes | 14 | `tokens/size.css` |
| Shadows | 7 | `tokens/shadow.css` |
| Durations | 5 | `tokens/motion.css` |

## Spacing

`--kolabing-space-gutter` · `--kolabing-space-lg` · `--kolabing-space-margin-mobile` · `--kolabing-space-md` · `--kolabing-space-sm` · `--kolabing-space-xl` · `--kolabing-space-xs` · `--kolabing-space-xxl` · `--kolabing-space-xxs` · `--kolabing-space-xxxl` · `--kolabing-space-xxxs`

## Radius

`--kolabing-radius-card` · `--kolabing-radius-input` · `--kolabing-radius-lg` · `--kolabing-radius-md` · `--kolabing-radius-option-card` · `--kolabing-radius-pill` · `--kolabing-radius-round` · `--kolabing-radius-sm` · `--kolabing-radius-thumbnail` · `--kolabing-radius-xl` · `--kolabing-radius-xs` · `--kolabing-radius-xxl`

## Component sizes

`--kolabing-size-bottom-nav-height` · `--kolabing-size-bottom-nav-icon-size` · `--kolabing-size-bottom-safe-area` · `--kolabing-size-button-height` · `--kolabing-size-button-height-secondary` · `--kolabing-size-grid-spacing` · `--kolabing-size-icon-size` · `--kolabing-size-icon-size-large` · `--kolabing-size-icon-size-small` · `--kolabing-size-input-height-dark` · `--kolabing-size-input-height-light` · `--kolabing-size-list-item-spacing` · `--kolabing-size-max-content-width` · `--kolabing-size-min-touch-target`

## Shadows

`--kolabing-shadow-ambient` · `--kolabing-shadow-bottom-nav` · `--kolabing-shadow-button` · `--kolabing-shadow-button-secondary` · `--kolabing-shadow-card` · `--kolabing-shadow-card-hover` · `--kolabing-shadow-focus-ring`

## Text classes

`.kolabing-body-large` · `.kolabing-body-lg` · `.kolabing-body-md` · `.kolabing-body-medium` · `.kolabing-body-sm` · `.kolabing-body-small` · `.kolabing-button` · `.kolabing-button-label-lg` · `.kolabing-button-label-md` · `.kolabing-caption-secondary` · `.kolabing-card-title-hero` · `.kolabing-card-title-large` · `.kolabing-chip-label` · `.kolabing-display-large` · `.kolabing-display-medium` · `.kolabing-display-small` · `.kolabing-display-title` · `.kolabing-eyebrow` · `.kolabing-headline-large` · `.kolabing-headline-medium` · `.kolabing-label-large` · `.kolabing-label-medium` · `.kolabing-label-small` · `.kolabing-meta-label` · `.kolabing-name-bold` · `.kolabing-section-heading-large` · `.kolabing-title-large` · `.kolabing-title-medium`

Deprecated (present for fidelity, do not use in new work):
`.kolabing-button-small` · `.kolabing-chip-label-medium` · `.kolabing-chip-label-small` · `.kolabing-headline-small` · `.kolabing-page-title` · `.kolabing-page-title-small` · `.kolabing-title-small`

## Colors

Read `tokens/color.css` for the full list with values. Names:

`--kolabing-color-accent-orange` · `--kolabing-color-accent-orange-text` · `--kolabing-color-active-bg` · `--kolabing-color-active-text` · `--kolabing-color-amber` · `--kolabing-color-amber-chip-container` · `--kolabing-color-amber-chip-text` · `--kolabing-color-app-background` · `--kolabing-color-background` · `--kolabing-color-border-error` · `--kolabing-color-border-focus` · `--kolabing-color-category-blue-bg` · `--kolabing-color-category-blue-text` · `--kolabing-color-category-lavender-bg` · `--kolabing-color-category-lavender-text` · `--kolabing-color-category-location-bg` · `--kolabing-color-category-location-text` · `--kolabing-color-category-mint-bg` · `--kolabing-color-category-mint-text` · `--kolabing-color-category-orange-bg` · `--kolabing-color-category-orange-text` · `--kolabing-color-category-red-bg` · `--kolabing-color-category-red-text` · `--kolabing-color-category-sage-bg` · `--kolabing-color-category-sage-text` · `--kolabing-color-charcoal` · `--kolabing-color-completed-bg` · `--kolabing-color-completed-text` · `--kolabing-color-control-border` · `--kolabing-color-dark-border` · `--kolabing-color-dark-surface` · `--kolabing-color-divider` · `--kolabing-color-error` · `--kolabing-color-error-bg` · `--kolabing-color-error-text` · `--kolabing-color-glass-destructive-ink` · `--kolabing-color-glass-ink` · `--kolabing-color-glass-white14` · `--kolabing-color-hairline` · `--kolabing-color-icon-stroke` · `--kolabing-color-info` · `--kolabing-color-ink` · `--kolabing-color-ink-body` · `--kolabing-color-inverse-on-surface` · `--kolabing-color-inverse-surface` · `--kolabing-color-muted` · `--kolabing-color-muted-filter` · `--kolabing-color-nav-bar-background` · `--kolabing-color-nav-inactive` · `--kolabing-color-nav-inactive-subtle` · `--kolabing-color-on-accent` · `--kolabing-color-on-primary` · `--kolabing-color-on-secondary` · `--kolabing-color-on-surface` · `--kolabing-color-on-surface-variant` · `--kolabing-color-orange` · `--kolabing-color-orange-tint` · `--kolabing-color-outline` · `--kolabing-color-outline-variant` · `--kolabing-color-overlay-dark30` · `--kolabing-color-overlay-dark50` · `--kolabing-color-overlay-dark60` · `--kolabing-color-pastel-yellow-bg` · `--kolabing-color-pastel-yellow-border` · `--kolabing-color-pending-bg` · `--kolabing-color-pending-text` · `--kolabing-color-pill-pressed-fill` · `--kolabing-color-primary` · `--kolabing-color-primary-dark` · `--kolabing-color-primary-gradient` · `--kolabing-color-primary-tint` · `--kolabing-color-secondary` · `--kolabing-color-secondary-container` · `--kolabing-color-soft-accent` · `--kolabing-color-soft-yellow` · `--kolabing-color-soft-yellow-border` · `--kolabing-color-success` · `--kolabing-color-surface` · `--kolabing-color-surface-container` · `--kolabing-color-surface-container-high` · `--kolabing-color-surface-container-low` · `--kolabing-color-surface-variant` · `--kolabing-color-tertiary` · `--kolabing-color-tertiary-container` · `--kolabing-color-text-on-dark` · `--kolabing-color-text-tertiary` · `--kolabing-color-title-ink` · `--kolabing-color-warning` · `--kolabing-color-xp-green` · `--kolabing-color-xp-green-container` · `--kolabing-color-xp-green-on-container` · `--kolabing-color-yellow-tint`
