<!--
  This template is MANDATORY. A PR is not "ready" until every section is filled in.
  Do NOT delete sections — if one does not apply, write "N/A" with a one-line reason.
  This is a MOBILE (Flutter) repo: always consider iOS AND Android.
-->

## 🎯 What does this PR do?
<!-- What changed? Short, clear, bullet points. -->



## 🐞 What problem does it solve?
<!-- The bug / need / request behind it. Link the issue: Closes #__ -->



## 🚀 What's needed for this to work in production?
<!--
  After merge, what is required for this to work in prod? Write "Nothing extra" if none.
  - [ ] New env var / secret: ____
  - [ ] Backend deploy / migration / new endpoint must be live: ____
  - [ ] New App Store / Play Store build (version / build no: ____)
  - [ ] Feature flag / remote config: ____
  - [ ] Third-party setup (IAP product, push cert, deep link, etc.): ____
-->



## 📱 Which branch should be merged for this work?
<!-- Note any dependencies. Otherwise write "This branch only". -->

- Base branch: `master`
- Dependent branch(es): ____

## 🧪 How to test this merge (reviewer must be able to reproduce)
<!-- Clear steps so a reviewer can verify the change on a device. -->

- **Affected role:** Business / Community / Attendee (keep what applies)
- **Test account / data:** ____
- **Steps:**
  1.
  2.
  3.
- **Expected result:** ____

## 📸 Screenshots / screen recording
<!--
  MANDATORY for ANY design / UI change — a PR that touches UI without a screenshot
  will not be merged. Include before/after. Prefer BOTH iOS and Android.
  If there is genuinely no UI change, tick the box below instead.
-->

- [ ] This PR has **no UI/design change** (no screenshot needed)

| Before | After |
| ------ | ----- |
|        |       |

---

## ✅ Definition of Done (check before requesting review)
- [ ] `flutter analyze` is clean (no new errors/warnings)
- [ ] `dart format lib test` applied to changed files
- [ ] Tested on **iOS** simulator/device
- [ ] Tested on **Android** emulator/device
- [ ] **Screenshots attached for every UI/design change** (see section above)
- [ ] New user-facing strings exist in i18n (`app_en.arb` + `app_es.arb` + `app_ca.arb`) and `flutter gen-l10n` was run
- [ ] No hardcoded values (base URL / IDs / emails / city–category lists — all from the API)
- [ ] `BACKLOG.md` updated (finished item removed / new bug added)

## 🤖 Was AI used?
<!-- Which tool + what you had it do? Ownership stays with you — just be transparent. -->

