import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/discovery/models/discovery_item.dart';
import 'package:kolabing_app/features/discovery/models/explore_feed_item.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/widgets/explore_swipe_card.dart';

ExploreFeedItem _role({
  String id = 'role-1',
  String eligible = 'community',
  int needed = 1,
  int filled = 0,
  Object? lookingFor,
  bool viewerHasApplied = false,
  int? matchScore = 82,
  String? compensation = 'value_exchange',
}) => ExploreFeedItem.fromJson(<String, dynamic>{
  'item_type': 'multi_kolab_role',
  'id': id,
  'multi_kolab_event_id': 'event-1',
  'role_title': 'Run Club Partner',
  'event_title': 'Kolabing Launch Weekend',
  'status': 'open',
  'looking_for': <String, dynamic>{
    'eligible_account_type': eligible,
    'required': true,
    if (lookingFor != null) 'partner_type': lookingFor,
  },
  'positions_needed': needed,
  'positions_filled': filled,
  'positions_remaining': needed - filled,
  'compensation': <String, dynamic>{'type': compensation},
  'city': 'Barcelona',
  'target_date': <String, dynamic>{'mode': 'exact', 'date': '2026-09-12'},
  'match_score': matchScore,
  'viewer_has_applied': viewerHasApplied,
  'creator_profile': <String, dynamic>{'id': 'organizer-1'},
});

ExploreFeedItem _offer() => ExploreOfferItem(
  DiscoveryItem.fromJson(<String, dynamic>{
    'id': 'kolab-1',
    'creator_type': 'business',
    'intent_type': 'venue_promotion',
    'title': 'Sunset rooftop collab',
    'description': 'Host your creator event on our rooftop',
    'preferred_city': 'Barcelona',
    'availability': <String, dynamic>{
      'mode': 'one_time',
      'start': '2026-05-20',
      'end': '2026-05-20',
    },
    'creator_profile': <String, dynamic>{
      'id': 'creator-1',
      'display_name': 'Casa Sol',
    },
    'business_offer': <String, dynamic>{
      'offer_types': <String>['venue'],
      'venue_type': 'rooftop',
    },
    'match_score': 92,
  }),
);

