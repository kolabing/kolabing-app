# design-sync notes

Running record for `/design-sync` on this repo. Read before re-syncing.

## This repo is outside the converter's envelope

Kolabing's design system is **Flutter/Dart**. Claude Design renders compiled
**React** (`_ds_bundle.js` exposing components on `window.<globalName>.*`), so the
standard `/design-sync` converter cannot run here — there is no `dist/` to bundle
and no component can be shipped. Do not try to make `package-build.mjs` work.

What we ship instead is a **token-only** bundle produced by
`scripts/design_tokens_to_css.py`. No components, no `_ds_bundle.js`.

`_ds_sync.json` is deliberately **omitted**: the anchor's hash recipe is defined for
the storybook/package shapes and there is no honest way to compute it for a
hand-authored layout. Consequence, accepted: every re-sync re-verifies from scratch.

## Two design systems now live in the project

The project (`97e56a75-16a3-4edf-98fb-9570e659eab4`) was **not empty** when created
— it came pre-seeded with a real, well-authored **Kolabing marketing-web** design
system (`--kb-*`, derived from the Laravel repo's Blade templates). Decision
(Volkan, 2026-08-17): **keep both, clearly separated.**

- Mobile app → `--kolabing-*`, `styles.css`, `components/Foundations/*`
- Marketing web → `--kb-*`, `styles.marketing.css`, `guidelines/*.md`, `_preview/*`

`guidelines/00-SCOPE.md` (ours) is the file that tells the design agent which is
which. Keep it accurate.

### Damage done on the first upload — do not repeat

The first upload assumed a freshly-created project is empty and overwrote the
marketing system's `styles.css`, `README.md`, `fonts/fonts.css` and
`tokens/{color,typography,space,radius,size,shadow,motion}.css`. **These are not
recoverable from here.** The marketing system's authoritative sources survived
(`tokens/palette.css`, `tokens/fonts.css`, `tokens/layout.css`, all four
`guidelines/*.md`, all `fonts/*.woff2`), and `styles.marketing.css` was added to
give it a working entry point again.

**Before any future upload: `list_files` first and diff, even on a project you just
created.** Never assume empty.

## Findings in the Flutter sources

- `typography.dart` sets `color: Color(0xFF857E70)` on every Anton style, but
  `theme.dart` `_buildTextTheme` (lines ~484-502) overwrites it with `onSurface`
  on every single style. Those literals are **dead** — never rendered. The
  generator deliberately drops them; text inherits `--kolabing-color-on-surface`.
  Worth deleting from the Dart source at some point.
- 7 text styles carry `/// @deprecated`. They are emitted for fidelity but marked
  `DEPRECATED` in `tokens/typography.css` and excluded from the Typography card
  and the conventions doc.
- `colors.dart` (`KolabingColors`) is the legacy static palette; `color_tokens.dart`
  (`KolabingColorTokens.light` / `.night`) is the runtime one and is what the
  generator reads — it is the only source with a dark set.

## Environment gotchas

- The system Python has **no CA bundle** — `urllib` fails with
  `CERTIFICATE_VERIFY_FAILED`. The font fetcher shells out to `curl` instead.
- The Chrome extension for `claude-in-chrome` was not connected. Render
  verification runs headless through the Puppeteer already vendored at
  `instagram-stories/node_modules/puppeteer` (see the verify script in the PR
  description). Six checks: 3 cards × light/dark, asserting fonts actually load,
  tokens resolve, and the night palette swaps.
- Fonts are **base64-embedded** into `fonts/fonts.css`. A published page runs under
  a strict CSP that blocks `fonts.gstatic.com`, so a `<link>` would silently fall
  back. The marketing half instead references sibling `fonts/*.woff2` by relative
  URL (`tokens/fonts.css`) — that pattern was already in the project and is fine
  because it is same-origin.

## Refresh procedure

```bash
python3 scripts/design_tokens_to_css.py                 # regenerate ds-bundle/
python3 scripts/design_tokens_to_css.py --fetch-fonts   # + re-vendor fonts (needs network)
```

`ds-bundle/` is gitignored — it is generated. Hand-authored bundle files live in
`.design-sync/overlay/` and are copied in by the generator.

This is a **one-way** copy. It drifts whenever the Dart tokens change and nobody
re-runs the generator.
