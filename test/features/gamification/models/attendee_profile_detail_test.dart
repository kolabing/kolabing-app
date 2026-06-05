import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/models/attendee_profile_detail.dart';

void main() {
  group('AttendeeProfileDetail.fromJson', () {
    test('parses the full aggregate payload', () {
      final detail = AttendeeProfileDetail.fromJson(<String, dynamic>{
        'identity': <String, dynamic>{
          'id': 'p1',
          'name': 'Ada Lovelace',
          'avatar_url': 'https://cdn/ada.png',
        },
        'gamification': <String, dynamic>{
          'points': 150,
          'level': <String, dynamic>{
            'number': 3,
            'title': 'Explorer',
            'min_xp': 100,
            'max_xp': 200,
            'color': '#FF8800',
          },
          'badges': <String, dynamic>{
            'count': 2,
            'items': <dynamic>[
              <String, dynamic>{
                'slug': 'first-event',
                'earned_at': '2026-05-01T10:00:00Z',
              },
              <String, dynamic>{'slug': 'streak-5'},
            ],
          },
        },
        'communities': <dynamic>[
          <String, dynamic>{
            'id': 'c1',
            'name': 'Runners',
            'slug': 'runners',
            'avatar_url': null,
            'tier_name': 'Gold',
            'can_manage': true,
          },
        ],
        'events_attended': <String, dynamic>{
          'total': 12,
          'recent': <dynamic>[
            <String, dynamic>{
              'event_id': 'e1',
              'event_name': 'Morning Run',
              'event_date': '2026-05-10',
              'checked_in_at': '2026-05-10T08:00:00Z',
              'community': <String, dynamic>{'id': 'c1', 'name': 'Runners'},
            },
          ],
        },
        'friends_count': 7,
      });

      expect(detail.identity.name, 'Ada Lovelace');
      expect(detail.identity.avatarUrl, 'https://cdn/ada.png');
      expect(detail.gamification.points, 150);
      expect(detail.gamification.badgeCount, 2);
      expect(detail.gamification.badges, hasLength(2));
      expect(detail.gamification.badges.first.slug, 'first-event');
      expect(detail.gamification.badges.last.earnedAt, isNull);

      final level = detail.gamification.level;
      expect(level, isNotNull);
      expect(level!.number, 3);
      expect(level.title, 'Explorer');
      expect(level.color, const Color(0xFFFF8800));
      expect(level.progressFor(150), 0.5);

      expect(detail.communities, hasLength(1));
      expect(detail.communities.first.tierName, 'Gold');
      expect(detail.communities.first.canManage, isTrue);

      expect(detail.eventsAttended.total, 12);
      expect(detail.eventsAttended.recent.first.eventName, 'Morning Run');
      expect(detail.eventsAttended.recent.first.community?.name, 'Runners');

      expect(detail.friendsCount, 7);
    });

    test('tolerates a null level and a missing friends_count', () {
      final detail = AttendeeProfileDetail.fromJson(<String, dynamic>{
        'identity': <String, dynamic>{'id': 'p2', 'name': 'Grace'},
        'gamification': <String, dynamic>{
          'points': 0,
          'level': null,
          'badges': <String, dynamic>{'count': 0, 'items': <dynamic>[]},
        },
        'communities': <dynamic>[],
        'events_attended': <String, dynamic>{'total': 0, 'recent': <dynamic>[]},
      });

      expect(detail.gamification.level, isNull);
      expect(detail.friendsCount, isNull);
      expect(detail.communities, isEmpty);
      expect(detail.eventsAttended.recent, isEmpty);
    });
  });

  group('AttendeeLevel.progressFor', () {
    test('clamps below the level floor to 0', () {
      const level = AttendeeLevel(
        number: 2,
        title: 'X',
        minXp: 100,
        maxXp: 200,
      );
      expect(level.progressFor(50), 0.0);
    });

    test('clamps above the level ceiling to 1', () {
      const level = AttendeeLevel(
        number: 2,
        title: 'X',
        minXp: 100,
        maxXp: 200,
      );
      expect(level.progressFor(500), 1.0);
    });

    test('returns 1 for a zero-width level window', () {
      const level = AttendeeLevel(
        number: 9,
        title: 'Max',
        minXp: 500,
        maxXp: 500,
      );
      expect(level.progressFor(500), 1.0);
    });
  });

  group('AttendeeLevel.color', () {
    test('parses a 6-digit hex without a hash', () {
      const level = AttendeeLevel(
        number: 1,
        title: 'X',
        minXp: 0,
        maxXp: 10,
        colorHex: '00AAFF',
      );
      expect(level.color, const Color(0xFF00AAFF));
    });

    test('returns null for malformed hex', () {
      const level = AttendeeLevel(
        number: 1,
        title: 'X',
        minXp: 0,
        maxXp: 10,
        colorHex: 'nope',
      );
      expect(level.color, isNull);
    });
  });

  group('AttendedEventsPage.fromJson', () {
    test('parses data list and meta, computing hasMore', () {
      final page = AttendedEventsPage.fromJson(<String, dynamic>{
        'data': <dynamic>[
          <String, dynamic>{
            'event_id': 'e1',
            'event_name': 'Run',
            'event_date': '2026-05-10',
            'checked_in_at': '2026-05-10T08:00:00Z',
            'community': null,
          },
        ],
        'meta': <String, dynamic>{
          'current_page': 1,
          'last_page': 3,
          'per_page': 20,
          'total': 50,
        },
      });

      expect(page.events, hasLength(1));
      expect(page.events.first.community, isNull);
      expect(page.currentPage, 1);
      expect(page.lastPage, 3);
      expect(page.total, 50);
      expect(page.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () {
      final page = AttendedEventsPage.fromJson(<String, dynamic>{
        'data': <dynamic>[],
        'meta': <String, dynamic>{
          'current_page': 3,
          'last_page': 3,
          'per_page': 20,
          'total': 50,
        },
      });
      expect(page.hasMore, isFalse);
    });
  });
}
