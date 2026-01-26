/// User type enumeration
enum UserType {
  business,
  community;

  /// Parse user type from string
  static UserType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'business':
        return UserType.business;
      case 'community':
        return UserType.community;
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
    }
  }
}

/// City model for user profile
class City {
  const City({
    required this.id,
    required this.name,
    this.country,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
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
class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.name,
    this.about,
    this.businessType,
    this.city,
    this.instagram,
    this.website,
    this.profilePhoto,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) =>
      BusinessProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        about: json['about'] as String?,
        businessType: json['business_type'] as String?,
        city: json['city'] != null
            ? City.fromJson(json['city'] as Map<String, dynamic>)
            : null,
        instagram: json['instagram'] as String?,
        website: json['website'] as String?,
        profilePhoto: json['profile_photo'] as String?,
      );

  final String id;
  final String name;
  final String? about;
  final String? businessType;
  final City? city;
  final String? instagram;
  final String? website;
  final String? profilePhoto;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (about != null) 'about': about,
        if (businessType != null) 'business_type': businessType,
        if (city != null) 'city': city!.toJson(),
        if (instagram != null) 'instagram': instagram,
        if (website != null) 'website': website,
        if (profilePhoto != null) 'profile_photo': profilePhoto,
      };
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
  });

  factory CommunityProfile.fromJson(Map<String, dynamic> json) =>
      CommunityProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        about: json['about'] as String?,
        communityType: json['community_type'] as String?,
        city: json['city'] != null
            ? City.fromJson(json['city'] as Map<String, dynamic>)
            : null,
        instagram: json['instagram'] as String?,
        tiktok: json['tiktok'] as String?,
        website: json['website'] as String?,
        profilePhoto: json['profile_photo'] as String?,
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

/// Main user model
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.userType,
    this.phoneNumber,
    this.avatarUrl,
    this.onboardingCompleted = false,
    this.businessProfile,
    this.communityProfile,
    this.subscription,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        userType: UserType.fromString(json['user_type'] as String),
        phoneNumber: json['phone_number'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
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
        subscription: json['subscription'] != null
            ? UserSubscription.fromJson(
                json['subscription'] as Map<String, dynamic>,
              )
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String email;
  final UserType userType;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool onboardingCompleted;
  final BusinessProfile? businessProfile;
  final CommunityProfile? communityProfile;
  final UserSubscription? subscription;
  final DateTime? createdAt;

  /// Check if user is business type
  bool get isBusiness => userType == UserType.business;

  /// Check if user is community type
  bool get isCommunity => userType == UserType.community;

  /// Get display name from profile
  String get displayName {
    if (isBusiness && businessProfile != null) {
      return businessProfile!.name;
    } else if (isCommunity && communityProfile != null) {
      return communityProfile!.name;
    }
    return email.split('@').first;
  }

  /// Get profile photo URL
  String? get profilePhotoUrl {
    if (isBusiness && businessProfile != null) {
      return businessProfile!.profilePhoto;
    } else if (isCommunity && communityProfile != null) {
      return communityProfile!.profilePhoto;
    }
    return avatarUrl;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'user_type': userType.toApiValue(),
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'onboarding_completed': onboardingCompleted,
        if (businessProfile != null)
          'business_profile': businessProfile!.toJson(),
        if (communityProfile != null)
          'community_profile': communityProfile!.toJson(),
        if (subscription != null) 'subscription': subscription!.toJson(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? email,
    UserType? userType,
    String? phoneNumber,
    String? avatarUrl,
    bool? onboardingCompleted,
    BusinessProfile? businessProfile,
    CommunityProfile? communityProfile,
    UserSubscription? subscription,
    DateTime? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        userType: userType ?? this.userType,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        businessProfile: businessProfile ?? this.businessProfile,
        communityProfile: communityProfile ?? this.communityProfile,
        subscription: subscription ?? this.subscription,
        createdAt: createdAt ?? this.createdAt,
      );
}
