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
    this.communityAvatarUrl,
    this.endDate,
    this.hasReward = false,
    this.rewardDescription,
  });

  /// Unique identifier for the collaboration request
  final String id;

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

  /// Returns the first character of the community name for avatar fallback
  String get communityInitial =>
      communityName.isNotEmpty ? communityName[0].toUpperCase() : '?';

  /// Creates a copy of this CollabRequest with the given fields replaced
  CollabRequest copyWith({
    String? id,
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
  }) =>
      CollabRequest(
        id: id ?? this.id,
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
