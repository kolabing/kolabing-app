import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/notification_preferences.dart';
import '../models/subscription.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final authService = ref.read(authServiceProvider);
  return ProfileService(authService: authService);
});

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
      (subscription?.isActive ?? false) ||
      (profile?.hasActiveSubscription ?? false);

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
  // Resolved lazily via a getter (NOT a `late final` assigned in build()):
  // build() can re-run on the same notifier instance (e.g. when the provider is
  // invalidated on logout/login), and re-assigning a `late final` throws
  // LateInitializationError. A getter is idempotent across rebuilds.
  ProfileService get _profileService => ref.read(profileServiceProvider);
  bool _isLoadingInProgress = false;
  int _activeSessionVersion = 0;
  String? _activeUserId;

  @override
  ProfileState build() {
    ref.listen<AuthState>(authProvider, _handleAuthStateChanged);
    Future.microtask(_loadProfileIfAuthenticated);
    return const ProfileState();
  }

  void _handleAuthStateChanged(AuthState? previous, AuthState next) {
    final nextUserId = next.user?.id;

    if (!next.isAuthenticated || nextUserId == null) {
      _activeUserId = null;
      _invalidateActiveProfileWork();
      _clearSignedOutState();
      return;
    }

    if (_activeUserId != nextUserId) {
      _activeUserId = nextUserId;
      _invalidateActiveProfileWork();
      _clearSignedOutState();
      Future.microtask(_loadProfileIfAuthenticated);
    }
  }

  void _invalidateActiveProfileWork() {
    _activeSessionVersion++;
    _isLoadingInProgress = false;
  }

  void _clearSignedOutState() {
    state = const ProfileState(isLoading: false, isInitialized: false);
  }

  bool _isStaleLoad(int sessionVersion) =>
      sessionVersion != _activeSessionVersion;

  Future<void> _loadProfileIfAuthenticated() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _activeUserId = null;
      _clearSignedOutState();
      return;
    }

    _activeUserId = authState.user!.id;
    await loadProfile();
  }

  /// Load all profile data
  Future<void> loadProfile() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _activeUserId = null;
      _isLoadingInProgress = false;
      _clearSignedOutState();
      return;
    }

    // Prevent multiple simultaneous loads
    if (_isLoadingInProgress) {
      return;
    }
    _isLoadingInProgress = true;
    final sessionVersion = _activeSessionVersion;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _profileService.getProfile();
      if (_isStaleLoad(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        profile: profile,
        isLoading: true,
        isInitialized: true,
        clearError: true,
        subscription: null,
        clearSubscription: true,
      );

      var notificationPrefs = state.notificationPrefs;
      try {
        notificationPrefs = await _profileService.getNotificationPreferences();
      } on ApiException catch (e) {
        debugPrint('Load notification preferences API error: $e');
      } on NetworkException catch (e) {
        debugPrint('Load notification preferences network error: $e');
      } on Exception catch (e) {
        debugPrint('Load notification preferences error: $e');
      }
      if (_isStaleLoad(sessionVersion)) {
        return;
      }

      Subscription? subscription;
      if (profile.isBusiness) {
        try {
          subscription = await _profileService.getSubscription();
        } on ApiException catch (e) {
          debugPrint('Load subscription API error: $e');
        } on NetworkException catch (e) {
          debugPrint('Load subscription network error: $e');
        } on Exception catch (e) {
          debugPrint('Load subscription error: $e');
        }
      }
      if (_isStaleLoad(sessionVersion)) {
        return;
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
      if (_isStaleLoad(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.error.message,
      );
    } on AuthException catch (e) {
      if (_isStaleLoad(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.message,
      );
    } on NetworkException catch (e) {
      if (_isStaleLoad(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.message,
      );
    } on Exception {
      if (_isStaleLoad(sessionVersion)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: 'An unexpected error occurred',
      );
    } finally {
      if (!_isStaleLoad(sessionVersion)) {
        _isLoadingInProgress = false;
      }
    }
  }

  /// Refresh profile data
  Future<void> refresh() async {
    await loadProfile();
  }

  /// Update profile photo from a picked image file.
  ///
  /// Sends the image as a multipart file (the backend validates `profile_photo`
  /// as an uploaded image file; a base64 string is rejected with 422).
  Future<bool> updateProfilePhoto(String filePath) async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      final updatedProfile = await _profileService.updateProfilePhotoFile(
        filePath: filePath,
      );

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

  /// Sign out user — clears token, storage, and all cached provider state.
  ///
  /// The full teardown of user-scoped providers (including this provider via
  /// `invalidateUserScopedProviders`) now lives in
  /// `AuthNotifier.logout()`, so every logout path resets the same state. We
  /// only delegate here.
  Future<void> signOut() async {
    _invalidateActiveProfileWork();
    state = state.copyWith(isUpdating: true, clearError: true);
    await ref.read(authProvider.notifier).logout();
    _clearSignedOutState();
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _profileService.deleteAccount();
      _invalidateActiveProfileWork();
      await ref.read(authProvider.notifier).logout();
      _clearSignedOutState();
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
