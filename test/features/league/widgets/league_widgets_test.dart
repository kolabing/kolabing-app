import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/league/models/league_models.dart';
import 'package:kolabing_app/features/league/providers/league_provider.dart';
import 'package:kolabing_app/features/league/screens/league_table_screen.dart';
import 'package:kolabing_app/features/league/screens/organiser_level_screen.dart';
import 'package:kolabing_app/features/league/widgets/league_preview_card.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

final _now = DateTime.utc(2026, 9, 21, 12);

CommunityRank _rank({
  List<LeagueRow>? preview,
  NextReward? nextReward = const NextReward(
    message: 'Complete 1 kolab this month with 20+ attendees to stay Trusted',
  ),
  String? topReward =
      'Reach top 3 for Top: intros to sports and fashion brands',
}) => CommunityRank(
  city: const LeagueCity(name: 'Barcelona', key: 'barcelona'),
  month: '2026-09',
  seasonEndsAt: DateTime.utc(2026, 9, 30, 12),
  rank: 4,
  total: 12,
  points: 355,
  preview:
      preview ??
      const [
        LeagueRow(rank: 1, displayName: 'Barcelona Run Club', points: 412),
        LeagueRow(rank: 2, displayName: 'Good Ripple', points: 380),
        LeagueRow(rank: 3, displayName: 'All Barcelona', points: 366),
        LeagueRow(
          rank: 4,
          displayName: 'Real Run Club',
          points: 355,
          isViewer: true,
        ),
      ],
  nextReward: nextReward,
  topReward: topReward,
);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required List<dynamic> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: overrides.cast(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: KolabingTheme.lightTheme,
        home: child,
      ),
    ),
  );
  await tester.pump();
}

Widget _cardHost({VoidCallback? onLeague, VoidCallback? onLevel}) => Scaffold(
  body: ListView(
    children: [
      LeaguePreviewCard(
        onOpenLeague: onLeague,
        onOpenLevel: onLevel,
        now: _now,
      ),
    ],
  ),
);

