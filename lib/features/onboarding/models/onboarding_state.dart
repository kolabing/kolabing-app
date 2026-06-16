import '../../../utils/referral_code.dart';
import '../../auth/models/user_model.dart';
import 'onboarding_photo.dart';
import 'place_suggestion.dart';

/// Onboarding data state
class OnboardingData {
  const OnboardingData({
    required this.userType,
    this.name,
    this.photoBase64,
    this.photoFileName,
    this.photoMimeType,
    this.type,
    this.typeSlug,
    this.typeName,
    this.businessTypeIds = const [],
    this.businessTypeSlugs = const [],
    this.businessTypeNames = const [],
    this.hasVenue,
    this.targetCityIds = const [],
    this.targetCityNames = const [],
    this.offering,
    this.productType,
    this.communitySize,
    this.cityId,
    this.cityName,
    this.location,
    this.importedPlaceId,
    this.venueName,
    this.venueType,
    this.venueCapacity,
    this.venuePhotos = const [],
    this.venuePhone,
    this.venueWebsite,
    this.venueOpeningHours = const [],
    this.venueDescription,
    this.venuePriceLevel,
    this.venueRating,
    this.venueUserRatingsTotal,
    this.venueGooglePlaceTypes = const [],
    this.about,
    this.phone,
    this.instagram,
    this.tiktok,
    this.website,
    this.referralCode,
    this.currentStep = 1,
  });

  /// User type (business or community)
  final UserType userType;

  /// Business name or display name
  final String? name;

  /// Profile photo as base64 encoded string
  final String? photoBase64;

  /// Profile photo file name
  final String? photoFileName;

  /// Profile photo MIME type (e.g., 'image/jpeg', 'image/png')
  final String? photoMimeType;

  /// Business type ID or community type ID
  final String? type;

  /// Type slug for API payload (e.g., 'restaurante', 'running-club')
  final String? typeSlug;

  /// Type display name for summary
  final String? typeName;

  /// Business category ids (business only, up to 3)
  final List<String> businessTypeIds;

  /// Business category slugs (business only, up to 3)
  final List<String> businessTypeSlugs;

  /// Business category display names (business only, up to 3)
  final List<String> businessTypeNames;

  /// Goal selected on the first business onboarding step.
  ///
  /// `true`  -> "Fill my venue" (venue path: Google Places lookup, etc.).
  /// `false` -> "Promote a product/service" (product path: no physical venue).
  /// `null`  -> not chosen yet. Sent to the backend as `has_venue`; the column
  /// is being added server-side separately, so the submit is guarded against a
  /// 422 on the unknown field (see [OnboardingNotifier.completeWithEmail]).
  final bool? hasVenue;

  /// Target city ids for the product path (business with no venue).
  ///
  /// Free businesses may pick up to 3 cities; Premium is unlimited. The UI
  /// enforces the free limit. Sent to the backend as `target_city_ids[]`.
  final List<String> targetCityIds;

  /// Display names for [targetCityIds], parallel-indexed (for summaries/chips).
  final List<String> targetCityNames;

  /// Optional free-text "what you offer" (product path, business only).
  final String? offering;

  /// Product-type slug (product path, business only). Drives the backend
  /// auto-offer category. Admin-managed via `GET /lookup/product-types`; slugs
  /// match `ProductType.toApiValue()`. Sent as `product_type`; the field is
  /// being added server-side, so the submit is guarded against a 422 on the
  /// unknown field (see [OnboardingNotifier.completeWithEmail]).
  final String? productType;

  /// Stable community size captured during community onboarding (community
  /// only). Sent as `community_size`; the column is being added server-side, so
  /// the submit is guarded against a 422 on the unknown field.
  final int? communitySize;

  /// Selected city ID
  final String? cityId;

  /// City display name for summary
  final String? cityName;

  /// Selected business place from autocomplete
  final PlaceSuggestion? location;

  /// Place id that was last successfully imported from Google.
  final String? importedPlaceId;

