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

  @override
  CommunityDirectoryState build() => _state;

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}
}

Future<void> _pump(WidgetTester tester, CommunityDirectoryState state) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        communityDirectoryProvider.overrideWith(() => _FixedDirectory(state)),
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
  await tester.pumpAndSettle();
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
    expect(find.text('No open kolabs'), findsNWidgets(2));
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
    expect(find.text('2 open kolabs'), findsOneWidget);
    expect(find.textContaining('hidden until you subscribe'), findsNothing);
  });

  testWidgets('an empty directory says so', (tester) async {
    await _pump(tester, const CommunityDirectoryState());

    expect(find.text('No communities yet'), findsOneWidget);
  });
}
