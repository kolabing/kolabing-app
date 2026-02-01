import 'package:flutter/foundation.dart';

import '../providers/gallery_provider.dart';

// =============================================================================
// Past Collaboration Model
// =============================================================================

@immutable
class PastCollaboration {
  const PastCollaboration({
    required this.id,
    required this.title,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.completedAt,
    this.status = 'completed',
  });

  factory PastCollaboration.fromJson(Map<String, dynamic> json) =>
      PastCollaboration(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        partnerName: json['partner_name'] as String? ?? '',
        partnerAvatarUrl: json['partner_avatar_url'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String) ??
                DateTime.now()
            : DateTime.now(),
        status: json['status'] as String? ?? 'completed',
      );

  final String id;
  final String title;
  final String partnerName;
  final String? partnerAvatarUrl;
  final DateTime completedAt;
  final String status;

  String get partnerInitial =>
      partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?';
}

// =============================================================================
// Public Profile Model
// =============================================================================

@immutable
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.userType,
    required this.displayName,
    this.avatarUrl,
    this.about,
    this.type,
    this.cityName,
    this.instagram,
    this.tiktok,
    this.website,
    this.gallery = const [],
    this.pastCollaborations = const [],
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
        id: json['id']?.toString() ?? '',
        userType: json['user_type'] as String? ?? '',
        displayName: json['display_name'] as String? ?? 'Unknown',
        avatarUrl: json['avatar_url'] as String?,
        about: json['about'] as String?,
        type: json['type'] as String?,
        cityName: json['city_name'] as String?,
        instagram: json['instagram'] as String?,
        tiktok: json['tiktok'] as String?,
        website: json['website'] as String?,
        gallery: (json['gallery'] as List<dynamic>?)
                ?.map((e) => GalleryPhoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        pastCollaborations: (json['past_collaborations'] as List<dynamic>?)
                ?.map((e) =>
                    PastCollaboration.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  final String id;
  final String userType;
  final String displayName;
  final String? avatarUrl;
  final String? about;
  final String? type;
  final String? cityName;
  final String? instagram;
  final String? tiktok;
  final String? website;
  final List<GalleryPhoto> gallery;
  final List<PastCollaboration> pastCollaborations;

  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  bool get isBusiness => userType == 'business';
  bool get isCommunity => userType == 'community';

  bool get hasAbout => about != null && about!.isNotEmpty;
  bool get hasGallery => gallery.isNotEmpty;
  bool get hasCollaborations => pastCollaborations.isNotEmpty;
  bool get hasSocialLinks =>
      (instagram != null && instagram!.isNotEmpty) ||
      (tiktok != null && tiktok!.isNotEmpty) ||
      (website != null && website!.isNotEmpty);

  PublicProfile copyWith({
    List<GalleryPhoto>? gallery,
    List<PastCollaboration>? pastCollaborations,
  }) =>
      PublicProfile(
        id: id,
        userType: userType,
        displayName: displayName,
        avatarUrl: avatarUrl,
        about: about,
        type: type,
        cityName: cityName,
        instagram: instagram,
        tiktok: tiktok,
        website: website,
        gallery: gallery ?? this.gallery,
        pastCollaborations: pastCollaborations ?? this.pastCollaborations,
      );
}
