# ⚠️ Read this first — two design systems live in this project

Kolabing ships two products with different visual languages. Both are here. They
are **not** two themes of one system and must not be blended.

| | **Mobile app** | **Marketing web** |
|---|---|---|
| Namespace | `--kolabing-*` | `--kb-*` |
| Entry point | `styles.css` | `styles.marketing.css` |
| Token files | `tokens/color.css`, `typography.css`, `space.css`, `radius.css`, `size.css`, `shadow.css`, `motion.css` | `tokens/palette.css`, `tokens/fonts.css`, `tokens/layout.css` |
| Docs | `README.md` | the other files in this folder |
| Cards | `components/Foundations/*` | `_preview/*` |
| Source | Flutter `lib/config/theme/` in `kolabing/kolabing-app` | Blade templates in the Laravel repo |

**The other files in this folder — `brand.md`, `color.md`, `components.md`,
`typography.md` — describe the MARKETING system only.** They were written before
the mobile-app tokens were added here, so where they say "Kolabing" without
qualification, read "Kolabing marketing web". Their rules do not govern app designs.

## The disagreements are real, not bugs

Each side is correct for its own product. Do not "fix" one to match the other:

| | Mobile app | Marketing web |
|---|---|---|
| Primary CTA | yellow ground, dark ink | **dark ground, yellow text** |
| Dark theme | full night palette (87 tokens) | none — dark *bands* on a light page |
| Page ground | warm parchment `#faf5ea` | white / cool tint `#f7f8fa` |
| Yellow | `#ffe28c`, used as CTA fill | `#ffe28c`, accent only — never a fill |
| Corners | cards 24 · inputs 16 · pills for chips | everything pill (`999px`) |
| Extra fonts | — | Caveat, DM Sans, Montserrat, Playfair Display |

## Which to use

If the request names a product, follow it. If it describes a phone screen, a
Kolab/collaboration flow, or anything a business or community user does inside the
app → **mobile app**. If it describes a landing page, pricing page, or public
marketing surface → **marketing web**. If it is genuinely ambiguous, ask.

## Known gap

When the mobile-app tokens were synced into this project, the marketing system's
own `tokens/color.css`, `typography.css`, `space.css`, `radius.css`, `size.css`,
`shadow.css`, `motion.css`, plus its `styles.css` and `README.md`, were overwritten
by the app equivalents. The marketing system's authoritative sources —
`tokens/palette.css`, `tokens/fonts.css`, `tokens/layout.css` and the guideline
docs — all survived, and `styles.marketing.css` was added to give it a working
entry point again. If you need the overwritten marketing token files back,
re-derive them from the Laravel repo's Blade templates; do not invent values.
