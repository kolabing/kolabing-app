import '../../../utils/remote_media_url.dart';
import 'verification_channel.dart';

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
    this.isMember,
    this.myJoinRequestStatus,
    this.inviteUrl,
    this.isVerified = false,
    this.verificationStatus,
    this.verificationChannels = const [],
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
      avatarUrl: normalizeRemoteMediaUrlOrNull(json['avatar_url'] as String?),
      isPrimary: json['is_primary'] as bool? ?? true,
      joinPolicy:
          CommunityJoinPolicy.fromString(json['join_policy'] as String? ?? 'open'),
      memberCount: json['member_count'] as int?,
      // Viewer-scoped fields exposed by `GET /communities/{id}` (attendee
      // community-profile contract). Self-gated: null when the backend hasn't
      // deployed them yet, so the CTA degrades gracefully instead of crashing.
      isMember: json['is_member'] as bool?,
      myJoinRequestStatus: json['my_join_request_status'] as String?,
      // Canonical join/invite link (`GET /communities/{id}`). Self-gated: ships
      // in parallel, so null on older payloads — callers fall back to a
      // slug-based link.
      inviteUrl: (json['invite_url'] ?? json['join_url']) as String?,
      // Community verification (shared contract). Self-gated: defaults keep the
      // tick hidden + channels empty when the backend hasn't deployed yet.
      isVerified: json['is_verified'] as bool? ?? false,
      verificationStatus: json['verification_status']?.toString(),
      verificationChannels:
          VerificationChannel.listFromJson(json['verification_channels']),
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

  /// Whether the viewer is already a member (`GET /communities/{id}`). Null when
  /// the backend hasn't exposed it yet (self-gated; treat null as "unknown").
  final bool? isMember;

  /// The viewer's join-request state for an `invite_only` community: one of
  /// `pending` | `approved` | `declined`, or null (no request / not deployed).
  final String? myJoinRequestStatus;

  /// Canonical join/invite link from the backend (`GET /communities/{id}`).
  /// Null until the backend exposes it; use [shareInviteUrl] which falls back
  /// to a slug-based link.
  final String? inviteUrl;

  /// Whether this community has earned the verified tick (shared contract
  /// `is_verified`). Drives [VerifiedTick]. Defaults false (unverified).
  final bool isVerified;

  /// Free-form review state (`verification_status`), e.g. `pending`,
  /// `verified`, `rejected`. Display/diagnostic only — the tick is driven by
  /// [isVerified].
  final String? verificationStatus;

  /// The owner-only proof channels ({type,url}) backing the verification
  /// request. Empty for non-owner viewers (the backend omits it).
  final List<VerificationChannel> verificationChannels;

  /// Convenience: a pending join request is outstanding for the viewer.
  bool get hasPendingJoinRequest => myJoinRequestStatus == 'pending';

  /// Best-available invite link to share (#5): the backend's [inviteUrl] when
  /// present, else a slug-based fallback. Returns null if neither is usable.
  String? get shareInviteUrl {
    if (inviteUrl != null && inviteUrl!.isNotEmpty) return inviteUrl;
    if (slug.isNotEmpty) return 'https://kolabing.com/c/$slug';
    return null;
  }

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
        if (isMember != null) 'is_member': isMember,
        if (myJoinRequestStatus != null)
          'my_join_request_status': myJoinRequestStatus,
        if (inviteUrl != null) 'invite_url': inviteUrl,
        'is_verified': isVerified,
        if (verificationStatus != null)
          'verification_status': verificationStatus,
        if (verificationChannels.isNotEmpty)
          'verification_channels':
              verificationChannels.map((c) => c.toJson()).toList(),
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
    bool? isMember,
    String? myJoinRequestStatus,
    String? inviteUrl,
    bool? isVerified,
    String? verificationStatus,
    List<VerificationChannel>? verificationChannels,
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
        isMember: isMember ?? this.isMember,
        myJoinRequestStatus: myJoinRequestStatus ?? this.myJoinRequestStatus,
        inviteUrl: inviteUrl ?? this.inviteUrl,
        isVerified: isVerified ?? this.isVerified,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        verificationChannels:
            verificationChannels ?? this.verificationChannels,
      );
}
