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
import '../models/onboarding_photo.dart';
import '../models/onboarding_state.dart';
import '../models/place_details_import.dart';
import '../models/place_suggestion.dart';
import '../services/onboarding_service.dart';

/// Onboarding service provider
final onboardingServiceProvider = Provider<OnboardingService>(
  (ref) => OnboardingService(),
);

/// Business types provider
final businessTypesProvider = FutureProvider.autoDispose<List<BusinessType>>((
  ref,
) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getBusinessTypes();
});

/// Community types provider
final communityTypesProvider = FutureProvider.autoDispose<List<CommunityType>>((
  ref,
) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getCommunityTypes();
});

/// Cities provider
final citiesProvider = FutureProvider.autoDispose<List<OnboardingCity>>((
  ref,
) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getCities();
});

/// Place suggestions for the business location step.
final placeSuggestionsProvider = FutureProvider.autoDispose
    .family<List<PlaceSuggestion>, String>((ref, query) async {
      if (query.trim().length < 2) {
        return const [];
      }
      final service = ref.watch(onboardingServiceProvider);
      return service.searchPlaces(query.trim());
    });

/// Filtered cities based on search query
final filteredCitiesProvider = Provider.autoDispose
    .family<AsyncValue<List<OnboardingCity>>, String>((ref, query) {
      final citiesAsync = ref.watch(citiesProvider);

      return citiesAsync.when(
        data: (cities) {
          if (query.isEmpty) {
            return AsyncValue.data(cities);
          }
          final filtered = cities
              .where(
                (city) =>
                    city.name.toLowerCase().contains(query.toLowerCase()) ||
                    (city.country?.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
          return AsyncValue.data(filtered);
        },
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
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

  /// Update name (step 1).
  ///
  /// For business users the merged step-2 screen uses a single name field for
  /// both the business and its primary venue. We mirror the value into
  /// [OnboardingData.venueName] so the `primary_venue.name` payload field
  /// stays in sync without asking the user twice.
  void updateName(String name) {
    if (state == null) return;
    if (state!.isBusiness) {
      final trimmed = name.trim();
      state = state!.copyWith(
        name: name,
        venueName: trimmed.isEmpty ? null : trimmed,
        clearVenueName: trimmed.isEmpty,
      );
    } else {
      state = state!.copyWith(name: name);
    }
  }

  /// Update photo (step 1)
  Future<void> updatePhoto(File file) async {
    if (state == null) return;

    try {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final fileName = file.path.split('/').last;

      state = state!.copyWith(
        photoBase64: base64,
        photoFileName: fileName,
        photoMimeType: _inferMimeType(fileName),
      );
    } on Exception catch (e) {
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
    state = state!.copyWith(
      type: typeId,
      typeSlug: typeSlug,
      typeName: typeName,
    );
  }

  /// Toggle a business category selection (max 3).
  void toggleBusinessType(BusinessType type) {
    if (state == null) return;

    final currentIds = List<String>.from(state!.selectedBusinessTypeIds);
    final currentSlugs = List<String>.from(state!.selectedBusinessTypeSlugs);
    final currentNames = List<String>.from(state!.selectedBusinessTypeNames);
    final existingIndex = currentIds.indexOf(type.id);

    if (existingIndex >= 0) {
      currentIds.removeAt(existingIndex);
      currentSlugs.removeAt(existingIndex);
      currentNames.removeAt(existingIndex);
    } else if (currentIds.length < 3) {
      currentIds.add(type.id);
      currentSlugs.add(type.slug);
      currentNames.add(type.name);
    }

    state = state!.copyWith(
      type: currentIds.isNotEmpty ? currentIds.first : null,
      typeSlug: currentSlugs.isNotEmpty ? currentSlugs.first : null,
      typeName: currentNames.isNotEmpty ? currentNames.first : null,
      businessTypeIds: currentIds,
      businessTypeSlugs: currentSlugs,
      businessTypeNames: currentNames,
      clearTypeSelection: currentIds.isEmpty,
    );
  }

  /// Update city (step 3)
  void updateCity(String cityId, String cityName) {
    if (state == null) return;
    state = state!.copyWith(cityId: cityId, cityName: cityName);
  }

  /// Select the primary business location from autocomplete.
  void updateLocation(PlaceSuggestion location) {
    if (state == null) return;
    final importedPlaceChanged =
        state!.importedPlaceId != null &&
        state!.importedPlaceId != location.placeId;
    state = state!.copyWith(
      location: location,
      cityId: location.cityId ?? state!.cityId,
      cityName: location.city,
      clearImportedPlace: importedPlaceChanged,
    );
  }

  /// Update primary venue name.
  void updateVenueName(String? name) {
    if (state == null) return;
    if (name == null || name.trim().isEmpty) {
      state = state!.copyWith(clearVenueName: true);
    } else {
      state = state!.copyWith(venueName: name.trim());
    }
  }

  /// Update primary venue type.
  void updateVenueType(String? venueType) {
    if (state == null) return;
    if (venueType == null || venueType.trim().isEmpty) {
      state = state!.copyWith(clearVenueType: true);
    } else {
      state = state!.copyWith(venueType: venueType);
    }
  }

  /// Update primary venue capacity.
  void updateVenueCapacity(int? capacity) {
    if (state == null) return;
    state = state!.copyWith(
      venueCapacity: capacity,
      clearVenueCapacity: capacity == null,
    );
  }

  /// Add a venue photo.
  Future<void> addVenuePhoto(File file) async {
    if (state == null) return;

    try {
      final bytes = await file.readAsBytes();
      final photo = OnboardingPhoto.upload(
        id: '${DateTime.now().microsecondsSinceEpoch}-${file.path.split('/').last}',
        base64: base64Encode(bytes),
        fileName: file.path.split('/').last,
        mimeType: _inferMimeType(file.path),
      );
      state = state!.copyWith(venuePhotos: [...state!.venuePhotos, photo]);
    } on Exception catch (e) {
      debugPrint('Error encoding venue photo: $e');
    }
  }

  /// Remove a venue photo.
  void removeVenuePhoto(int index) {
    if (state == null || index < 0 || index >= state!.venuePhotos.length) {
      return;
    }
    final photos = List<OnboardingPhoto>.from(state!.venuePhotos)
      ..removeAt(index);
    state = state!.copyWith(venuePhotos: photos);
  }

  /// Move a venue photo to a new position.
  void moveVenuePhoto(int fromIndex, int toIndex) {
    if (state == null ||
        fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= state!.venuePhotos.length ||
        toIndex >= state!.venuePhotos.length ||
        fromIndex == toIndex) {
      return;
    }

    final photos = List<OnboardingPhoto>.from(state!.venuePhotos);
    final photo = photos.removeAt(fromIndex);
    photos.insert(toIndex, photo);
    state = state!.copyWith(venuePhotos: photos);
  }

  /// Apply a successful Google place import into local onboarding state.
  void applyPlaceImport(
    PlaceDetailsImport placeImport, {
    List<BusinessType> businessTypes = const [],
  }) {
    if (state == null) return;

    final resolvedTypes = _resolveImportedBusinessTypes(
      placeImport.allCategorySlugs,
      businessTypes,
    );
    final preservedCustomPhotos = state!.venuePhotos
        .where((photo) => !photo.isGoogleImported)
        .toList(growable: false);

    final importedPhotos = placeImport.primaryVenue.photos
        .where(
          (photo) =>
              photo.resourceName.trim().isNotEmpty &&
              photo.previewUrl.trim().isNotEmpty,
        )
        .map(
          (photo) => OnboardingPhoto.googleImported(
            resourceName: photo.resourceName,
            previewUrl: photo.previewUrl,
            width: photo.width,
            height: photo.height,
            authorAttributions: photo.authorAttributions,
          ),
        )
        .toList(growable: false);

    final placeSuggestion = placeImport.toPlaceSuggestion();
    final about = placeImport.about?.trim();
    final normalizedPhone = placeImport.phoneNumber?.trim();
    final normalizedWebsite = placeImport.website?.trim();
    final venueDescription = placeImport.primaryVenue.description?.trim();

    state = state!.copyWith(
      name: placeImport.name.trim().isEmpty ? state!.name : placeImport.name,
      about: about?.isEmpty ?? true ? state!.about : about,
      phone: normalizedPhone?.isEmpty ?? true ? state!.phone : normalizedPhone,
      website: normalizedWebsite?.isEmpty ?? true
          ? state!.website
          : normalizedWebsite,
      cityId: placeImport.cityId ?? placeSuggestion.cityId ?? state!.cityId,
      cityName: placeImport.cityName ?? placeSuggestion.city,
      location: placeSuggestion,
      importedPlaceId: placeSuggestion.placeId,
      venueName: placeImport.primaryVenue.name.trim().isEmpty
          ? state!.venueName
          : placeImport.primaryVenue.name,
      venueType:
          placeImport.primaryVenue.venueType ??
          placeImport.businessType ??
          resolvedTypes.typeSlug ??
          state!.venueType,
      venueCapacity: placeImport.primaryVenue.capacity ?? state!.venueCapacity,
      venuePhotos: [...importedPhotos, ...preservedCustomPhotos],
      venuePhone: normalizedPhone?.isEmpty ?? true
          ? placeImport.primaryVenue.phoneNumber ?? state!.venuePhone
          : normalizedPhone,
      venueWebsite: normalizedWebsite?.isEmpty ?? true
          ? placeImport.primaryVenue.website ?? state!.venueWebsite
          : normalizedWebsite,
      venueOpeningHours: placeImport.primaryVenue.openingHours,
      venueDescription: (about?.isNotEmpty ?? false)
          ? about
          : (venueDescription?.isNotEmpty ?? false)
          ? venueDescription
          : state!.venueDescription,
      venuePriceLevel: placeImport.primaryVenue.priceLevel,
      venueRating: placeImport.primaryVenue.rating,
      venueUserRatingsTotal: placeImport.primaryVenue.userRatingsTotal,
      venueGooglePlaceTypes: placeImport.primaryVenue.googlePlaceTypes,
      type: resolvedTypes.typeId ?? state!.type,
      typeSlug: resolvedTypes.typeSlug ?? state!.typeSlug,
      typeName: resolvedTypes.typeName ?? state!.typeName,
      businessTypeIds: resolvedTypes.businessTypeIds,
      businessTypeSlugs: resolvedTypes.businessTypeSlugs,
      businessTypeNames: resolvedTypes.businessTypeNames,
    );
  }

  /// Update about (step 4)
  void updateAbout(String? about) {
    if (state == null) return;
    if (about == null || about.isEmpty) {
      state = state!.copyWith(clearAbout: true, clearVenueDescription: true);
    } else {
      state = state!.copyWith(about: about, venueDescription: about);
    }
  }

  /// Update phone (step 4 - business only)
  void updatePhone(String? phone) {
    if (state == null) return;
    if (phone == null || phone.isEmpty) {
      state = state!.copyWith(clearPhone: true, clearVenuePhone: true);
    } else {
      state = state!.copyWith(phone: phone, venuePhone: phone);
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
      state = state!.copyWith(clearWebsite: true, clearVenueWebsite: true);
    } else {
      // Add https:// if not present
      final url = website.startsWith('http') ? website : 'https://$website';
      state = state!.copyWith(website: url, venueWebsite: url);
    }
  }

  /// Update optional referral code for business signups.
  void updateReferralCode(String? referralCode) {
    if (state == null) return;
    if (referralCode == null || referralCode.trim().isEmpty) {
      state = state!.copyWith(clearReferralCode: true);
    } else {
      state = state!.copyWith(referralCode: referralCode.trim());
    }
  }

  String _inferMimeType(String fileNameOrPath) {
    final extension = fileNameOrPath.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  _ResolvedImportedBusinessTypes _resolveImportedBusinessTypes(
    List<String> importedSlugs,
    List<BusinessType> availableTypes,
  ) {
    if (importedSlugs.isEmpty) {
      return _ResolvedImportedBusinessTypes.empty();
    }

    final normalizedSlugs = importedSlugs
        .map((slug) => slug.trim().toLowerCase())
        .where((slug) => slug.isNotEmpty)
        .take(3)
        .toList(growable: false);

    if (availableTypes.isEmpty) {
      return _ResolvedImportedBusinessTypes(
        typeSlug: normalizedSlugs.first,
        typeName: _humanizeSlug(normalizedSlugs.first),
        businessTypeSlugs: normalizedSlugs,
        businessTypeNames: normalizedSlugs
            .map(_humanizeSlug)
            .toList(growable: false),
      );
    }

    final matched = availableTypes
        .where(
          (type) => normalizedSlugs.contains(type.slug.trim().toLowerCase()),
        )
        .take(3)
        .toList(growable: false);

    if (matched.isEmpty) {
      return _ResolvedImportedBusinessTypes(
        typeSlug: normalizedSlugs.first,
        typeName: _humanizeSlug(normalizedSlugs.first),
        businessTypeSlugs: normalizedSlugs,
        businessTypeNames: normalizedSlugs
            .map(_humanizeSlug)
            .toList(growable: false),
      );
    }

    return _ResolvedImportedBusinessTypes(
      typeId: matched.first.id,
      typeSlug: matched.first.slug,
      typeName: matched.first.name,
      businessTypeIds: matched.map((type) => type.id).toList(growable: false),
      businessTypeSlugs: matched
          .map((type) => type.slug)
          .toList(growable: false),
      businessTypeNames: matched
          .map((type) => type.name)
          .toList(growable: false),
    );
  }

  String _humanizeSlug(String slug) => slug
      .split(RegExp(r'[_-]'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');

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
        return state!.isStep4Complete;
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
      debugPrint(
        '[B6] completeWithEmail aborted: state=${state == null ? "null" : "incomplete"} '
        '(step1=${state?.isStep1Complete} step2=${state?.isStep2Complete} '
        'step3=${state?.isStep3Complete})',
      );
      return const OnboardingResult(
        success: false,
        errorMessage: 'Please complete all required fields',
      );
    }

    debugPrint(
      '[B6] completeWithEmail: userType=${state!.userType} '
      'email=$email name=${state!.name} venueType=${state!.venueType} '
      'venueCapacity=${state!.venueCapacity} '
      'venuePhotos=${state!.venuePhotos.length} '
      'businessTypes=${state!.selectedBusinessTypeSlugs.length}',
    );

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

      debugPrint(
        '[B6] register* succeeded — user=${authResponse.user.email} '
        'hasToken=${authResponse.token.isNotEmpty}',
      );

      // Update auth state
      await ref.read(authProvider.notifier).checkAuthStatus();

      return OnboardingResult(success: true, user: authResponse.user);
    } on ApiException catch (e) {
      debugPrint(
        '[B6] ApiException: status=${e.error.statusCode} '
        'message=${e.error.message} '
        'fieldErrors=${e.error.errors?.keys.toList() ?? []}',
      );
      return OnboardingResult(success: false, error: e.error);
    } on NetworkException catch (e) {
      debugPrint('[B6] NetworkException: ${e.message}');
      return OnboardingResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Exception catch (e) {
      debugPrint('[B6] Unexpected exception: $e');
      return const OnboardingResult(
        success: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  /// Complete onboarding for an already-authenticated user.
  Future<OnboardingResult> completeAuthenticatedOnboarding() async {
    if (state == null || !state!.isComplete) {
      return const OnboardingResult(
        success: false,
        errorMessage: 'Please complete all required fields',
      );
    }

    try {
      final authService = ref.read(authServiceProvider);
      final service = ref.read(onboardingServiceProvider);
      final token = await authService.getToken();

      if (token == null || token.isEmpty) {
        return const OnboardingResult(
          success: false,
          errorMessage: 'Your session expired. Please sign in again.',
        );
      }

      if (state!.isBusiness) {
        await service.completeBusinessOnboarding(token, state!);
      } else {
        await service.completeCommunityOnboarding(token, state!);
      }

      await ref.read(authProvider.notifier).checkAuthStatus();
      return const OnboardingResult(success: true);
    } on ApiException catch (e) {
      return OnboardingResult(success: false, error: e.error);
    } on NetworkException catch (e) {
      return OnboardingResult(
        success: false,
        errorMessage: e.message,
        isNetworkError: true,
      );
    } on Exception catch (e) {
      debugPrint('Authenticated onboarding error: $e');
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

class _ResolvedImportedBusinessTypes {
  const _ResolvedImportedBusinessTypes({
    this.typeId,
    this.typeSlug,
    this.typeName,
    this.businessTypeIds = const [],
    this.businessTypeSlugs = const [],
    this.businessTypeNames = const [],
  });

  const _ResolvedImportedBusinessTypes.empty()
    : typeId = null,
      typeSlug = null,
      typeName = null,
      businessTypeIds = const [],
      businessTypeSlugs = const [],
      businessTypeNames = const [];

  final String? typeId;
  final String? typeSlug;
  final String? typeName;
  final List<String> businessTypeIds;
  final List<String> businessTypeSlugs;
  final List<String> businessTypeNames;
}

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
