# Attendee Google + Apple Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Google + Apple social signup/login for the attendee user type; new social attendees enter the existing 4-step onboarding with name prefilled. Google ships now; Apple is flag-gated until the backend honors `user_type` (ticket filed).

**Architecture:** Reuse existing `GoogleSignInButton`/`AppleSignInButton` and the existing `signInWithGoogle`/`signInWithApple` auth-provider methods, threading an optional `UserType userTypeHint`. The attendee register screen gains a social section; `resolveAuthDestination` routes a brand-new attendee into onboarding. The Apple button is gated by `Platform.isIOS && FeatureFlags.attendeeAppleSignupEnabled` (default false).

**Tech Stack:** Flutter, Riverpod 3 (Notifier), `google_sign_in 6.2.1`, `sign_in_with_apple 7.0.1`, gen-l10n, `http`/`http/testing` MockClient, `flutter_test`.

Run all commands from the worktree root:
`/Users/volkanoluc/.config/superpowers/worktrees/kolabing-app/feat-attendee-social-login`

---

### Task 1: i18n keys for the social section

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`, `lib/l10n/app_ca.arb`
- Generated: `lib/l10n/app_localizations*.dart` (via `flutter gen-l10n`)

- [ ] **Step 1: Add keys to `app_en.arb`** (after the existing `signInWithGoogle` block, line ~675–680)

```json
  "signInWithApple": "Sign in with Apple",
  "@signInWithApple": {
    "description": "Apple social sign-in button label on auth screens"
  },
  "authOrContinueWith": "or continue with",
  "@authOrContinueWith": {
    "description": "Divider label above social sign-in buttons"
  },
```

- [ ] **Step 2: Add the same keys to `app_es.arb`** (Castilian Spanish)

```json
  "signInWithApple": "Iniciar sesión con Apple",
  "authOrContinueWith": "o continúa con",
```

- [ ] **Step 3: Add the same keys to `app_ca.arb`** (Catalan)

```json
  "signInWithApple": "Inicia sessió amb Apple",
  "authOrContinueWith": "o continua amb",
```

- [ ] **Step 4: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: completes with no error; `AppLocalizations` now exposes `signInWithApple` and `authOrContinueWith`.

- [ ] **Step 5: Verify the getters exist**

Run: `grep -n "signInWithApple\|authOrContinueWith" lib/l10n/app_localizations.dart`
Expected: both appear as abstract getters.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "i18n(auth): add signInWithApple + authOrContinueWith (en/es/ca)"
```

---

### Task 2: Feature flag

**Files:**
- Create: `lib/config/constants/feature_flags.dart`
- Test: `test/config/constants/feature_flags_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/constants/feature_flags.dart';

void main() {
  test('attendee Apple signup is off by default (pending backend user_type)', () {
    expect(FeatureFlags.attendeeAppleSignupEnabled, isFalse);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/config/constants/feature_flags_test.dart`
Expected: FAIL — `feature_flags.dart` does not exist / `FeatureFlags` undefined.

- [ ] **Step 3: Create the flag**

```dart
/// Compile-time feature flags.
///
/// Flip [attendeeAppleSignupEnabled] to `true` only after the backend
/// `POST /auth/apple` accepts and honors `user_type` (see
/// kolabing-v2 ticket 2026-06-11-attendee-apple-social-usertype). Until then,
/// a new Apple user would be created with the backend's default type, so the
/// Apple button stays hidden on the attendee surface.
abstract final class FeatureFlags {
  const FeatureFlags._();

  static const bool attendeeAppleSignupEnabled = false;
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/config/constants/feature_flags_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/config/constants/feature_flags.dart test/config/constants/feature_flags_test.dart
git commit -m "feat(config): add attendeeAppleSignupEnabled feature flag (default off)"
```

---

### Task 3: auth_service — pass `user_type` on Apple login

