import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/notification_service.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

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
  }) =>
      AuthState(
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
  @override
  AuthState build() {
    NotificationService.instance.onTokenRefresh((token) {
      _authService.registerDeviceToken(token);
    });
    return const AuthState();
  }

  AuthService get _authService => ref.read(authServiceProvider);

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

      unawaited(_registerFcmToken());

      return AuthResult(
        success: true,
        isNewUser: false,
        user: response.user,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.error.message,
      );
      return AuthResult(
        success: false,
        error: e.error,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.message,
      );
      return AuthResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Exception catch (e) {
      debugPrint('Sign in error: $e');
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
  Future<AuthResult> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _authService.loginWithGoogle();

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
        isNewUser: false,
      );

      unawaited(_registerFcmToken());

      return AuthResult(
        success: true,
        isNewUser: false,
        user: response.user,
      );
    } on AuthCancelledException {
      // User cancelled, return to previous state
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return const AuthResult(
        success: false,
        cancelled: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.error.message,
      );
      return AuthResult(
        success: false,
        error: e.error,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.message,
      );
      return AuthResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Exception catch (e) {
      debugPrint('Sign in error: $e');
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
        final user = await _authService.getCurrentUser();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } on Exception catch (e) {
      debugPrint('Check auth status error: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Delete FCM token so this device stops receiving notifications
      await NotificationService.instance.deleteToken();
      await _authService.logout();
    } on Exception catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Clear any error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: null,
      );
    }
  }

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

  /// Sign in with Apple (existing users only)
  Future<AuthResult> signInWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);

    try {
      final response = await _authService.loginWithApple();

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        token: response.token,
        isNewUser: response.isNewUser,
      );

      unawaited(_registerFcmToken());

      return AuthResult(
        success: true,
        isNewUser: response.isNewUser,
        user: response.user,
      );
    } on AuthCancelledException {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return const AuthResult(
        success: false,
        cancelled: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.error.message,
      );
      return AuthResult(
        success: false,
        error: e.error,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: e.message,
      );
      return AuthResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Exception catch (e) {
      debugPrint('Apple sign in error: $e');
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
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

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

  return authState.isNewUser || !authState.user!.onboardingCompleted;
});

/// Provider for getting navigation route after auth
final authNavigationRouteProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }

  final user = authState.user!;

  // Attendees skip onboarding
  if (user.isAttendee) return '/attendee';

  // New users or incomplete onboarding -> onboarding
  if (authState.isNewUser || !user.onboardingCompleted) {
    return '/onboarding';
  }

  // Existing users -> dashboard based on type
  return user.isBusiness ? '/business' : '/community';
});