  /// Primary venue name (business only)
  final String? venueName;

  /// Primary venue type API value (business only)
  final String? venueType;

  /// Primary venue capacity (business only)
  final int? venueCapacity;

  /// Primary venue photos (business only)
  final List<OnboardingPhoto> venuePhotos;

  /// Primary venue phone number (business only)
  final String? venuePhone;

  /// Primary venue website (business only)
  final String? venueWebsite;

  /// Primary venue opening hours copied from Google import when available.
  final List<String> venueOpeningHours;

  /// Primary venue description sent alongside the top-level business about.
  final String? venueDescription;

  /// Primary venue Google price level.
  final String? venuePriceLevel;

  /// Primary venue Google rating.
  final double? venueRating;

  /// Primary venue Google review count.
  final int? venueUserRatingsTotal;

  /// Primary venue Google place types.
  final List<String> venueGooglePlaceTypes;

  /// About text (optional)
  final String? about;

  /// Phone number in E.164 format (optional, business only)
  final String? phone;

  /// Instagram handle without @ (optional)
  final String? instagram;

  /// TikTok handle without @ (optional, community only)
  final String? tiktok;

  /// Website URL (optional)
  final String? website;

  /// Optional referral code for business signups.
  final String? referralCode;

  /// Current onboarding step (1-4)
  final int currentStep;

  /// Resolved business ids including legacy single-select data.
  List<String> get selectedBusinessTypeIds {
    if (businessTypeIds.isNotEmpty) return businessTypeIds;
    if (type != null && type!.isNotEmpty) return [type!];
    return const [];
  }

  /// Resolved business slugs including legacy single-select data.
  List<String> get selectedBusinessTypeSlugs {
    if (businessTypeSlugs.isNotEmpty) return businessTypeSlugs;
    if (typeSlug != null && typeSlug!.isNotEmpty) return [typeSlug!];
    return const [];
  }

  /// Resolved business names including legacy single-select data.
  List<String> get selectedBusinessTypeNames {
    if (businessTypeNames.isNotEmpty) return businessTypeNames;
    if (typeName != null && typeName!.isNotEmpty) return [typeName!];
    return const [];
  }

  /// UI summary for the selected business categories.
  String get businessTypesSummary {
    final names = selectedBusinessTypeNames;
    if (names.isEmpty) return 'Unknown type';
    return names.join(' · ');
  }

  /// True when this is a business that chose the "promote a product/service"
  /// goal (no physical venue). Used to branch onboarding completeness and
  /// navigation between the venue path and the product path.
  bool get isProductBusiness => isBusiness && hasVenue == false;

  /// Check if step 1 is complete (name is required)
  bool get isStep1Complete {
    if (isProductBusiness) {
      // Product path step 1 is identity: name + at least one category.
      return name != null &&
          name!.trim().isNotEmpty &&
          selectedBusinessTypeSlugs.isNotEmpty;
    }
    if (isBusiness) {
      return location != null &&
          location!.city.trim().isNotEmpty &&
          location!.formattedAddress.trim().isNotEmpty;
    }
    return name != null && name!.trim().isNotEmpty;
  }

  /// Check if step 2 is complete.
  ///
  /// For business users this is the merged business + venue identity screen,
  /// requiring business name, at least one business type, venue type and
  /// capacity. The venue name is mirrored from the business name.
  bool get isStep2Complete {
    if (isProductBusiness) {
      // Product path step 2 is the multi-select cities step.
      return targetCityIds.isNotEmpty;
    }
    if (isBusiness) {
      return name != null &&
          name!.trim().isNotEmpty &&
          selectedBusinessTypeSlugs.isNotEmpty &&
          venueType != null &&
          venueType!.trim().isNotEmpty &&
          venueCapacity != null &&
          venueCapacity! > 0;
    }
    return type != null && type!.isNotEmpty;
  }