**Files:**
- Modify: `lib/features/auth/services/auth_service.dart` (`loginWithApple` ~761; `_authenticateWithApple` ~779)
- Test: `test/features/auth/services/apple_user_type_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  http.Response _ok() => http.Response(
        jsonEncode(<String, dynamic>{
          'data': <String, dynamic>{
            'token': 't-1',
            'token_type': 'Bearer',
            'is_new_user': true,
            'user': <String, dynamic>{
              'id': 'a-1',
              'email': 'a@example.com',
              'user_type': 'attendee',
            },
          },
        }),
        200,
      );

  test('authenticateWithApple includes user_type when provided', () async {
    Map<String, dynamic>? sentBody;
    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _ok();
      }),
    );

    await service.authenticateWithApple('id-tok', 'Jane Doe', userType: 'attendee');

    expect(sentBody?['identity_token'], 'id-tok');
    expect(sentBody?['name'], 'Jane Doe');
    expect(sentBody?['user_type'], 'attendee');
  });

  test('authenticateWithApple omits user_type when null', () async {
    Map<String, dynamic>? sentBody;
    final service = AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return _ok();
      }),
    );

    await service.authenticateWithApple('id-tok', null);

    expect(sentBody?['identity_token'], 'id-tok');
    expect(sentBody?.containsKey('user_type'), isFalse);
    expect(sentBody?.containsKey('name'), isFalse);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/auth/services/apple_user_type_test.dart`
Expected: FAIL — `authenticateWithApple` is not defined (currently private `_authenticateWithApple` with no `userType`).

- [ ] **Step 3: Update `loginWithApple` to accept and forward `userType`**

Replace the existing `loginWithApple` (lines ~761–777) with:

```dart
  /// Login / sign up with Apple.
  ///
  /// POST /api/v1/auth/apple
  ///
  /// [userType] (api value e.g. `'attendee'`) is forwarded so the backend can
  /// create a new account with the requested role. Harmless for existing users.
  Future<AuthResponse> loginWithApple({String? userType}) async {
    try {
      final credential = await getAppleCredential();
      return await authenticateWithApple(
        credential.identityToken,
        credential.fullName,
        userType: userType,
      );
    } on AuthCancelledException {
      rethrow;
    } on Exception catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('Apple login error: $e');
      throw AuthException('Apple login failed: $e');
    }
  }
```

- [ ] **Step 4: Rename `_authenticateWithApple` → `authenticateWithApple` (visibleForTesting) and add `userType` to the body**

Replace the method signature/body opener (lines ~779–797) with:

```dart
  @visibleForTesting
  Future<AuthResponse> authenticateWithApple(
    String identityToken,
    String? fullName, {
    String? userType,
  }) async {
    final url = '$_baseUrl/auth/apple';
    debugPrint('[Apple] Login: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'identity_token': identityToken,
          if (fullName != null) 'name': fullName,
          if (userType != null) 'user_type': userType,
        }),
      );
```

Leave the rest of the method body (the `if (statusCode == 200 || 201)` handling) unchanged.

Note: `package:flutter/foundation.dart` (already imported for `debugPrint`) provides `@visibleForTesting`.

- [ ] **Step 5: Run the test**

