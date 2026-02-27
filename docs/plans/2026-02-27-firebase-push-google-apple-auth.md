# Firebase Push Notifications + Google/Apple Sign In

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Firebase Cloud Messaging (push notifications), fix Google Sign In iOS config, and add Apple Sign In to the Kolabing Flutter app.

**Architecture:** Keep existing Google auth flow (google_sign_in → Laravel backend /api/v1/auth/google). Add Apple Sign In with same pattern (sign_in_with_apple → /api/v1/auth/apple). Add Firebase ONLY for FCM push notifications — not for auth. FCM token registered to backend after login.

**Tech Stack:** firebase_core ^3.x, firebase_messaging ^15.x, sign_in_with_apple ^6.x, flutter_local_notifications ^17.x, existing google_sign_in ^6.2.1

---

## ⚠️ MANUAL SETUP REQUIRED FIRST (before writing any code)

These steps require human interaction with external consoles. Complete them before starting Task 1.

### Firebase Console Setup
1. Go to https://console.firebase.google.com → Create project: "Kolabing"
2. Add iOS app → Bundle ID: `com.kolabing.kolabingApp`
3. Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`
4. In Xcode, drag `GoogleService-Info.plist` into the Runner target (check "Copy items if needed")
5. Firebase Console → Project Settings → Cloud Messaging → APNs Auth Key → upload your APNs key (from Apple Developer Portal → Keys → create key with APNs capability)

### Xcode Capabilities
1. Open `ios/Runner.xcworkspace` in Xcode
2. Runner target → Signing & Capabilities → + Capability → **Push Notifications**
3. Runner target → Signing & Capabilities → + Capability → **Sign In with Apple**
4. These create the `.entitlements` file automatically

### Apple Developer Portal
- Ensure Push Notifications is enabled for `com.kolabing.kolabingApp` App ID

---

## Task 1: Add Packages

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependencies**

```yaml
# In pubspec.yaml, under dependencies:

  # Firebase
  firebase_core: ^3.9.0
  firebase_messaging: ^15.2.4

  # Local notifications (for foreground display on iOS)
  flutter_local_notifications: ^18.0.1

  # Apple Sign In
  sign_in_with_apple: ^7.0.1
```

**Step 2: Install**

```bash
flutter pub get
```

Expected: Dependencies resolved without conflicts.

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add firebase_messaging, flutter_local_notifications, sign_in_with_apple packages"
```

---

## Task 2: iOS Configuration

**Files:**
- Modify: `ios/Runner/Info.plist`

**Step 1: Add REVERSED_CLIENT_ID URL scheme for Google Sign In**

Open `ios/Runner/GoogleService-Info.plist`, find the `REVERSED_CLIENT_ID` value (looks like `com.googleusercontent.apps.XXXXXX`). Then add to `ios/Runner/Info.plist` before `</dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>PASTE_REVERSED_CLIENT_ID_HERE</string>
    </array>
  </dict>
</array>
```

