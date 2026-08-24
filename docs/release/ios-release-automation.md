# Shipping to TestFlight without opening App Store Connect

> Ticket: kolabing-app#159.
> **One visit to App Store Connect, once, ever. After that: one command.**

---

## Why this exists

Two things kept costing time.

**The export failed for a reason Xcode hid.** `make ipa-dev` ended with
`error: exportArchive Copy failed`. Running the export by hand showed what Apple
actually said:

```
Unable to log in with account 'volkan@24saatteis.com'.
Your session has expired. Please log in.
```

Automatic signing wants a **live Apple Developer session inside Xcode**, and that
session dies quietly. Nothing in the build output says so.

**And the build number was hand-edited.** Forgetting to bump `pubspec.yaml` means
Apple rejects the upload *after* a two-minute archive.

An **App Store Connect API key** fixes the first permanently — there is no
session to expire — and the script fixes the second.

## What this does NOT need

No fastlane. No Ruby gems. No Homebrew package. Nothing to install.

`xcodebuild` and `xcrun altool` are both already inside Xcode, and both accept an
API key. That is the whole toolchain.

---

## One-time setup

### 1. Create the key (the only ASC visit)

**App Store Connect → Users and Access → Integrations → App Store Connect API →
generate a key.** Role: **App Manager**.

- The `.p8` downloads **once** and can never be downloaded again. If it is lost,
  revoke it and make another.
- Copy the **Key ID** and the **Issuer ID** from that same page.

Put the key somewhere outside the repo:

```bash
mkdir -p ~/.appstoreconnect/private_keys
mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
chmod 600 ~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8
```

**Keep the filename `AuthKey_<KEYID>.p8`.** `altool` finds the key by that
convention, and the script refuses early rather than letting you discover it
after an archive.

### 2. Point the repo at it

```bash
cat > .env.release <<'EOF'
ASC_KEY_ID=XXXXXXXXXX
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ASC_KEY_PATH=$HOME/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8
EOF
```

`.env.release` and `*.p8` are both gitignored, by name and by extension —
committing either is a credential leak, so it is guarded twice.

---

## Using it

```bash
make beta-dev      # dev-API build → TestFlight
make beta-prod     # prod-API build → TestFlight
make beta-dry      # build and export, upload nothing
```

Each run:

1. **checks the credentials first** — before the archive, not after, because
   discovering a missing key two minutes in is the experience this replaces;
2. bumps the build number in `pubspec.yaml`;
3. archives with the right `APP_ENV`;
4. exports **with the API key**, so signing cannot fail on a stale session;
5. **validates** with Apple (seconds) before uploading (minutes);
6. uploads, and tells you to commit the build number.

`--no-bump` reuses the current number. `--dry-run` stops before the upload.

### If Flutter's own export step fails

It does not matter. `flutter build ipa` runs Apple's export internally with the
Xcode session, and the script expects that to fail — the archive has already
succeeded by then, so it re-exports the same archive with the API key. That
fallback is the point, not a workaround.

---

## What is still Apple's, not ours

Worth knowing so it does not look like a bug in the automation:

| Thing | Automated? |
|---|---|
| Build → TestFlight | **Yes** |
| Appears for **internal** testers | **Yes**, automatically after processing |
| First build for an **external** group | **No** — Apple requires a one-off review of that build |
| Submitting for App Store review | **No** — the version's metadata (screenshots, what's new) has to exist first |
| Answering the export-compliance / content questions | **No** — Apple's questionnaire |

So: TestFlight is genuinely one command. A **store release** is one command plus
whatever Apple asks that release, which for a first submission of a new version
is real work.

---

## Running it without this laptop

`.github/workflows/ios-testflight.yml` does the same thing on a macOS runner,
triggered by a tag:

```bash
git tag ios-beta-1.5.2 && git push origin ios-beta-1.5.2
```

Three repository secrets are needed: `ASC_KEY_ID`, `ASC_ISSUER_ID`, and
`ASC_KEY_P8_BASE64` (`base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy`).

**It is disabled by default** (`workflow_dispatch` plus the tag pattern) and two
things are worth knowing before turning it on: macOS runner minutes cost roughly
ten times Linux ones, and a leaked repository secret is a leaked App Store key.
The local path needs neither.

---

## Troubleshooting

| Symptom | Cause |
|---|---|
| `exportArchive Copy failed` | The Xcode session, not the archive. That is what the API key removes — if you see this from `make beta-*`, the key is not being used |
| `The build number … has already been used` | Re-run without `--no-bump` |
| `Invalid Signature`/`Missing Provisioning` | The key lacks **App Manager**; a Developer-role key can upload but not manage signing |
| `Cannot find AuthKey_… .p8` | The filename must be exactly `AuthKey_<KEYID>.p8` |
| Validation passes, processing fails hours later | Usually an ITMS-90xxx about an entitlement or an icon. Apple emails the detail; `altool --validate-app` cannot see everything |