void main() {
  group('LeaguePreviewCard', () {
    testWidgets('shows position, top 3 + you, banner and top reward', (
      tester,
    ) async {
      var leagueTaps = 0;
      var levelTaps = 0;
      await _pump(
        tester,
        child: _cardHost(
          onLeague: () => leagueTaps++,
          onLevel: () => levelTaps++,
        ),
        overrides: [communityRankProvider.overrideWith((ref) async => _rank())],
      );

      expect(find.text('Barcelona league · September'), findsOneWidget);
      expect(find.text("You're #4 of 12 · 9 days left"), findsOneWidget);
      expect(find.text('Barcelona Run Club'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Real Run Club'), findsNothing);
      expect(find.textContaining('stay Trusted'), findsOneWidget);
      expect(find.byKey(const Key('league-card-top-reward')), findsOneWidget);

      await tester.tap(find.byKey(const Key('league-card-tap')));
      await tester.tap(find.byKey(const Key('league-reward-banner')));
      expect(leagueTaps, 1);
      expect(levelTaps, 1);
    });

    testWidgets('marks a gap when the viewer is below the top 3', (
      tester,
    ) async {
      await _pump(
        tester,
        child: _cardHost(),
        overrides: [
          communityRankProvider.overrideWith(
            (ref) async => _rank(
              preview: const [
                LeagueRow(rank: 1, displayName: 'A', points: 9),
                LeagueRow(rank: 2, displayName: 'B', points: 8),
                LeagueRow(rank: 3, displayName: 'C', points: 7),
                LeagueRow(rank: 7, displayName: 'D', points: 4),
                LeagueRow(
                  rank: 8,
                  displayName: 'Me',
                  points: 3,
                  isViewer: true,
                ),
              ],
            ),
          ),
        ],
      );
      expect(find.text('···'), findsOneWidget);
    });

    testWidgets('empty preview shows the empty line, no banner if none', (
      tester,
    ) async {
      await _pump(
        tester,
        child: _cardHost(),
        overrides: [
          communityRankProvider.overrideWith(
            (ref) async =>
                _rank(preview: const [], nextReward: null, topReward: null),
          ),
        ],
      );
      expect(find.byKey(const Key('league-card-empty')), findsOneWidget);
      expect(find.byKey(const Key('league-reward-banner')), findsNothing);
      expect(find.byKey(const Key('league-card-top-reward')), findsNothing);
    });

    testWidgets('loading shows the placeholder', (tester) async {
      final pending = Completer<CommunityRank?>();
      await _pump(
        tester,
        child: _cardHost(),
        overrides: [
          communityRankProvider.overrideWith((ref) => pending.future),
        ],
      );
      expect(find.byKey(const Key('league-card-loading')), findsOneWidget);
      pending.complete(null);
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const Key('league-card-hidden'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('null (endpoint not live / not organiser) hides the card', (
      tester,
    ) async {
      await _pump(
        tester,
        child: _cardHost(),
        overrides: [communityRankProvider.overrideWith((ref) async => null)],
      );
      expect(
        find.byKey(const Key('league-card-hidden'), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byKey(const Key('league-card')), findsNothing);
    });

    testWidgets('an error hides the card on Home', (tester) async {
      await _pump(
        tester,
        child: _cardHost(),
        overrides: [
          communityRankProvider.overrideWith(
            (ref) async => throw Exception('boom'),
          ),
        ],
      );
      expect(
        find.byKey(const Key('league-card-hidden'), skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in Spanish and Catalan', (tester) async {
      for (final locale in const [Locale('es'), Locale('ca')]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              communityRankProvider.overrideWith((ref) async => _rank()),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: _cardHost(),
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('league-card')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('LeagueTableScreen', () {
    testWidgets('shows the full table with the viewer highlighted', (
      tester,
    ) async {
      await _pump(
        tester,
        child: const LeagueTableScreen(),
        overrides: [
          communityRankProvider.overrideWith((ref) async => _rank()),
          leagueTableProvider.overrideWith(
            (ref, city) async => const LeagueTable(
              month: '2026-09',
              divisions: [
                LeagueDivision(
                  key: 'city',
                  label: 'City',
                  rows: [
                    LeagueRow(
                      rank: 1,
                      displayName: 'Barcelona Run Club',
                      points: 412,
                    ),
                    LeagueRow(
                      rank: 4,
                      displayName: 'Real Run Club',
                      points: 355,
                    ),
                    LeagueRow(
                      rank: 5,
                      displayName: 'The Junction',
                      points: 310,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      await tester.pump();

      expect(find.text('Barcelona league'), findsOneWidget);
      expect(find.byKey(const Key('league-season-line')), findsOneWidget);
      expect(find.text('The Junction'), findsOneWidget);
      // No is_viewer flag in the table: the rank endpoint's #4 is "You".
      expect(find.text('You'), findsOneWidget);
      expect(find.textContaining('How points work'), findsOneWidget);
    });

    testWidgets('empty table shows the empty state', (tester) async {
      await _pump(
        tester,
        child: const LeagueTableScreen(),
        overrides: [
          communityRankProvider.overrideWith((ref) async => _rank()),
          leagueTableProvider.overrideWith(
            (ref, city) async => const LeagueTable(),
          ),
        ],
      );
      await tester.pump();
      expect(find.byKey(const Key('league-table-empty')), findsOneWidget);
    });

    testWidgets('unavailable when the league is not live', (tester) async {
      await _pump(
        tester,
        child: const LeagueTableScreen(),
        overrides: [communityRankProvider.overrideWith((ref) async => null)],
      );
      expect(find.text("The city league isn't available yet."), findsOneWidget);
    });

    testWidgets('error shows retry', (tester) async {
      await _pump(
        tester,
        child: const LeagueTableScreen(),
        overrides: [
          communityRankProvider.overrideWith((ref) async => _rank()),
          leagueTableProvider.overrideWith(
            (ref, city) async => throw Exception('boom'),
          ),
        ],
      );
      await tester.pump();
      expect(find.text("Couldn't load the league"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('OrganiserLevelScreen', () {
    const level = OrganiserLevel(
      levelRaw: 'rising',
      nextLevelRaw: 'trusted',
      criteria: [
        LevelCriterion(
          key: 'kolabs_completed',
          label: 'Kolab completed in the app',
          value: 0,
          target: 1,
          met: false,
        ),
        LevelCriterion(
          key: 'check_ins',
          label: 'Attendees checked in',
          value: 24,
          target: 20,
          met: true,
        ),
        LevelCriterion(
          key: 'turnout',
          label: 'Turnout',
          value: 0.82,
          target: 0.6,
          met: true,
          unit: 'ratio',
        ),
      ],
      perks: ['Badge on your applications'],
      nextPerks: ['Kept listed and shown first to venues'],
    );

    testWidgets('shows criteria met / not met and perks', (tester) async {
      await _pump(
        tester,
        child: const OrganiserLevelScreen(),
        overrides: [
          organiserLevelProvider.overrideWith((ref) async => level),
          communityRankProvider.overrideWith((ref) async => _rank()),
        ],
      );

      expect(find.byKey(const Key('level-name')), findsOneWidget);
      expect(find.text('Rising'), findsOneWidget);
      expect(find.text('Next: Trusted'), findsOneWidget);
      expect(find.text('To reach Trusted'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('criterion-open-kolabs_completed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('criterion-met-check_ins')),
        findsOneWidget,
      );
      expect(find.text('0/1'), findsOneWidget);
      expect(find.text('82% / 60%'), findsOneWidget);
      expect(find.text('Badge on your applications'), findsOneWidget);
      expect(find.text('Trusted unlocks'), findsOneWidget);
      expect(find.text('At the top'), findsOneWidget);
    });

    testWidgets('no criteria shows the empty line', (tester) async {
      await _pump(
        tester,
        child: const OrganiserLevelScreen(),
        overrides: [
          organiserLevelProvider.overrideWith(
            (ref) async => const OrganiserLevel(levelRaw: 'new'),
          ),
          communityRankProvider.overrideWith((ref) async => null),
        ],
      );
      expect(find.byKey(const Key('level-no-criteria')), findsOneWidget);
      expect(find.text('At the top'), findsNothing);
    });

    testWidgets('unavailable state', (tester) async {
      await _pump(
        tester,
        child: const OrganiserLevelScreen(),
        overrides: [
          organiserLevelProvider.overrideWith((ref) async => null),
          communityRankProvider.overrideWith((ref) async => null),
        ],
      );
      expect(find.text("Levels aren't available yet."), findsOneWidget);
    });

    testWidgets('error state with retry', (tester) async {
      await _pump(
        tester,
        child: const OrganiserLevelScreen(),
        overrides: [
          organiserLevelProvider.overrideWith(
            (ref) async => throw Exception('boom'),
          ),
          communityRankProvider.overrideWith((ref) async => null),
        ],
      );
      expect(find.text("Couldn't load your level"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('backend contract (kolabing-v2#359)', () {
    testWidgets('league off (no city): only the reward banner shows', (
      tester,
    ) async {
      var levelTaps = 0;
      await _pump(
        tester,
        child: _cardHost(onLevel: () => levelTaps++),
        overrides: [
          communityRankProvider.overrideWith(
            (ref) async => const CommunityRank(
              nextReward: NextReward(
                message: 'Complete your first kolab in the app to reach Rising',
              ),
              topReward: 'Top organisers get personal intros',
            ),
          ),
        ],
      );
      expect(find.byKey(const Key('league-reward-only')), findsOneWidget);
      expect(find.byKey(const Key('league-card')), findsNothing);
      expect(find.textContaining('Top organisers'), findsNothing);
      await tester.tap(find.byKey(const Key('league-reward-banner')));
      expect(levelTaps, 1);
    });

    testWidgets('league off and no reward: hidden', (tester) async {
      await _pump(
        tester,
        child: _cardHost(),
        overrides: [
          communityRankProvider.overrideWith(
            (ref) async => const CommunityRank(),
          ),
        ],
      );
      expect(
        find.byKey(const Key('league-card-hidden'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('divided table shows headers and zone markers', (tester) async {
      await _pump(
        tester,
        child: const LeagueTableScreen(),
        overrides: [
          communityRankProvider.overrideWith((ref) async => _rank()),
          leagueTableProvider.overrideWith(
            (ref, city) async => const LeagueTable(
              month: '2026-09',
              divisionsEnabled: true,
              divisions: [
                LeagueDivision(
                  key: 'large',
                  label: 'Division 1 (200+ members)',
                  rows: [
                    LeagueRow(
                      rank: 1,
                      displayName: 'Big Club',
                      points: 500,
                      promotionZone: true,
                    ),
                  ],
                ),
                LeagueDivision(
                  key: 'small',
                  label: 'Division 3 (under 50 members)',
                  rows: [
                    LeagueRow(
                      rank: 1,
                      displayName: 'Real Run Club',
                      points: 90,
                      isViewer: true,
                    ),
                    LeagueRow(
                      rank: 2,
                      displayName: 'Tiny Club',
                      points: 10,
                      relegationZone: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('league-division-large')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('league-division-small')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('league-row-up-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('league-row-down-2')), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('level: informative rank row, days left, next reward', (
      tester,
    ) async {
      await _pump(
        tester,
        child: const OrganiserLevelScreen(),
        overrides: [
          organiserLevelProvider.overrideWith(
            (ref) async => const OrganiserLevel(
              levelRaw: 'trusted',
              nextLevelRaw: 'top',
              criteria: [
                LevelCriterion(
                  key: 'monthly_kolab',
                  label: 'Kolab this month with 20+ check-ins',
                  value: 1,
                  target: 1,
                  met: true,
                ),
                LevelCriterion(
                  key: 'league_rank',
                  label: 'City league rank',
                  value: 5,
                  target: 3,
                  met: false,
                  unit: 'rank',
                ),
                LevelCriterion(
                  key: 'kolabs_completed',
                  label: 'Kolabs completed in the app',
                  value: 4,
                  target: 1,
                  met: true,
                  required: false,
                ),
              ],
              nextPerks: [
                'Personal introductions to sports brands, fashion brands and venues',
              ],
              daysLeft: 12,
              nextReward: NextReward(
                message:
                    "You're #5. Reach the top 3 of your city league for Top",
              ),
            ),
          ),
          communityRankProvider.overrideWith((ref) async => null),
        ],
      );
      expect(find.text('To reach Top'), findsOneWidget);
      expect(find.text('#5 / top 3'), findsOneWidget);
      expect(find.byKey(const Key('level-next-reward')), findsOneWidget);
      expect(find.byKey(const Key('level-days-left')), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Top unlocks'), findsOneWidget);
      expect(find.textContaining('Personal introductions'), findsOneWidget);
    });
  });
}
