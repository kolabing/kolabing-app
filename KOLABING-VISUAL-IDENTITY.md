# Kolabing — Visual Identity & Logo Design Brief
### For use with Gemini Image Generation

---

## About Kolabing

**What it is:** A collaboration marketplace mobile app (iOS & Android) that connects **businesses** with **communities** for partnership and sponsorship opportunities.

**The name:** "Kolabing" = Collaboration + the suffix "-ing" (action-oriented, ongoing, dynamic). It implies movement, growth, and active partnership.

**Core idea:** Two worlds meeting — the structured world of business and the organic world of community. Neither one dominates; together they create something new.

**Target audience:**
- **Businesses:** Brands, SMBs, startups seeking authentic community reach and local partnerships
- **Community leaders:** Neighborhood groups, creators, collectives, nonprofits seeking sponsorships and business support
- **Age range:** Primarily 25–45 years old
- **Tone:** Modern, optimistic, energetic but trustworthy

---

## Design System Reference

| Token | Value | Notes |
|---|---|---|
| Primary Yellow | `#FFD861` | Main brand color — vibrant, warm, energetic |
| Background Light | `#F7F8FA` | Clean, airy feel |
| Dark Background | `#000000` | Used in auth screens — creates contrast |
| Near-Black Surface | `#0a0a0e` | Used behind glow elements — richer than pure black |
| Dark Card Surface | `#111118` | Secondary dark surface for cards and sections |
| Text Primary | `#232323` | Near-black, not pure black |
| Success Green | `#7AE7A3` | Growth, partnership |
| Error Red | `#E14D76` | Alert states only |
| Headline Font | Rubik (bold, uppercase) | Strong, geometric, modern |
| Body Font | Open Sans | Readable, neutral |
| Label Font | Darker Grotesque (uppercase) | Character, informal but clear |

