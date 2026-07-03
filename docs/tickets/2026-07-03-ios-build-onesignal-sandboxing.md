# iOS build fails to launch — OneSignal dSYM / Xcode 16 User Script Sandboxing

**For:** Maria & Volkan · **Date:** 2026-07-03 · **Fix branch:** `fix/ios-build-onesignal-sandboxing`

## Symptom
`flutter run -d ios` (and an Xcode **Archive** for App Store) fails **after** the
compile finishes. The Xcode build reports "**Xcode build done**", then:

```
Failed to build iOS app
Error (Xcode): dSYMs/OneSignalCore.framework.dSYM/Contents/Resources/DWARF/.OneSignalCore.<rand>:
  move_file: dSYMs/OneSignalCore.framework.dSYM/Contents/Resources/DWARF/OneSignalCore: No such file or directory
  .../ios/Pods/rsync(...)
Error (Xcode): rsync_receiver / unexpected end of file / io_read_* / rsync_sender
Could not build the application for the simulator.
Error launching application on iPhone 17.
```

And, once we tried the wrong fix (below), the tell-tale line appeared:

```
warning: Stale file '.../Runner.app.dSYM/Contents/Resources/DWARF/Runner' is located
  outside of the allowed root paths.
warning: ... make sure the Firebase run script build phase is the last build phase and
  no other scripts have moved the dSYM ...
```

## Root cause
**Xcode 16 turns on `ENABLE_USER_SCRIPT_SANDBOXING = YES` by default.** That sandboxes
the CocoaPods / OneSignal / Firebase-Crashlytics **build-script phases** and forbids
them from reading/writing files (the framework **dSYMs**) that live outside the script's
declared sandbox. So the OneSignal `[CP] … / rsync` dSYM copy and the Firebase Crashlytics
`upload-symbols` phase fail with `move_file … No such file` and "outside of the allowed
root paths". The app never installs → "Error launching application".

This is **not** an OneSignal bug and **not** a corrupt Pods install — it's the Xcode 16
sandbox default colliding with these two pods' dSYM script phases.

## What did NOT work (so nobody wastes time on them)
- `flutter clean` + `rm -rf ios/Pods && pod install` + rebuild — **does not** fix it (the
  sandbox is still on). It resolved a *different* one-off corruption earlier but not this.
- Forcing `DEBUG_INFORMATION_FORMAT = dwarf` (skip dSYM) — **breaks Firebase Crashlytics**,
  which *requires* the dSYM (`dwarf-with-dsym`). Do not do this.

## The fix (applied on this branch)
Set **`ENABLE_USER_SCRIPT_SANDBOXING = NO`** for both the Pods and the Runner target:

1. **`ios/Podfile`** — in `post_install`, for every pod target/config:
   ```ruby
   config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
   ```
2. **`ios/Flutter/Debug.xcconfig`** and **`ios/Flutter/Release.xcconfig`** — add:
   ```
   ENABLE_USER_SCRIPT_SANDBOXING=NO
   ```
   (Debug = `flutter run`; Release = the App Store archive — both need it.)
3. `pod install` (updates `ios/Podfile.lock`).

After this, `flutter run` builds, installs, and launches cleanly.

### Files changed
- `ios/Podfile`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`
- `ios/Podfile.lock`

## Notes
- `ENABLE_USER_SCRIPT_SANDBOXING` is a **build-time** setting for the *build scripts*. It
  does **not** affect the shipped app, its runtime, or App Store review — it only lets the
  Pods' dSYM scripts run. Widely-used fix for CocoaPods on Xcode 15/16.
- For **CI / the App Store build (+20)**: this must be present, else the archive fails the
  same way. Release.xcconfig covers it here; if CI sets build settings elsewhere, mirror it.
- **Aside (disk):** the failures were compounded by a nearly-full disk. A fresh iOS build
  needs a few GB (Pods + DerivedData + build). Clear regenerable caches if it errors with
  `No space left on device` (Xcode DerivedData, `flutter clean`, Pods).

## Recommendation
Merge this into `master` so every dev + CI can build iOS on Xcode 16. Low risk (build-config
only, no app-code change).
