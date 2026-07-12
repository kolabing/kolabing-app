import '../../../utils/profile_type_formatter.dart';
import '../../../utils/remote_media_url.dart';

/// User type enumeration
enum UserType {
  business,
  community,
  attendee;

  /// Parse user type from string
  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'business':
        return UserType.business;
      case 'community':
        return UserType.community;
      case 'attendee':
        return UserType.attendee;
      default:
        return UserType.community;
    }
  }

  /// Convert to API string value
  String toApiValue() => name;

  /// Display label for UI
  String get label {
    switch (this) {
      case UserType.business:
        return 'BUSINESS';
      case UserType.community:
        return 'COMMUNITY';
      case UserType.attendee:
        return 'ATTENDEE';
    }
  }
}

/// City model for user profile
class City {
  const City({required this.id, required this.name, this.country});

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String,
    country: json['country'] as String?,
  );

  final String id;
  final String name;
  final String? country;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (country != null) 'country': country,
  };
}

/// Business profile model
class PrimaryVenueProfile {
  const PrimaryVenueProfile({
    required this.name,
    required this.formattedAddress,
    required this.city,
    this.placeId,
    this.country,
    this.latitude,
    this.longitude,
    this.venueType,
    this.capacity,
    this.photos = const [],
  });

  factory PrimaryVenueProfile.fromJson(Map<String, dynamic> json) =>
      PrimaryVenueProfile(
        name: json['name']?.toString() ?? '',
        formattedAddress:
            json['formatted_address']?.toString() ??
            json['address']?.toString() ??
            '',
        city: json['city']?.toString() ?? '',
        placeId: json['place_id']?.toString(),
        country: json['country']?.toString(),
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        venueType: json['venue_type']?.toString(),
        capacity: _parseInt(json['capacity']),
        photos: json['photos'] is List
            ? (json['photos'] as List)
                  .map((e) => normalizeRemoteMediaUrl(e.toString()))
                  .where((url) => url.isNotEmpty)
                  .toList()
            : const [],
      );

  final String name;
  final String formattedAddress;
  final String city;
  final String? placeId;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? venueType;
  final int? capacity;
  final List<String> photos;

  Map<String, dynamic> toJson() => {
    'name': name,
    'formatted_address': formattedAddress,
    'city': city,
    if (placeId != null) 'place_id': placeId,
    if (country != null) 'country': country,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (venueType != null) 'venue_type': venueType,
    if (capacity != null) 'capacity': capacity,
    if (photos.isNotEmpty) 'photos': photos,
  };
}

class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.name,
    this.about,
    this.businessType,
    this.businessTypes = const [],
    this.city,
    this.instagram,
    this.website,
    this.profilePhoto,
    this.primaryVenue,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    final rawBusinessTypes = json['business_types'] as List<dynamic>?;
    final businessTypes =
        rawBusinessTypes?.map((e) => e.toString()).toList() ?? const <String>[];

    return BusinessProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      about: json['about'] as String?,
      businessType:
          (json['business_type'] as String?) ??
          (businessTypes.isNotEmpty ? businessTypes.first : null),
      businessTypes: businessTypes,
      city: json['city'] != null
          ? City.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      instagram: json['instagram'] as String?,
      website: json['website'] as String?,
      profilePhoto: json['profile_photo'] as String?,
      primaryVenue: json['primary_venue'] != null
          ? PrimaryVenueProfile.fromJson(
              json['primary_venue'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String id;
  final String name;
  final String? about;
  final String? businessType;
  final List<String> businessTypes;
  final City? city;
  final String? instagram;
  final String? website;
  final String? profilePhoto;
  final PrimaryVenueProfile? primaryVenue;

  String get businessTypesSummary {
    if (businessTypes.isNotEmpty) {
      return businessTypes.map(formatProfileTypeLabel).join(' · ');
    }
    return formatProfileTypeLabel(businessType ?? 'Business');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (about != null) 'about': about,
    if (businessType != null) 'business_type': businessType,
    if (businessTypes.isNotEmpty) 'business_types': businessTypes,
    if (city != null) 'city': city!.toJson(),
    if (instagram != null) 'instagram': instagram,
    if (website != null) 'website': website,
    if (profilePhoto != null) 'profile_photo': profilePhoto,
    if (primaryVenue != null) 'primary_venue': primaryVenue!.toJson(),
  };
}

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Community profile model
class CommunityProfile {
  const CommunityProfile({
    required this.id,
    required this.name,
    this.about,
    this.communityType,
    this.city,
    this.instagram,
    this.tiktok,
    this.website,
    this.profilePhoto,
    this.communitySize,
  });

  factory CommunityProfile.fromJson(Map<String, dynamic> json) =>
      CommunityProfile(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        about: json['about'] as String?,
        communityType: json['community_type'] as String?,
        city: json['city'] != null
            ? City.fromJson(json['city'] as Map<String, dynamic>)
            : null,
        instagram: json['instagram'] as String?,
        tiktok: json['tiktok'] as String?,
        website: json['website'] as String?,
        profilePhoto: json['profile_photo'] as String?,
        communitySize: json['community_size'] is int
            ? json['community_size'] as int
            : int.tryParse('${json['community_size'] ?? ''}'),
      );

  final String id;
  final String name;
  final String? about;
  final String? communityType;
  final City? city;
  final String? instagram;
  final String? tiktok;
  final String? website;
  final String? profilePhoto;

  /// Approximate member count (backend column `community_profiles.community_size`).
  final int? communitySize;

  String get communityTypeLabel =>
      formatProfileTypeLabel(communityType ?? 'Community');

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (about != null) 'about': about,
    if (communityType != null) 'community_type': communityType,
    if (city != null) 'city': city!.toJson(),
    if (instagram != null) 'instagram': instagram,
    if (tiktok != null) 'tiktok': tiktok,
    if (website != null) 'website': website,
    if (profilePhoto != null) 'profile_photo': profilePhoto,
    if (communitySize != null) 'community_size': communitySize,
  };
}

