#!/usr/bin/env python3
"""Generate a Claude Design token bundle from Kolabing's Dart design tokens.

Kolabing's design system is Flutter/Dart. Claude Design (claude.ai/design) renders
compiled React, so the standard `/design-sync` converter does not apply to this
repo — there is no `dist/` to bundle. This script instead emits a *token-only*
bundle: the design language (colors, type, spacing, radius, shadow, motion) as CSS
custom properties, so mockups built in Claude Design land on-brand.

Every value is parsed out of the Dart sources — nothing is transcribed by hand, so
values cannot drift by typo. Re-run this after changing anything under
`lib/config/theme/` or `lib/config/constants/`.

    python3 scripts/design_tokens_to_css.py                 # regenerate ds-bundle/
    python3 scripts/design_tokens_to_css.py --fetch-fonts   # + refresh vendored fonts (needs network)

Fonts are vendored into `.design-sync/fonts/` and base64-embedded into the output,
because a published Artifact runs under a strict CSP that blocks external hosts —
a Google Fonts <link> would silently render in a fallback face.
"""

from __future__ import annotations

import argparse
import base64
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OUT = REPO / "ds-bundle"
FONT_SRC = REPO / ".design-sync" / "fonts"

THEME = REPO / "lib" / "config" / "theme"
CONST = REPO / "lib" / "config" / "constants"

PREFIX = "--kolabing"


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #

def kebab(name: str) -> str:
    """camelCase -> kebab-case."""
    return re.sub(r"(?<!^)(?=[A-Z])", "-", name).lower()


