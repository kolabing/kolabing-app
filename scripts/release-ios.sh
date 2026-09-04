#!/usr/bin/env bash
#
# Build and upload an iOS build to TestFlight, with no interactive login and no
# App Store Connect visit (kolabing-app#159).
#
# Everything here uses tools already inside Xcode — `xcodebuild` and
# `xcrun altool`. No fastlane, no Ruby gems, nothing to install.
#
# The reason this exists: `make ipa-dev` failed with the famously unhelpful
# `error: exportArchive Copy failed`, and the real cause was only visible by
# running the export by hand — "Unable to log in with account … Your session has
# expired." Automatic signing wants a live Apple Developer session in Xcode, and
# that session dies quietly. An App Store Connect API key has no session to
# expire.
#
# Usage:
#   scripts/release-ios.sh dev            # dev API build → TestFlight
#   scripts/release-ios.sh prod           # prod API build → TestFlight
#   scripts/release-ios.sh prod --no-bump # reuse the current build number
#   scripts/release-ios.sh dev --dry-run  # build and export, upload nothing
#
# Credentials come from ./.env.release (gitignored) or the environment:
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH
set -euo pipefail

cd "$(dirname "$0")/.."

ENV_NAME="${1:-}"
shift || true

BUMP=1
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --no-bump) BUMP=0 ;;
    --dry-run) DRY_RUN=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 64 ;;
  esac
done

case "$ENV_NAME" in
  dev|prod) ;;
  *) echo "Usage: $0 {dev|prod} [--no-bump] [--dry-run]" >&2; exit 64 ;;
esac

say() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }
die() { printf '\n\033[31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

# -----------------------------------------------------------------------------
# Credentials — checked FIRST.
#
# Deliberately before anything slow. The archive takes about two minutes, and
# discovering a missing key after it is the experience this script replaces.
# -----------------------------------------------------------------------------
[ -f .env.release ] && set -a && . ./.env.release && set +a

: "${ASC_KEY_ID:=}" "${ASC_ISSUER_ID:=}" "${ASC_KEY_PATH:=}"

if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ] || [ -z "$ASC_KEY_PATH" ]; then
  cat >&2 <<'MISSING'
✗ No App Store Connect API key configured.

  One-time setup (the only ASC visit this whole thing needs):

    1. App Store Connect → Users and Access → Integrations
       → App Store Connect API → generate a key, role "App Manager"
    2. Download the .p8. It downloads ONCE and cannot be re-downloaded.
       Keep it outside the repo, e.g. ~/.appstoreconnect/private_keys/
    3. Copy the Key ID and the Issuer ID from that same page
    4. Write them into .env.release (gitignored):

         ASC_KEY_ID=XXXXXXXXXX
         ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
         ASC_KEY_PATH=$HOME/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8

  See docs/release/ios-release-automation.md
MISSING
  exit 1
fi

ASC_KEY_PATH="${ASC_KEY_PATH/#\~/$HOME}"
[ -f "$ASC_KEY_PATH" ] || die "The key file is not there: $ASC_KEY_PATH"

# altool finds the .p8 by convention: AuthKey_<KEYID>.p8 in a private_keys dir.
# Pointing it at the file's own directory means the key can live anywhere.
export API_PRIVATE_KEYS_DIR
API_PRIVATE_KEYS_DIR="$(cd "$(dirname "$ASC_KEY_PATH")" && pwd)"

expected_name="AuthKey_${ASC_KEY_ID}.p8"
if [ "$(basename "$ASC_KEY_PATH")" != "$expected_name" ]; then
  die "altool requires the key to be named $expected_name (it is $(basename "$ASC_KEY_PATH"))"
fi

say "Credentials look usable (key $ASC_KEY_ID)"

# -----------------------------------------------------------------------------
# Build number
#
# Monotonic and automatic, because forgetting to bump it means Apple rejects the
# upload AFTER a full archive. pubspec stays the source of truth so the number is
# in git rather than in someone's head.
# -----------------------------------------------------------------------------
current="$(grep -E '^version:' pubspec.yaml | head -1 | sed 's/version: *//')"
short="${current%%+*}"
build="${current##*+}"

if [ "$BUMP" -eq 1 ]; then
  build=$((build + 1))
  # Same expression on GNU and BSD sed: match the whole line, rewrite it.
  sed -i '' "s/^version: .*/version: ${short}+${build}/" pubspec.yaml
  say "Build number → ${short}+${build}  (was ${current})"
else
  say "Build number kept at ${short}+${build}"
fi

# -----------------------------------------------------------------------------
# Archive
# -----------------------------------------------------------------------------
say "Archiving ($ENV_NAME)…"
flutter build ipa \
  --dart-define=APP_ENV="$ENV_NAME" \
  --export-options-plist=ios/ExportOptions.plist \
  || {
    # Flutter's own export is what fails on an expired Xcode session. The archive
    # itself will have succeeded, so fall through and export it ourselves with
    # the API key — which is the whole point of this script.
    say "Flutter's export step failed; exporting with the API key instead"
  }

ARCHIVE="build/ios/archive/Runner.xcarchive"
[ -d "$ARCHIVE" ] || die "No archive at $ARCHIVE — the build itself failed, so there is nothing to export."

# Fail closed before export, not after upload (#202). The define above is only an
# instruction; this reads the host actually baked into the binary. Once a build
# is in App Store Connect, a dev one and a prod one are the same row.
say "Verifying the archive really targets $ENV_NAME…"
./scripts/verify-build-env.sh "$ENV_NAME" "$ARCHIVE" \
  || die "The archive does not target $ENV_NAME. Not exporting, not uploading."

IPA_DIR="build/ios/ipa"
IPA="$(ls -t "$IPA_DIR"/*.ipa 2>/dev/null | head -1 || true)"

if [ -z "$IPA" ]; then
  say "Exporting the archive with the App Store Connect key…"
  rm -rf "$IPA_DIR"
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist ios/ExportOptions.plist \
    -exportPath "$IPA_DIR" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    || die "Export failed. Run the same command by hand to see Apple's actual message — Xcode hides it behind 'Copy failed'."

  IPA="$(ls -t "$IPA_DIR"/*.ipa 2>/dev/null | head -1 || true)"
fi

[ -n "$IPA" ] || die "Export produced no .ipa"
say "Built $IPA"

if [ "$DRY_RUN" -eq 1 ]; then
  say "--dry-run: stopping before upload"
  exit 0
fi

# -----------------------------------------------------------------------------
# Upload
#
# Validated first: altool's validation catches the things Apple would otherwise
# reject minutes later in processing, and it costs seconds.
# -----------------------------------------------------------------------------
say "Validating with Apple…"
xcrun altool --validate-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
  || die "Apple rejected the build at validation. The message above is theirs."

say "Uploading to TestFlight…"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID" \
  || die "Upload failed. The build number may already exist — re-run without --no-bump."

cat <<DONE

✓ Uploaded ${short}+${build} ($ENV_NAME) to TestFlight.

  Apple processes it for a few minutes, then it appears for internal testers
  automatically. Nothing to click for an INTERNAL group.

  Still Apple's, not ours:
    · an EXTERNAL group's first build needs a one-off review
    · submitting for App Store review needs the version's metadata to exist

  Commit the build number so the next run starts from the right place:
    git add pubspec.yaml && git commit -m "chore(release): ${short}+${build} ($ENV_NAME)"
DONE