Run: `flutter test test/features/auth/services/apple_user_type_test.dart`
Expected: PASS (both tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/services/auth_service.dart test/features/auth/services/apple_user_type_test.dart
git commit -m "feat(auth): forward user_type on Apple login (testable seam)"
```

---

### Task 4: auth_provider — `userTypeHint` on social sign-in + honor Google `is_new_user`

**Files:**
- Modify: `lib/features/auth/providers/auth_provider.dart` (`signInWithGoogle` ~215; `signInWithApple` ~430)
- Test: `test/features/auth/providers/social_user_type_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';

class _RecordingAuthService extends AuthService {
  String? googleUserType;
  String? appleUserType;

  AuthResponse _attendee() => const AuthResponse(
        success: true,
        message: 'ok',
        token: 't-1',
        tokenType: 'Bearer',
        isNewUser: true,
        user: UserModel(
          id: 'a-1',
          email: 'a@example.com',
          userType: UserType.attendee,
          name: 'Jane Doe',
        ),
      );

  @override
  Future<AuthResponse> loginWithGoogle({String? userType}) async {
    googleUserType = userType;
    return _attendee();
  }

  @override
  Future<AuthResponse> loginWithApple({String? userType}) async {
    appleUserType = userType;
    return _attendee();
  }

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  test('signInWithGoogle forwards attendee hint and honors is_new_user', () async {
    final service = _RecordingAuthService();
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(authProvider.notifier)
        .signInWithGoogle(userTypeHint: UserType.attendee);
    await Future<void>.delayed(Duration.zero);

    expect(service.googleUserType, 'attendee');
    expect(result.success, isTrue);
    expect(result.isNewUser, isTrue);
    expect(result.user?.isAttendee, isTrue);
  });

  test('signInWithApple forwards attendee hint', () async {
    final service = _RecordingAuthService();
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(authProvider.notifier)
        .signInWithApple(userTypeHint: UserType.attendee);
    await Future<void>.delayed(Duration.zero);

    expect(service.appleUserType, 'attendee');
    expect(result.isNewUser, isTrue);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/auth/providers/social_user_type_test.dart`
Expected: FAIL — `signInWithGoogle`/`signInWithApple` do not accept `userTypeHint`.

- [ ] **Step 3: Update `signInWithGoogle`**

Change the signature and the two lines that call the service / set isNewUser. Replace the method header + body top (lines ~215–226) so it reads:

```dart
  Future<AuthResult> signInWithGoogle({UserType? userTypeHint}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _authService.loginWithGoogle(
        userType: userTypeHint?.toApiValue(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
        isNewUser: response.isNewUser,
      );
      _invalidateAfterSignIn();
```

Then update the success return (line ~237) from `isNewUser: false` to:

```dart
      return AuthResult(
        success: true,
        isNewUser: response.isNewUser,
        user: response.user,
      );
```

(Leave the `catch` blocks unchanged.)

- [ ] **Step 4: Update `signInWithApple`**

Change only the signature + the service call (lines ~430–434):

```dart
  Future<AuthResult> signInWithApple({UserType? userTypeHint}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _authService.loginWithApple(
        userType: userTypeHint?.toApiValue(),
      );
```

(The rest already uses `response.isNewUser`.)

- [ ] **Step 5: Run the test**

Run: `flutter test test/features/auth/providers/social_user_type_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/providers/auth_provider.dart test/features/auth/providers/social_user_type_test.dart
git commit -m "feat(auth): userTypeHint on social sign-in; honor Google is_new_user"
```

---

### Task 5: routing — new attendee → onboarding

**Files:**
- Modify: `lib/features/auth/utils/auth_navigation.dart` (lines 7–10)
- Test: `test/features/auth/utils/auth_navigation_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/utils/auth_navigation.dart';

void main() {
  const attendee = UserModel(
    id: 'a-1',
    email: 'a@example.com',
    userType: UserType.attendee,
  );
  const business = UserModel(
    id: 'b-1',
    email: 'b@example.com',
    userType: UserType.business,
  );

  test('new attendee routes into onboarding step 1', () {
    expect(
      resolveAuthDestination(attendee, isNewUser: true),
      KolabingRoutes.attendeeOnboardingStep1,
    );
  });

  test('existing attendee routes to the attendee dashboard', () {
    expect(
      resolveAuthDestination(attendee, isNewUser: false),
      KolabingRoutes.attendeeDashboard,
    );
  });

  test('new business still routes to business onboarding (regression)', () {
    expect(
      resolveAuthDestination(business, isNewUser: true),
      KolabingRoutes.businessOnboardingStep5,
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/auth/utils/auth_navigation_test.dart`
Expected: FAIL — new attendee currently returns `attendeeDashboard`, not `attendeeOnboardingStep1`.

- [ ] **Step 3: Update the attendee branch**

Replace lines 7–10 of `auth_navigation.dart`:

```dart
String resolveAuthDestination(UserModel user, {bool isNewUser = false}) {
  if (user.isAttendee) {
    // A brand-new social attendee (Google/Apple is_new_user) runs the 4-step
    // onboarding (name/handle/interests/join) just like the email/password
    // path; an existing attendee goes straight to their dashboard.
    return isNewUser
        ? KolabingRoutes.attendeeOnboardingStep1
        : KolabingRoutes.attendeeDashboard;
  }
```

(Leave the rest of the function unchanged.)

- [ ] **Step 4: Run the test**

Run: `flutter test test/features/auth/utils/auth_navigation_test.dart`
Expected: PASS (all three).

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/utils/auth_navigation.dart test/features/auth/utils/auth_navigation_test.dart
git commit -m "feat(auth): route new social attendees into onboarding"
```

---

### Task 6: attendee register screen — social section + handlers

**Files:**
- Modify: `lib/features/auth/screens/attendee_register_screen.dart`
- Test: `test/features/auth/screens/attendee_register_social_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/auth/screens/attendee_register_screen.dart';
import 'package:kolabing_app/features/auth/widgets/apple_sign_in_button.dart';
import 'package:kolabing_app/features/auth/widgets/google_sign_in_button.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AttendeeRegisterScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows Google button; Apple hidden while flag off', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    // attendeeAppleSignupEnabled is false by default → no Apple button.
    expect(find.byType(AppleSignInButton), findsNothing);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/auth/screens/attendee_register_social_test.dart`
Expected: FAIL — `GoogleSignInButton` is not in the screen yet (`findsNothing` vs `findsOneWidget`).

- [ ] **Step 3: Add imports** at the top of `attendee_register_screen.dart`

```dart
import 'dart:io';
```
and (with the other relative imports):
```dart
import '../../../config/constants/feature_flags.dart';
import '../../../config/routes/routes.dart';
import '../../onboarding/providers/attendee_onboarding_provider.dart';
import '../models/user_model.dart';
import '../utils/auth_navigation.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/google_sign_in_button.dart';
```

- [ ] **Step 4: Add social loading state fields**

In `_AttendeeRegisterScreenState`, next to `bool _isLoading = false;`:

```dart
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _anyLoading => _isLoading || _isGoogleLoading || _isAppleLoading;
```

- [ ] **Step 5: Add the social handlers** (place after `_handleRegister`)

```dart
  Future<void> _handleGoogleSignUp() async {
    if (_anyLoading || _showSuccess) return;
    setState(() => _isGoogleLoading = true);
    await _runSocial(
      () => ref
          .read(authProvider.notifier)
          .signInWithGoogle(userTypeHint: UserType.attendee),
      onDone: () {
        if (mounted) setState(() => _isGoogleLoading = false);
      },
    );
  }

  Future<void> _handleAppleSignUp() async {
    if (_anyLoading || _showSuccess) return;
    setState(() => _isAppleLoading = true);
    await _runSocial(
      () => ref
          .read(authProvider.notifier)
          .signInWithApple(userTypeHint: UserType.attendee),
      onDone: () {
        if (mounted) setState(() => _isAppleLoading = false);
      },
    );
  }

  Future<void> _runSocial(
    Future<AuthResult> Function() action, {
    required VoidCallback onDone,
  }) async {
    try {
      final result = await action();
      if (!mounted) return;

      if (result.success && result.user != null) {
        final user = result.user!;
        // Best-effort name prefill for a brand-new attendee.
        if (result.isNewUser &&
            user.isAttendee &&
            (user.name?.trim().isNotEmpty ?? false)) {
          ref.read(attendeeOnboardingProvider.notifier).updateName(user.name!.trim());
        }
        setState(() {
          _isGoogleLoading = false;
          _isAppleLoading = false;
          _showSuccess = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        context.go(resolveAuthDestination(user, isNewUser: result.isNewUser));
        return;
      }

      onDone();
      if (result.cancelled) return;
      if (result.isNetworkError) {
        _showNetworkErrorSnackBar();
      } else {
        _showErrorSnackBar(
          result.displayError.isNotEmpty
              ? result.displayError
              : AppLocalizations.of(context).authUnexpectedError,
        );
      }
    } on Object catch (e) {
      debugPrint('[attendee social] $e');
      if (!mounted) return;
      onDone();
      _showErrorSnackBar(AppLocalizations.of(context).authUnexpectedError);
    }
  }
```

Add the imports these reference at the top if missing: `import '../models/auth_response.dart';` is already present (provides `AuthResult`? No — `AuthResult` lives in `auth_provider.dart`, already imported). `debugPrint` needs `import 'package:flutter/foundation.dart';` — add it.

Note: confirm `AuthResult.displayError` and `AuthResult.isNetworkError` exist (they are used by `login_screen.dart`). If `displayError` is absent, use `result.errorMessage ?? result.error?.message ?? ''`.

- [ ] **Step 6: Render the social section** — inside the `Form` `Column`, replace the trailing `const SizedBox(height: 24),` (line ~393, right before the closing of the inner column) with:

```dart
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                AppLocalizations.of(context).authOrContinueWith,
                                style: KolabingTextStyles.bodySmall.copyWith(
                                  color: KolabingColors.textTertiary,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google (always available)
                        GoogleSignInButton(
                          onPressed: _handleGoogleSignUp,
                          buttonText:
                              AppLocalizations.of(context).signInWithGoogle,
                          isLoading: _isGoogleLoading,
                          showSuccess: _showSuccess,
                          isEnabled: !_anyLoading && !_showSuccess,
                        ),

                        // Apple (iOS only, gated until backend honors user_type)
                        if (Platform.isIOS &&
                            FeatureFlags.attendeeAppleSignupEnabled) ...[
                          const SizedBox(height: 12),
                          AppleSignInButton(
                            onPressed: _handleAppleSignUp,
                            buttonText:
                                AppLocalizations.of(context).signInWithApple,
                            isLoading: _isAppleLoading,
                            showSuccess: _showSuccess,
                            isEnabled: !_anyLoading && !_showSuccess,
                          ),
                        ],
                        const SizedBox(height: 24),
```

- [ ] **Step 7: Disable the email button + back while a social flow runs**

Change `onPressed: _isLoading ? null : _handleRegister,` (line ~409) to
`onPressed: _anyLoading ? null : _handleRegister,` and the loading spinner check
`_isLoading` (line ~420) to `_anyLoading`. Change the header back tap guard
`onTap: _isLoading ? null : _handleBack,` (line ~256) to `onTap: _anyLoading ? null : _handleBack,`.

- [ ] **Step 8: Run the widget test**

Run: `flutter test test/features/auth/screens/attendee_register_social_test.dart`
Expected: PASS (Google found, Apple not found).

- [ ] **Step 9: Analyze the touched files**

Run: `dart analyze lib/features/auth/screens/attendee_register_screen.dart`
Expected: No issues. (Fix any unused import / missing `displayError` per the Step-5 note.)

- [ ] **Step 10: Commit**

```bash
git add lib/features/auth/screens/attendee_register_screen.dart test/features/auth/screens/attendee_register_social_test.dart
git commit -m "feat(auth): Google/Apple social signup on the attendee register screen"
```

---

### Task 7: Backend ticket in kolabing-v2

**Files:**
- Create: `/Users/volkanoluc/Projects/kolabing-v2/docs/tickets/2026-06-11-attendee-apple-social-usertype.md`

- [ ] **Step 1: Write the ticket** (content below), describing the `POST /auth/apple` change to accept + honor `user_type`, mirroring `POST /auth/google`; auto-create `attendee_profiles`; return `is_new_user`; `onboarding_completed=false` for a fresh social attendee. Reference the Google controller as the template.

- [ ] **Step 2: Commit in the backend repo**

```bash
git -C /Users/volkanoluc/Projects/kolabing-v2 add docs/tickets/2026-06-11-attendee-apple-social-usertype.md
git -C /Users/volkanoluc/Projects/kolabing-v2 commit -m "docs(ticket): /auth/apple accept user_type for attendee social signup"
```

(Do not push; leave for review.)

---

### Task 8: Full verification

- [ ] **Step 1: Analyze**

Run: `dart analyze`
Expected: 0 errors.

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: all green (baseline 177 + new tests).

- [ ] **Step 3: No new hardcoded user-facing strings** — confirm the attendee screen uses `AppLocalizations` for the divider + button text (brand names "Google"/"Apple" on `login_screen` are exempt and untouched).

- [ ] **Step 4: Update BACKLOG.md** — add the feature under Incomplete Features (Google live, Apple flag-gated pending backend), then commit.

---

## Self-review notes
- Spec coverage: flag (T2), Apple user_type service (T3), provider hints + Google is_new_user (T4), routing (T5), screen + name prefill (T6), backend ticket (T7), i18n (T1), verify (T8). All spec sections mapped.
- Deviation from spec §7: `login_screen` button labels `'Google'`/`'Apple'` are **brand names** (i18n-rule exempt) and stay as-is — avoids churning the existing `login_screen_test` assertions (`find.text('Google'|'Apple')`). The attendee screen uses the localized full phrases.
- The flag=true + iOS Apple-visible path can't run on the test host (`Platform.isIOS` false); verify manually on an iOS sim/device after flipping the flag.