def argb_to_css(hex8: str) -> str:
    """0xAARRGGBB -> #rrggbb, or rgba(...) when not fully opaque."""
    v = int(hex8, 16)
    a, r, g, b = (v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF
    if a == 0xFF:
        return f"#{r:02x}{g:02x}{b:02x}"
    return f"rgba({r}, {g}, {b}, {round(a / 255, 4)})"


def num(value: str) -> float:
    """Evaluate the tiny arithmetic Flutter token files use: '90 / 80', '0.02 * 64', '-0.2'."""
    expr = value.strip()
    if not re.fullmatch(r"[-+*/(). 0-9]+", expr):
        raise ValueError(f"refusing to evaluate {expr!r}")
    return float(eval(expr, {"__builtins__": {}}, {}))  # noqa: S307 - guarded by the regex above


def fmt(n: float) -> str:
    """Trim trailing zeros so 16.0 -> 16 and 1.5556 stays 1.5556."""
    s = f"{n:.4f}".rstrip("0").rstrip(".")
    return s or "0"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def block(src: str, opener: str) -> str:
    """Return the text between `opener` and its matching close paren."""
    start = src.index(opener) + len(opener)
    depth = 1
    i = start
    while depth:
        if src[i] == "(":
            depth += 1
        elif src[i] == ")":
            depth -= 1
        i += 1
    return src[start : i - 1]


# --------------------------------------------------------------------------- #
# parsers
# --------------------------------------------------------------------------- #

def parse_color_set(src: str, setname: str) -> dict[str, str]:
    """Pull `name: Color(0x........)` pairs out of one KolabingColorTokens set."""
    body = block(src, f"static const KolabingColorTokens {setname} = KolabingColorTokens(")
    out: dict[str, str] = {}
    for name, hex8 in re.findall(r"(\w+):\s*Color\(0x([0-9A-Fa-f]{8})\)", body):
        out[name] = argb_to_css(hex8)
    # primaryGradient is a LinearGradient(topLeft -> bottomRight) == 135deg in CSS.
    grad = re.search(r"primaryGradient:\s*LinearGradient\((.*?)\),\s*\n", body, re.S)
    if grad:
        stops = re.findall(r"Color\(0x([0-9A-Fa-f]{8})\)", grad.group(1))
        if stops:
            out["primaryGradient"] = "linear-gradient(135deg, " + ", ".join(argb_to_css(s) for s in stops) + ")"
    return out


def parse_class_doubles(src: str, cls: str) -> dict[str, float]:
    """`static const double name = 12;` inside `abstract final class <cls>`."""
    m = re.search(rf"abstract final class {cls} \{{(.*?)\n\}}", src, re.S)
    if not m:
        return {}
    return {
        name: num(val)
        for name, val in re.findall(r"static const double (\w+)\s*=\s*([-0-9.]+);", m.group(1))
    }


def parse_durations(src: str, cls: str) -> dict[str, int]:
    m = re.search(rf"abstract final class {cls} \{{(.*?)\n\}}", src, re.S)
    if not m:
        return {}
    return {
        name: int(ms)
        for name, ms in re.findall(
            r"static const Duration (\w+)\s*=\s*Duration\(milliseconds:\s*(\d+)\)", m.group(1)
        )
    }


def parse_shadows(src: str) -> dict[str, str]:
    """`static const BoxShadow name = BoxShadow(color:, blurRadius:, offset:, spreadRadius:)`."""
    out: dict[str, str] = {}
    for name, body in re.findall(
        r"static const BoxShadow (\w+)\s*=\s*BoxShadow\((.*?)\);", src, re.S
    ):
        color = re.search(r"color:\s*Color\(0x([0-9A-Fa-f]{8})\)", body)
        blur = re.search(r"blurRadius:\s*([-0-9.]+)", body)
        spread = re.search(r"spreadRadius:\s*([-0-9.]+)", body)
        offset = re.search(r"offset:\s*Offset\(([-0-9.]+),\s*([-0-9.]+)\)", body)
        if not color:
            continue
        dx, dy = (offset.group(1), offset.group(2)) if offset else ("0", "0")
        parts = [f"{fmt(num(dx))}px", f"{fmt(num(dy))}px", f"{fmt(num(blur.group(1))) if blur else 0}px"]
        if spread and num(spread.group(1)) != 0:
            parts.append(f"{fmt(num(spread.group(1)))}px")
        rule = " ".join(parts) + " " + argb_to_css(color.group(1))
        # A fully transparent shadow is a Flutter "no-op" placeholder; CSS says `none`.
        out[name] = "none" if rule.endswith("rgba(0, 0, 0, 0.0)") else rule
    return out


def parse_text_styles(src: str) -> dict[str, dict]:
    """`static TextStyle get name => GoogleFonts.<family>(fontSize:, fontWeight:, height:, letterSpacing:)`.

    NOTE: the `color:` present on some styles is deliberately ignored. theme.dart's
    `_buildTextTheme` overwrites every style's color with `onSurface`, so those
    literals (#857E70) never reach a pixel. Emitting them would be a lie.
    """
    out: dict[str, dict] = {}
    for m in re.finditer(
        r"static TextStyle get (\w+) =>\s*GoogleFonts\.(\w+)\((.*?)\);", src, re.S
    ):
        name, family, body = m.group(1), m.group(2), m.group(3)
        # `/// @deprecated Use [x]` sits directly above the getter it retires.
        preamble = src[max(0, m.start() - 220) : m.start()]
        deprecated = "@deprecated" in preamble.rsplit("static TextStyle", 1)[-1]
        size = re.search(r"fontSize:\s*([-0-9.]+)", body)
        weight = re.search(r"fontWeight:\s*FontWeight\.w(\d+)", body)
        height = re.search(r"height:\s*([-0-9.\s/*]+?),", body)
        tracking = re.search(r"letterSpacing:\s*([-0-9.\s/*]+?),", body)
        if not size:
            continue
        out[name] = {
            "family": family,
            "size": num(size.group(1)),
            "weight": int(weight.group(1)) if weight else 400,
            "height": num(height.group(1)) if height else None,
            "tracking": num(tracking.group(1)) if tracking else None,
            "deprecated": deprecated,
        }
    return out


# --------------------------------------------------------------------------- #
# fonts
# --------------------------------------------------------------------------- #

GF_URL = (
    "https://fonts.googleapis.com/css2?family=Anton&family=Inter:wght@400..800&display=swap"
)
KEEP_SUBSETS = {"latin", "latin-ext"}  # en / es / ca all live here


#  Google Fonts serves a different CSS per User-Agent; this one gets woff2.
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0 Safari/537.36"


def _get(url: str) -> bytes:
    """Fetch over curl rather than urllib — the system Python here has no CA bundle."""
    import subprocess

    r = subprocess.run(
        ["curl", "-sSfL", "-A", UA, url], capture_output=True, check=False
    )
    if r.returncode != 0:
        print(f"!! fetch failed for {url}: {r.stderr.decode().strip()}", file=sys.stderr)
        sys.exit(1)
    return r.stdout


def fetch_fonts() -> None:
    """Vendor the Anton + Inter latin woff2 files into .design-sync/fonts/."""
    FONT_SRC.mkdir(parents=True, exist_ok=True)
    css = _get(GF_URL).decode("utf-8")

    faces = re.findall(r"/\* (\S+) \*/\s*@font-face \{(.*?)\}", css, re.S)
    manifest: list[str] = []
    for subset, body in faces:
        if subset not in KEEP_SUBSETS:
            continue
        fam = re.search(r"font-family:\s*'([^']+)'", body).group(1)
        weight = re.search(r"font-weight:\s*([\d ]+)", body).group(1).strip()
        url = re.search(r"url\((https://[^)]+\.woff2)\)", body).group(1)
        rng = re.search(r"unicode-range:\s*([^;]+);", body).group(1).strip()
        fname = f"{fam.lower()}-{subset}.woff2"
        data = _get(url)
        (FONT_SRC / fname).write_bytes(data)
        manifest.append(f"{fname}\t{fam}\t{weight}\t{rng}")
        print(f"  vendored {fname} ({len(data) / 1024:.1f} KB)")
    if not manifest:
        print("!! no latin @font-face blocks found — Google Fonts changed its CSS", file=sys.stderr)
        sys.exit(1)
    (FONT_SRC / "manifest.tsv").write_text("\n".join(manifest) + "\n", encoding="utf-8")


def build_fonts_css() -> str:
    """Emit @font-face rules with base64 data: URIs (CSP blocks external hosts)."""
    manifest = FONT_SRC / "manifest.tsv"
    if not manifest.exists():
        print(
            "!! .design-sync/fonts/manifest.tsv missing — run with --fetch-fonts once.",
            file=sys.stderr,
        )
        sys.exit(1)
    out = [
        "/* Kolabing web fonts — Anton (display) + Inter (body).",
        "   Base64-embedded on purpose: a published Artifact runs under a strict CSP",
        "   that blocks fonts.gstatic.com, so a <link> would fall back silently.",
        "   Source of truth: KolabingTypography in lib/config/theme/typography.dart. */",
        "",
    ]
    for line in manifest.read_text(encoding="utf-8").strip().splitlines():
        fname, fam, weight, rng = line.split("\t")
        b64 = base64.b64encode((FONT_SRC / fname).read_bytes()).decode("ascii")
        out += [
            "@font-face {",
            f"  font-family: '{fam}';",
            "  font-style: normal;",
            f"  font-weight: {weight};",
            "  font-display: swap;",
            f"  src: url(data:font/woff2;base64,{b64}) format('woff2');",
            f"  unicode-range: {rng};",
            "}",
            "",
        ]
    return "\n".join(out)


# --------------------------------------------------------------------------- #
# emitters
# --------------------------------------------------------------------------- #

def build_color_css(light: dict[str, str], night: dict[str, str]) -> str:
    def decls(tokens: dict[str, str], indent: str = "  ") -> str:
        return "\n".join(f"{indent}{PREFIX}-color-{kebab(k)}: {v};" for k, v in sorted(tokens.items()))

    # Only tokens that actually differ need redefining in the dark blocks.
    diff = {k: v for k, v in night.items() if light.get(k) != v}
    return f"""/* Kolabing colors — generated from lib/config/theme/color_tokens.dart.
   Light = KolabingColorTokens.light, dark = KolabingColorTokens.night.
   Do not edit by hand: run scripts/design_tokens_to_css.py. */

:root {{
{decls(light)}
}}

/* System dark, unless the viewer explicitly chose light. */
@media (prefers-color-scheme: dark) {{
  :root:not([data-theme="light"]) {{
{decls(diff, "    ")}
  }}
}}

/* Explicit dark choice wins in both directions. */
:root[data-theme="dark"] {{
{decls(diff)}
}}
"""


def build_type_css(styles: dict[str, dict]) -> str:
    fam = {"anton": f"var({PREFIX}-font-display)", "inter": f"var({PREFIX}-font-body)"}
    lines = [
        "/* Kolabing typography — generated from lib/config/theme/typography.dart.",
        "   Display = Anton (always uppercase), body/label/button = Inter.",
        "   Per-style `color:` in the Dart source is intentionally NOT carried over:",
        "   theme.dart _buildTextTheme overwrites it with onSurface, so text inherits",
        f"   var({PREFIX}-color-on-surface) here too.",
        "   Do not edit by hand: run scripts/design_tokens_to_css.py. */",
        "",
        "@import url('../fonts/fonts.css');",
        "",
        ":root {",
        f"  {PREFIX}-font-display: 'Anton', 'Arial Narrow', sans-serif;",
        f"  {PREFIX}-font-body: 'Inter', system-ui, -apple-system, sans-serif;",
        "",
    ]
    for name, s in sorted(styles.items()):
        k = kebab(name)
        lines.append(f"  {PREFIX}-text-{k}-size: {fmt(s['size'])}px;")
        lines.append(f"  {PREFIX}-text-{k}-weight: {s['weight']};")
        if s["height"] is not None:
            lines.append(f"  {PREFIX}-text-{k}-line-height: {fmt(s['height'])};")
        if s["tracking"] is not None:
            lines.append(f"  {PREFIX}-text-{k}-tracking: {fmt(s['tracking'])}px;")
    lines += ["}", ""]

    # Ready-made classes so the design agent has a real vocabulary instead of
    # reassembling four custom properties every time it sets a piece of text.
    lines.append("/* Text classes — the idiomatic way to type something.")
    lines.append("   Classes marked DEPRECATED are carried over for fidelity with the Flutter")
    lines.append("   source but should not be used in new designs — the comment names the")
    lines.append("   replacement, exactly as lib/config/theme/typography.dart does. */")
    for name, s in sorted(styles.items()):
        k = kebab(name)
        if s.get("deprecated"):
            lines.append(f"\n/* DEPRECATED — {name}: see typography.dart for the replacement. */")
        decl = [
            f"  font-family: {fam.get(s['family'], fam['inter'])};",
            f"  font-size: var({PREFIX}-text-{k}-size);",
            f"  font-weight: var({PREFIX}-text-{k}-weight);",
        ]
        if s["height"] is not None:
            decl.append(f"  line-height: var({PREFIX}-text-{k}-line-height);")
        if s["tracking"] is not None:
            decl.append(f"  letter-spacing: var({PREFIX}-text-{k}-tracking);")
        if s["family"] == "anton":
            decl.append("  text-transform: uppercase;")
        lines += ["", f".kolabing-{k} {{", *decl, "}"]
    return "\n".join(lines) + "\n"


def build_scale_css(title: str, source: str, group: str, values: dict[str, float], unit: str = "px") -> str:
    body = "\n".join(f"  {PREFIX}-{group}-{kebab(k)}: {fmt(v)}{unit};" for k, v in sorted(values.items()))
    return (
        f"/* Kolabing {title} — generated from {source}.\n"
        f"   Do not edit by hand: run scripts/design_tokens_to_css.py. */\n\n"
        f":root {{\n{body}\n}}\n"
    )


def build_shadow_css(shadows: dict[str, str]) -> str:
    body = "\n".join(f"  {PREFIX}-shadow-{kebab(k)}: {v};" for k, v in sorted(shadows.items()))
    return (
        "/* Kolabing elevation — generated from KolabingShadows in lib/config/constants/layout.dart.\n"
        "   Shadows are deliberately minimal: cards lean on borders, buttons are flat, no glow.\n"
        "   Do not edit by hand: run scripts/design_tokens_to_css.py. */\n\n"
        f":root {{\n{body}\n}}\n"
    )


def build_motion_css(durations: dict[str, int]) -> str:
    # `defaultDuration` -> `--kolabing-duration-default`, not `-default-duration`.
    body = "\n".join(
        f"  {PREFIX}-duration-{kebab(re.sub(r'Duration$', '', k)) or 'base'}: {v}ms;"
        for k, v in sorted(durations.items())
    )
    return (
        "/* Kolabing motion — generated from KolabingTransitions in lib/config/constants/layout.dart.\n"
        "   Curves map Flutter's Curves.easeInOut / easeOut onto their CSS equivalents.\n"
        "   Do not edit by hand: run scripts/design_tokens_to_css.py. */\n\n"
        f":root {{\n{body}\n"
        f"  {PREFIX}-ease-default: cubic-bezier(0.42, 0, 0.58, 1);\n"
        f"  {PREFIX}-ease-modal: cubic-bezier(0, 0, 0.58, 1);\n"
        "}\n\n"
        "@media (prefers-reduced-motion: reduce) {\n"
        "  *, *::before, *::after {\n"
        "    animation-duration: 0.01ms !important;\n"
        "    transition-duration: 0.01ms !important;\n"
        "  }\n"
        "}\n"
    )


CARD_SHELL = """<!-- @dsCard group="Foundations" -->
<link rel="stylesheet" href="../../../styles.css" />
<style>
  .k-sheet {{ padding: 24px; background: var({p}-color-app-background); }}
  .k-sheet h2 {{ margin: 0 0 4px; font-size: 22px; letter-spacing: 0.3px; }}
  .k-sheet .k-note {{
    margin: 0 0 20px; color: var({p}-color-on-surface-variant);
    font-size: 13px; font-family: var({p}-font-body); text-transform: none;
  }}
  .k-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }}
  .k-swatch {{
    border: 1px solid var({p}-color-outline-variant);
    border-radius: var({p}-radius-md); overflow: hidden;
    background: var({p}-color-surface);
  }}
  .k-chip {{ height: 52px; }}
  .k-meta {{ padding: 8px 10px; font-family: var({p}-font-body); }}
  .k-meta code {{ font-size: 10.5px; color: var({p}-color-on-surface-variant); word-break: break-all; }}
  .k-meta b {{ display: block; font-size: 12px; color: var({p}-color-on-surface); }}
  .k-row {{
    display: flex; align-items: baseline; gap: 16px; padding: 10px 0;
    border-bottom: 1px solid var({p}-color-hairline);
  }}
  .k-row .k-key {{
    flex: 0 0 190px; font-family: var({p}-font-body); font-size: 11px;
    color: var({p}-color-on-surface-variant); text-transform: none;
  }}
  .k-bar {{ background: var({p}-color-primary); border-radius: var({p}-radius-xs); height: 14px; }}
  .k-box {{
    background: var({p}-color-surface); border: 1px solid var({p}-color-outline-variant);
    width: 84px; height: 56px;
  }}
</style>
<div class="k-sheet">
  <h2 class="kolabing-section-heading-large">{title}</h2>
  <p class="k-note">{note}</p>
  {body}
</div>
"""


def build_cards(light: dict[str, str], styles: dict[str, dict],
                spacing: dict[str, float], radius: dict[str, float]) -> dict[str, str]:
    """Three Foundations cards. Generated, so they cannot drift from the tokens."""

    def shell(title: str, note: str, body: str) -> str:
        return CARD_SHELL.format(p=PREFIX, title=title, note=note, body=body)

    # --- Colors -------------------------------------------------------------
    swatches = []
    for name in sorted(light):
        if name == "primaryGradient":
            continue
        var = f"{PREFIX}-color-{kebab(name)}"
        swatches.append(
            f'<div class="k-swatch"><div class="k-chip" style="background: var({var})"></div>'
            f'<div class="k-meta"><b>{name}</b><code>{var}</code></div></div>'
        )
    colors = shell(
        "Colors",
        f"{len(swatches)} tokens from KolabingColorTokens. Every swatch is live — "
        "switch this page to dark and they repaint from the night set.",
        f'<div class="k-grid">{"".join(swatches)}</div>',
    )

    # --- Typography ---------------------------------------------------------
    rows = []
    for name, s in sorted(styles.items(), key=lambda kv: -kv[1]["size"]):
        if s.get("deprecated"):
            continue
        k = kebab(name)
        rows.append(
            f'<div class="k-row"><div class="k-key">.kolabing-{k}<br>{fmt(s["size"])}px / {s["weight"]}</div>'
            f'<div class="kolabing-{k}">{"Kolabing" if s["family"] == "anton" else "Collaborate with communities"}</div></div>'
        )
    typography = shell(
        "Typography",
        "Anton for display (always uppercase), Inter for everything else. "
        "Deprecated styles are omitted here — see tokens/typography.css.",
        "".join(rows),
    )

    # --- Scale --------------------------------------------------------------
    sp = "".join(
        f'<div class="k-row"><div class="k-key">{PREFIX}-space-{kebab(k)}<br>{fmt(v)}px</div>'
        f'<div class="k-bar" style="width: var({PREFIX}-space-{kebab(k)})"></div></div>'
        for k, v in sorted(spacing.items(), key=lambda kv: kv[1])
    )
    rd = "".join(
        f'<div class="k-row"><div class="k-key">{PREFIX}-radius-{kebab(k)}<br>{fmt(v)}px</div>'
        f'<div class="k-box" style="border-radius: var({PREFIX}-radius-{kebab(k)})"></div></div>'
        for k, v in sorted(radius.items(), key=lambda kv: kv[1])
    )
    scale = shell(
        "Spacing &amp; radius",
        "4px base unit. Radii run small (4) to pill (9999); cards use 24.",
        f"{sp}<div style='height:20px'></div>{rd}",
    )

    return {"Colors": colors, "Typography": typography, "Scale": scale}


def build_readme(light, night, styles, spacing, radius, sizes, shadows, durations) -> str:
    """Conventions header (hand-authored, committed) + a generated token index."""
    header = REPO / ".design-sync" / "conventions.md"
    parts = [header.read_text(encoding="utf-8").rstrip() + "\n"] if header.exists() else []

    def names(group: str, keys) -> str:
        return " · ".join(f"`{PREFIX}-{group}-{kebab(k)}`" for k in sorted(keys))

    live = {k: v for k, v in styles.items() if not v.get("deprecated")}
    dark_overrides = len([k for k in night if night[k] != light.get(k)])

    parts.append(f"""
---

# Token index

Generated from the Flutter sources by `scripts/design_tokens_to_css.py`.
Everything below is reachable from `styles.css`'s `@import` closure.

| Group | Count | File |
|---|---|---|
| Colors | {len(light)} ({dark_overrides} redefined in dark) | `tokens/color.css` |
| Text styles | {len(styles)} ({len(live)} current, {len(styles) - len(live)} deprecated) | `tokens/typography.css` |
| Spacing | {len(spacing)} | `tokens/space.css` |
| Radii | {len(radius)} | `tokens/radius.css` |
| Component sizes | {len(sizes)} | `tokens/size.css` |
| Shadows | {len(shadows)} | `tokens/shadow.css` |
| Durations | {len(durations)} | `tokens/motion.css` |

## Spacing

{names("space", spacing)}

## Radius

{names("radius", radius)}

## Component sizes

{names("size", sizes)}

## Shadows

{names("shadow", shadows)}

## Text classes

{" · ".join(f"`.kolabing-{kebab(k)}`" for k in sorted(live))}

Deprecated (present for fidelity, do not use in new work):
{" · ".join(f"`.kolabing-{kebab(k)}`" for k in sorted(styles) if styles[k].get("deprecated"))}

## Colors

Read `tokens/color.css` for the full list with values. Names:

{names("color", light)}
""")
    return "\n".join(parts)


STYLES_CSS = f"""/* Kolabing Design System — token entry point.

   Rendered designs receive ONLY this file's transitive @import closure, so every
   token file must be reachable from here.

   Generated from the Flutter sources by scripts/design_tokens_to_css.py.
   Do not edit by hand — edit the Dart tokens and regenerate. */

@import url('./tokens/color.css');
@import url('./tokens/typography.css');
@import url('./tokens/space.css');
@import url('./tokens/radius.css');
@import url('./tokens/size.css');
@import url('./tokens/shadow.css');
@import url('./tokens/motion.css');

/* Page ground. Set explicitly: a transparent body borrows the host's theme. */
body {{
  margin: 0;
  background: var({PREFIX}-color-app-background);
  color: var({PREFIX}-color-on-surface);
  font-family: var({PREFIX}-font-body);
  font-size: var({PREFIX}-text-body-medium-size);
  line-height: var({PREFIX}-text-body-medium-line-height);
  -webkit-font-smoothing: antialiased;
}}

/* Anton is an all-caps display face by convention in this app — every headline
   in the Flutter code calls .toUpperCase() on its string. */
h1, h2, h3 {{
  font-family: var({PREFIX}-font-display);
  font-weight: 400;
  text-transform: uppercase;
  color: var({PREFIX}-color-on-surface);
}}

/* Minimum touch target, straight from KolabingLayout.minTouchTarget. */
button, a[role="button"], [data-touch-target] {{
  min-height: var({PREFIX}-size-min-touch-target);
}}
"""


# --------------------------------------------------------------------------- #
# main
# --------------------------------------------------------------------------- #

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--fetch-fonts", action="store_true", help="re-vendor fonts (needs network)")
    args = ap.parse_args()

    if args.fetch_fonts:
        print("Fetching fonts...")
        fetch_fonts()

    tokens_src = read(THEME / "color_tokens.dart")
    typo_src = read(THEME / "typography.dart")
    space_src = read(CONST / "spacing.dart")
    radius_src = read(CONST / "radius.dart")
    layout_src = read(CONST / "layout.dart")

    light = parse_color_set(tokens_src, "light")
    night = parse_color_set(tokens_src, "night")
    styles = parse_text_styles(typo_src)
    spacing = parse_class_doubles(space_src, "KolabingSpacing")
    radius = parse_class_doubles(radius_src, "KolabingRadius")
    sizes = parse_class_doubles(layout_src, "KolabingLayout")
    shadows = parse_shadows(layout_src)
    durations = parse_durations(layout_src, "KolabingTransitions")

    for label, got in [
        ("light colors", light), ("night colors", night), ("text styles", styles),
        ("spacing", spacing), ("radius", radius), ("sizes", sizes),
        ("shadows", shadows), ("durations", durations),
    ]:
        if not got:
            print(f"!! parsed 0 {label} — the Dart source shape changed", file=sys.stderr)
            sys.exit(1)

    (OUT / "tokens").mkdir(parents=True, exist_ok=True)
    (OUT / "fonts").mkdir(parents=True, exist_ok=True)

    (OUT / "fonts" / "fonts.css").write_text(build_fonts_css(), encoding="utf-8")
    (OUT / "tokens" / "color.css").write_text(build_color_css(light, night), encoding="utf-8")
    (OUT / "tokens" / "typography.css").write_text(build_type_css(styles), encoding="utf-8")
    (OUT / "tokens" / "space.css").write_text(
        build_scale_css("spacing scale", "KolabingSpacing in lib/config/constants/spacing.dart", "space", spacing),
        encoding="utf-8")
    (OUT / "tokens" / "radius.css").write_text(
        build_scale_css("corner radii", "KolabingRadius in lib/config/constants/radius.dart", "radius", radius),
        encoding="utf-8")
    (OUT / "tokens" / "size.css").write_text(
        build_scale_css("component sizes", "KolabingLayout in lib/config/constants/layout.dart", "size", sizes),
        encoding="utf-8")
    (OUT / "tokens" / "shadow.css").write_text(build_shadow_css(shadows), encoding="utf-8")
    (OUT / "tokens" / "motion.css").write_text(build_motion_css(durations), encoding="utf-8")
    (OUT / "styles.css").write_text(STYLES_CSS, encoding="utf-8")

    for name, html in build_cards(light, styles, spacing, radius).items():
        d = OUT / "components" / "Foundations" / name
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{name}.html").write_text(html, encoding="utf-8")

    (OUT / "README.md").write_text(
        build_readme(light, night, styles, spacing, radius, sizes, shadows, durations),
        encoding="utf-8",
    )

    # Hand-authored bundle files (the marketing entry point + the two-system scope
    # doc) live in .design-sync/overlay/ so ds-bundle/ stays purely generated.
    overlay = REPO / ".design-sync" / "overlay"
    copied = 0
    for src in sorted(overlay.rglob("*")):
        if src.is_file():
            dst = OUT / src.relative_to(overlay)
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(src.read_bytes())
            copied += 1

    print(f"Copied {copied} overlay file(s) from .design-sync/overlay/.")
    print(
        f"Wrote {OUT.relative_to(REPO)}/ — "
        f"{len(light)} colors ({len([k for k in night if night[k] != light.get(k)])} dark overrides), "
        f"{len(styles)} text styles, {len(spacing)} spacing, {len(radius)} radii, "
        f"{len(sizes)} sizes, {len(shadows)} shadows, {len(durations)} durations."
    )


if __name__ == "__main__":
    main()
