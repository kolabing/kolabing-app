/// How members are placed into a [CommunityTier].
///
/// IMPORTANT: [toApiValue] strings are the backend enum wire values
/// (`community_tiers.assignment_rule`). Never rename them without a backend
/// change. See docs/plans/community-members-tiers-phase1.md §3.3.
enum TierAssignmentRule {
  /// Leader assigns / promotes by hand. Never auto-applied or auto-overwritten.
  manual,

  /// Auto when member XP >= [CommunityTier.threshold] (point_ledger / wallets).
  xpThreshold,

  /// Auto after [CommunityTier.threshold] days in the community (from joinedAt).
  tenure,

  /// Auto after [CommunityTier.threshold] check-ins to THIS community's events.
  eventsAttended;

  static TierAssignmentRule fromString(String value) {
    switch (value) {
      case 'manual':
        return TierAssignmentRule.manual;
      case 'xp_threshold':
        return TierAssignmentRule.xpThreshold;
      case 'tenure':
        return TierAssignmentRule.tenure;
      case 'events_attended':
        return TierAssignmentRule.eventsAttended;
      default:
        return TierAssignmentRule.manual;
    }
  }

  String toApiValue() {
    switch (this) {
      case TierAssignmentRule.manual:
        return 'manual';
      case TierAssignmentRule.xpThreshold:
        return 'xp_threshold';
      case TierAssignmentRule.tenure:
        return 'tenure';
      case TierAssignmentRule.eventsAttended:
        return 'events_attended';
    }
  }

  String get displayName {
    switch (this) {
      case TierAssignmentRule.manual:
        return 'Assigned manually';
      case TierAssignmentRule.xpThreshold:
        return 'By XP earned';
      case TierAssignmentRule.tenure:
        return 'By time in community';
      case TierAssignmentRule.eventsAttended:
        return 'By events attended';
    }
  }

  /// Unit label for [CommunityTier.threshold] in this rule (empty for manual).
  String get thresholdUnit {
    switch (this) {
      case TierAssignmentRule.manual:
        return '';
      case TierAssignmentRule.xpThreshold:
        return 'XP';
      case TierAssignmentRule.tenure:
        return 'days';
      case TierAssignmentRule.eventsAttended:
        return 'events';
    }
  }

  bool get isAutomatic => this != TierAssignmentRule.manual;
}

/// The flexible permission / visibility payload a tier carries.
///
/// Phase 1 stores and round-trips this; gating enforcement (content + chat)
/// lands in later phases. Kept as typed lists with a raw fallback so new keys
/// the backend adds do not break parsing.
class TierPermissions {
  const TierPermissions({
    this.view = const [],
    this.chatChannels = const [],
    this.perks = const [],
    this.capabilities = const [],
    this.raw = const {},
  });

  factory TierPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TierPermissions();
    List<String> list(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
    return TierPermissions(
      view: list('view'),
      chatChannels: list('chat_channels'),
      perks: list('perks'),
      capabilities: list('capabilities'),
      raw: Map<String, dynamic>.from(json),
    );
  }

  /// Content surfaces this tier may see (e.g. `events`, `minutes`).
  final List<String> view;

  /// Chat channels this tier may access (designed-for; chat ships later).
  final List<String> chatChannels;

  /// Non-cash perks (e.g. `partner_discount`). No real-money cash-out in v1.
  final List<String> perks;

  /// Free-form capability flags (distinct from the orthogonal `canManage`).
  final List<String> capabilities;

  /// The full original map, so unknown keys survive a round-trip.
  final Map<String, dynamic> raw;

  Map<String, dynamic> toJson() => {
        ...raw,
        'view': view,
        'chat_channels': chatChannels,
        'perks': perks,
        'capabilities': capabilities,
      };
}

/// A leader-defined rung within a single community.
///
/// Tiers are community-agnostic: the leader supplies the meaning (Greek
/// "Exec/Active/Pledge", a run club's "Captain/Regular/Newbie", etc.).
/// A tier's status ladder is ORTHOGONAL to admin power — "can manage" lives on
/// the membership ([CommunityMember.canManage]), not here.
class CommunityTier {
  const CommunityTier({
    required this.id,
    required this.communityId,
    required this.name,
    required this.rank,
    required this.assignmentRule,
    this.color,
    this.threshold,
    this.permissions = const TierPermissions(),
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityTier.fromJson(Map<String, dynamic> json) {
    return CommunityTier(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      name: json['name'] as String,
      rank: json['rank'] as int? ?? 0,
      color: json['color'] as String?,
      assignmentRule:
          TierAssignmentRule.fromString(json['assignment_rule'] as String? ?? 'manual'),
      threshold: json['threshold'] as int?,
      permissions:
          TierPermissions.fromJson(json['permissions'] as Map<String, dynamic>?),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String communityId;
  final String name;

  /// Ascending = higher standing. Used to pick the highest satisfied tier.
  final int rank;

  /// Hex string (e.g. `#FFD861`); null falls back to a theme default.
  final String? color;
  final TierAssignmentRule assignmentRule;

  /// XP amount / days / event count, per [assignmentRule]. Null for manual.
  final int? threshold;
  final TierPermissions permissions;

  /// The tier new joiners land in (exactly one per community).
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'community_id': communityId,
        'name': name,
        'rank': rank,
        if (color != null) 'color': color,
        'assignment_rule': assignmentRule.toApiValue(),
        if (threshold != null) 'threshold': threshold,
        'permissions': permissions.toJson(),
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  CommunityTier copyWith({
    String? id,
    String? communityId,
    String? name,
    int? rank,
    String? color,
    TierAssignmentRule? assignmentRule,
    int? threshold,
    TierPermissions? permissions,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CommunityTier(
        id: id ?? this.id,
        communityId: communityId ?? this.communityId,
        name: name ?? this.name,
        rank: rank ?? this.rank,
        color: color ?? this.color,
        assignmentRule: assignmentRule ?? this.assignmentRule,
        threshold: threshold ?? this.threshold,
        permissions: permissions ?? this.permissions,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