**Step 2: Verify Info.plist has required keys** (already present, verify):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Kolabing needs your location...</string>
<key>NSCameraUsageDescription</key>
<string>Kolabing needs camera access...</string>
```

**Step 3: Commit**

```bash
git add ios/Runner/Info.plist ios/Runner/GoogleService-Info.plist
git commit -m "feat: add iOS Firebase config and Google Sign In URL scheme"
```

---

## Task 3: Create NotificationService

**Files:**
- Create: `lib/services/notification_service.dart`

**Step 1: Create the service**

```dart
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Service for Firebase Cloud Messaging push notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel for high-importance notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kolabing_high_importance',
    'Kolabing Notifications',
    description: 'Notifications for new applications, messages, and updates.',
    importance: Importance.high,
  );

  /// Callback for notification tap → navigation
  void Function(Map<String, dynamic> data)? onNotificationTap;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize FCM. Call once from main() after Firebase.initializeApp().
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications for foreground display on Android
    await _setupLocalNotifications();

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Token Management
  // ---------------------------------------------------------------------------

  /// Get the current FCM token. Returns null if not available.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Token: $token');
      return token;
    } on Exception catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
      return null;
    }
  }

  /// Subscribe to token refresh events.
  /// Call [onToken] whenever a new token is issued.
  void onTokenRefresh(void Function(String token) onToken) {
    _messaging.onTokenRefresh.listen(onToken);
  }

  // ---------------------------------------------------------------------------
  // Foreground Notifications
  // ---------------------------------------------------------------------------

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        // User tapped local notification
        debugPrint('[FCM] Local notification tapped: ${response.payload}');
      },
    );

    // Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    // On iOS, foreground notifications are shown by the system
    // (configured via setForegroundNotificationPresentationOptions)
    // On Android, we show via local notifications
    if (Platform.isAndroid) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    onNotificationTap?.call(message.data);
  }
}
```

**Step 2: Commit**

```bash
git add lib/services/notification_service.dart
git commit -m "feat: add NotificationService with FCM foreground/background/tap handling"
```

---

## Task 4: Initialize Firebase in main.dart

**Files:**
- Modify: `lib/main.dart`

**Step 1: Update main() to init Firebase**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/routes.dart';
import 'config/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await Firebase.initializeApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: KolabingApp(),
    ),
  );
}

class KolabingApp extends StatelessWidget {
  const KolabingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Kolabing',
        debugShowCheckedModeBanner: false,
        theme: KolabingTheme.lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: kolabingRouter,
      );
}
```

**Step 2: Verify compile**

```bash
flutter analyze lib/main.dart
```

Expected: No errors.

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize Firebase in main()"
```

---

## Task 5: FCM Token Registration in AuthService

**Files:**
- Modify: `lib/features/auth/services/auth_service.dart`

**Step 1: Add registerDeviceToken method**

Add this method to `AuthService` class (after `signOutGoogle()`):

```dart
// ---------------------------------------------------------------------------
// FCM Device Token
// ---------------------------------------------------------------------------

/// Register FCM device token with backend.
///
/// POST /api/v1/me/device-token
/// Call after successful login (any method).
Future<void> registerDeviceToken(String fcmToken) async {
  final token = await getToken();
  if (token == null) return;

  final url = '$_baseUrl/me/device-token';
  debugPrint('[FCM] Registering device token: POST $url');

  try {
    final response = await _httpClient.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'token': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      }),
    );
    debugPrint('[FCM] Register token response: ${response.statusCode}');
  } on Exception catch (e) {
    debugPrint('[FCM] Register token error: $e');
    // Non-fatal: don't throw, just log
  }
}
```

Add `import 'dart:io';` at the top of the file.

**Step 2: Commit**

```bash
git add lib/features/auth/services/auth_service.dart
git commit -m "feat: add registerDeviceToken to AuthService"
```

---

## Task 6: Register FCM Token After Login

**Files:**
- Modify: `lib/features/auth/providers/auth_provider.dart`

**Step 1: Find the _onLoginSuccess or equivalent method**

After any successful auth (email, Google, Apple), call token registration.

Find where `_saveAuthData` or `status: AuthStatus.authenticated` is set, and add:

```dart
// After successful auth, register FCM token
unawaited(_registerFcmToken());
```

Add this private method to `AuthNotifier`:

```dart
Future<void> _registerFcmToken() async {
  try {
    final fcmToken = await NotificationService.instance.getToken();
    if (fcmToken != null) {
      await _authService.registerDeviceToken(fcmToken);
    }
  } on Exception catch (e) {
    debugPrint('[FCM] Token registration error: $e');
  }
}
```

Add import:
```dart
import '../../../services/notification_service.dart';
```

Also add `unawaited` import if needed:
```dart
import 'dart:async';
```

**Step 2: Also setup token refresh listener in auth provider init**

In `AuthNotifier` constructor or `build()`:
```dart
NotificationService.instance.onTokenRefresh((token) {
  _authService.registerDeviceToken(token);
});
```

**Step 3: Commit**

```bash
git add lib/features/auth/providers/auth_provider.dart
git commit -m "feat: register FCM token after successful auth"
```

---

## Task 7: Add loginWithApple to AuthService

**Files:**
- Modify: `lib/features/auth/services/auth_service.dart`

**Step 1: Add Apple auth methods**

```dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// ---------------------------------------------------------------------------
// Apple Sign In
// ---------------------------------------------------------------------------

