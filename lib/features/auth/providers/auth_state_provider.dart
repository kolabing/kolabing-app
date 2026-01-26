import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      // Check authentication status
      final session = Supabase.instance.client.auth.currentSession;

      if (session == null) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.signIn,
        );
        return '/auth/sign-in';
      }

      // Get user type from profile
      final userType = await _getUserType(session.user.id);

      if (userType == 'business') {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.businessDashboard,
        );
        return '/business';
      } else {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.communityDashboard,
        );
        return '/community';
      }
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

  /// Get user type from Supabase profile
  Future<String> _getUserType(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('user_type')
          .eq('id', userId)
          .single();

      final userType = response['user_type'];
      return userType is String ? userType : 'community';
    } on Exception {
      // Default to community if profile fetch fails
      return 'community';
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