  /// Check if step 3 is complete (city is required)
  bool get isStep3Complete {
    if (isProductBusiness) {
      // Product path step 3 (about/contact + optional offer photos) has no hard
      // requirement beyond steps 1-2; about and photos are optional.
      return true;
    }
    if (isBusiness) {
      return venuePhotos.isNotEmpty;
    }
    return cityId != null && cityId!.isNotEmpty;
  }

  /// Check if step 4 is complete.
  ///
  /// For business users the step-3 (legacy) profile form was merged into
  /// step 2, so this delegates to [isStep2Complete] and is kept for
  /// compatibility with [canProceed] / [isComplete].
  bool get isStep4Complete {
    if (isProductBusiness) return true;
    if (isBusiness) return isStep2Complete;
    return true;
  }

  /// Check if all required fields are complete
  bool get isComplete =>
      isStep1Complete && isStep2Complete && isStep3Complete && isStep4Complete;

  /// Is business user
  bool get isBusiness => userType == UserType.business;

  /// Is community user
  bool get isCommunity => userType == UserType.community;

  OnboardingData copyWith({
    UserType? userType,
    String? name,
    String? photoBase64,
    String? photoFileName,
    String? photoMimeType,
    String? type,
    String? typeSlug,
    String? typeName,
    List<String>? businessTypeIds,
    List<String>? businessTypeSlugs,
    List<String>? businessTypeNames,
    bool? hasVenue,
    List<String>? targetCityIds,
    List<String>? targetCityNames,
    String? offering,
    int? communitySize,
    String? cityId,
    String? cityName,
    PlaceSuggestion? location,
    String? importedPlaceId,
    String? venueName,
    String? venueType,
    int? venueCapacity,
    List<OnboardingPhoto>? venuePhotos,
    String? venuePhone,
    String? venueWebsite,
    List<String>? venueOpeningHours,
    String? venueDescription,
    String? venuePriceLevel,
    double? venueRating,
    int? venueUserRatingsTotal,
    List<String>? venueGooglePlaceTypes,
    String? productType,
    String? about,
    String? phone,
    String? instagram,
    String? tiktok,
    String? website,
    String? referralCode,
    int? currentStep,
    bool clearProductType = false,
    bool clearPhoto = false,
    bool clearAbout = false,
    bool clearPhone = false,
    bool clearInstagram = false,
    bool clearTiktok = false,
    bool clearWebsite = false,
    bool clearLocation = false,
    bool clearImportedPlace = false,
    bool clearVenueName = false,
    bool clearVenueType = false,
    bool clearVenueCapacity = false,
    bool clearVenuePhone = false,
    bool clearVenueWebsite = false,
    bool clearVenueDescription = false,
    bool clearVenuePriceLevel = false,
    bool clearVenueRating = false,
    bool clearVenueUserRatingsTotal = false,
    bool clearTypeSelection = false,
    bool clearReferralCode = false,
    bool clearOffering = false,
    bool clearCommunitySize = false,
  }) => OnboardingData(
    userType: userType ?? this.userType,
    name: name ?? this.name,
    photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
    photoFileName: clearPhoto ? null : (photoFileName ?? this.photoFileName),
    photoMimeType: clearPhoto ? null : (photoMimeType ?? this.photoMimeType),
    type: clearTypeSelection ? null : (type ?? this.type),
    typeSlug: clearTypeSelection ? null : (typeSlug ?? this.typeSlug),
    typeName: clearTypeSelection ? null : (typeName ?? this.typeName),
    businessTypeIds: businessTypeIds ?? this.businessTypeIds,
    businessTypeSlugs: businessTypeSlugs ?? this.businessTypeSlugs,
    businessTypeNames: businessTypeNames ?? this.businessTypeNames,
    hasVenue: hasVenue ?? this.hasVenue,
    targetCityIds: targetCityIds ?? this.targetCityIds,
    targetCityNames: targetCityNames ?? this.targetCityNames,
    offering: clearOffering ? null : (offering ?? this.offering),
    productType: clearProductType ? null : (productType ?? this.productType),
    communitySize: clearCommunitySize
        ? null
        : (communitySize ?? this.communitySize),
    cityId: cityId ?? this.cityId,
    cityName: cityName ?? this.cityName,
    location: clearLocation ? null : (location ?? this.location),
    importedPlaceId: clearImportedPlace
        ? null
        : (importedPlaceId ?? this.importedPlaceId),
    venueName: clearVenueName ? null : (venueName ?? this.venueName),
    venueType: clearVenueType ? null : (venueType ?? this.venueType),
    venueCapacity: clearVenueCapacity
        ? null
        : (venueCapacity ?? this.venueCapacity),
    venuePhotos: venuePhotos ?? this.venuePhotos,
    venuePhone: clearVenuePhone ? null : (venuePhone ?? this.venuePhone),
    venueWebsite: clearVenueWebsite
        ? null
        : (venueWebsite ?? this.venueWebsite),
    venueOpeningHours: venueOpeningHours ?? this.venueOpeningHours,
    venueDescription: clearVenueDescription
        ? null
        : (venueDescription ?? this.venueDescription),
    venuePriceLevel: clearVenuePriceLevel
        ? null
        : (venuePriceLevel ?? this.venuePriceLevel),
    venueRating: clearVenueRating ? null : (venueRating ?? this.venueRating),
    venueUserRatingsTotal: clearVenueUserRatingsTotal
        ? null
        : (venueUserRatingsTotal ?? this.venueUserRatingsTotal),
    venueGooglePlaceTypes: venueGooglePlaceTypes ?? this.venueGooglePlaceTypes,
    about: clearAbout ? null : (about ?? this.about),
    phone: clearPhone ? null : (phone ?? this.phone),
    instagram: clearInstagram ? null : (instagram ?? this.instagram),
    tiktok: clearTiktok ? null : (tiktok ?? this.tiktok),
    website: clearWebsite ? null : (website ?? this.website),
    referralCode: clearReferralCode
        ? null
        : (referralCode ?? this.referralCode),
    currentStep: currentStep ?? this.currentStep,
  );

