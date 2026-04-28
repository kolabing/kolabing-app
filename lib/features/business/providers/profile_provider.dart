import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/application_provider.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../kolab/providers/my_kolabs_provider.dart';
import '../models/notification_preferences.dart';
import '../models/subscription.dart';
import '../services/profile_service.dart';

/// Profile state
class ProfileState {
  const ProfileState({
    this.profile,
    this.notificationPrefs,
    this.subscription,
    this.isLoading = true,
    this.isInitialized = false,
    this.isUpdating = false,
    this.error,
  });

  final UserModel? profile;
  final NotificationPreferences? notificationPrefs;
  final Subscription? subscription;
  final bool isLoading;
  final bool isInitialized;
  final bool isUpdating;
  final String? error;

  bool get hasData => profile != null;

  /// Whether the user has an active subscription.
  /// Checks both the subscription object AND the backend's has_active_subscription flag
  /// (which covers test users who bypass subscription requirements).
  bool get isSubscribed =>
      subscription?.isActive == true || profile?.hasActiveSubscription == true;

  ProfileState copyWith({
    UserModel? profile,
    NotificationPreferences? notificationPrefs,
    Subscription? subscription,
    bool? isLoading,
    bool? isInitialized,
    bool? isUpdating,
    String? error,
    bool clearError = false,
    bool clearSubscription = false,
  }) => ProfileState(
    profile: profile ?? this.profile,
    notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    subscription: clearSubscription
        ? subscription
        : (subscription ?? this.subscription),
    isLoading: isLoading ?? this.isLoading,
    isInitialized: isInitialized ?? this.isInitialized,
    isUpdating: isUpdating ?? this.isUpdating,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Profile notifier for managing profile state
class ProfileNotifier extends Notifier<ProfileState> {
  late final ProfileService _profileService;
  late final AuthService _authService;

  @override
  ProfileState build() {
    _authService = ref.read(authServiceProvider);
    _profileService = ProfileService(authService: _authService);
    // Auto-load profile on initialization
    Future.microtask(() => loadProfile());
    return const ProfileState();
  }

  bool _isLoadingInProgress = false;

  /// Load all profile data
  Future<void> loadProfile() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingInProgress) {
      return;
    }
    _isLoadingInProgress = true;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch profile first
      final profile = await _profileService.getProfile();

      // Fetch notification preferences
      final notificationPrefs = await _profileService
          .getNotificationPreferences();

      // Fetch subscription (only for business users)
      Subscription? subscription;
      if (profile.isBusiness) {
        subscription = await _profileService.getSubscription();
      }

      state = state.copyWith(
        profile: profile,
        notificationPrefs: notificationPrefs,
        subscription: subscription,
        isLoading: false,
        isInitialized: true,
        clearSubscription: true,
      );
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: 'An unexpected error occurred',
      );
    } finally {
      _isLoadingInProgress = false;
    }
  }

  /// Refresh profile data
  Future<void> refresh() async {
    await loadProfile();
  }

  /// Update profile photo
  Future<bool> updateProfilePhoto(String base64Photo, String mimeType) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final dataUri = 'data:$mimeType;base64,$base64Photo';
      final updatedProfile = await _profileService.updateProfile({
        'profile_photo': dataUri,
      });

      state = state.copyWith(profile: updatedProfile, isUpdating: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.error.message);
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
      return false;
    } on Exception {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update profile photo',
      );
      return false;
    }
  }

  /// Update profile data
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updatedProfile = await _profileService.updateProfile(data);

      state = state.copyWith(profile: updatedProfile, isUpdating: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.error.message);
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
      return false;
    } on Exception {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update profile',
      );
      return false;
    }
  }

  /// Update notification preference
  Future<void> updateNotificationPreference(String key, bool value) async {
    if (state.notificationPrefs == null) return;

    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updated = await _profileService.updateNotificationPreferences({
        key: value,
      });

      state = state.copyWith(notificationPrefs: updated, isUpdating: false);
    } on ApiException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.error.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
    } on Exception {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update notification preference',
      );
    }
  }

  /// Sign out user — clears token, storage, and all cached provider state
  Future<void> signOut() async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _authService.logout();
    } on Exception catch (e) {
      debugPrint('Logout service error: $e');
    }

    // Reset auth state
    ref.read(authProvider.notifier).logout();

    // Invalidate all user-scoped providers so stale data
    // is not visible if another user signs in
    ref.invalidate(dashboardProvider);
    ref.invalidate(myApplicationsProvider);
    ref.invalidate(receivedApplicationsProvider);
    ref.invalidate(chatMessagesProvider);
    ref.invalidate(unreadMessagesCountProvider);
    ref.invalidate(opportunityListProvider);
    ref.invalidate(myOpportunitiesProvider);
    ref.invalidate(myKolabsProvider);
    ref.invalidate(notificationProvider);

    // Reset own state last
    state = const ProfileState();
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _profileService.deleteAccount();
      await _authService.logout();
      state = const ProfileState();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.error.message);
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
      return false;
    } on Exception {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to delete account',
      );
      return false;
    }
  }

  /// Refresh subscription
  Future<void> refreshSubscription() async {
    try {
      final subscription = await _profileService.getSubscription();
      state = state.copyWith(
        subscription: subscription,
        clearSubscription: true,
      );
    } on Exception {
      // Silently fail subscription refresh
    }
  }

  /// Get checkout URL
  Future<String?> getCheckoutUrl() async {
    try {
      return await _profileService.createCheckoutSession(
        successUrl: 'kolabing://subscription/success',
        cancelUrl: 'kolabing://subscription/cancel',
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.error.message);
      return null;
    } on NetworkException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } on Exception {
      state = state.copyWith(error: 'Failed to create checkout session');
      return null;
    }
  }

  /// Get billing portal URL
  Future<String?> getBillingPortalUrl() async {
    try {
      return await _profileService.getBillingPortalUrl(
        returnUrl: 'kolabing://subscription/portal-return',
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.error.message);
      return null;
    } on NetworkException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    } on Exception {
      state = state.copyWith(error: 'Failed to get billing portal');
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updated = await _profileService.cancelSubscription();
      state = state.copyWith(subscription: updated, isUpdating: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.error.message);
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
      return false;
    } on Exception {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to cancel subscription',
      );
      return false;
    }
  }

  /// Reactivate subscription (undo cancellation)
  Future<bool> reactivateSubscription() async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updated = await _profileService.reactivateSubscription();
      state = state.copyWith(subscription: updated, isUpdating: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.error.message);
      return false;
    } on NetworkException catch (e) {
      state = state.copyWith(isUpdating: false, error: e.message);
      return false;
    } on Exception {
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to reactivate subscription',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Profile provider
final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
