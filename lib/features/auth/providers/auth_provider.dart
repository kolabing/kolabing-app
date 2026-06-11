import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../services/analytics/analytics_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/one_signal_service.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/auth_navigation.dart';
import '../utils/session_reset.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Auth state for the application
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.isNewUser = false,
    this.error,
  });

  /// Current authentication status
  final AuthStatus status;

  /// Current authenticated user
  final UserModel? user;

  /// Auth token
  final String? token;

  /// Whether the user is a new registration
  final bool isNewUser;

  /// Error message if authentication failed
  final String? error;

  /// Whether user is authenticated
  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  /// Whether authentication is in progress
  bool get isLoading => status == AuthStatus.loading;

  /// Whether there was an error
  bool get hasError => status == AuthStatus.error && error != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? token,
    bool? isNewUser,
    String? error,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    token: token ?? this.token,
    isNewUser: isNewUser ?? this.isNewUser,
    error: error,
  );

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.email}, isNewUser: $isNewUser)';
}

/// Authentication status
enum AuthStatus {
  /// Initial state, not yet checked
  initial,

  /// Checking authentication status
  loading,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Authentication failed with error
  error,
}

/// Auth state notifier for managing authentication
class AuthNotifier extends Notifier<AuthState> {
  StreamSubscription<AuthSessionChange>? _sessionChangeSubscription;
  bool _isExplicitLogoutInProgress = false;
  bool _userScopedInvalidationScheduled = false;

  @override
  AuthState build() {
    _sessionChangeSubscription ??= AuthService.sessionChanges.listen(
      _handleSessionChange,
    );
    ref.onDispose(() {
      unawaited(_sessionChangeSubscription?.cancel());
      _sessionChangeSubscription = null;
    });

    if (Firebase.apps.isNotEmpty) {
      NotificationService.instance.onTokenRefresh((token) {
        unawaited(_registerDeviceToken(token));
      });
    }
    return const AuthState();
  }

  AuthService get _authService => ref.read(authServiceProvider);

  void _handleSessionChange(AuthSessionChange change) {
    if (change != AuthSessionChange.cleared || _isExplicitLogoutInProgress) {
      return;
    }

    if (state.status == AuthStatus.unauthenticated &&
        state.user == null &&
        state.token == null) {
      return;
    }

    state = const AuthState(status: AuthStatus.unauthenticated);
    _scheduleUserScopedInvalidation();
    unawaited(AnalyticsService.instance.reset());
    unawaited(OneSignalService.instance.logout());
  }

  void _scheduleUserScopedInvalidation() {
    if (_userScopedInvalidationScheduled) {
      return;
    }

    _userScopedInvalidationScheduled = true;
    Future<void>.microtask(() {
      _userScopedInvalidationScheduled = false;
      invalidateUserScopedProviders(ref);
    });
  }

  /// Tear down the previous account's user-scoped providers right after a NEW
  /// account signs in (account switch). Without this, kept-alive Notifiers
  /// (chat inbox, unread badge, dashboard, community) keep serving the prior
  /// user's cached data until a manual refresh — FX-9. The token is already
  /// rotated by [AuthService] at this point, so the rebuild refetches as the
  /// new user. Scheduled as a microtask so it runs after the authenticated
  /// state has propagated.
  void _invalidateAfterSignIn() => _scheduleUserScopedInvalidation();

  /// Sign in with email and password
  ///
  /// Returns AuthResult with success/failure information
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _authService.loginWithEmail(
        email: email,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
        isNewUser: false,
      );
      _invalidateAfterSignIn();

      unawaited(_syncPushIdentity(response.user));
      unawaited(
        AnalyticsService.instance.capture(
          AnalyticsEvents.userLoggedIn,
          properties: {'method': 'email'},
        ),
      );