Future<void> _pumpCard(
  WidgetTester tester,
  ExploreFeedItem item, {
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 844),
  VoidCallback? onTap,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExploreSwipeCard(item: item, onTap: onTap),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('a Multi-Kolab role renders through the ordinary offer card', () {
    testWidgets('it uses the SAME widget as an ordinary offer', (tester) async {
      await _pumpCard(tester, _role());
      expect(find.byType(ExploreSwipeCard), findsOneWidget);

      await _pumpCard(tester, _offer());
      expect(find.byType(ExploreSwipeCard), findsOneWidget);
    });

    testWidgets('the role title is the card\'s primary title', (tester) async {
      await _pumpCard(tester, _role());

      expect(find.text('Run Club Partner'), findsOneWidget);
    });

    testWidgets('the parent event title and city form the meta row', (
      tester,
    ) async {
      await _pumpCard(tester, _role());

      expect(find.text('Kolabing Launch Weekend'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
    });

    testWidgets('the match percentage uses the ordinary match badge', (
      tester,
    ) async {
      await _pumpCard(tester, _role());

      expect(find.text('82% match'), findsOneWidget);
    });

    testWidgets('no match badge is shown when the feed has no score', (
      tester,
    ) async {
      await _pumpCard(tester, _role(matchScore: null));

      expect(find.textContaining('% match'), findsNothing);
    });
  });

  group('Multi-Kolab badge', () {
    testWidgets('is shown on a role card', (tester) async {
      await _pumpCard(tester, _role());

      expect(
        find.byKey(const Key('explore-card-multi-kolab-badge')),
        findsOneWidget,
      );
      expect(find.text('Multi-Kolab'), findsOneWidget);
    });

    testWidgets('is NOT shown on an ordinary offer card', (tester) async {
      await _pumpCard(tester, _offer());

      expect(
        find.byKey(const Key('explore-card-multi-kolab-badge')),
        findsNothing,
      );
      expect(find.text('Multi-Kolab'), findsNothing);
    });
  });

  group('partner-request copy', () {
    testWidgets('a specific partner type reads "Looking for ..."', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        _role(
          lookingFor: <String, dynamic>{'key': 'run_club', 'label': 'Run club'},
        ),
      );

      expect(find.text('Looking for Run club'), findsOneWidget);
    });

    testWidgets('an open-ended business role reads "Open to any business"', (
      tester,
    ) async {
      await _pumpCard(tester, _role(eligible: 'business'));

      expect(find.text('Open to any business'), findsOneWidget);
    });

    testWidgets('an open-ended community role reads "Open to any community"', (
      tester,
    ) async {
      await _pumpCard(tester, _role(eligible: 'community'));

      expect(find.text('Open to any community'), findsOneWidget);
    });

    testWidgets('an open-ended either role reads "Open to any partner"', (
      tester,
    ) async {
      await _pumpCard(tester, _role(eligible: 'either'));

      expect(find.text('Open to any partner'), findsOneWidget);
    });
  });

  group('remaining positions', () {
    testWidgets('a multi-position role shows its remaining count', (
      tester,
    ) async {
      await _pumpCard(tester, _role(needed: 4, filled: 1));

      expect(find.text('3 spots open'), findsOneWidget);
    });

    testWidgets('a single remaining position is singular', (tester) async {
      await _pumpCard(tester, _role(needed: 2, filled: 1));

      expect(find.text('1 spot open'), findsOneWidget);
    });

    testWidgets('a single-position role shows no spot count', (tester) async {
      await _pumpCard(tester, _role(needed: 1, filled: 0));

      expect(find.textContaining('spot'), findsNothing);
    });
  });

  group('supporting facts', () {
    testWidgets('the compensation type is surfaced as a chip', (tester) async {
      await _pumpCard(tester, _role());

      expect(find.text('Value exchange'), findsOneWidget);
    });

    testWidgets('an already-applied role is marked on the card', (
      tester,
    ) async {
      await _pumpCard(tester, _role(viewerHasApplied: true));

      expect(find.text('Applied'), findsOneWidget);
    });

    testWidgets('a role the viewer has not applied to has no Applied chip', (
      tester,
    ) async {
      await _pumpCard(tester, _role());

      expect(find.text('Applied'), findsNothing);
    });
  });

  group('ordinary offer card regression', () {
    testWidgets('still shows the creator name, city and match badge', (
      tester,
    ) async {
      await _pumpCard(tester, _offer());

      expect(find.text('Casa Sol'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      expect(find.text('92% match'), findsOneWidget);
    });
  });

  group('localisation', () {
    testWidgets('role copy is translated in Spanish', (tester) async {
      await _pumpCard(
        tester,
        _role(needed: 3, filled: 1),
        locale: const Locale('es'),
      );

      expect(find.text('Multi-Kolab'), findsOneWidget);
      expect(find.text('Abierto a cualquier comunidad'), findsOneWidget);
      expect(find.text('2 plazas libres'), findsOneWidget);
    });

    testWidgets('role copy is translated in Catalan', (tester) async {
      await _pumpCard(
        tester,
        _role(needed: 3, filled: 1),
        locale: const Locale('ca'),
      );

      expect(find.text('Obert a qualsevol comunitat'), findsOneWidget);
      expect(find.text('2 places lliures'), findsOneWidget);
    });
  });

  group('responsive surfaces', () {
    for (final surface in const <(String, Size)>[
      ('small phone', Size(320, 640)),
      ('large phone', Size(430, 932)),
    ]) {
      testWidgets('renders without overflow on a ${surface.$1}', (
        tester,
      ) async {
        await _pumpCard(
          tester,
          _role(needed: 4, filled: 1),
          surface: surface.$2,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Run Club Partner'), findsOneWidget);
        expect(
          find.byKey(const Key('explore-card-multi-kolab-badge')),
          findsOneWidget,
        );
      });
    }
  });

  testWidgets('tapping a role card invokes onTap', (tester) async {
    var tapped = false;
    await _pumpCard(tester, _role(), onTap: () => tapped = true);

    await tester.tap(find.text('Run Club Partner'));
    expect(tapped, isTrue);
  });
}