**Key design rules from the app:**
- Yellow always pairs with black text (never white on yellow)
- Cards use 16dp radius → rounded, friendly
- Buttons: 52dp height, 12dp radius → solid, tappable
- Animations: 300ms default — smooth but snappy
- Glow effects are exclusively yellow (#FFD861) on dark surfaces — see Glow System section

---

## Brand Personality

| Trait | Description |
|---|---|
| Energetic | Things happen here. Movement, action, growth. |
| Inclusive | Both sides of the equation matter equally |
| Modern | Clean, digital-native, minimal |
| Trustworthy | Reliable enough for business, welcoming for community |
| Optimistic | Partnership creates more than either party could alone |

**NOT:** Corporate, cold, aggressive, overly playful, or cluttered.

---

## Logo System

### Current Logo Assets

The Kolabing logo exists in two primary forms:

**K Lettermark** — the app icon and social profile avatar. A standalone K lettermark on a black square background (`#0a0a0e`), rendered in yellow (`#FFD861`) with the neon glow treatment (see Glow System). The K is constructed as two distinct puzzle-piece paths — a deliberate collaboration metaphor. Use for: app icons, social profile images, favicon.

**Square Wordmark** — "KOLABING" centered in Rubik 900, yellow on black, with neon glow and animated pulse. The canonical banner/header asset. Use for: social posts, app store feature graphic, website headers, splash screen wordmark. Source file: `kolabing-logo-square.html`.

### Logo Usage Rules

| Format | Use for | Glow level |
|---|---|---|
| K lettermark | App icon, social avatar, favicon | Intense (on black bg) |
| Square wordmark | Social posts, banners, splash screen | Default (animated) |
| Wordmark in nav/header | Website nav, app top bar | Soft (static) |
| Monochrome wordmark | Print, embossing, one-color contexts | None |

---

## Glow System

The neon glow is Kolabing's primary visual signature on dark backgrounds. It turns the brand's yellow into something that feels alive — premium, energetic, and immediately recognizable. It is used across the website hero, app splash screen, social media content, and the App Store feature graphic.

### The Rule

> Glow is exclusively **yellow (#FFD861) on dark backgrounds**. It appears on the **wordmark and headlines only** — never on body text, UI labels, or filled button backgrounds.

### Four Glow Levels

| Level | CSS Variable | Use case |
|---|---|---|
| **Soft** | `--glow-soft` | Nav wordmark, section eyebrow labels, app screen subtitles, email header |
| **Default** | `--glow-default` | Website H1, social post wordmark, app onboarding headlines, square logo |
| **Intense** | `--glow-intense` | App splash screen K, App Store feature graphic, full-screen social covers |
| **Icon** | `--glow-icon` | Standalone K lettermark at any size |

### Ambient Background

Every glowing text block should sit in front of a **radial ambient halo** — a soft yellow radial gradient in the background that grounds the effect and makes it feel dimensional rather than floating.

```css
--glow-ambient: radial-gradient(ellipse at center, rgba(255,216,97,0.18) 0%, transparent 70%);
--glow-ambient-intense: radial-gradient(ellipse at center, rgba(255,216,97,0.28) 0%, transparent 65%);
```

### Animation

For animated contexts (website hero, social video/GIF, app splash), use the **text-pulse** keyframe — a slow 3s oscillation between Default and Intense that creates life without distraction.

```css
@keyframes text-pulse {
  0%, 100% { text-shadow: var(--glow-default); }
  50%       { text-shadow: var(--glow-intense); }
}
/* Usage: animation: text-pulse 3s ease-in-out infinite; */
```

### Copy-Ready CSS Variables

Paste into any website stylesheet or design token file:

```css
:root {
  --yellow: #FFD861;

  /* Soft: nav logo, labels, eyebrows */
  --glow-soft:
    0 0 6px rgba(255,216,97,0.7),
    0 0 16px rgba(255,216,97,0.4),
    0 0 35px rgba(255,216,97,0.2);

  /* Default: wordmark, hero headlines, section titles */
  --glow-default:
    0 0 10px rgba(255,216,97,0.95),
    0 0 25px rgba(255,216,97,0.75),
    0 0 55px rgba(255,216,97,0.45),
    0 0 100px rgba(255,216,97,0.22),
    0 0 160px rgba(255,216,97,0.1);

  /* Intense: splash screen, App Store graphic, social covers */
  --glow-intense:
    0 0 16px rgba(255,216,97,1),
    0 0 40px rgba(255,216,97,0.9),
    0 0 90px rgba(255,216,97,0.65),
    0 0 160px rgba(255,216,97,0.38),
    0 0 240px rgba(255,216,97,0.18);

  /* Icon: standalone K lettermark */
  --glow-icon:
    0 0 8px rgba(255,216,97,0.9),
    0 0 20px rgba(255,216,97,0.6),
    0 0 45px rgba(255,216,97,0.3);

  /* Ambient background radial halo */
  --glow-ambient: radial-gradient(ellipse at center, rgba(255,216,97,0.18) 0%, transparent 70%);
  --glow-ambient-intense: radial-gradient(ellipse at center, rgba(255,216,97,0.28) 0%, transparent 65%);
}
```

**Flutter equivalent (Dart) — BoxShadow for Text or Container:**
```dart
// Default glow
shadows: [
  Shadow(color: Color(0xF2FFD861), blurRadius: 10),
  Shadow(color: Color(0xBFFFD861), blurRadius: 25),
  Shadow(color: Color(0x73FFD861), blurRadius: 55),
  Shadow(color: Color(0x38FFD861), blurRadius: 100),
]
// Intense glow
shadows: [
  Shadow(color: Color(0xFFFFD861), blurRadius: 16),
  Shadow(color: Color(0xE6FFD861), blurRadius: 40),
  Shadow(color: Color(0xA6FFD861), blurRadius: 90),
  Shadow(color: Color(0x61FFD861), blurRadius: 160),
]
```

### Application Map

| Touchpoint | Element | Glow level | Animated |
|---|---|---|---|
| Website — nav | KOLABING wordmark | Soft | No |
| Website — hero H1 | Headline text | Default | Yes — text-pulse |
| Website — section eyebrows | Small label text | Soft | No |
| App — splash screen | K lettermark | Intense | Yes — text-pulse |
| App — splash screen | KOLABING wordmark below K | Soft | No |
| App — onboarding screens | Screen headline | Default | No |
| App — home top bar | KOLABING nav logo | Soft | No |
| Social — square post (1:1) | Full wordmark | Default | Yes (export as video/GIF) |
| Social — story (9:16) | Headline copy | Default | Yes (export as video) |
| Social — profile avatar | K on yellow circle | None — flat | No |
| App Store — feature graphic | KOLABING hero text | Intense | No (static image) |
| Email header | KOLABING wordmark | Soft | No (not supported in email clients) |

### Do & Don't

**Do:**
- Use glow only on dark backgrounds — `#000`, `#0a0a0e`, `#111118`
- Add the ambient radial background behind every glowing text block
- Use Rubik 900 for all glowing text — weight is integral to the effect reading correctly
- Animate with text-pulse (3s ease-in-out infinite) on hero and social contexts
- Keep intense glow to full-screen, full-bleed moments only

**Don't:**
- Never use glow on light (`#F7F8FA`) or yellow backgrounds — it disappears or looks muddy
- Never apply glow to body copy, subheadings, or UI form labels
- Never use intense glow inline within a layout — it belongs on splash/cover contexts only
- Never apply glow to white text — yellow only
- Never add glow to the CTA button fill — the yellow button is flat; glow lives on text, not fills
- Never use the social profile avatar (K on yellow) with glow — that format is flat by design

---

## Logo Design Prompts for Gemini

Use the following prompts. Experiment with multiple variations.

---

### PROMPT 1 — Primary Wordmark Logo

```
Design a modern minimalist wordmark logo for an app called "Kolabing".
The name should be set in a bold geometric sans-serif typeface similar to Rubik or Nunito.
Use vibrant yellow (#FFD861) as the primary color on a black background.
The "K" or the letters "lab" could be subtly highlighted or stylized to hint at
collaboration and connection. Clean, tech-forward, mobile-first aesthetic.
No gradients, no shadows. Flat design. The logo should work at small sizes on a phone screen.
White version on black background. High contrast. Startup feel, not corporate.
```

---

### PROMPT 2 — Icon / App Icon (Symbol only)

```
Design an app icon for a collaboration marketplace called "Kolabing".
The symbol should abstractly represent two entities connecting or coming together —
like two puzzle pieces, two overlapping shapes, two paths merging, or a handshake
abstracted into geometric form.
Colors: vibrant yellow (#FFD861) as dominant, with black and white accents.
Style: flat, geometric, minimal, rounded corners (16px radius).
Should work as a standalone symbol without text.
Suitable for iOS and Android app store icon — square format with rounded corners.
Modern, bold, clean. No gradients.
```

---

### PROMPT 3 — Logo with Symbol + Wordmark (Horizontal)

```
Design a horizontal combination logo for "Kolabing" — a business-community
collaboration marketplace app.
Left side: a compact geometric symbol representing connection or bridge between
two parties (abstract, minimal).
Right side: the wordmark "Kolabing" in bold geometric sans-serif.
Color palette: black background, yellow (#FFD861) as primary accent, white text.
Flat design, no gradients, no shadows. Modern startup aesthetic.
The symbol and wordmark should feel like they belong together — same visual weight,
same design language.
```

---

### PROMPT 4 — Logo Exploring the "K" Lettermark

```
Design a bold lettermark logo using the letter "K" for an app called "Kolabing".
The "K" should incorporate a visual metaphor of two sides coming together —
for example, the two diagonal arms of the K pointing toward a central connection point,
or the K constructed from two interlocking shapes.
Colors: yellow (#FFD861) and black.
Style: geometric, flat, strong, minimal.
The result should feel like a modern tech brand — think Notion, Linear, Figma-level
design quality. Clean and memorable at 32x32px or smaller.
```

---

### PROMPT 5 — Dark Theme Hero Visual (App Store / Social Banner)

```
Create a dark-themed hero banner for a mobile app called "Kolabing".
Background: near-black (#0a0a0e).
Typography: "Kolabing" in large, bold uppercase Rubik-style font in yellow (#FFD861),
with a soft neon glow radiating from the letters.
Subtitle text below: "Where Businesses Meet Communities" in white, smaller weight.
Visual elements: abstract geometric shapes suggesting connection, bridge, or network —
floating soft yellow and green (#7AE7A3) geometric forms, minimal and airy.
Bottom half: faint phone mockup outline or abstract UI elements.
Overall mood: premium, modern, energetic. Suitable for App Store feature graphic
(2560x1440px landscape). Flat design, no photorealism.
```

---

### PROMPT 6 — Light Theme Marketing Visual

```
Design a clean, light-themed promotional graphic for "Kolabing" —
a collaboration marketplace connecting businesses and communities.
Background: light gray (#F7F8FA).
Headline: "Kolabing" in bold uppercase black text.
Tagline: "Collaborate. Grow. Together."
Color accents: yellow (#FFD861) shapes and lines.
Include two abstract illustrated figures or shapes representing a business entity
and a community entity, facing each other, with a visual bridge or connection
between them. Modern flat illustration style, minimal linework.
Clean, friendly, professional. Not clipart — closer to Stripe or Notion marketing style.
```

---

### PROMPT 7 — Monochrome / Single Color Version

```
Design a single-color version of the Kolabing logo — wordmark only —
in pure white on a black background, and pure black on a white background.
The wordmark "Kolabing" in a bold geometric sans-serif, optionally with a
simple connecting symbol integrated into the letterforms.
No color, no gradients. Should be used for embossing, watermarks,
one-color print applications. Clean, strong, timeless.
```

---

### PROMPT 8 — Social Media Profile Icon

```
Create a circular social media profile icon for "Kolabing".
Circle with yellow (#FFD861) background.
Centered bold letter "K" or a minimal two-shape connection symbol in black.
Flat, no gradients, no shadow. Crisp at 400x400px and still readable at 50x50px.
Modern, startup-style social avatar. Think the simplicity of Notion's icon or
Linear's icon — geometric, memorable, instantly recognizable.
Note: this format is intentionally flat — no glow effect on the yellow background.
```

---

### PROMPT 9 — Neon Glow Dark Social Cover

```
Create a dark-themed social media cover image for "Kolabing".
Background: near-black (#0a0a0e).
Center: the wordmark "KOLABING" in Rubik Black, uppercase, in yellow (#FFD861)
with a multi-layer neon glow effect radiating outward from the letters.
Behind the text: a soft radial elliptical halo in yellow, fading to transparent —
gives the glow a sense of ambient light sourcing.
No other decorative elements — the glow is the visual.
Mood: electric, premium, alive. Like a neon sign in a dark room.
Suitable for: Instagram post (1:1), Twitter/X header, LinkedIn banner.
```

---

## Visual Moodboard Direction

When exploring options, aim for references in this space:

- **Industry:** Collaboration tools, community platforms, marketplace apps
- **Visual peers:** Notion (minimal, geometric), Bumble (bold yellow brand), Luma (dark premium), Linear (precise, clean)
- **NOT:** Fiverr's busyness, Craigslist's rawness, Facebook's corporate blue, overly illustrated fintech brands
- **Feel:** Like something a 30-year-old business founder AND a 28-year-old community organizer would both trust and enjoy using

---

## Quick Reference for Any Prompt

Always include these elements as needed:

| Element | Spec |
|---|---|
| Primary color | `#FFD861` (warm yellow) |
| Dark color | `#000000` / `#0a0a0e` (pure black / near-black for glow contexts) |
| Light BG | `#F7F8FA` |
| Accent green | `#7AE7A3` |
| Font style | Bold geometric sans-serif (Rubik-like) |
| Style | Flat, no gradients, minimal — except glow treatment on dark BG |
| Corners | Rounded (16dp equivalent) |
| Feeling | Energetic, trustworthy, modern |
| Avoid | Gradients (except ambient glow), photorealism, corporate stock imagery, excessive color |

---

## Tagline Options (include in prompts as needed)

- "Where Businesses Meet Communities"
- "Collaborate. Grow. Together."
- "Partnership, Activated."
- "Build Together."
- "The Collaboration Marketplace."