      return AuthResult(success: true, isNewUser: false, user: response.user);
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.error.message);
      return AuthResult(success: false, error: e.error);
    } on NetworkException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.message);
      return AuthResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Object catch (e, st) {
      debugPrint('Sign in error: $e');
      debugPrint('$st');
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'An unexpected error occurred',
      );
      return const AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Sign in with Google (existing users only)
  ///
  /// Returns AuthResult with success/failure information
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

      unawaited(_syncPushIdentity(response.user));
      unawaited(
        AnalyticsService.instance.capture(
          AnalyticsEvents.userLoggedIn,
          properties: {'method': 'google'},
        ),
      );

      return AuthResult(
        success: true,
        isNewUser: response.isNewUser,
        user: response.user,
      );
    } on AuthCancelledException {
      // User cancelled, return to previous state
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return const AuthResult(success: false, cancelled: true);
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.error.message);
      return AuthResult(success: false, error: e.error);
    } on NetworkException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.message);
      return AuthResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Object catch (e, st) {
      debugPrint('Sign in error: $e');
      debugPrint('$st');
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'An unexpected error occurred',
      );
      return const AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final isAuthenticated = await _authService.isAuthenticated();

      if (isAuthenticated) {
        final token = await _authService.getToken();
        final user = await _authService.restoreSessionUser();
        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            token: token,
          );
          unawaited(_syncPushIdentity(user));
        } else {
          unawaited(OneSignalService.instance.logout());
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      } else {
        unawaited(OneSignalService.instance.logout());
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } on Exception catch (e) {
      debugPrint('Check auth status error: $e');
      unawaited(OneSignalService.instance.logout());
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Call after a successful REGISTRATION (account creation) — onboarding
  /// (business/community) and attendee register.
  Future<void> onRegistered() async {
    await checkAuthStatus();
    final user = state.user;
    if (user != null) {
      unawaited(
        AnalyticsService.instance.capture(
          AnalyticsEvents.userSignedUp,
          properties: {'user_type': user.userType.toApiValue()},
        ),
      );
    }
    unawaited(_registerFcmToken());
  }

  /// Logout current user
  Future<void> logout() async {
    _isExplicitLogoutInProgress = true;
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final fcmToken = await NotificationService.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _authService.removeDeviceToken(fcmToken);
      }

      // Delete FCM token so this device stops receiving notifications
      await NotificationService.instance.deleteToken();
      await OneSignalService.instance.logout();
      unawaited(AnalyticsService.instance.reset());
      await _authService.logout();
    } on Exception catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // Publish the signed-out auth state FIRST so the app can immediately
      // leave protected shells before any always-mounted tab provider rebuilds
      // into a "session expired" error screen during teardown.
      state = const AuthState(status: AuthStatus.unauthenticated);
      _scheduleUserScopedInvalidation();

      _isExplicitLogoutInProgress = false;
    }
  }

  /// Sync a freshly-updated [UserModel] into auth state and the session cache,
  /// without a full re-auth. Used when a flow already holds the updated user
  /// (e.g. persisting the home city via `PUT /me/profile`).
  Future<void> syncUser(UserModel user) async {
    if (!state.isAuthenticated) return;
    await _authService.cacheUser(user);
    state = state.copyWith(user: user);
  }

  /// Clear any error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: null);
    }
  }

  Future<void> _registerFcmToken() async {
    await _registerFcmTokenWithRetry();
  }

  Future<void> syncPushPermissionGrant() async {
    final user = state.user;
    if (!state.isAuthenticated || user == null) {
      return;
    }

    try {
      await OneSignalService.instance.syncUserAfterPermissionGrant(user);
    } on Exception catch (e) {
      debugPrint('[OneSignal] Post-permission sync error: $e');
    }

    await _registerFcmTokenWithRetry(attempts: 4);
  }

  Future<void> _registerFcmTokenWithRetry({int attempts = 1}) async {
    try {
      for (var attempt = 0; attempt < attempts; attempt++) {
        final fcmToken = await NotificationService.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _registerDeviceToken(fcmToken);
          return;
        }

        if (attempt < attempts - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 750));
        }
      }
    } on Exception catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  Future<void> _syncPushIdentity(UserModel user) async {
    // Identify the user in analytics (idempotent; also covers session restore).
    unawaited(AnalyticsService.instance.identify(user));

    try {
      await OneSignalService.instance.loginUser(user);
    } on Exception catch (e) {
      debugPrint('[OneSignal] Identity sync error: $e');
    }

    await _registerFcmToken();
  }

  Future<void> _registerDeviceToken(String fcmToken) async {
    String? appVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } on Exception catch (e) {
      debugPrint('[FCM] Package info unavailable: $e');
    }

    final locale = PlatformDispatcher.instance.locale.languageCode;
    final timezone = DateTime.now().timeZoneName;

    await _authService.registerDeviceToken(
      fcmToken,
      appVersion: appVersion,
      locale: locale,
      timezone: timezone,
    );
  }

  /// Sign in with Apple (existing users only)
  Future<AuthResult> signInWithApple({UserType? userTypeHint}) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _authService.loginWithApple(
        userType: userTypeHint?.toApiValue(),
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
        isNewUser: response.isNewUser,
      );
      _invalidateAfterSignIn();

      unawaited(_syncPushIdentity(response.user));
      unawaited(
        AnalyticsService.instance.capture(
          AnalyticsEvents.userLoggedIn,
          properties: {'method': 'apple'},
        ),
      );

      return AuthResult(
        success: true,
        isNewUser: response.isNewUser,
        user: response.user,
      );
    } on AuthCancelledException {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return const AuthResult(success: false, cancelled: true);
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.error.message);
      return AuthResult(success: false, error: e.error);
    } on NetworkException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.message);
      return AuthResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Object catch (e, st) {
      debugPrint('Apple sign in error: $e');
      debugPrint('$st');
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'An unexpected error occurred',
      );
      return const AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }
}

