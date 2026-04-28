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
    this.cityId,
    this.cityName,
    this.location,
    this.venueName,
    this.venueType,
    this.venueCapacity,
    this.venuePhotos = const [],
    this.about,
    this.phone,
    this.instagram,
    this.tiktok,
    this.website,
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

  /// Selected city ID
  final String? cityId;

  /// City display name for summary
  final String? cityName;

  /// Selected business place from autocomplete
  final PlaceSuggestion? location;

  /// Primary venue name (business only)
  final String? venueName;

  /// Primary venue type API value (business only)
  final String? venueType;

  /// Primary venue capacity (business only)
  final int? venueCapacity;

  /// Primary venue photos (business only)
  final List<OnboardingPhoto> venuePhotos;

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

  /// Check if step 1 is complete (name is required)
  bool get isStep1Complete {
    if (isBusiness) {
      return location != null &&
          location!.city.trim().isNotEmpty &&
          location!.formattedAddress.trim().isNotEmpty;
    }
    return name != null && name!.trim().isNotEmpty;
  }

  /// Check if step 2 is complete (type is required)
  bool get isStep2Complete {
    if (isBusiness) {
      return venueName != null &&
          venueName!.trim().isNotEmpty &&
          venueType != null &&
          venueType!.trim().isNotEmpty &&
          venueCapacity != null &&
          venueCapacity! > 0;
    }
    return type != null && type!.isNotEmpty;
  }

  /// Check if step 3 is complete (city is required)
  bool get isStep3Complete {
    if (isBusiness) {
      return venuePhotos.isNotEmpty;
    }
    return cityId != null && cityId!.isNotEmpty;
  }

  /// Check if step 4 is complete
  bool get isStep4Complete {
    if (isBusiness) {
      return name != null &&
          name!.trim().isNotEmpty &&
          selectedBusinessTypeSlugs.isNotEmpty;
    }
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
    String? cityId,
    String? cityName,
    PlaceSuggestion? location,
    String? venueName,
    String? venueType,
    int? venueCapacity,
    List<OnboardingPhoto>? venuePhotos,
    String? about,
    String? phone,
    String? instagram,
    String? tiktok,
    String? website,
    int? currentStep,
    bool clearPhoto = false,
    bool clearAbout = false,
    bool clearPhone = false,
    bool clearInstagram = false,
    bool clearTiktok = false,
    bool clearWebsite = false,
    bool clearLocation = false,
    bool clearVenueName = false,
    bool clearVenueType = false,
    bool clearVenueCapacity = false,
    bool clearTypeSelection = false,
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
    cityId: cityId ?? this.cityId,
    cityName: cityName ?? this.cityName,
    location: clearLocation ? null : (location ?? this.location),
    venueName: clearVenueName ? null : (venueName ?? this.venueName),
    venueType: clearVenueType ? null : (venueType ?? this.venueType),
    venueCapacity: clearVenueCapacity
        ? null
        : (venueCapacity ?? this.venueCapacity),
    venuePhotos: venuePhotos ?? this.venuePhotos,
    about: clearAbout ? null : (about ?? this.about),
    phone: clearPhone ? null : (phone ?? this.phone),
    instagram: clearInstagram ? null : (instagram ?? this.instagram),
    tiktok: clearTiktok ? null : (tiktok ?? this.tiktok),
    website: clearWebsite ? null : (website ?? this.website),
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
    final resolvedCityName = location?.city.isNotEmpty == true
        ? location!.city
        : cityName;
    final resolvedBusinessSlugs = selectedBusinessTypeSlugs;

    return {
      'name': name?.trim(),
      if (_profilePhotoDataUri != null) 'profile_photo': _profilePhotoDataUri,
      if (resolvedBusinessSlugs.isNotEmpty)
        'business_type': resolvedBusinessSlugs.first,
      if (resolvedBusinessSlugs.isNotEmpty)
        'business_types': resolvedBusinessSlugs,
      if (resolvedCityId != null && resolvedCityId.isNotEmpty)
        'city_id': resolvedCityId,
      if (resolvedCityName != null && resolvedCityName.isNotEmpty)
        'city_name': resolvedCityName,
      if (about != null && about!.isNotEmpty) 'about': about?.trim(),
      if (phone != null && phone!.isNotEmpty) 'phone_number': phone?.trim(),
      if (instagram != null && instagram!.isNotEmpty)
        'instagram': instagram?.trim(),
      if (website != null && website!.isNotEmpty) 'website': website?.trim(),
      'primary_venue': {
        'name': venueName?.trim(),
        'venue_type': venueType,
        'capacity': venueCapacity,
        'place_id': location?.placeId,
        'formatted_address': location?.formattedAddress,
        'city': location?.city,
        if (location?.country != null) 'country': location?.country,
        if (location?.latitude != null) 'latitude': location?.latitude,
        if (location?.longitude != null) 'longitude': location?.longitude,
        if (venuePhotos.isNotEmpty)
          'photos': venuePhotos.map((photo) => photo.dataUri).toList(),
      },
    };
  }

  /// Convert to community onboarding API payload
  Map<String, dynamic> toCommunityPayload() => {
    'name': name?.trim(),
    if (_profilePhotoDataUri != null) 'profile_photo': _profilePhotoDataUri,
    'community_type': typeSlug,
    'city_id': cityId,
    if (about != null && about!.isNotEmpty) 'about': about?.trim(),
    if (phone != null && phone!.isNotEmpty) 'phone_number': phone?.trim(),
    if (instagram != null && instagram!.isNotEmpty)
      'instagram': instagram?.trim(),
    if (tiktok != null && tiktok!.isNotEmpty) 'tiktok': tiktok?.trim(),
    if (website != null && website!.isNotEmpty) 'website': website?.trim(),
  };

  @override
  String toString() =>
      'OnboardingData(userType: $userType, name: $name, type: $type, cityId: $cityId, place: ${location?.placeId}, step: $currentStep)';
}