/// Sign in with Apple and get identity token.
Future<({String identityToken, String? fullName})> getAppleCredential() async {
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    if (credential.identityToken == null) {
      throw const AuthException('Failed to get Apple identity token');
    }

    final fullName = [
      credential.givenName,
      credential.familyName,
    ].where((n) => n != null && n.isNotEmpty).join(' ');

    return (
      identityToken: credential.identityToken!,
      fullName: fullName.isEmpty ? null : fullName,
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      throw const AuthCancelledException();
    }
    throw AuthException('Apple Sign In failed: ${e.message}');
  } on Exception catch (e) {
    throw AuthException('Apple Sign In failed: $e');
  }
}

/// Login with Apple.
///
/// POST /api/v1/auth/apple
Future<AuthResponse> loginWithApple() async {
  try {
    final credential = await getAppleCredential();
    return await _authenticateWithApple(
      credential.identityToken,
      credential.fullName,
    );
  } on AuthCancelledException {
    rethrow;
  } on Exception catch (e) {
    debugPrint('Apple login error: $e');
    throw AuthException('Apple login failed: $e');
  }
}

Future<AuthResponse> _authenticateWithApple(
  String identityToken,
  String? fullName,
) async {
  final url = '$_baseUrl/auth/apple';
  debugPrint('🍎 Apple Login: POST $url');

  final response = await _httpClient.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'identity_token': identityToken,
      if (fullName != null) 'name': fullName,
    }),
  );

  debugPrint('🍎 Apple login response: ${response.statusCode}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final authResponse = AuthResponse.fromJson(json);
    await _saveAuthData(authResponse);
    return authResponse;
  } else {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException(
      error: ApiError.fromJson(json, statusCode: response.statusCode),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/auth/services/auth_service.dart
git commit -m "feat: add loginWithApple to AuthService"
```

---

## Task 8: Add signInWithApple to AuthProvider

**Files:**
- Modify: `lib/features/auth/providers/auth_provider.dart`

**Step 1: Add method (mirror of signInWithGoogle)**

```dart
/// Sign in with Apple
Future<AuthResult> signInWithApple() async {
  state = state.copyWith(status: AuthStatus.loading);

  try {
    final response = await _authService.loginWithApple();
    final user = response.data?.user;

    if (user == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Apple sign in failed: no user data',
      );
      return AuthResult.failure('Apple sign in failed: no user data');
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      token: response.data?.token,
      isNewUser: response.data?.isNewUser ?? false,
    );

    unawaited(_registerFcmToken());

    return AuthResult.success(
      user: user,
      isNewUser: response.data?.isNewUser ?? false,
    );
  } on AuthCancelledException {
    state = state.copyWith(status: AuthStatus.unauthenticated);
    return AuthResult.cancelled();
  } on ApiException catch (e) {
    state = state.copyWith(
      status: AuthStatus.error,
      error: e.error.message,
    );
    return AuthResult.failure(e.error.message);
  } on Exception catch (e) {
    state = state.copyWith(
      status: AuthStatus.error,
      error: e.toString(),
    );
    return AuthResult.failure(e.toString());
  }
}
```

**Step 2: Commit**

```bash
git add lib/features/auth/providers/auth_provider.dart
git commit -m "feat: add signInWithApple to AuthProvider"
```

---

## Task 9: Create AppleSignInButton Widget

**Files:**
- Create: `lib/features/auth/widgets/apple_sign_in_button.dart`
- Modify: `lib/features/auth/widgets/widgets.dart`

**Step 1: Create button (mirrors GoogleSignInButton)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';

/// Apple Sign In button matching the app's design system
class AppleSignInButton extends StatefulWidget {
  const AppleSignInButton({
    required this.onPressed,
    super.key,
    this.buttonText = 'Sign in with Apple',
    this.isLoading = false,
    this.showSuccess = false,
    this.isEnabled = true,
  });

  final VoidCallback? onPressed;
  final String buttonText;
  final bool isLoading;
  final bool showSuccess;
  final bool isEnabled;

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  bool get _canInteract =>
      widget.isEnabled &&
      !widget.isLoading &&
      !widget.showSuccess &&
      widget.onPressed != null;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          if (!_canInteract) return;
          HapticFeedback.mediumImpact();
          widget.onPressed?.call();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _canInteract ? 1.0 : 0.6,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildContent(),
          ),
        ),
      );

  Widget _buildContent() {
    if (widget.isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }
    if (widget.showSuccess) {
      return const Center(
        child: Icon(Icons.check_rounded, size: 24, color: Colors.white),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.apple, size: 24, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            widget.buttonText.toUpperCase(),
            style: KolabingTextStyles.button.copyWith(
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Export from widgets.dart**

Add to `lib/features/auth/widgets/widgets.dart`:
```dart
export 'apple_sign_in_button.dart';
```

**Step 3: Commit**

```bash
git add lib/features/auth/widgets/apple_sign_in_button.dart lib/features/auth/widgets/widgets.dart
git commit -m "feat: add AppleSignInButton widget"
```

---

## Task 10: Add Apple Button to Login Screens

**Files:**
- Modify: `lib/features/auth/screens/login_screen.dart`
- Modify: `lib/features/auth/screens/sign_in_screen.dart` (if Google button is there)

**Step 1: Add Apple handler in login_screen.dart**

Find `_handleGoogleSignIn()` method, add below it:

```dart
Future<void> _handleAppleSignIn() async {
  if (_isLoading || _isGoogleLoading || _isAppleLoading || _showSuccess) return;
  FocusScope.of(context).unfocus();
  setState(() => _isAppleLoading = true);

  final result = await ref.read(authProvider.notifier).signInWithApple();

  if (!mounted) return;

  if (result.success) {
    setState(() {
      _isAppleLoading = false;
      _showSuccess = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final route = await _getNavigationRoute(result);
    if (!mounted) return;
    context.go(route);
  } else if (result.cancelled) {
    setState(() => _isAppleLoading = false);
  } else {
    setState(() => _isAppleLoading = false);
    _showErrorSnackBar(result.displayError);
  }
}
```

Add `bool _isAppleLoading = false;` to the state fields.

**Step 2: Add Apple button in the build method**

After the Google button, add:

```dart
const SizedBox(height: 12),
AppleSignInButton(
  buttonText: 'Sign in with Apple',
  isLoading: _isAppleLoading,
  showSuccess: _showSuccess,
  isEnabled: !_isLoading && !_isGoogleLoading,
  onPressed: _handleAppleSignIn,
),
```

Add import:
```dart
import '../widgets/apple_sign_in_button.dart';
```

**Step 3: Mirror for sign_in_screen.dart if it has Google button**

Apply same pattern.

**Step 4: Commit**

```bash
git add lib/features/auth/screens/login_screen.dart lib/features/auth/screens/sign_in_screen.dart
git commit -m "feat: add Apple Sign In button to login screens"
```

---

## Task 11: Initialize NotificationService After Login

**Files:**
- Modify: `lib/main.dart` or appropriate initialization point

**Step 1: Initialize NotificationService in main()**

```dart
// After Firebase.initializeApp()
await NotificationService.instance.initialize();
```

**Step 2: Setup navigation handler for notification taps**

In the router or shell widget, set `onNotificationTap`:

```dart
NotificationService.instance.onNotificationTap = (data) {
  // Navigate based on notification type
  final type = data['type'] as String?;
  final id = data['id'] as String?;
  if (type == 'application' && id != null) {
    kolabingRouter.push('/application/$id');
  } else if (type == 'message' && id != null) {
    kolabingRouter.push('/chat/$id');
  }
};
```

**Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: initialize NotificationService and setup notification tap navigation"
```

---

## Task 12: Fix Google Sign In clientId (iOS)

**Files:**
- Modify: `lib/features/auth/services/auth_service.dart`

**Step 1: Pass iOS client ID to GoogleSignIn**

Open `ios/Runner/GoogleService-Info.plist`, find `CLIENT_ID` value.

In `auth_service.dart`, update the `GoogleSignIn` constructor:

```dart
_googleSignIn = googleSignIn ??
    GoogleSignIn(
      clientId: 'YOUR_IOS_CLIENT_ID_FROM_GoogleService-Info.plist',
      scopes: ['email', 'profile'],
    ),
```

**Step 2: Commit**

```bash
git add lib/features/auth/services/auth_service.dart
git commit -m "fix: set iOS clientId for Google Sign In"
```

---

## Task 13: Write Backend API Documentation

**Files:**
- Create: `docs/api/social-auth-push-notifications.md`

Write the backend API documentation (see Task 13 content below).

**Step 1: Create document** (content provided in separate section below)

**Step 2: Commit**

```bash
git add docs/api/social-auth-push-notifications.md
git commit -m "docs: add backend API spec for Apple auth and FCM token registration"
```

---

## Backend API Specification

> **For backend developer:** Implement these 2 endpoints.

---

### POST /api/v1/auth/apple

Authenticate user with Apple Sign In identity token.

**Request:**
```json
POST /api/v1/auth/apple
Content-Type: application/json

{
  "identity_token": "eyJhbGci...",  // Apple JWT identity token
  "name": "John Doe"                // optional, only sent on first sign-in
}
```

**Validation:**
- `identity_token`: required, string
- `name`: optional, string, max 255

**Backend should:**
1. Verify the `identity_token` with Apple's public keys (https://appleid.apple.com/auth/keys)
2. Extract `sub` (Apple user ID) and `email` from the token
3. Find existing user by Apple `sub` OR by email
4. If new user: create user with `user_type` = null (needs to go through onboarding) OR return error asking to register first
5. Return same response format as `/api/v1/auth/google`

**Response (200/201 - success):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "66|bearertoken...",
    "token_type": "Bearer",
    "is_new_user": false,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "user_type": "business",
      "avatar_url": null,
      "email_verified_at": "2026-01-01T00:00:00Z",
      "onboarding_completed": true,
      "created_at": "2026-01-01T00:00:00Z",
      "updated_at": "2026-01-01T00:00:00Z"
    }
  }
}
```

**Response (404 - user not found):**
```json
{
  "success": false,
  "message": "No account found with this Apple ID. Please register first.",
  "errors": null
}
```

**Response (422 - validation error):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "identity_token": ["The identity token field is required."]
  }
}
```

