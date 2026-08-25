/// Lifecycle state of a [CommunityMember] within a community.
///
/// IMPORTANT: [toApiValue] strings are the backend enum wire values
/// (`community_members.status`). Never rename without a backend change.
enum MembershipStatus {
  active,
  inactive,
  removed;

  static MembershipStatus fromString(String value) {
    switch (value) {
      case 'active':
        return MembershipStatus.active;
      case 'inactive':
        return MembershipStatus.inactive;
      case 'removed':
        return MembershipStatus.removed;
      default:
        return MembershipStatus.active;
    }
  }

  String toApiValue() => name;

  String get displayName {
    switch (this) {
      case MembershipStatus.active:
        return 'Active';
      case MembershipStatus.inactive:
        return 'Inactive';
      case MembershipStatus.removed:
        return 'Removed';
    }
  }
}

/// The link between a member (an `attendee` profile, shown as "Community
/// Member" in the UI) and a community. This row CARRIES the tier — a person
/// can belong to many communities, holding one independent tier in each.
///
/// [canManage] is the orthogonal admin capability (decision D1): it is granted
/// independently of [tierId], so a non-top-tier member can still administer,
/// and the top tier is not implicitly an admin.
class CommunityMember {
  const CommunityMember({
    required this.id,
    required this.communityId,
    required this.profileId,
    this.tierId,
    this.canManage = false,
    this.status = MembershipStatus.active,
    required this.joinedAt,
    this.tierAssignedAt,
    this.memberName,
    this.memberAvatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    // Roster responses may nest a profile summary; tolerate both shapes.
    final profile = json['profile'] as Map<String, dynamic>?;
    return CommunityMember(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      profileId: json['profile_id'] as String,
      tierId:
          json['tier_id'] as String? ??
          (json['tier'] as Map<String, dynamic>?)?['id'] as String?,
      canManage: json['can_manage'] as bool? ?? false,
      status: MembershipStatus.fromString(
        json['status'] as String? ?? 'active',
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      tierAssignedAt: json['tier_assigned_at'] != null
          ? DateTime.parse(json['tier_assigned_at'] as String)
          : null,
      memberName: json['name'] as String? ?? profile?['name'] as String?,
      memberAvatarUrl:
          json['avatar_url'] as String? ?? profile?['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String communityId;
  final String profileId;

  /// Null until a tier is assigned (manually) or evaluated (auto rules).
  final String? tierId;

  /// Orthogonal admin capability — independent of [tierId] (D1).
  final bool canManage;
  final MembershipStatus status;
  final DateTime joinedAt;
  final DateTime? tierAssignedAt;

  /// Member profile summary, when the roster endpoint nests it.
  final String? memberName;
  final String? memberAvatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == MembershipStatus.active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'community_id': communityId,
    'profile_id': profileId,
    if (tierId != null) 'tier_id': tierId,
    'can_manage': canManage,
    'status': status.toApiValue(),
    'joined_at': joinedAt.toIso8601String(),
    if (tierAssignedAt != null)
      'tier_assigned_at': tierAssignedAt!.toIso8601String(),
    if (memberName != null) 'name': memberName,
    if (memberAvatarUrl != null) 'avatar_url': memberAvatarUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  CommunityMember copyWith({
    String? id,
    String? communityId,
    String? profileId,
    String? tierId,
    bool? canManage,
    MembershipStatus? status,
    DateTime? joinedAt,
    DateTime? tierAssignedAt,
    String? memberName,
    String? memberAvatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CommunityMember(
    id: id ?? this.id,
    communityId: communityId ?? this.communityId,
    profileId: profileId ?? this.profileId,
    tierId: tierId ?? this.tierId,
    canManage: canManage ?? this.canManage,
    status: status ?? this.status,
    joinedAt: joinedAt ?? this.joinedAt,
    tierAssignedAt: tierAssignedAt ?? this.tierAssignedAt,
    memberName: memberName ?? this.memberName,
    memberAvatarUrl: memberAvatarUrl ?? this.memberAvatarUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
