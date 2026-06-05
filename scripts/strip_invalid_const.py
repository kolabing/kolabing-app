#!/usr/bin/env python3
"""Iteratively remove `const` keywords that became invalid after the night-mode
codemod (a const expression now contains a runtime `context.colors.x`).

For each const-family analyzer error, find the nearest `const` token at or
before the error offset and delete it. Removing `const` is always
compile-safe (it only ever downgrades to a prefer_const info lint), so this
converges without breaking code. Re-runs analyze between passes so cascading
parent consts resolve.
"""
import re
import subprocess
import sys

CONST_ERROR_CODES = {
    "invalid_constant",
    "non_constant_list_element",
    "const_initialized_with_non_constant_value",
    "non_constant_map_element",
    "non_constant_map_key",
    "const_constructor_with_field_initialized_by_non_const",
    "const_with_non_const",
}

ERR_RE = re.compile(r"^\s+error - (.+?):(\d+):(\d+) - .* - ([a-z_]+)$")


def offset_of(text, line, col):
    lines = text.splitlines(keepends=True)
    return sum(len(l) for l in lines[: line - 1]) + (col - 1)


def analyze():
    res = subprocess.run(
        ["dart", "analyze", "lib/"], capture_output=True, text=True
    )
    return res.stdout + res.stderr


def collect_const_errors(output):
    errs = {}
    for ln in output.splitlines():
        m = ERR_RE.match(ln)
        if not m:
            continue
        path, line, col, code = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
        if code in CONST_ERROR_CODES:
            errs.setdefault(path, []).append((line, col))
    return errs


def fix_file(path, positions):
    full = "lib/" + path if not path.startswith("lib/") else path
    with open(full, "r") as f:
        text = f.read()
    # Compute removal offsets: nearest `const` token at/before each error offset.
    const_tokens = [m.start() for m in re.finditer(r"\bconst\b", text)]
    to_remove = set()
    for line, col in positions:
        err_off = offset_of(text, line, col)
        candidates = [c for c in const_tokens if c <= err_off]
        if candidates:
            to_remove.add(max(candidates))
    if not to_remove:
        return 0
    # Remove from the end so offsets stay valid; strip one trailing whitespace.
    for off in sorted(to_remove, reverse=True):
        end = off + len("const")
        # swallow a single following space if present
        if end < len(text) and text[end] == " ":
            end += 1
        text = text[:off] + text[end:]
    with open(full, "w") as f:
        f.write(text)
    return len(to_remove)


def main():
    for it in range(40):
        out = analyze()
        errs = collect_const_errors(out)
        if not errs:
            print(f"[pass {it}] no const errors remaining")
            return 0
        removed = 0
        for path, positions in errs.items():
            removed += fix_file(path, positions)
        total = sum(len(v) for v in errs.values())
        print(f"[pass {it}] const errors={total} across {len(errs)} files, removed {removed} const tokens")
        if removed == 0:
            print("no progress; stopping")
            return 1
    print("hit iteration cap")
    return 1


if __name__ == "__main__":
    sys.exit(main())
