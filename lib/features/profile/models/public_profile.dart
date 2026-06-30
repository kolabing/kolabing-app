import 'package:flutter/foundation.dart';

import '../../../utils/profile_type_formatter.dart';
import '../../friends/models/friendship.dart';
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

@immutable
class RatingBreakdown {
  const RatingBreakdown({
    required this.communication,
    required this.reliability,
    required this.fit,
    required this.value,
    required this.repeat,
  });

  factory RatingBreakdown.fromJson(Map<String, dynamic> json) =>
      RatingBreakdown(
        communication: (json['communication'] as num?)?.toDouble() ?? 0,
        reliability: (json['reliability'] as num?)?.toDouble() ?? 0,
        fit: (json['fit'] as num?)?.toDouble() ?? 0,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        repeat: (json['repeat'] as num?)?.toDouble() ?? 0,
      );

  final double communication;
  final double reliability;
  final double fit;
  final double value;
  final double repeat;
}

@immutable
class Reputation {
  const Reputation({
    this.averageRating,
    required this.reviewCount,
    required this.uniquePartnerCount,
    this.breakdown,
  });

  factory Reputation.fromJson(Map<String, dynamic> json) => Reputation(
    averageRating: (json['average_rating'] as num?)?.toDouble(),
    reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    uniquePartnerCount: (json['unique_partner_count'] as num?)?.toInt() ?? 0,
    breakdown: json['breakdown'] != null
        ? RatingBreakdown.fromJson(
            (json['breakdown'] as Map).cast<String, dynamic>(),
          )
        : null,
  );

  final double? averageRating;
  final int reviewCount;
  final int uniquePartnerCount;
  final RatingBreakdown? breakdown;

  bool get hasReviews => reviewCount > 0;
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
    this.friendStatus,
    this.friendsCount = 0,
    this.reputation,
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
    // NF-17: present only once the backend deploys the friend graph. When the
    // key is ABSENT we keep [friendStatus] null so the friend CTA self-gates
    // (hidden). When present but unknown, `FriendStatus.fromApi` defaults to
    // `none`.
    friendStatus: json.containsKey('friend_status')
        ? FriendStatus.fromApi(json['friend_status'] as String?)
        : null,
    friendsCount: (json['friends_count'] as num?)?.toInt() ?? 0,
    reputation: json['reputation'] != null
        ? Reputation.fromJson(
            (json['reputation'] as Map).cast<String, dynamic>(),
          )
        : null,
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

  /// NF-17 friend relationship to the viewer. Null when the backend hasn't
  /// shipped the friend graph yet (older/undeployed payload), in which case
  /// the friend CTA is hidden ([supportsFriends] is false).
  final FriendStatus? friendStatus;

  /// Accepted-friends count for this profile (0 on older payloads).
  final int friendsCount;

  /// PR 4: public reputation summary. Null on older/cached payloads that
  /// predate the backend's `reputation` key.
  final Reputation? reputation;

  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  bool get isBusiness => userType == 'business';
  bool get isCommunity => userType == 'community';

  /// Whether the backend reported a [friendStatus] for this profile. When false
  /// the friend graph is undeployed for this payload and every friend surface
  /// (CTA, count) must stay hidden. Self for your own profile also has no CTA.
  bool get supportsFriends =>
      friendStatus != null && friendStatus != FriendStatus.self;

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
    FriendStatus? friendStatus,
    int? friendsCount,
    Reputation? reputation,
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
    friendStatus: friendStatus ?? this.friendStatus,
    friendsCount: friendsCount ?? this.friendsCount,
    reputation: reputation ?? this.reputation,
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