/// User subscription model
class UserSubscription {
  const UserSubscription({
    required this.status,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      UserSubscription(
        status: json['status'] as String,
        currentPeriodEnd: json['current_period_end'] != null
            ? DateTime.parse(json['current_period_end'] as String)
            : null,
        cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      );

  final String status;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  bool get isActive => status == 'active';

  Map<String, dynamic> toJson() => {
    'status': status,
    if (currentPeriodEnd != null)
      'current_period_end': currentPeriodEnd!.toIso8601String(),
    'cancel_at_period_end': cancelAtPeriodEnd,
  };
}

/// Legal-agreement (Terms of Service + Privacy Policy) consent state, returned
/// as a `terms` block on the user by GET /auth/me. The version is always read
/// from the backend — never hardcoded in the app.
class UserTerms {
  const UserTerms({
    this.currentVersion,
    this.acceptedVersion,
    this.acceptedAt,
    this.needsAcceptance = false,
  });

  factory UserTerms.fromJson(Map<String, dynamic> json) => UserTerms(
    currentVersion: json['current_version'] as String?,
    acceptedVersion: json['accepted_version'] as String?,
    acceptedAt: json['accepted_at'] != null
        ? DateTime.tryParse(json['accepted_at'] as String)
        : null,
    needsAcceptance: json['needs_acceptance'] as bool? ?? false,
  );

  /// The currently-published agreement version (date-based, e.g. `2026-07-12`).
  final String? currentVersion;

  /// The version the user last accepted (null if never).
  final String? acceptedVersion;

  /// When the user last accepted.
  final DateTime? acceptedAt;

  /// True when the user must (re-)accept before continuing.
  final bool needsAcceptance;

  Map<String, dynamic> toJson() => {
    if (currentVersion != null) 'current_version': currentVersion,
    if (acceptedVersion != null) 'accepted_version': acceptedVersion,
    if (acceptedAt != null) 'accepted_at': acceptedAt!.toIso8601String(),
    'needs_acceptance': needsAcceptance,
  };
}

/// Attendee profile model for gamification stats
class AttendeeProfileData {
  const AttendeeProfileData({
    required this.id,
    required this.profileId,
    this.totalPoints = 0,
    this.totalChallengesCompleted = 0,
    this.totalEventsAttended = 0,
    this.globalRank,
  });

  factory AttendeeProfileData.fromJson(Map<String, dynamic> json) =>
      AttendeeProfileData(
        id: json['id']?.toString() ?? '',
        profileId: json['profile_id']?.toString() ?? '',
        totalPoints: json['total_points'] as int? ?? 0,
        totalChallengesCompleted:
            json['total_challenges_completed'] as int? ?? 0,
        totalEventsAttended: json['total_events_attended'] as int? ?? 0,
        globalRank: json['global_rank'] as int?,
      );

  final String id;
  final String profileId;
  final int totalPoints;
  final int totalChallengesCompleted;
  final int totalEventsAttended;
  final int? globalRank;

  Map<String, dynamic> toJson() => {
    'id': id,
    'profile_id': profileId,
    'total_points': totalPoints,
    'total_challenges_completed': totalChallengesCompleted,
    'total_events_attended': totalEventsAttended,
    if (globalRank != null) 'global_rank': globalRank,
  };
}

/// Main user model
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.userType,
    this.phoneNumber,
    this.avatarUrl,
    this.hasActiveSubscription = false,
    this.businessProfile,
    this.communityProfile,
    this.attendeeProfile,
    this.subscription,
    this.createdAt,
    this.name,
    this.handle,
    this.interests = const [],
    this.cityId,
    this.cityName,
    this.terms,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    userType: UserType.fromString(json['user_type']?.toString() ?? ''),
    phoneNumber: json['phone_number'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    hasActiveSubscription: json['has_active_subscription'] as bool? ?? false,
    businessProfile: json['business_profile'] != null
        ? BusinessProfile.fromJson(
            json['business_profile'] as Map<String, dynamic>,
          )
        : null,
    communityProfile: json['community_profile'] != null
        ? CommunityProfile.fromJson(
            json['community_profile'] as Map<String, dynamic>,
          )
        : null,
    attendeeProfile: json['attendee_profile'] != null
        ? AttendeeProfileData.fromJson(
            json['attendee_profile'] as Map<String, dynamic>,
          )
        : null,
    subscription: json['subscription'] != null
        ? UserSubscription.fromJson(
            json['subscription'] as Map<String, dynamic>,
          )
        : null,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
    // Universal identity fields on `profiles` (identity contract §1/§2). Present
    // once the backend deploys; null/empty on older payloads.
    name: json['name'] as String?,
    handle: json['handle'] as String?,
    interests:
        (json['interests'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    // Top-level city on `profiles` (attendees have no business/community
    // profile to carry it). Returned by /me/profile once the backend deploys.
    cityId: json['city_id'] as String?,
    cityName: json['city_name'] as String?,
    terms: json['terms'] != null
        ? UserTerms.fromJson(json['terms'] as Map<String, dynamic>)
        : null,
  );

  final String id;
  final String email;
  final UserType userType;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool hasActiveSubscription;
  final BusinessProfile? businessProfile;
  final CommunityProfile? communityProfile;
  final AttendeeProfileData? attendeeProfile;
  final UserSubscription? subscription;
  final DateTime? createdAt;

  /// Top-level display name on `profiles` (used by attendees, who have no
  /// business/community profile). Null on older payloads.
  final String? name;

  /// Top-level city on `profiles` (attendees). Null on older payloads / roles
  /// that carry city on their extended profile.
  final String? cityId;
  final String? cityName;

  /// Universal `@handle` (lowercase, `^[a-z0-9_]{3,20}$`). Null until set.
  final String? handle;

  /// Community-type interest SLUGS chosen at onboarding (identity contract §2).
  final List<String> interests;

  /// Legal-agreement consent state (`terms` block from GET /auth/me). Null on
  /// older payloads / before the backend deploys the consent flow.
  final UserTerms? terms;

  /// True when the user must (re-)accept the current Terms + Privacy version.
  bool get needsTermsAcceptance => terms?.needsAcceptance ?? false;

  /// Check if user is business type
  bool get isBusiness => userType == UserType.business;

  /// Check if user is community type
  bool get isCommunity => userType == UserType.community;

  /// Check if user is attendee type
  bool get isAttendee => userType == UserType.attendee;

  /// Get display name from profile
  String get displayName {
    if (isBusiness && businessProfile != null) {
      return businessProfile!.name;
    } else if (isCommunity && communityProfile != null) {
      return communityProfile!.name;
    }
    // Attendees carry their name at the top level (`profiles.name`).
    if (name != null && name!.trim().isNotEmpty) {
      return name!.trim();
    }
    return email.split('@').first;
  }

  /// Get profile photo URL (normalized to an absolute URL — the raw
  /// `profile_photo` from the API can be relative/host-less, which fails
  /// `Image.network` and falls back to an initials placeholder).
  String? get profilePhotoUrl {
    final raw = (isBusiness && businessProfile != null)
        ? businessProfile!.profilePhoto
        : (isCommunity && communityProfile != null)
            ? communityProfile!.profilePhoto
            : avatarUrl;
    if (raw == null || raw.trim().isEmpty) return null;
    return normalizeRemoteMediaUrl(raw);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'user_type': userType.toApiValue(),
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'has_active_subscription': hasActiveSubscription,
    if (businessProfile != null) 'business_profile': businessProfile!.toJson(),
    if (communityProfile != null)
      'community_profile': communityProfile!.toJson(),
    if (attendeeProfile != null) 'attendee_profile': attendeeProfile!.toJson(),
    if (subscription != null) 'subscription': subscription!.toJson(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (name != null) 'name': name,
    if (handle != null) 'handle': handle,
    if (interests.isNotEmpty) 'interests': interests,
    if (terms != null) 'terms': terms!.toJson(),
  };

  UserModel copyWith({
    String? id,
    String? email,
    UserType? userType,
    String? phoneNumber,
    String? avatarUrl,
    bool? hasActiveSubscription,
    BusinessProfile? businessProfile,
    CommunityProfile? communityProfile,
    AttendeeProfileData? attendeeProfile,
    UserSubscription? subscription,
    DateTime? createdAt,
    String? name,
    String? handle,
    List<String>? interests,
    String? cityId,
    String? cityName,
    UserTerms? terms,
  }) => UserModel(
    id: id ?? this.id,
    email: email ?? this.email,
    userType: userType ?? this.userType,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
    businessProfile: businessProfile ?? this.businessProfile,
    communityProfile: communityProfile ?? this.communityProfile,
    attendeeProfile: attendeeProfile ?? this.attendeeProfile,
    subscription: subscription ?? this.subscription,
    createdAt: createdAt ?? this.createdAt,
    name: name ?? this.name,
    handle: handle ?? this.handle,
    interests: interests ?? this.interests,
    cityId: cityId ?? this.cityId,
    cityName: cityName ?? this.cityName,
    terms: terms ?? this.terms,
  );
}