  /// Get profile photo as data URI format
  String? get _profilePhotoDataUri {
    if (photoBase64 == null) return null;
    final mimeType = photoMimeType ?? 'image/jpeg';
    return 'data:$mimeType;base64,$photoBase64';
  }

  /// Convert to business onboarding API payload
  Map<String, dynamic> toBusinessPayload() {
    final resolvedCityId = location?.cityId ?? cityId;
    final resolvedCityName = (location?.city.isNotEmpty ?? false)
        ? location!.city
        : cityName;
    final resolvedBusinessSlugs = selectedBusinessTypeSlugs;
    final normalizedReferralCode = normalizeReferralCode(referralCode);
    // Product path uses the first selected target city as the profile city when
    // there is no venue to derive it from.
    final productCityId = (resolvedCityId == null || resolvedCityId.isEmpty)
        ? (targetCityIds.isNotEmpty ? targetCityIds.first : null)
        : resolvedCityId;
    final productCityName = (resolvedCityName == null || resolvedCityName.isEmpty)
        ? (targetCityNames.isNotEmpty ? targetCityNames.first : null)
        : resolvedCityName;

    return {
      'name': name?.trim(),
      if (_profilePhotoDataUri != null) 'profile_photo': _profilePhotoDataUri,
      if (resolvedBusinessSlugs.isNotEmpty)
        'business_type': resolvedBusinessSlugs.first,
      if (resolvedBusinessSlugs.isNotEmpty)
        'business_types': resolvedBusinessSlugs,
      if (resolvedBusinessSlugs.isNotEmpty) 'categories': resolvedBusinessSlugs,
      // Goal flag — backend column `business_profiles.has_venue` (being added
      // separately). Only sent when a goal was actually chosen.
      if (hasVenue != null) 'has_venue': hasVenue,
      if (isProductBusiness) ...{
        if (productCityId != null && productCityId.isNotEmpty)
          'city_id': productCityId,
        if (productCityName != null && productCityName.isNotEmpty)
          'city_name': productCityName,
        if (targetCityIds.isNotEmpty) 'target_city_ids': targetCityIds,
        if (offering != null && offering!.trim().isNotEmpty)
          'offering': offering!.trim(),
        // Drives the backend auto-offer category. Guarded by the 422-strip
        // retry so onboarding still completes if the field isn't deployed.
        if (productType != null && productType!.trim().isNotEmpty)
          'product_type': productType!.trim(),
        if (venuePhotos.isNotEmpty)
          'offer_photos': venuePhotos
              .map((photo) => photo.payloadValue)
              .where((value) => value.trim().isNotEmpty)
              .toList(),
      } else ...{
        if (resolvedCityId != null && resolvedCityId.isNotEmpty)
          'city_id': resolvedCityId,
        if (resolvedCityName != null && resolvedCityName.isNotEmpty)
          'city_name': resolvedCityName,
      },
      if (about != null && about!.isNotEmpty) 'about': about?.trim(),
      if (phone != null && phone!.isNotEmpty) 'phone_number': phone?.trim(),
      if (instagram != null && instagram!.isNotEmpty)
        'instagram': instagram?.trim(),
      if (website != null && website!.isNotEmpty) 'website': website?.trim(),
      if (normalizedReferralCode != null)
        'referral_code': normalizedReferralCode,
      // Venue path only — product businesses have no physical venue.
      if (!isProductBusiness) 'primary_venue': {
        'name': venueName?.trim(),
        'venue_type': venueType,
        'capacity': venueCapacity,
        'place_id': location?.placeId,
        'formatted_address': location?.formattedAddress,
        'city': location?.city,
        if (location?.country != null) 'country': location?.country,
        if (location?.latitude != null) 'latitude': location?.latitude,
        if (location?.longitude != null) 'longitude': location?.longitude,
        if (venuePhone != null && venuePhone!.isNotEmpty)
          'phone_number': venuePhone?.trim(),
        if (venueWebsite != null && venueWebsite!.isNotEmpty)
          'website': venueWebsite?.trim(),
        if (venueOpeningHours.isNotEmpty) 'opening_hours': venueOpeningHours,
        if (venueDescription != null && venueDescription!.isNotEmpty)
          'description': venueDescription?.trim(),
        if (venuePriceLevel != null && venuePriceLevel!.isNotEmpty)
          'price_level': venuePriceLevel,
        if (venueRating != null) 'rating': venueRating,
        if (venueUserRatingsTotal != null)
          'user_ratings_total': venueUserRatingsTotal,
        if (venueGooglePlaceTypes.isNotEmpty)
          'google_place_types': venueGooglePlaceTypes,
        if (venuePhotos.isNotEmpty)
          'photos': venuePhotos
              .map((photo) => photo.payloadValue)
              .where((value) => value.trim().isNotEmpty)
              .toList(),
      },
    };
  }

  /// Convert to community onboarding API payload
  Map<String, dynamic> toCommunityPayload() => {
    'name': name?.trim(),
    if (_profilePhotoDataUri != null) 'profile_photo': _profilePhotoDataUri,
    'community_type': typeSlug,
    'city_id': cityId,
    // Stable community size — backend column `community_profiles.community_size`
    // (being added separately). Guarded against a 422 on the unknown field at
    // the submit layer.
    if (communitySize != null) 'community_size': communitySize,
    if (about != null && about!.isNotEmpty) 'about': about?.trim(),
    if (phone != null && phone!.isNotEmpty) 'phone_number': phone?.trim(),
    if (instagram != null && instagram!.isNotEmpty)
      'instagram': instagram?.trim(),
    if (tiktok != null && tiktok!.isNotEmpty) 'tiktok': tiktok?.trim(),
    if (website != null && website!.isNotEmpty) 'website': website?.trim(),
  };

  @override
  String toString() =>
      'OnboardingData(userType: $userType, name: $name, type: $type, cityId: $cityId, place: ${location?.placeId}, importedPlaceId: $importedPlaceId, step: $currentStep)';
}
