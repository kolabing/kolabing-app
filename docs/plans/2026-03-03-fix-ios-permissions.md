# Fix iOS Location & Notification Permissions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix location and push notification permissions on iOS so that the system dialogs appear when requested and the app appears in Settings → Privacy & Security.

**Architecture:** The `permission_handler` 12.x package uses conditional compilation on iOS — all permission types are disabled by default and must be explicitly opted-in via `GCC_PREPROCESSOR_DEFINITIONS` in the Podfile. Without the macros, `request()` silently returns `denied` and no iOS system dialog ever appears. Adding the macros and re-running `pod install` rebuilds the native plugin with the correct permission handlers compiled in.

**Tech Stack:** Flutter, `permission_handler ^12.0.1`, CocoaPods (Podfile), iOS native layer

---

## Background: Why Permissions Break on iOS

`permission_handler` on iOS uses preprocessor flags to conditionally compile permission handlers. The package ships with everything disabled to keep binary size small. Developers must explicitly opt-in to each permission type in the Podfile. Without these flags:

- `Permission.locationWhenInUse.request()` — silently returns `denied`, no dialog shown, app never registers with iOS location services
- `Permission.notification.request()` — silently returns `denied`, no dialog shown
- `Permission.camera.request()` — would also silently fail (QR scanner is affected too)

The iOS `Info.plist` already has all the correct usage description strings (`NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription` etc.) — those are fine and do not need changes.

The `AndroidManifest.xml` already has all necessary permission declarations — Android is not affected by this issue.

---

## Files to Touch

- **Modify:** `ios/Podfile` (add `GCC_PREPROCESSOR_DEFINITIONS` to `post_install` block)

---

### Task 1: Add permission_handler preprocessor macros to iOS Podfile

**Files:**
- Modify: `ios/Podfile:39-43` (the `post_install` block)

**Step 1: Open `ios/Podfile` and locate the `post_install` block**

Current state (lines 39-43):
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

**Step 2: Replace the `post_install` block with the version that includes permission macros**

New content:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        ## permission_handler: enable the permissions actually used in this app
        'PERMISSION_LOCATION=1',
        'PERMISSION_NOTIFICATIONS=1',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

**Step 3: Commit the Podfile change**

```bash
git add ios/Podfile
git commit -m "fix(ios): enable permission_handler macros for location, notifications, camera"
```

---

### Task 2: Re-install CocoaPods and rebuild

**Step 1: Remove the old Pods build artifacts**

```bash
cd ios
rm -rf Pods Podfile.lock
```

**Step 2: Re-run pod install**

```bash
pod install
cd ..
```

Expected output: `Pod installation complete! There are N dependencies from the Podfile and N total pods installed.`
No errors expected. If you see errors about missing specs, run `pod repo update` first.

**Step 3: Clean Flutter build cache**

```bash
flutter clean
flutter pub get
```

**Step 4: Build and run on iOS simulator or device**

```bash
flutter run -d ios
```

**Step 5: Verify location permission dialog appears**

In the running app:
1. Navigate to the Permission screen (shown after login/registration, or reset by signing out and back in)
2. Tap the **Allow** button next to **Location**
3. Expected: iOS system dialog appears asking "Allow Kolabing App to use your location?"
4. After allowing, open iPhone Settings → Privacy & Security → Location Services
5. Expected: **Kolabing App** appears in the list with status "While Using"

**Step 6: Verify notification permission dialog appears**

1. On the same Permission screen, tap **Allow** next to **Notifications**
2. Expected: iOS system dialog appears asking "Kolabing App Would Like to Send You Notifications"
3. After allowing, open iPhone Settings → Notifications → Kolabing App
4. Expected: **Kolabing App** appears and "Allow Notifications" toggle is ON

**Step 7: Verify camera still works (no regression)**

1. Navigate to the QR scanner (gamification check-in)
2. Expected: Camera permission dialog appears (or camera opens if already granted)

---

### Task 3: Reset permissions on test device to re-test from scratch (optional but recommended)

If you already tapped "Allow" before (when the dialog was broken) and the OS showed the dialog and recorded a choice, you may need to reset permissions to verify the fix.

**Option A: Reset on Simulator**

```bash
# In Simulator menu: Device → Erase All Content and Settings
# Or via xcrun:
xcrun simctl privacy booted reset all
```

Then rebuild and run.

**Option B: Reset on Physical Device**

Go to Settings → General → Transfer or Reset iPhone → Reset → Reset Location & Privacy.

Then rebuild and run again from Task 2 Step 4.

---

## What Was NOT Changed

- `ios/Runner/Info.plist` — already correct, has all usage description strings
- `android/app/src/main/AndroidManifest.xml` — already correct, has all permission declarations
- `lib/services/permission_service.dart` — correct implementation, the issue was native layer only
- `lib/features/permission/screens/permission_screen.dart` — correct, no changes needed
- `lib/services/notification_service.dart` — correct, Firebase handles its own notification presentation

## Known Limitation

On iOS, if a user already previously denied a permission (before the fix, the system may have recorded a denial if the dialog was shown), they'll need to go to Settings and manually re-enable it. The `permission_screen.dart` already handles this with `_showSettingsDialog` which calls `openAppSettings()`.
