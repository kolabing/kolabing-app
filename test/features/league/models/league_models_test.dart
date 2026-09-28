import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/league/models/league_models.dart';

void main() {
  group('CommunityRank.fromJson', () {
    test('parses the full contract', () {
      final rank = CommunityRank.fromJson(<String, dynamic>{
        'city': 'Barcelona',
        'city_id': 'c-17',
        'month': '2026-09',
        'division': 'city',
        'division_label': 'City',
        'season_ends_at': '2026-09-30T21:59:59Z',
        'rank': 4,
        'total': 12,
        'points': 355,
        'score_breakdown': <String, dynamic>{
          'kolabs_completed': 160,
          'check_ins': '120',
          'bogus': 'n/a',
        },
        'preview': <dynamic>[
          <String, dynamic>{
            'rank': 4,
            'profile_id': 'p4',
            'display_name': 'Real Run Club',
            'points': 355,
            'is_viewer': true,
          },
          <String, dynamic>{
            'rank': 1,
            'profile_id': 'p1',
            'display_name': 'Barcelona Run Club',
            'points': 412,
            'is_viewer': false,
          },
          <String, dynamic>{'rank': 2, 'display_name': 'Good Ripple'},
          <String, dynamic>{'display_name': 'No rank, dropped'},
        ],
        'promotion_zone': false,
        'relegation_zone': true,
        'level': 'rising',
        'next_reward': <String, dynamic>{
          'type': 'level',
          'level': 'trusted',
          'message': 'Complete 1 kolab this month with 20+ attendees',
          'remaining': <String, dynamic>{'kolabs_completed': 1, 'checkins': 20},
          'days_left': 12,
        },
        'top_reward': 'Top: personal intros to sports and fashion brands',
      });

      expect(rank.city?.name, 'Barcelona');
      expect(rank.city?.key, 'c-17');
      expect(rank.hasLeague, isTrue);
      expect(rank.month, '2026-09');
      expect(rank.division, 'City');
      expect(rank.divisionKey, 'city');
      expect(rank.levelRaw, 'rising');
      expect(rank.seasonEndsAt, DateTime.utc(2026, 9, 30, 21, 59, 59));
      expect(rank.rank, 4);
      expect(rank.total, 12);
      expect(rank.isRanked, isTrue);
      expect(rank.points, 355);
      expect(rank.scoreBreakdown, <String, num>{
        'kolabs_completed': 160,
        'check_ins': 120,
      });
      // Sorted by rank; the row without a rank is dropped.
      expect(rank.preview.map((r) => r.rank), <int>[1, 2, 4]);
      expect(rank.preview.last.isViewer, isTrue);
      expect(rank.preview[1].points, 0);
      expect(rank.promotionZone, isFalse);
      expect(rank.relegationZone, isTrue);
      expect(rank.nextReward?.level, 'trusted');
      expect(rank.nextReward?.remaining['kolabs_completed'], 1);
      expect(rank.nextReward?.daysLeft, 12);
      expect(rank.topReward, startsWith('Top:'));
    });

    test('survives an empty / minimal payload', () {
      final rank = CommunityRank.fromJson(const <String, dynamic>{});
      expect(rank.city, isNull);
      expect(rank.hasLeague, isFalse);
      expect(rank.rank, isNull);
      expect(rank.isRanked, isFalse);
      expect(rank.points, 0);
      expect(rank.preview, isEmpty);
      expect(rank.nextReward, isNull);
      expect(rank.topReward, isNull);
    });

    test('accepts city objects, string numbers and object rewards', () {
      final rank = CommunityRank.fromJson(<String, dynamic>{
        'city': <String, dynamic>{'id': 7, 'name': 'Barcelona', 'slug': 'bcn'},
        'rank': '2',
        'total': 9.0,
        'points': '81',
        'preview': 'not a list',
        'next_reward': 'Host 1 more kolab',
        'top_reward': <String, dynamic>{'message': 'Brand intros'},
        'division': <String, dynamic>{'label': 'Small communities'},
      });
      expect(rank.city?.name, 'Barcelona');
      expect(rank.city?.key, '7');
      expect(rank.rank, 2);
      expect(rank.total, 9);
      expect(rank.points, 81);
      expect(rank.preview, isEmpty);
      expect(rank.nextReward?.message, 'Host 1 more kolab');
      expect(rank.topReward, 'Brand intros');
      expect(rank.division, 'Small communities');
    });

    test('a next_reward without a message is dropped', () {
      final rank = CommunityRank.fromJson(<String, dynamic>{
        'next_reward': <String, dynamic>{'type': 'level', 'message': null},
      });
      expect(rank.nextReward, isNull);
    });
  });

  group('LeagueTable.fromJson', () {
    test('reads the divisions contract', () {
      final table = LeagueTable.fromJson(<String, dynamic>{
        'city': 'Barcelona',
        'city_id': 'c-17',
        'month': '2026-09',
        'season_ends_at': '2026-09-30T21:59:59Z',
        'divisions_enabled': true,
        'divisions': <dynamic>[
          <String, dynamic>{
            'key': 'large',
            'label': 'Division 1 (200+ members)',
            'rows': <dynamic>[
              <String, dynamic>{
                'rank': 2,
                'display_name': 'B',
                'points': 5,
                'relegation_zone': true,
              },
              <String, dynamic>{
                'rank': 1,
                'display_name': 'A',
                'points': 9,
                'is_viewer': true,
                'promotion_zone': false,
              },
            ],
          },
          <String, dynamic>{'key': 'small', 'rows': <dynamic>[]},
        ],
      });
      expect(table.city?.key, 'c-17');
      expect(table.divisionsEnabled, isTrue);
      expect(table.showDivisionHeaders, isTrue);
      expect(table.divisions.first.label, 'Division 1 (200+ members)');
      expect(table.divisions.last.label, 'small');
      expect(table.divisions.first.rows.map((r) => r.displayName), <String>[
        'A',
        'B',
      ]);
      expect(table.divisions.first.rows.last.relegationZone, isTrue);
      expect(table.divisions.first.rows.first.isViewer, isTrue);
      expect(table.isEmpty, isFalse);
    });

    test('single division: no headers', () {
      final table = LeagueTable.fromJson(<String, dynamic>{
        'divisions_enabled': false,
        'divisions': <dynamic>[
          <String, dynamic>{
            'key': 'city',
            'label': 'City',
            'rows': <dynamic>[
              <String, dynamic>{'rank': 1, 'display_name': 'A'},
            ],
          },
        ],
      });
      expect(table.showDivisionHeaders, isFalse);
    });

    test('reads a flat rows object and a bare list', () {
      expect(
        LeagueTable.fromJson(<dynamic>[
          <String, dynamic>{'rank': 1, 'display_name': 'A'},
        ]).divisions.single.rows.length,
        1,
      );
      expect(
        LeagueTable.fromJson(<String, dynamic>{
          'rows': <dynamic>[
            <String, dynamic>{'rank': 1, 'name': 'A', 'score': 3},
          ],
        }).divisions.single.rows.single.points,
        3,
      );
      expect(LeagueTable.fromJson(null).isEmpty, isTrue);
    });
  });

  group('OrganiserLevel.fromJson', () {
    test('parses levels, criteria and perks', () {
      final level = OrganiserLevel.fromJson(<String, dynamic>{
        'level': 'rising',
        'next_level': 'trusted',
        'criteria': <dynamic>[
          <String, dynamic>{
            'key': 'kolabs_completed',
            'label': 'Kolabs completed in the app',
            'value': 0,
            'target': 1,
            'met': false,
            'required': true,
          },
          <String, dynamic>{
            'key': 'league_rank',
            'label': 'City league rank',
            'value': null,
            'target': 3,
            'met': false,
            'required': false,
            'unit': 'rank',
          },
          <String, dynamic>{
            'key': 'turnout',
            'label': 'Turnout',
            'value': 0.82,
            'target': 0.6,
            'met': true,
            'unit': 'ratio',
          },
          <String, dynamic>{'label': 'no key, dropped'},
        ],
        'perks': <dynamic>['Badge on your applications'],
        'next_perks': <dynamic>[
          'Shown first to venues',
          <String, dynamic>{'label': 'Top intros'},
        ],
        'month': '2026-09',
        'days_left': 12,
        'next_reward': <String, dynamic>{
          'type': 'level',
          'level': 'trusted',
          'message': 'Complete 1 kolab this month with 20+ attendees',
        },
        'evaluated_at': '2026-09-28T02:00:00Z',
      });
      expect(level.level, OrganiserLevelKind.rising);
      expect(level.nextLevel, OrganiserLevelKind.trusted);
      expect(level.criteria.length, 3);
      expect(level.criteria.first.met, isFalse);
      expect(level.criteria[1].required, isFalse);
      expect(level.criteria[1].value, isNull);
      expect(level.criteria.last.required, isTrue);
      expect(level.daysLeft, 12);
      expect(level.nextReward?.type, 'level');
      expect(level.criteria.last.unit, 'ratio');
      expect(level.criteria.last.value, 0.82);
      expect(level.perks, <String>['Badge on your applications']);
      expect(level.nextPerks, <String>['Shown first to venues', 'Top intros']);
      expect(level.evaluatedAt, isNotNull);
    });

    test('defaults and unknown levels', () {
      final level = OrganiserLevel.fromJson(<String, dynamic>{
        'level': 'legend',
        'criteria': null,
      });
      expect(level.level, OrganiserLevelKind.unknown);
      expect(level.levelRaw, 'legend');
      expect(level.nextLevel, isNull);
      expect(level.criteria, isEmpty);

      expect(
        OrganiserLevel.fromJson(const <String, dynamic>{}).level,
        OrganiserLevelKind.newcomer,
      );
    });
  });

  test('daysUntil rounds up and never goes negative', () {
    final now = DateTime.utc(2026, 9, 21, 12);
    expect(daysUntil(null, now), isNull);
    expect(daysUntil(DateTime.utc(2026, 9, 30, 12), now), 9);
    expect(daysUntil(DateTime.utc(2026, 9, 30, 13), now), 10);
    expect(daysUntil(DateTime.utc(2026, 9, 20), now), 0);
  });
}
