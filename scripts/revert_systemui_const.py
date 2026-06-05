#!/usr/bin/env python3
"""Revert `context.colors.x` -> `KolabingColors.x` ONLY inside the
`_configureSystemUI` method bodies.

That method runs during initState (before dependencies are available), where
`Theme.of(context)` — which `context.colors` calls — is illegal. These system
chrome colors were static `KolabingColors` values before the night-mode
migration, so reverting them restores correct, crash-free behavior.
"""
import re
import sys

FILES = [
    "lib/features/auth/screens/user_type_selection_screen.dart",
    "lib/features/auth/screens/reset_password_screen.dart",
    "lib/features/auth/screens/sign_in_screen.dart",
    "lib/features/auth/screens/attendee_register_screen.dart",
    "lib/features/auth/screens/splash_screen.dart",
    "lib/features/permission/screens/permission_screen.dart",
    "lib/features/onboarding/screens/business/business_final_screen.dart",
    "lib/features/onboarding/screens/business/business_step2_screen.dart",
    "lib/features/onboarding/screens/business/business_step3_screen.dart",
    "lib/features/onboarding/screens/business/business_step5_screen.dart",
    "lib/features/onboarding/screens/community/community_step1_screen.dart",
    "lib/features/onboarding/screens/community/community_step2_screen.dart",
    "lib/features/onboarding/screens/community/community_step3_screen.dart",
    "lib/features/onboarding/screens/community/community_step4_screen.dart",
    "lib/features/onboarding/screens/community/community_final_screen.dart",
]


def revert_method(text):
    """Find each `_configureSystemUI` method and revert context.colors within it."""
    out = []
    i = 0
    pat = re.compile(r"_configureSystemUI\s*\([^)]*\)\s*\{")
    total = 0
    while True:
        m = pat.search(text, i)
        if not m:
            out.append(text[i:])
            break
        out.append(text[i:m.end()])
        # Walk braces to find the method end.
        depth = 1
        j = m.end()
        while j < len(text) and depth > 0:
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
            j += 1
        body = text[m.end():j]
        new_body, n = re.subn(r"context\.colors\.", "KolabingColors.", body)
        total += n
        out.append(new_body)
        i = j
    return "".join(out), total


def main():
    grand = 0
    for f in FILES:
        try:
            with open(f) as fh:
                text = fh.read()
        except FileNotFoundError:
            print(f"skip (missing): {f}")
            continue
        new, n = revert_method(text)
        if n:
            with open(f, "w") as fh:
                fh.write(new)
            print(f"{f}: reverted {n}")
            grand += n
    print(f"total reverted: {grand}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
