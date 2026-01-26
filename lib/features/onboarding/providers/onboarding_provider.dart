import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/business_type.dart';
import '../models/city.dart';
import '../models/community_type.dart';
import '../models/onboarding_state.dart';
import '../services/onboarding_service.dart';

/// Onboarding service provider
final onboardingServiceProvider =
    Provider<OnboardingService>((ref) => OnboardingService());

/// Business types provider
final businessTypesProvider =
    FutureProvider.autoDispose<List<BusinessType>>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getBusinessTypes();
});

/// Community types provider
final communityTypesProvider =
    FutureProvider.autoDispose<List<CommunityType>>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getCommunityTypes();
});

/// Cities provider
final citiesProvider =
    FutureProvider.autoDispose<List<OnboardingCity>>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getCities();
});

/// Filtered cities based on search query
final filteredCitiesProvider =
    Provider.autoDispose.family<AsyncValue<List<OnboardingCity>>, String>(
        (ref, query) {
  final citiesAsync = ref.watch(citiesProvider);

  return citiesAsync.when(
    data: (cities) {
      if (query.isEmpty) {
        return AsyncValue.data(cities);
      }
      final filtered = cities
          .where((city) =>
              city.name.toLowerCase().contains(query.toLowerCase()) ||
              (city.country?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Onboarding state notifier using modern Riverpod 3.x Notifier
class OnboardingNotifier extends Notifier<OnboardingData?> {
  @override
  OnboardingData? build() => null;

  /// Initialize onboarding with user type
  void initialize(UserType userType) {
    state = OnboardingData(userType: userType);
  }

  /// Update name (step 1)
  void updateName(String name) {
    if (state == null) return;
    state = state!.copyWith(name: name);
  }

  /// Update photo (step 1)
  Future<void> updatePhoto(File file) async {
    if (state == null) return;

    try {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final fileName = file.path.split('/').last;

      // Determine MIME type from file extension
      final extension = fileName.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          mimeType = 'image/jpeg';
          break;
      }

      state = state!.copyWith(
        photoBase64: base64,
        photoFileName: fileName,
        photoMimeType: mimeType,
      );
    } catch (e) {
      debugPrint('Error encoding photo: $e');
    }
  }

  /// Clear photo
  void clearPhoto() {
    if (state == null) return;
    state = state!.copyWith(clearPhoto: true);
  }

  /// Update type (step 2) - business type or community type
  /// [typeId] - The UUID of the type
  /// [typeSlug] - The slug used for API payload
  /// [typeName] - The display name for UI
  void updateType(String typeId, String typeSlug, String typeName) {
    if (state == null) return;
    state = state!.copyWith(type: typeId, typeSlug: typeSlug, typeName: typeName);
  }

  /// Update city (step 3)
  void updateCity(String cityId, String cityName) {
    if (state == null) return;
    state = state!.copyWith(cityId: cityId, cityName: cityName);
  }

  /// Update about (step 4)
  void updateAbout(String? about) {
    if (state == null) return;
    if (about == null || about.isEmpty) {
      state = state!.copyWith(clearAbout: true);
    } else {
      state = state!.copyWith(about: about);
    }
  }

  /// Update phone (step 4 - business only)
  void updatePhone(String? phone) {
    if (state == null) return;
    if (phone == null || phone.isEmpty) {
      state = state!.copyWith(clearPhone: true);
    } else {
      state = state!.copyWith(phone: phone);
    }
  }

  /// Update instagram (step 4)
  void updateInstagram(String? instagram) {
    if (state == null) return;
    // Remove @ prefix if present
    final handle = instagram?.replaceFirst('@', '');
    if (handle == null || handle.isEmpty) {
      state = state!.copyWith(clearInstagram: true);
    } else {
      state = state!.copyWith(instagram: handle);
    }
  }

  /// Update tiktok (step 4 - community only)
  void updateTiktok(String? tiktok) {
    if (state == null) return;
    // Remove @ prefix if present
    final handle = tiktok?.replaceFirst('@', '');
    if (handle == null || handle.isEmpty) {
      state = state!.copyWith(clearTiktok: true);
    } else {
      state = state!.copyWith(tiktok: handle);
    }
  }

  /// Update website (step 4)
  void updateWebsite(String? website) {
    if (state == null) return;
    if (website == null || website.isEmpty) {
      state = state!.copyWith(clearWebsite: true);
    } else {
      // Add https:// if not present
      final url = website.startsWith('http') ? website : 'https://$website';
      state = state!.copyWith(website: url);
    }
  }

  /// Go to next step
  void nextStep() {
    if (state == null) return;
    if (state!.currentStep < 4) {
      state = state!.copyWith(currentStep: state!.currentStep + 1);
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state == null) return;
    if (state!.currentStep > 1) {
      state = state!.copyWith(currentStep: state!.currentStep - 1);
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (state == null) return;
    if (step >= 1 && step <= 4) {
      state = state!.copyWith(currentStep: step);
    }
  }

  /// Check if can proceed to next step
  bool canProceed() {
    if (state == null) return false;

    switch (state!.currentStep) {
      case 1:
        return state!.isStep1Complete;
      case 2:
        return state!.isStep2Complete;
      case 3:
        return state!.isStep3Complete;
      case 4:
        return true; // Step 4 is all optional
      default:
        return false;
    }
  }

  /// Complete onboarding with email and password registration
  ///
  /// This uses the new combined registration API that includes all onboarding
  /// data in a single request.
  Future<OnboardingResult> completeWithEmail({
    required String email,
    required String password,
  }) async {
    if (state == null || !state!.isComplete) {
      return const OnboardingResult(
        success: false,
        errorMessage: 'Please complete all required fields',
      );
    }

    try {
      final authService = ref.read(authServiceProvider);

      // Single API call that combines registration + onboarding data
      final AuthResponse authResponse;
      if (state!.isBusiness) {
        authResponse = await authService.registerBusiness(
          email: email,
          password: password,
          onboardingData: state!,
        );
      } else {
        authResponse = await authService.registerCommunity(
          email: email,
          password: password,
          onboardingData: state!,
        );
      }

      // Update auth state
      ref.read(authProvider.notifier).checkAuthStatus();

      return OnboardingResult(
        success: true,
        user: authResponse.user,
      );
    } on ApiException catch (e) {
      return OnboardingResult(
        success: false,
        error: e.error,
      );
    } on NetworkException catch (e) {
      return OnboardingResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } catch (e) {
      debugPrint('Onboarding error: $e');
      return const OnboardingResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Reset onboarding state
  void reset() {
    state = null;
  }
}

/// Onboarding state provider using modern NotifierProvider
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData?>(
  OnboardingNotifier.new,
);

/// Result of onboarding attempt
class OnboardingResult {
  const OnboardingResult({
    required this.success,
    this.user,
    this.error,
    this.errorMessage,
    this.cancelled = false,
    this.isNetworkError = false,
  });

  final bool success;
  final UserModel? user;
  final ApiError? error;
  final String? errorMessage;
  final bool cancelled;
  final bool isNetworkError;

  String get displayError {
    if (error != null) {
      return error!.message;
    }
    return errorMessage ?? 'An unexpected error occurred';
  }

  bool get isUserTypeMismatch => error?.isUserTypeMismatch ?? false;
}
