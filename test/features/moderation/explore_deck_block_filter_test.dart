import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/screens/explore_screen.dart';
import 'package:kolabing_app/features/discovery/models/discovery_item.dart';
import 'package:kolabing_app/features/discovery/models/explore_feed_item.dart';

ExploreFeedItem _item({required String id, required String creatorProfileId}) {
  return ExploreOfferItem(_offer(id: id, creatorProfileId: creatorProfileId));
}

/// One open Multi-Kolab role feed entry.
ExploreFeedItem _role({
  required String id,
  String organizerProfileId = 'organizer-1',
  String eligible = 'either',
  String status = 'open',
  int needed = 1,
  int filled = 0,
}) => ExploreFeedItem.fromJson(<String, dynamic>{
  'item_type': 'multi_kolab_role',
  'id': id,
  'multi_kolab_event_id': 'event-1',
  'role_title': 'Role $id',
  'event_title': 'Kolabing Launch Weekend',
  'status': status,
  'eligible_account_type': eligible,
  'positions_needed': needed,
  'positions_filled': filled,
  'organizer_profile': <String, dynamic>{'id': organizerProfileId},
});

DiscoveryItem _offer({required String id, required String creatorProfileId}) {
  return DiscoveryItem.fromJson(<String, dynamic>{
    'id': id,
    'creator_type': 'community',
    'intent_type': 'seeking_sponsor',
    'title': 'Kolab $id',
    'description': 'desc',
    'preferred_city': 'Barcelona',
    // A wide one-time window around the fixed `today` used in the test so the
    // Kolab counts as open for applications.
    'availability': <String, dynamic>{
      'mode': 'one_time',
      'start': '2026-07-01',
      'end': '2026-12-31',
    },
    'creator_profile': <String, dynamic>{
      'id': creatorProfileId,
      'display_name': 'Creator $creatorProfileId',
    },
  });
}

void main() {
  final today = DateTime(2026, 7, 15);

  test('Explore deck excludes items whose creator profile is blocked', () {
    final items = [
      _item(id: 'k1', creatorProfileId: 'creator-A'),
      _item(id: 'k2', creatorProfileId: 'creator-B'),
      _item(id: 'k3', creatorProfileId: 'creator-A'),
    ];

    final visible = filterExploreDeckItems(
      items,
      blockedProfileIds: {'creator-A'},
      myProfileId: null,
      today: today,
      isCommunityViewer: true,
    );

    // Both of creator-A's Kolabs are gone; creator-B's remains.
    expect(visible.map((i) => i.feedKey), ['offer:k2']);
  });

  test('nothing is dropped when the blocked set is empty', () {
    final items = [
      _item(id: 'k1', creatorProfileId: 'creator-A'),
      _item(id: 'k2', creatorProfileId: 'creator-B'),
    ];

    final visible = filterExploreDeckItems(
      items,
      blockedProfileIds: const <String>{},
      myProfileId: null,
      today: today,
      isCommunityViewer: true,
    );

    expect(visible.map((i) => i.feedKey), ['offer:k1', 'offer:k2']);
  });

  test('the viewer\'s own Kolab is also excluded', () {
    final items = [
      _item(id: 'mine', creatorProfileId: 'me'),
      _item(id: 'k2', creatorProfileId: 'creator-B'),
    ];

    final visible = filterExploreDeckItems(
      items,
      blockedProfileIds: const <String>{},
      myProfileId: 'me',
      today: today,
      isCommunityViewer: true,
    );

    expect(visible.map((i) => i.feedKey), ['offer:k2']);
  });

  group('mixed feed — Multi-Kolab roles', () {
    List<String> keys(
      List<ExploreFeedItem> items, {
      required bool isCommunityViewer,
      String? myProfileId,
      Set<String> blocked = const <String>{},
    }) => filterExploreDeckItems(
      items,
      blockedProfileIds: blocked,
      myProfileId: myProfileId,
      today: today,
      isCommunityViewer: isCommunityViewer,
    ).map((ExploreFeedItem i) => i.feedKey).toList();

    test('ordinary offers and roles are interleaved in one feed', () {
      final items = [
        _item(id: 'k1', creatorProfileId: 'creator-A'),
        _role(id: 'r1'),
        _item(id: 'k2', creatorProfileId: 'creator-B'),
      ];

      expect(keys(items, isCommunityViewer: true), [
        'offer:k1',
        'multi-kolab-role:r1',
        'offer:k2',
      ]);
    });

    test('a community role reaches only the community feed', () {
      final items = [_role(id: 'r1', eligible: 'community')];

      expect(keys(items, isCommunityViewer: true), ['multi-kolab-role:r1']);
      expect(keys(items, isCommunityViewer: false), isEmpty);
    });

    test('a business role reaches only the business feed', () {
      final items = [_role(id: 'r1', eligible: 'business')];

      expect(keys(items, isCommunityViewer: false), ['multi-kolab-role:r1']);
      expect(keys(items, isCommunityViewer: true), isEmpty);
    });

    test('an either role reaches both feeds', () {
      final items = [_role(id: 'r1', eligible: 'either')];

      expect(keys(items, isCommunityViewer: true), ['multi-kolab-role:r1']);
      expect(keys(items, isCommunityViewer: false), ['multi-kolab-role:r1']);
    });

    test('a filled role never reaches either feed', () {
      final items = [_role(id: 'r1', status: 'filled', needed: 1, filled: 1)];

      expect(keys(items, isCommunityViewer: true), isEmpty);
      expect(keys(items, isCommunityViewer: false), isEmpty);
    });

    test("the organizer's own role is excluded from their feed", () {
      final items = [_role(id: 'r1', organizerProfileId: 'me')];

      expect(keys(items, isCommunityViewer: true, myProfileId: 'me'), isEmpty);
      expect(
        keys(items, isCommunityViewer: true, myProfileId: 'someone-else'),
        ['multi-kolab-role:r1'],
      );
    });

    test('a role whose organizer is blocked is hidden', () {
      final items = [_role(id: 'r1', organizerProfileId: 'organizer-A')];

      expect(
        keys(items, isCommunityViewer: true, blocked: {'organizer-A'}),
        isEmpty,
      );
    });

    test('a multi-position role still produces exactly one feed entry', () {
      final items = [_role(id: 'r1', needed: 4, filled: 1)];

      expect(keys(items, isCommunityViewer: true), ['multi-kolab-role:r1']);
    });
  });
}
