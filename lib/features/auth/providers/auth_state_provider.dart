import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/permission_service.dart';
import '../services/auth_service.dart';

/// Key for storing onboarding completion status
const String _onboardingCompletedKey = 'onboarding_completed';

/// Represents the navigation destination after splash screen
enum SplashNavigationTarget {
  /// User has not completed onboarding
  onboarding,

  /// User is not authenticated
  signIn,

  /// User is authenticated as business
  businessDashboard,

  /// User is authenticated as community
  communityDashboard,

  /// User is authenticated as attendee
  attendeeDashboard,
}

/// State for splash screen initialization
class SplashState {
  const SplashState({
    this.isLoading = true,
    this.navigationTarget,
    this.errorMessage,
  });

  /// Whether the splash screen is still loading
  final bool isLoading;

  /// The navigation target after splash screen
  final SplashNavigationTarget? navigationTarget;

  /// Error message if initialization failed
  final String? errorMessage;

  /// Whether initialization completed successfully
  bool get isComplete => !isLoading && navigationTarget != null;

  /// Whether there was an error during initialization
  bool get hasError => errorMessage != null;

  SplashState copyWith({
    bool? isLoading,
    SplashNavigationTarget? navigationTarget,
    String? errorMessage,
  }) =>
      SplashState(
        isLoading: isLoading ?? this.isLoading,
        navigationTarget: navigationTarget ?? this.navigationTarget,
        errorMessage: errorMessage,
      );
}

/// Notifier for managing splash screen state
class SplashStateNotifier extends Notifier<SplashState> {
  @override
  SplashState build() => const SplashState();

  /// Initialize the app and determine navigation target
  ///
  /// This runs in parallel with the splash animation.
  /// Returns the navigation target route path.
  Future<String> initialize() async {
    try {
      // Check onboarding status
      final hasCompletedOnboarding = await _checkOnboardingStatus();

      if (!hasCompletedOnboarding) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.onboarding,
        );
        return '/onboarding';
      }

      // Check authentication status via stored token
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.signIn,
        );
        return '/auth/sign-in';
      }

      // Get user type from stored user data
      final user = await authService.getStoredUser();

      final String dashboard;
      final SplashNavigationTarget navTarget;
      if (user?.isAttendee ?? false) {
        dashboard = '/attendee';
        navTarget = SplashNavigationTarget.attendeeDashboard;
      } else if (user?.isBusiness ?? false) {
        dashboard = '/business';
        navTarget = SplashNavigationTarget.businessDashboard;
      } else {
        dashboard = '/community';
        navTarget = SplashNavigationTarget.communityDashboard;
      }

      // Check if the permission screen needs to be shown
      final hasShownPermissions =
          await PermissionService.instance.hasShownPermissionScreen();

      if (!hasShownPermissions) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: navTarget,
        );
        return '/permissions?destination=${Uri.encodeComponent(dashboard)}';
      }

      state = state.copyWith(
        isLoading: false,
        navigationTarget: navTarget,
      );
      return dashboard;
    } on Exception catch (e) {
      // On error, default to sign in
      state = state.copyWith(
        isLoading: false,
        navigationTarget: SplashNavigationTarget.signIn,
        errorMessage: 'Failed to initialize: $e',
      );
      return '/auth/sign-in';
    }
  }

  /// Check if user has completed onboarding
  Future<bool> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } on Exception {
      // If we cannot read preferences, assume onboarding not completed
      return false;
    }
  }

}

/// Provider for splash screen state and initialization logic
final splashStateProvider =
    NotifierProvider<SplashStateNotifier, SplashState>(SplashStateNotifier.new);

/// Provider for checking and setting onboarding status
final onboardingStatusProvider =
    Provider<OnboardingStatus>((ref) => OnboardingStatus());

/// Utility class for managing onboarding status
class OnboardingStatus {
  /// Check if onboarding has been completed
  Future<bool> hasCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } on Exception {
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
    } on Exception {
      // Silently fail - user will see onboarding again
    }
  }

  /// Reset onboarding status (for testing/development)
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
    } on Exception {
      // Silently fail
    }
  }
}
