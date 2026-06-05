import 'community.dart';
import 'community_member.dart';
import 'community_tier.dart';

/// A member's-eye view of one of their communities: the community itself plus
/// the member's own tier and capability in it. Returned by `GET /me/memberships`
/// (each item nests `community` and `tier`). Distinct from [CommunityMember],
/// which is the leader's-eye roster row.
class CommunityMembership {
  const CommunityMembership({
    required this.community,
    this.tier,
    this.canManage = false,
    this.status = MembershipStatus.active,
    this.joinedAt,
  });

  factory CommunityMembership.fromJson(Map<String, dynamic> json) {
    final tierJson = json['tier'] as Map<String, dynamic>?;
    return CommunityMembership(
      community:
          Community.fromJson(json['community'] as Map<String, dynamic>),
      tier: tierJson != null ? CommunityTier.fromJson(tierJson) : null,
      canManage: json['can_manage'] as bool? ?? false,
      status:
          MembershipStatus.fromString(json['status'] as String? ?? 'active'),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }

  final Community community;

  /// The member's current tier in this community (null if unassigned).
  final CommunityTier? tier;

  /// Whether the member holds the admin capability here (orthogonal to tier).
  final bool canManage;
  final MembershipStatus status;
  final DateTime? joinedAt;
}
