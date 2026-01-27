import 'package:flutter/foundation.dart';

/// Types of collaboration requests
enum CollabType {
  event,
  partnership,
  campaign;

  String get displayName {
    switch (this) {
      case CollabType.event:
        return 'Event';
      case CollabType.partnership:
        return 'Partnership';
      case CollabType.campaign:
        return 'Campaign';
    }
  }

  /// Convert from API string value
  static CollabType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'event':
        return CollabType.event;
      case 'partnership':
        return CollabType.partnership;
      case 'campaign':
        return CollabType.campaign;
      default:
        return CollabType.event;
    }
  }

  /// Convert to API string value
  String toApiValue() => name;
}

/// Status of a collaboration request
enum CollabStatus {
  active,
  published,
  closed;

  String get displayName {
    switch (this) {
      case CollabStatus.active:
        return 'Active';
      case CollabStatus.published:
        return 'Published';
      case CollabStatus.closed:
        return 'Closed';
    }
  }

  /// Convert from API string value
  static CollabStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return CollabStatus.active;
      case 'published':
        return CollabStatus.published;
      case 'closed':
        return CollabStatus.closed;
      default:
        return CollabStatus.active;
    }
  }

  /// Convert to API string value
  String toApiValue() => name;
}

/// Collaboration request model
///
/// Contains all information about a collaboration request from a community.
/// Represents opportunities that businesses can browse and apply to.
@immutable
class CollabRequest {
  const CollabRequest({
    required this.id,
    required this.communityName,
    required this.communityUsername,
    required this.title,
    required this.description,
    required this.collabType,
    required this.location,
    required this.startDate,
    required this.status,
    this.communityId,
    this.communityAvatarUrl,
    this.endDate,
    this.hasReward = false,
    this.rewardDescription,
    this.expectedAttendees,
    this.budget,
    this.requirements,
  });

  /// Creates a CollabRequest from API JSON response
  factory CollabRequest.fromJson(Map<String, dynamic> json) {
    // Handle nested community/user object if present
    final community = json['community'] as Map<String, dynamic>? ??
        json['user'] as Map<String, dynamic>?;

    // Handle nested city object
    final cityData = json['city'] as Map<String, dynamic>?;

    // Parse ID - can be int or string from API
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String?) ?? '';

    // Parse community ID if needed
    final communityId = community?['id'];
    final communityIdStr =
        communityId is int ? communityId.toString() : (communityId as String?);

    return CollabRequest(
      id: id,
      communityId: communityIdStr,
      communityName: community?['name'] as String? ??
          community?['business_name'] as String? ??
          json['community_name'] as String? ??
          'Unknown Community',
      communityUsername: community?['username'] as String? ??
          community?['slug'] as String? ??
          json['community_username'] as String? ??
          'unknown',
      communityAvatarUrl: community?['avatar_url'] as String? ??
          community?['profile_photo_url'] as String? ??
          community?['profile_photo'] as String? ??
          json['community_avatar_url'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      collabType: CollabType.fromString(
          json['collab_type'] as String? ?? json['type'] as String? ?? 'event'),
      location: json['location'] as String? ??
          cityData?['name'] as String? ??
          'Unknown',
      startDate: _parseDate(json['start_date'] ?? json['event_date']),
      endDate: _parseDateNullable(json['end_date']),
      status: CollabStatus.fromString(json['status'] as String? ?? 'active'),
      hasReward: json['has_reward'] as bool? ??
          json['reward_description'] != null,
      rewardDescription: json['reward_description'] as String?,
      // Additional fields from API
      expectedAttendees: json['expected_attendees'] as int?,
      budget: json['budget'] as String?,
      requirements: json['requirements'] as String?,
    );
  }

  /// Helper to parse dates from various formats
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Helper to parse nullable dates
  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Converts this CollabRequest to JSON for API requests
  Map<String, dynamic> toJson() => {
        'id': id,
        if (communityId != null) 'community_id': communityId,
        'community_name': communityName,
        'community_username': communityUsername,
        if (communityAvatarUrl != null) 'community_avatar_url': communityAvatarUrl,
        'title': title,
        'description': description,
        'collab_type': collabType.toApiValue(),
        'location': location,
        'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
        'status': status.toApiValue(),
        'has_reward': hasReward,
        if (rewardDescription != null) 'reward_description': rewardDescription,
        if (expectedAttendees != null) 'expected_attendees': expectedAttendees,
        if (budget != null) 'budget': budget,
        if (requirements != null) 'requirements': requirements,
      };

  /// Unique identifier for the collaboration request
  final String id;

  /// Community ID for API calls
  final String? communityId;

  /// Display name of the community
  final String communityName;

  /// Username/handle of the community (without @)
  final String communityUsername;

  /// URL to the community's avatar image
  final String? communityAvatarUrl;

  /// Title of the collaboration request
  final String title;

  /// Detailed description of the collaboration opportunity
  final String description;

  /// Type of collaboration (event, partnership, campaign)
  final CollabType collabType;

  /// Location where the collaboration will take place
  final String location;

  /// Start date of the collaboration
  final DateTime startDate;

  /// End date of the collaboration (optional for ongoing partnerships)
  final DateTime? endDate;

  /// Current status of the request
  final CollabStatus status;

  /// Whether the collaboration includes a reward
  final bool hasReward;

  /// Description of the reward (if hasReward is true)
  final String? rewardDescription;

  /// Expected number of attendees
  final int? expectedAttendees;

  /// Budget for collaboration
  final String? budget;

  /// Requirements for collaboration
  final String? requirements;

  /// Returns the first character of the community name for avatar fallback
  String get communityInitial =>
      communityName.isNotEmpty ? communityName[0].toUpperCase() : '?';

  /// Creates a copy of this CollabRequest with the given fields replaced
  CollabRequest copyWith({
    String? id,
    String? communityId,
    String? communityName,
    String? communityUsername,
    String? communityAvatarUrl,
    String? title,
    String? description,
    CollabType? collabType,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    CollabStatus? status,
    bool? hasReward,
    String? rewardDescription,
    int? expectedAttendees,
    String? budget,
    String? requirements,
  }) =>
      CollabRequest(
        id: id ?? this.id,
        communityId: communityId ?? this.communityId,
        communityName: communityName ?? this.communityName,
        communityUsername: communityUsername ?? this.communityUsername,
        communityAvatarUrl: communityAvatarUrl ?? this.communityAvatarUrl,
        title: title ?? this.title,
        description: description ?? this.description,
        collabType: collabType ?? this.collabType,
        location: location ?? this.location,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        hasReward: hasReward ?? this.hasReward,
        rewardDescription: rewardDescription ?? this.rewardDescription,
        expectedAttendees: expectedAttendees ?? this.expectedAttendees,
        budget: budget ?? this.budget,
        requirements: requirements ?? this.requirements,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollabRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CollabRequest(id: $id, title: $title)';
}
