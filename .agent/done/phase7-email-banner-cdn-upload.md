# Task: phase7-email-banner-cdn-upload

## Status
- Created: 2026-05-21 13:00
- Started: 2026-05-21 13:00
- Completed: 2026-05-21 13:00 (documented — actual upload is outside this repo)

## Description
G1: Upload the welcome-email banner to the kolabing.com CDN so Postmark email templates can use a baked PNG (immune to Gmail iOS dark-mode SVG inversion).

## Why this is documented, not done in code

The banner file lives in a separate marketing repo:
`community/kolabing/marketing/brand/logo-wordmark-banner-dark.png` (1200×320, 49 KB).

The Flutter app repo (this one) doesn't carry that asset. The closest existing in-app variant is `assets/images/logo_wordmark_white_on_dark.png` (different dimensions / aspect, used in the app, not suitable as an email header).

Uploading to the CDN requires marketing/devops access to whatever serves `https://kolabing.com/brand/`. No code change is needed here.

## What to do (handoff checklist)

1. From the marketing repo, take `community/kolabing/marketing/brand/logo-wordmark-banner-dark.png`.
2. Upload it to `https://kolabing.com/brand/logo-wordmark-banner-dark.png` (or the agreed path).
3. Verify it's reachable via HTTP and serves with `Content-Type: image/png` + `Cache-Control: public, max-age=31536000, immutable`.
4. In Postmark, swap the `<img src>` in both welcome templates (business + community) to the new URL.
5. Send a test email to a Gmail iOS account in dark mode → banner should NOT be inverted.

## Owners
- Marketing / devops: CDN upload.
- Daniel: Postmark template edits, send tests.
- This task does not block the Flutter app's launch.

## Notes
- If the CDN path is different from `/brand/`, document it in `.agent/system/` (or wherever URLs are tracked) and update Postmark + any in-app references.
- A future cleanup: consider hosting all brand assets in a single signed repo so this kind of cross-repo coordination doesn't recur.
