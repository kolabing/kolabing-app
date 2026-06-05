import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/community/models/community.dart';
import 'package:kolabing_app/features/community/models/community_member.dart';
import 'package:kolabing_app/features/community/models/community_membership.dart';
import 'package:kolabing_app/features/community/models/community_tier.dart';

/// Locks the NF-6 contract: these payloads mirror the kolabing-v2 Resource
/// shapes (CommunityResource / CommunityTierResource / CommunityMemberResource
/// and the GET /me/memberships map) verified against the backend on
/// branch feat/community-members-tiers. If the backend shape drifts, these fail.
void main() {
  group('Community.fromJson (CommunityResource)', () {
    final json = {
      'id': 'c1',
      'owner_profile_id': 'p1',
      'community_profile_id': null,
      'name': 'Kappa Delta — Beta Chi',
      'slug': 'kd-beta-chi',
      'type': 'greek',
      'description': null,
      'avatar_url': null,
      'is_primary': true,
      'join_policy': 'invite_only',
      'member_count': 84,
      'created_at': '2026-06-02T10:00:00+00:00',
      'updated_at': '2026-06-02T10:00:00+00:00',
    };

    test('parses fields + enums', () {
      final c = Community.fromJson(json);
      expect(c.id, 'c1');
      expect(c.ownerProfileId, 'p1');
      expect(c.type, CommunityType.greek);
      expect(c.joinPolicy, CommunityJoinPolicy.inviteOnly);
      expect(c.joinPolicy.allowsSelfJoin, isFalse);
      expect(c.isPrimary, isTrue);
      expect(c.memberCount, 84);
    });

    test('enum wire values round-trip', () {
      expect(CommunityType.greek.toApiValue(), 'greek');
      expect(CommunityJoinPolicy.inviteOnly.toApiValue(), 'invite_only');
      expect(CommunityType.fromString('fitness'), CommunityType.fitness);
      expect(CommunityJoinPolicy.fromString('open'), CommunityJoinPolicy.open);
    });
  });

  group('CommunityTier.fromJson (CommunityTierResource)', () {
    final json = {
      'id': 't1',
      'community_id': 'c1',
      'name': 'Exec',
      'rank': 3,
      'color': '#FFD861',
      'assignment_rule': 'events_attended',
      'threshold': 5,
      'permissions': {
        'view': ['events', 'minutes'],
        'chat_channels': ['exec'],
        'perks': ['partner_discount'],
        'capabilities': <String>[],
      },
      'is_default': false,
      'created_at': '2026-06-02T10:00:00+00:00',
      'updated_at': '2026-06-02T10:00:00+00:00',
    };

    test('parses rule, threshold and permissions', () {
      final t = CommunityTier.fromJson(json);
      expect(t.assignmentRule, TierAssignmentRule.eventsAttended);
      expect(t.assignmentRule.isAutomatic, isTrue);
      expect(t.assignmentRule.thresholdUnit, 'events');
      expect(t.threshold, 5);
      expect(t.permissions.view, ['events', 'minutes']);
      expect(t.permissions.chatChannels, ['exec']);
      expect(t.permissions.perks, ['partner_discount']);
    });

    test('all rule wire values map', () {
      expect(TierAssignmentRule.manual.toApiValue(), 'manual');
      expect(TierAssignmentRule.xpThreshold.toApiValue(), 'xp_threshold');
      expect(TierAssignmentRule.tenure.toApiValue(), 'tenure');
      expect(TierAssignmentRule.eventsAttended.toApiValue(), 'events_attended');
      expect(
        TierAssignmentRule.fromString('xp_threshold'),
        TierAssignmentRule.xpThreshold,
      );
    });
  });

  group('CommunityMember.fromJson (CommunityMemberResource)', () {
    test('reads nested tier + profile and can_manage/status', () {
      final json = {
        'id': 'm1',
        'community_id': 'c1',
        'profile_id': 'p9',
        'tier': {
          'id': 't1',
          'community_id': 'c1',
          'name': 'Active',
          'rank': 2,
          'color': null,
          'assignment_rule': 'manual',
          'threshold': null,
          'permissions': <String, dynamic>{},
          'is_default': true,
          'created_at': '2026-06-02T10:00:00+00:00',
          'updated_at': '2026-06-02T10:00:00+00:00',
        },
        'tier_id': 't1',
        'can_manage': true,
        'status': 'active',
        'joined_at': '2026-06-02T10:00:00+00:00',
        'tier_assigned_at': null,
        'profile': {'name': 'Brooke M.', 'avatar_url': 'https://x/y.png'},
        'created_at': '2026-06-02T10:00:00+00:00',
        'updated_at': '2026-06-02T10:00:00+00:00',
      };
      final m = CommunityMember.fromJson(json);
      expect(m.tierId, 't1');
      expect(m.canManage, isTrue);
      expect(m.status, MembershipStatus.active);
      expect(m.isActive, isTrue);
      expect(m.memberName, 'Brooke M.');
      expect(m.memberAvatarUrl, 'https://x/y.png');
    });

    test('tolerates flat tier_id + flat name/avatar (no nesting)', () {
      final json = {
        'id': 'm2',
        'community_id': 'c1',
        'profile_id': 'p10',
        'tier_id': null,
        'can_manage': false,
        'status': 'inactive',
        'joined_at': '2026-06-02T10:00:00+00:00',
        'name': 'Jordan T.',
        'avatar_url': null,
        'created_at': '2026-06-02T10:00:00+00:00',
        'updated_at': '2026-06-02T10:00:00+00:00',
      };
      final m = CommunityMember.fromJson(json);
      expect(m.tierId, isNull);
      expect(m.status, MembershipStatus.inactive);
      expect(m.isActive, isFalse);
      expect(m.memberName, 'Jordan T.');
    });
  });

  group('CommunityMembership.fromJson (GET /me/memberships item)', () {
    test('parses nested community + tier + can_manage', () {
      final json = {
        'community': {
          'id': 'c1',
          'owner_profile_id': 'p1',
          'community_profile_id': null,
          'name': 'City Run Club',
          'slug': 'city-run-club',
          'type': 'running',
          'description': null,
          'avatar_url': null,
          'is_primary': true,
          'join_policy': 'open',
          'member_count': 30,
          'created_at': '2026-06-02T10:00:00+00:00',
          'updated_at': '2026-06-02T10:00:00+00:00',
        },
        'tier': {
          'id': 't9',
          'community_id': 'c1',
          'name': 'Captain',
          'rank': 3,
          'color': '#7AE7A3',
          'assignment_rule': 'tenure',
          'threshold': 90,
          'permissions': <String, dynamic>{},
          'is_default': false,
          'created_at': '2026-06-02T10:00:00+00:00',
          'updated_at': '2026-06-02T10:00:00+00:00',
        },
        'can_manage': false,
        'status': 'active',
        'joined_at': '2026-06-02T10:00:00+00:00',
      };
      final ms = CommunityMembership.fromJson(json);
      expect(ms.community.name, 'City Run Club');
      expect(ms.community.type, CommunityType.running);
      expect(ms.tier?.name, 'Captain');
      expect(ms.tier?.assignmentRule, TierAssignmentRule.tenure);
      expect(ms.canManage, isFalse);
      expect(ms.status, MembershipStatus.active);
    });

    test('handles null tier (unassigned member)', () {
      final json = {
        'community': {
          'id': 'c2',
          'owner_profile_id': 'p2',
          'name': 'Book Club',
          'slug': 'book-club',
          'type': 'other',
          'is_primary': true,
          'join_policy': 'open',
          'created_at': '2026-06-02T10:00:00+00:00',
          'updated_at': '2026-06-02T10:00:00+00:00',
        },
        'tier': null,
        'can_manage': false,
        'status': 'active',
        'joined_at': '2026-06-02T10:00:00+00:00',
      };
      final ms = CommunityMembership.fromJson(json);
      expect(ms.tier, isNull);
      expect(ms.community.type, CommunityType.other);
    });
  });
}
