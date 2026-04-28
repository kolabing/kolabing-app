import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/routes/routes.dart';
import '../../../services/permission_service.dart';
import '../services/auth_service.dart';
import '../utils/auth_navigation.dart';

/// Represents the navigation destination after splash screen
enum SplashNavigationTarget {
  /// User is not authenticated yet
  welcome,

  /// User needs to complete business onboarding
  businessOnboarding,

  /// User needs to complete community onboarding
  communityOnboarding,

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
  }) => SplashState(
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
      final authService = AuthService();
      final token = await authService.getToken();
      final storedUser = await authService.getStoredUser();

      // Fresh launches should land on the welcome chooser, not jump straight
      // into onboarding, unless we already know there is an authenticated user
      // who needs to continue onboarding.
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.welcome,
        );
        return KolabingRoutes.welcome;
      }

      final user = await authService.restoreSessionUser() ?? storedUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.welcome,
        );
        return KolabingRoutes.welcome;
      }

      final destination = resolveAuthDestination(user);

      if (destination == KolabingRoutes.businessOnboardingStep1) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.businessOnboarding,
        );
        return destination;
      }

      if (destination == KolabingRoutes.communityOnboardingStep1) {
        state = state.copyWith(
          isLoading: false,
          navigationTarget: SplashNavigationTarget.communityOnboarding,
        );
        return destination;
      }

      final String dashboard;
      final SplashNavigationTarget navTarget;
      if (user.isAttendee) {
        dashboard = KolabingRoutes.attendeeDashboard;
        navTarget = SplashNavigationTarget.attendeeDashboard;
      } else if (user.isBusiness) {
        dashboard = KolabingRoutes.businessDashboard;
        navTarget = SplashNavigationTarget.businessDashboard;
      } else {
        dashboard = KolabingRoutes.communityDashboard;
        navTarget = SplashNavigationTarget.communityDashboard;
      }

      // Check if the permission screen needs to be shown
      final hasShownPermissions = await PermissionService.instance
          .hasShownPermissionScreen();

      if (!hasShownPermissions) {
        state = state.copyWith(isLoading: false, navigationTarget: navTarget);
        return '${KolabingRoutes.permissions}?destination='
            '${Uri.encodeComponent(dashboard)}';
      }

      state = state.copyWith(isLoading: false, navigationTarget: navTarget);
      return dashboard;
    } on Exception catch (e) {
      // On error, default to the safe welcome chooser.
      state = state.copyWith(
        isLoading: false,
        navigationTarget: SplashNavigationTarget.welcome,
        errorMessage: 'Failed to initialize: $e',
      );
      return KolabingRoutes.welcome;
    }
  }
}

/// Provider for splash screen state and initialization logic
final splashStateProvider = NotifierProvider<SplashStateNotifier, SplashState>(
  SplashStateNotifier.new,
);
