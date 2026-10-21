// Business Explore → Communities (ROLES §2.24). A free business scrolls every
// community with the identity withheld; a subscribed business sees names.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/discovery/models/directory_community.dart';
import 'package:kolabing_app/features/discovery/providers/community_directory_provider.dart';
import 'package:kolabing_app/features/discovery/widgets/community_directory_list.dart';
import 'package:kolabing_app/features/onboarding/models/community_type.dart';
import 'package:kolabing_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

class _FixedDirectory extends CommunityDirectoryNotifier {
  _FixedDirectory(this._state);

  final CommunityDirectoryState _state;
  int loadMoreCalls = 0;

  @override
  CommunityDirectoryState build() => _state;

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
  }

  @override
  Future<void> refresh() async {}
}

Future<void> _pump(
  WidgetTester tester,
  CommunityDirectoryState state, {
  _FixedDirectory? notifier,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        communityDirectoryProvider.overrideWith(
          () => notifier ?? _FixedDirectory(state),
        ),
        communityTypesProvider.overrideWith(
          (ref) async => const <CommunityType>[
            CommunityType(id: '1', name: 'Running club', slug: 'running'),
          ],
        ),
      ],
      child: MaterialApp(
        theme: KolabingTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CommunityDirectoryList()),
      ),
    ),
  );
  // The bottom loader spins forever while pages remain, so a visible one
  // never settles.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a free business sees every community, names withheld', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const CommunityDirectoryState(
        currentPage: 1,
        total: 2,
        items: <DirectoryCommunity>[
          DirectoryCommunity(
            id: 'c-1',
            identityMasked: true,
            communityType: 'running',
            communitySize: 120,
            cityName: 'Barcelona',
          ),
          DirectoryCommunity(id: 'c-2', identityMasked: true),
        ],
      ),
    );

    expect(find.text('2 communities on Kolabing'), findsOneWidget);
    expect(find.textContaining('hidden until you subscribe'), findsOneWidget);
    expect(find.text('Running club · 120 people · Barcelona'), findsOneWidget);
    expect(find.text('No kolabs yet'), findsNWidgets(2));
    // A screen reader hears "Hidden community", never the placeholder dots.
    expect(find.bySemanticsLabel(RegExp('Hidden community')), findsNWidgets(2));
    expect(find.bySemanticsLabel(RegExp('●')), findsNothing);
    semantics.dispose();
  });

  testWidgets('a subscribed business sees names and no lock banner', (
    tester,
  ) async {
    await _pump(
      tester,
      const CommunityDirectoryState(
        currentPage: 1,
        total: 1,
        items: <DirectoryCommunity>[
          DirectoryCommunity(
            id: 'c-1',
            identityMasked: false,
            displayName: 'Barcelona Run Club',
            publishedKolabsCount: 2,
            isVerified: true,
          ),
        ],
      ),
    );

    expect(find.text('1 community on Kolabing'), findsOneWidget);
    expect(find.text('Barcelona Run Club'), findsOneWidget);
    expect(find.text('2 kolabs published'), findsOneWidget);
    expect(find.textContaining('hidden until you subscribe'), findsNothing);
  });

  testWidgets('an empty directory says so', (tester) async {
    await _pump(tester, const CommunityDirectoryState());

    expect(find.text('No communities yet'), findsOneWidget);
  });

  testWidgets('a masked row never draws a name or logo, even if one is sent', (
    tester,
  ) async {
    await _pump(
      tester,
      const CommunityDirectoryState(
        currentPage: 1,
        total: 1,
        items: <DirectoryCommunity>[
          DirectoryCommunity(
            id: 'c-1',
            identityMasked: true,
            displayName: 'Leaked Name',
            avatarUrl: 'https://cdn.test/leak.png',
          ),
        ],
      ),
    );

    expect(find.text('Leaked Name'), findsNothing);
    expect(find.textContaining('Leaked'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('scrolling to the end asks for the next page', (tester) async {
    final state = CommunityDirectoryState(
      currentPage: 1,
      lastPage: 3,
      total: 60,
      items: <DirectoryCommunity>[
        for (var i = 0; i < 20; i++)
          DirectoryCommunity(id: 'c-$i', identityMasked: true),
      ],
    );
    final notifier = _FixedDirectory(state);
    await _pump(tester, state, notifier: notifier);

    expect(notifier.loadMoreCalls, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pump();

    expect(notifier.loadMoreCalls, greaterThan(0));
    // A loader sits under the last row while pages remain.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a first page shorter than the screen loads the next one', (
    tester,
  ) async {
    const state = CommunityDirectoryState(
      currentPage: 1,
      lastPage: 2,
      total: 21,
      items: <DirectoryCommunity>[
        DirectoryCommunity(id: 'c-1', identityMasked: true),
      ],
    );
    final notifier = _FixedDirectory(state);
    await _pump(tester, state, notifier: notifier, settle: false);

    expect(notifier.loadMoreCalls, greaterThan(0));
  });
}
