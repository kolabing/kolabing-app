import '../../auth/models/user_model.dart';

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
    this.cityId,
    this.cityName,
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

  /// Selected city ID
  final String? cityId;

  /// City display name for summary
  final String? cityName;

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

  /// Check if step 1 is complete (name is required)
  bool get isStep1Complete => name != null && name!.trim().isNotEmpty;

  /// Check if step 2 is complete (type is required)
  bool get isStep2Complete => type != null && type!.isNotEmpty;

  /// Check if step 3 is complete (city is required)
  bool get isStep3Complete => cityId != null && cityId!.isNotEmpty;

  /// Check if step 4 is complete (always complete - all optional)
  bool get isStep4Complete => true;

  /// Check if all required fields are complete
  bool get isComplete => isStep1Complete && isStep2Complete && isStep3Complete;

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
    String? cityId,
    String? cityName,
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
  }) =>
      OnboardingData(
        userType: userType ?? this.userType,
        name: name ?? this.name,
        photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
        photoFileName:
            clearPhoto ? null : (photoFileName ?? this.photoFileName),
        photoMimeType:
            clearPhoto ? null : (photoMimeType ?? this.photoMimeType),
        type: type ?? this.type,
        typeSlug: typeSlug ?? this.typeSlug,
        typeName: typeName ?? this.typeName,
        cityId: cityId ?? this.cityId,
        cityName: cityName ?? this.cityName,
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
  Map<String, dynamic> toBusinessPayload() => {
        'name': name?.trim(),
        if (_profilePhotoDataUri != null) 'profile_photo': _profilePhotoDataUri,
        'business_type': typeSlug,
        'city_id': cityId,
        if (about != null && about!.isNotEmpty) 'about': about?.trim(),
        if (phone != null && phone!.isNotEmpty) 'phone_number': phone?.trim(),
        if (instagram != null && instagram!.isNotEmpty)
          'instagram': instagram?.trim(),
        if (website != null && website!.isNotEmpty) 'website': website?.trim(),
      };

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
      'OnboardingData(userType: $userType, name: $name, type: $type, cityId: $cityId, step: $currentStep)';
}
