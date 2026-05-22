import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

/// Dashboard state
class DashboardState {
  const DashboardState({
    this.businessData,
    this.communityData,
    this.isLoading = true,
    this.isInitialized = false,
    this.error,
  });

  final BusinessDashboard? businessData;
  final CommunityDashboard? communityData;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  bool get hasData => businessData != null || communityData != null;
  bool get isBusiness => businessData != null;
  bool get isCommunity => communityData != null;

  DashboardState copyWith({
    BusinessDashboard? businessData,
    CommunityDashboard? communityData,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool clearError = false,
    bool clearBusiness = false,
    bool clearCommunity = false,
  }) => DashboardState(
    // `clearBusiness` / `clearCommunity` force the field to null. This is
    // how loading one role's dashboard drops the OTHER role's stale data:
    // without it, a leftover `businessData` keeps `isBusiness` true and the
    // wrong (or a blank) dashboard renders, which read as "broken". The
    // previous implementation had this inverted (it returned the new value
    // when clearing instead of null).
    businessData: clearBusiness ? null : (businessData ?? this.businessData),
    communityData: clearCommunity
        ? null
        : (communityData ?? this.communityData),
    isLoading: isLoading ?? this.isLoading,
    isInitialized: isInitialized ?? this.isInitialized,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Dashboard notifier for managing dashboard state
class DashboardNotifier extends Notifier<DashboardState> {
  late DashboardService _dashboardService;

  @override
  DashboardState build() {
    final authService = ref.read(authServiceProvider);
    _dashboardService = DashboardService(authService: authService);
    // Auto-load dashboard on initialization
    Future.microtask(() => load());
    return const DashboardState();
  }

  /// Load dashboard data from API
  Future<void> load() async {
    // Prevent multiple simultaneous loads
    if (state.isLoading && state.isInitialized) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _dashboardService.getDashboard();

      if (response.isBusiness) {
        state = state.copyWith(
          businessData: response.businessDashboard,
          isLoading: false,
          isInitialized: true,
          // Clear any stale community data so the role switch is clean.
          clearCommunity: true,
        );
      } else if (response.isCommunity) {
        state = state.copyWith(
          communityData: response.communityDashboard,
          isLoading: false,
          isInitialized: true,
          // Clear any stale business data so the role switch is clean.
          clearBusiness: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          error: 'Unknown dashboard type',
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.error.message,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.message,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.message,
      );
    } on Exception {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: 'An unexpected error occurred',
      );
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await load();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Dashboard provider
final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
