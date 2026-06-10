import 'package:flutter/foundation.dart';

import '../../../utils/profile_type_formatter.dart';
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

@immutable
class PublicProfileReviewAuthor {
  const PublicProfileReviewAuthor({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.userType,
  });

  factory PublicProfileReviewAuthor.fromJson(Map<String, dynamic> json) =>
      PublicProfileReviewAuthor(
        id: json['id']?.toString() ?? '',
        displayName: json['display_name'] as String? ?? 'Unknown',
        avatarUrl: json['avatar_url'] as String?,
        userType: json['user_type'] as String? ?? '',
      );

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String userType;

  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}

@immutable
class PublicProfileReview {
  const PublicProfileReview({
    required this.id,
    required this.rating,
    this.body,
    this.wouldCollaborateAgain,
    this.createdAt,
    required this.reviewer,
  });

  factory PublicProfileReview.fromJson(Map<String, dynamic> json) =>
      PublicProfileReview(
        id: json['id']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        body: json['body'] as String?,
        wouldCollaborateAgain: json['would_collaborate_again'] as bool?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        reviewer: PublicProfileReviewAuthor.fromJson(
          (json['reviewer'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
      );

  final String id;
  final int rating;
  final String? body;
  final bool? wouldCollaborateAgain;
  final DateTime? createdAt;
  final PublicProfileReviewAuthor reviewer;

  bool get hasBody => body != null && body!.trim().isNotEmpty;
}

@immutable
class PaginatedPublicProfileReviews {
  const PaginatedPublicProfileReviews({
    required this.reviews,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<PublicProfileReview> reviews;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
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
    this.serverTypeLabel,
    this.cityName,
    this.instagram,
    this.tiktok,
    this.website,
    this.gallery = const [],
    this.pastCollaborations = const [],
    this.completedKolabsCount,
    this.recentReviews = const [],
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
    id: json['id']?.toString() ?? '',
    userType: json['user_type'] as String? ?? '',
    displayName: json['display_name'] as String? ?? 'Unknown',
    // Logo is returned as an absolute URL. `PublicProfileResource` exposes
    // it under three identical keys (`avatar_url`, `logo_url`,
    // `profile_photo`); read them in order so the model is resilient to the
    // backend trimming any single key later.
    avatarUrl: _firstNonEmpty([
      json['avatar_url'] as String?,
      json['logo_url'] as String?,
      json['profile_photo'] as String?,
    ]),
    about: json['about'] as String?,
    type: json['type'] as String?,
    // Server-formatted, human-readable type label (e.g. "Run Club"). When
    // present we display it verbatim and never re-format it client-side.
    serverTypeLabel: json['type_label'] as String?,
    cityName: json['city_name'] as String?,
    instagram: json['instagram'] as String?,
    tiktok: json['tiktok'] as String?,
    website: json['website'] as String?,
    gallery:
        (json['gallery'] as List<dynamic>?)
            ?.map((e) => GalleryPhoto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    pastCollaborations:
        (json['past_collaborations'] as List<dynamic>?)
            ?.map((e) => PastCollaboration.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    completedKolabsCount: json['completed_kolabs_count'] as int?,
    recentReviews:
        (json['recent_reviews'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PublicProfileReview.fromJson)
            .toList() ??
        const [],
  );

  final String id;
  final String userType;
  final String displayName;
  final String? avatarUrl;
  final String? about;
  final String? type;

  /// Pre-formatted type label from the backend (`type_label`). Preferred for
  /// display. Null on older payloads, in which case we format [type] locally.
  final String? serverTypeLabel;
  final String? cityName;
  final String? instagram;
  final String? tiktok;
  final String? website;
  final List<GalleryPhoto> gallery;
  final List<PastCollaboration> pastCollaborations;

  /// Authoritative count from backend. Falls back to pastCollaborations.length
  /// when backend hasn't returned the field yet (older payloads).
  final int? completedKolabsCount;
  final List<PublicProfileReview> recentReviews;

  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  bool get isBusiness => userType == 'business';
  bool get isCommunity => userType == 'community';

  /// A member (community attendee). Member profiles are a social hub, not a
  /// collaboration resume, so [PublicProfileScreen] renders a dedicated layout.
  bool get isAttendee => userType == 'attendee';

  /// Whether the loaded display name is missing or the model's "Unknown"
  /// placeholder. Used to fall back to an optimistic name from the caller.
  bool get hasRealDisplayName =>
      displayName.trim().isNotEmpty && displayName != 'Unknown';

  bool get hasAbout => about != null && about!.isNotEmpty;
  bool get hasGallery => gallery.isNotEmpty;
  int get kolabsCount => completedKolabsCount ?? pastCollaborations.length;
  bool get hasCollaborations => kolabsCount > 0;
  bool get hasSocialLinks =>
      (instagram != null && instagram!.isNotEmpty) ||
      (tiktok != null && tiktok!.isNotEmpty) ||
      (website != null && website!.isNotEmpty);

  /// Display label for the profile type. Prefers the backend's pre-formatted
  /// `type_label`; falls back to formatting the raw [type] slug locally so we
  /// never show e.g. "run_club". Never double-transforms the server label.
  String? get typeLabel {
    final server = serverTypeLabel;
    if (server != null && server.trim().isNotEmpty) {
      return server;
    }
    if (type == null || type!.isEmpty) {
      return null;
    }
    return formatProfileTypeLabel(type!);
  }

  PublicProfile copyWith({
    String? userType,
    String? displayName,
    String? avatarUrl,
    List<GalleryPhoto>? gallery,
    List<PastCollaboration>? pastCollaborations,
    int? completedKolabsCount,
    List<PublicProfileReview>? recentReviews,
  }) => PublicProfile(
    id: id,
    userType: userType ?? this.userType,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    about: about,
    type: type,
    serverTypeLabel: serverTypeLabel,
    cityName: cityName,
    instagram: instagram,
    tiktok: tiktok,
    website: website,
    gallery: gallery ?? this.gallery,
    pastCollaborations: pastCollaborations ?? this.pastCollaborations,
    completedKolabsCount: completedKolabsCount ?? this.completedKolabsCount,
    recentReviews: recentReviews ?? this.recentReviews,
  );
}

/// Returns the first non-null, non-blank string from [candidates], or null.
String? _firstNonEmpty(List<String?> candidates) {
  for (final value in candidates) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
