#!/usr/bin/env bash
#
# Prove which backend an iOS artefact was built against (#202).
#
# `ApiConfig.baseUrl` is a compile-time constant, so the host is welded into
# every call site: a dev build carries fully folded request URLs like
# `…laravel.cloud/api/v1/me/rewards?page=1&limit=10`. That is what makes this
# checkable — and it is also why a wrong build is completely silent at runtime.
#
# The reason this exists: three archives of build 41 sat on one machine and did
# not agree — the `flutter build ipa` one was dev, the two Xcode ones were prod.
# Once uploaded, App Store Connect shows the same bundle id, the same version
# string and the same icon for both, so which one shipped stops being knowable.
#
# Both hosts are read out of lib/config/environment.dart. Copying them here
# would create a second source of truth for a base URL — forbidden by CLAUDE.md,
# and a stale copy would wave a wrong build through, which is worse than no
# check at all.
#
#   scripts/verify-build-env.sh prod [path/to/Runner.xcarchive|path/to/app.ipa]
#
# Defaults to build/ios/archive/Runner.xcarchive (what `flutter build ipa`
# writes). Exits non-zero, loudly, when the artefact is not the environment you
# asked for.

set -euo pipefail

say() { printf '\033[1;36m▸ %s\033[0m\n' "$1"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

WANT="${1:-}"
case "$WANT" in
  dev|prod) ;;
  *) echo "Usage: $0 {dev|prod} [archive-or-ipa]" >&2; exit 64 ;;
esac

TARGET="${2:-build/ios/archive/Runner.xcarchive}"
[ -e "$TARGET" ] || die "Nothing at $TARGET — archive first, or pass the path."

ENV_DART="lib/config/environment.dart"
[ -f "$ENV_DART" ] || die "$ENV_DART is missing; this script reads the hosts from it."

# _devBase / _prodBase are declared across two lines by the formatter, so join
# the file first and pull the string literal that follows each name.
read_base() {
  tr '\n' ' ' < "$ENV_DART" \
    | grep -oE "_${1}Base[[:space:]]*=[[:space:]]*'[^']+'" \
    | head -1 | sed "s/.*'\\(.*\\)'/\\1/"
}

DEV_BASE="$(read_base dev)"
PROD_BASE="$(read_base prod)"
[ -n "$DEV_BASE" ] && [ -n "$PROD_BASE" ] \
  || die "Could not read _devBase/_prodBase from $ENV_DART — has it been restructured?"

# Mirrors Environment.apiBaseUrl. If that ever stops being "<base>/api/v1" this
# check goes quiet rather than wrong: both counts drop to zero and we abort.
DEV_URL="${DEV_BASE}/api/v1"
PROD_URL="${PROD_BASE}/api/v1"

# ---------------------------------------------------------------- find the binary
WORK=""
# Must return 0: an EXIT trap whose last command fails takes the script down
# with it, so a passing check would exit 1 and read as a failure.
cleanup() { [ -n "$WORK" ] && rm -rf "$WORK"; return 0; }
trap cleanup EXIT

case "$TARGET" in
  *.ipa)
    WORK="$(mktemp -d)"
    unzip -qq "$TARGET" -d "$WORK" || die "Could not unzip $TARGET"
    APP="$(find "$WORK/Payload" -maxdepth 1 -name '*.app' | head -1)"
    ;;
  *)
    APP="$(find "$TARGET/Products/Applications" -maxdepth 1 -name '*.app' 2>/dev/null | head -1)"
    ;;
esac

[ -n "${APP:-}" ] && [ -d "$APP" ] || die "No .app inside $TARGET"

BIN="$APP/Frameworks/App.framework/App"
[ -f "$BIN" ] || die "No App.framework/App in $APP — is this a Flutter build?"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Info.plist" 2>/dev/null || echo '?')"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Info.plist" 2>/dev/null || echo '?')"

# ---------------------------------------------------------------- read the host
# Exact whole-line matches: the folded call-site URLs (".../api/v1/checkin") are
# longer lines and must not be counted as the base itself.
count_exact() { strings -a "$BIN" | grep -cxF "$1" || true; }

DEV_HITS="$(count_exact "$DEV_URL")"
PROD_HITS="$(count_exact "$PROD_URL")"

say "Artefact : $TARGET"
say "Version  : $VERSION ($BUILD)"
say "Wanted   : $WANT"
printf '  prod base %-4s %s\n' "$PROD_HITS" "$PROD_URL"
printf '  dev  base %-4s %s\n' "$DEV_HITS" "$DEV_URL"

if [ "$DEV_HITS" -eq 0 ] && [ "$PROD_HITS" -eq 0 ]; then
  die "Neither base URL is in the binary. Either the artefact is not this app, or
   Environment.apiBaseUrl no longer folds to '<base>/api/v1' — fix this script
   before trusting another build."
fi

if [ "$DEV_HITS" -gt 0 ] && [ "$PROD_HITS" -gt 0 ]; then
  die "Both hosts are baked in, so the environment cannot be read from the
   artefact. Something changed in how Environment resolves; do not upload."
fi

FOUND=prod
[ "$DEV_HITS" -gt 0 ] && FOUND=dev

if [ "$FOUND" != "$WANT" ]; then
  # No ${x^^}: macOS ships bash 3.2, where that is a syntax error.
  die "This is a $(echo "$FOUND" | tr '[:lower:]' '[:upper:]') build, and you asked for $(echo "$WANT" | tr '[:lower:]' '[:upper:]').
   Build it with:  make ipa-$WANT     (or flutter build ipa --dart-define=APP_ENV=$WANT)
   A bare Xcode Archive passes no define and falls back to prod in release."
fi

FOUND_URL="$PROD_URL"
[ "$FOUND" = dev ] && FOUND_URL="$DEV_URL"
printf '\033[1;32m✓ %s build confirmed — %s\033[0m\n' "$WANT" "$FOUND_URL"