---

### POST /api/v1/me/device-token

Register or update FCM push notification token for the authenticated user.

**Request:**
```json
POST /api/v1/me/device-token
Content-Type: application/json
Authorization: Bearer {user_token}

{
  "token": "fcm_token_string_here",
  "platform": "ios"  // or "android"
}
```

**Validation:**
- `token`: required, string
- `platform`: required, in:ios,android

**Backend should:**
1. Store/update the FCM token for the authenticated user
2. Associate with platform
3. Use this token to send push notifications via Firebase Admin SDK

**Response (200 - success):**
```json
{
  "success": true,
  "message": "Device token registered successfully"
}
```

**Sending notifications from backend:**
```php
// Laravel example using kreait/firebase-php
$messaging = app('firebase.messaging');
$message = CloudMessage::withTarget('token', $deviceToken)
    ->withNotification(Notification::create($title, $body))
    ->withData([
        'type' => 'application',  // or 'message', 'collaboration'
        'id'   => $entityId,
    ]);
$messaging->send($message);
```

**Notification data payload (Flutter reads this for navigation):**
```json
{
  "type": "application",  // application | message | collaboration
  "id": "uuid-of-entity"
}
```

---

## Testing Checklist

- [ ] `flutter run` compiles without errors
- [ ] Google Sign In opens Google account picker on iOS device
- [ ] Google Sign In completes and navigates to correct dashboard
- [ ] Apple Sign In opens Apple auth sheet
- [ ] Apple Sign In completes (requires real device, not simulator)
- [ ] FCM token appears in debug logs after login
- [ ] Backend receives device token registration request
- [ ] Push notification received when app is in background
- [ ] Push notification received when app is in foreground (in-app banner on iOS)
- [ ] Tapping notification navigates to correct screen

---

## Notes

- Apple Sign In **cannot be tested on simulator** — requires physical device
- Google Sign In requires the `REVERSED_CLIENT_ID` URL scheme in Info.plist — otherwise it silently fails
- FCM on iOS requires both Push Notifications capability AND APNs key uploaded to Firebase Console
- The `sign_in_with_apple` package requires iOS 13+ (deployment target is already 15.5 ✅)
