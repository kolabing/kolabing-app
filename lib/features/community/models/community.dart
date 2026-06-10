/// The kind of community a leader runs. Community-agnostic by design — the
/// tier system means Kolabing ships the mechanism and the leader supplies the
/// meaning. `greek` is the launch inspiration; the rest prove generality.
///
/// IMPORTANT: [toApiValue] strings are the backend enum wire values
/// (`communities.type`). Never rename without a backend change.
enum CommunityType {
  greek,
  fitness,
  running,
  business,
  other;

  static CommunityType fromString(String value) {
    switch (value) {
      case 'greek':
        return CommunityType.greek;
      case 'fitness':
        return CommunityType.fitness;
      case 'running':
        return CommunityType.running;
      case 'business':
        return CommunityType.business;
      default:
        return CommunityType.other;
    }
  }

  String toApiValue() => name;

  String get displayName {
    switch (this) {
      case CommunityType.greek:
        return 'Greek life';
      case CommunityType.fitness:
        return 'Fitness';
      case CommunityType.running:
        return 'Running club';
      case CommunityType.business:
        return 'Business community';
      case CommunityType.other:
        return 'Community';
    }
  }
}

/// Who may join a community.
///
/// Decision: communities support BOTH invite and open self-join, and a leader
/// may restrict to invite-only. `open` = members may self-join AND the leader
/// may invite; `inviteOnly` = leader / `can_manage` members add only.
enum CommunityJoinPolicy {
  open,
  inviteOnly;

  static CommunityJoinPolicy fromString(String value) {
    switch (value) {
      case 'open':
        return CommunityJoinPolicy.open;
      case 'invite_only':
        return CommunityJoinPolicy.inviteOnly;
      default:
        return CommunityJoinPolicy.open;
    }
  }

  String toApiValue() {
    switch (this) {
      case CommunityJoinPolicy.open:
        return 'open';
      case CommunityJoinPolicy.inviteOnly:
        return 'invite_only';
    }
  }

  bool get allowsSelfJoin => this == CommunityJoinPolicy.open;
}

/// A community (the GROUP a leader owns), distinct from `CommunityProfile`
/// (the marketplace identity in features/auth). One leader gets one community
/// free; a 2nd+ is gated behind Community Premium (NF-7). See
/// docs/plans/community-members-tiers-phase1.md §3.
class Community {
  const Community({
    required this.id,
    required this.ownerProfileId,
    required this.name,
    required this.slug,
    required this.type,
    this.communityProfileId,
    this.description,
    this.avatarUrl,
    this.isPrimary = true,
    this.joinPolicy = CommunityJoinPolicy.open,
    this.memberCount,
    required this.createdAt,
    required this.updatedAt,
    this.typeSlug,
    this.matched = false,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    // Tolerant of slim payloads (e.g. the `/communities/discover` card resource,
    // which omits owner/slug/timestamps) — default the fields a full community
    // row carries but a discovery card doesn't, so parsing never throws.
    return Community(
      id: json['id'] as String,
      ownerProfileId: json['owner_profile_id'] as String? ?? '',
      communityProfileId: json['community_profile_id'] as String?,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      type: CommunityType.fromString(json['type'] as String? ?? 'other'),
      // Raw backend type slug, preserved losslessly for interest matching /
      // the discover "For You" hint (the enum above collapses unknown slugs to
      // `other`, so never branch interest logic on it — see CANONICAL-LISTS).
      typeSlug: (json['type'] ?? json['community_type'])?.toString(),
      // Optional server hint that this row matched a viewer interest
      // (`GET /communities/discover` interest ranking, contract §7).
      matched: json['matched'] as bool? ?? false,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isPrimary: json['is_primary'] as bool? ?? true,
      joinPolicy:
          CommunityJoinPolicy.fromString(json['join_policy'] as String? ?? 'open'),
      memberCount: json['member_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String ownerProfileId;

  /// Optional link to the marketplace-facing `community_profiles` row.
  final String? communityProfileId;
  final String name;
  final String slug;
  final CommunityType type;
  final String? description;
  final String? avatarUrl;

  /// The leader's first (free) community. Creating a non-primary one is the
  /// NF-7 Community Premium gate.
  final bool isPrimary;
  final CommunityJoinPolicy joinPolicy;
  final int? memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Raw backend community-type slug (lossless; the [type] enum collapses
  /// unknown slugs to `other`). Use this for interest matching, never [type].
  final String? typeSlug;

  /// Server hint that this discover row matched one of the viewer's interests
  /// (contract §7). Drives the interest badge + the "For You" section.
  final bool matched;

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_profile_id': ownerProfileId,
        if (communityProfileId != null)
          'community_profile_id': communityProfileId,
        'name': name,
        'slug': slug,
        'type': type.toApiValue(),
        if (description != null) 'description': description,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'is_primary': isPrimary,
        'join_policy': joinPolicy.toApiValue(),
        if (memberCount != null) 'member_count': memberCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Community copyWith({
    String? id,
    String? ownerProfileId,
    String? communityProfileId,
    String? name,
    String? slug,
    CommunityType? type,
    String? description,
    String? avatarUrl,
    bool? isPrimary,
    CommunityJoinPolicy? joinPolicy,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? typeSlug,
    bool? matched,
  }) =>
      Community(
        id: id ?? this.id,
        ownerProfileId: ownerProfileId ?? this.ownerProfileId,
        communityProfileId: communityProfileId ?? this.communityProfileId,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        type: type ?? this.type,
        description: description ?? this.description,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isPrimary: isPrimary ?? this.isPrimary,
        joinPolicy: joinPolicy ?? this.joinPolicy,
        memberCount: memberCount ?? this.memberCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        typeSlug: typeSlug ?? this.typeSlug,
        matched: matched ?? this.matched,
      );
}
