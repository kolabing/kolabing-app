# Publishing Kolabing 1.5.0+16

Bundle id: `com.kolabing.kolabingApp` · Version: **1.5.0 (16)** · Code: `master`.

## 0. Pre-flight (already done)
- [x] Code on `master`, clean, 0 analyze errors.
- [x] Version `1.5.0+16` in `pubspec.yaml`.
- [x] App icon + web favicon refreshed; CHANGELOG + store notes written
      (`docs/release/1.5.0-store-notes.md`).
- [x] **Backend deployed** (kolabing-v2 `master` → prod via laravel.cloud; the
      `events.city_id` / visibility / discover migrations are live).

> The release **binaries can't be built on the agent machine** (no Android SDK,
> no Apple distribution signing). Do the steps below on your Mac/CI.

## 1. iOS — App Store / TestFlight
1. `flutter pub get`
2. Signing: in Xcode (`ios/Runner.xcworkspace`) make sure the target uses your
   **Apple Distribution** cert + a provisioning profile for `com.kolabing.kolabingApp`.
3. Build: `flutter build ipa --release`
   (or in Xcode: select **Any iOS Device** → **Product ▸ Archive**).
4. Upload: Xcode **Organizer ▸ Distribute App ▸ App Store Connect**, or open
   `build/ios/ipa/*.ipa` in **Transporter**.
5. App Store Connect → your app → **+ Version 1.5.0** → select build **(16)** →
   paste **What's New** from `1.5.0-store-notes.md` → screenshots/metadata →
   **Submit for Review** (or release to **TestFlight** first).

## 2. Android — Play Store
1. Ensure the **upload keystore** + `android/key.properties` are configured.
2. Build: `flutter build appbundle --release`
   → `build/app/outputs/bundle/release/app-release.aab`
3. Play Console → **Production** (or Internal testing) → **Create new release** →
   upload the `.aab` → paste release notes → review → **Roll out**.

## 3. Notes
- The **build number (16)** must be higher than the last published build on each
  store. If 16 is already taken, bump `pubspec.yaml` to `1.5.0+17` and rebuild.
- Backend is already live — no store gating; the app's new endpoints work in prod.
- After release, tag it: `git tag v1.5.0+16 && git push origin v1.5.0+16`.
