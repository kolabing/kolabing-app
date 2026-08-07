import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/business/screens/explore_screen.dart';
import 'package:kolabing_app/features/discovery/models/discovery_item.dart';

DiscoveryItem _item({required String id, required String creatorProfileId}) {
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
    );

    // Both of creator-A's Kolabs are gone; creator-B's remains.
    expect(visible.map((i) => i.id), ['k2']);
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
    );

    expect(visible.map((i) => i.id), ['k1', 'k2']);
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
    );

    expect(visible.map((i) => i.id), ['k2']);
  });
}