/// Provider for authentication state
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Result of authentication attempt
class AuthResult {
  const AuthResult({
    required this.success,
    this.isNewUser = false,
    this.user,
    this.error,
    this.errorMessage,
    this.cancelled = false,
    this.isNetworkError = false,
  });

  /// Whether authentication was successful
  final bool success;

  /// Whether this is a new user registration
  final bool isNewUser;

  /// The authenticated user
  final UserModel? user;

  /// API error if authentication failed
  final ApiError? error;

  /// Error message if authentication failed
  final String? errorMessage;

  /// Whether user cancelled the sign in
  final bool cancelled;

  /// Whether error was due to network issues
  final bool isNetworkError;

  /// Whether this is a user type mismatch error
  bool get isUserTypeMismatch => error?.isUserTypeMismatch ?? false;

  /// Whether user was not found (for Google login)
  bool get isUserNotFound {
    if (error == null) return false;
    // Check for 404 status or user not found message
    return error!.statusCode == 404 ||
        error!.message.toLowerCase().contains('not found') ||
        error!.message.toLowerCase().contains('no account');
  }

  /// Get user-friendly error message to display
  String get displayError {
    if (error != null) {
      return _toFriendlyMessage(error!.message);
    }
    return errorMessage != null
        ? _toFriendlyMessage(errorMessage!)
        : 'Something went wrong. Please try again.';
  }

  /// Maps technical API messages to user-friendly copy.
  static String _toFriendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid credentials') ||
        lower.contains('credentials are incorrect') ||
        lower.contains('unauthorized')) {
      return 'Incorrect email or password. Please check and try again.';
    }
    if (lower.contains('too many') || lower.contains('throttle')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('not found') || lower.contains('no account')) {
      return 'No account found with this email. Would you like to sign up?';
    }
    if (lower.contains('already exists') || lower.contains('already taken')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (lower.contains('email') && lower.contains('verified')) {
      return 'Please verify your email before signing in.';
    }
    return raw;
  }

  /// Get the existing user type from mismatch error
  UserType? get existingUserType {
    if (!isUserTypeMismatch) return null;

    final errorMsg = error?.errors?['user_type']?.firstOrNull ?? '';
    if (errorMsg.toLowerCase().contains('business')) {
      return UserType.business;
    } else if (errorMsg.toLowerCase().contains('community')) {
      return UserType.community;
    }
    return null;
  }
}

/// Provider for checking if user should see onboarding
final shouldShowOnboardingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated || authState.user == null) {
    return false;
  }

  // Onboarding is mandatory at registration; existing logged-in accounts have
  // already completed it. Only OAuth-newly-created users (`is_new_user: true`)
  // need to run onboarding.
  return authState.isNewUser;
});

/// Provider for getting navigation route after auth
final authNavigationRouteProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }

  final user = authState.user!;
  return resolveAuthDestination(user, isNewUser: authState.isNewUser);
});
