import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/discovery/models/directory_community.dart';
import 'package:kolabing_app/features/discovery/providers/community_directory_provider.dart';
import 'package:kolabing_app/features/discovery/widgets/community_directory_list.dart';
import 'package:kolabing_app/features/onboarding/models/community_type.dart';
import 'package:kolabing_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Visual-QA capture for the business community directory (SERR-201).
///
/// Named `..._capture.dart` so `flutter test` never collects it. Refresh with:
///
/// ```
/// flutter test test/features/discovery/widgets/community_directory_capture.dart \
///   --update-goldens
/// ```
///
/// Text is drawn in Liberation Sans standing in for Inter (the test binding
/// cannot fetch Google Fonts), so the PNGs document layout, copy and state.
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

Future<void> _loadFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  Future<ByteData> file(String path) async =>
      ByteData.sublistView(Uint8List.fromList(File(path).readAsBytesSync()));
  const dir = '/usr/share/fonts/truetype/liberation';
  // google_fonts registers Inter as `Inter_<variant>`; give each one a face.
  final families = <String>{
    'Roboto',
    'Inter',
    'Inter_regular',
    'Inter_italic',
    for (final w in <int>[100, 200, 300, 400, 500, 600, 700, 800, 900]) ...[
      'Inter_$w',
      'Inter_${w}italic',
    ],
  };
  for (final family in families) {
    await (FontLoader(family)
          ..addFont(file('$dir/LiberationSans-Regular.ttf'))
          ..addFont(file('$dir/LiberationSans-Bold.ttf')))
        .load();
  }
  await (FontLoader('packages/lucide_icons/Lucide')
        ..addFont(rootBundle.load('packages/lucide_icons/assets/lucide.ttf')))
      .load();
}

const _types = <CommunityType>[
  CommunityType(id: '1', name: 'Running club', slug: 'running'),
  CommunityType(id: '2', name: 'Book club', slug: 'book_club'),
  CommunityType(id: '3', name: 'Yoga', slug: 'yoga'),
  CommunityType(id: '4', name: 'Supper club', slug: 'supper_club'),
];

List<DirectoryCommunity> _rows({required bool masked}) => <DirectoryCommunity>[
  DirectoryCommunity(
    id: 'c-1',
    identityMasked: masked,
    displayName: masked ? null : 'Barcelona Run Club',
    communityType: 'running',
    communitySize: 180,
    cityName: 'Barcelona',
    isVerified: true,
    publishedKolabsCount: 2,
  ),
  DirectoryCommunity(
    id: 'c-2',
    identityMasked: masked,
    displayName: masked ? null : 'Gràcia Book Club',
    communityType: 'book_club',
    communitySize: 45,
    cityName: 'Barcelona',
  ),
  DirectoryCommunity(
    id: 'c-3',
    identityMasked: masked,
    displayName: masked ? null : 'Sunrise Yoga BCN',
    communityType: 'yoga',
    communitySize: 60,
    cityName: 'Barcelona',
    isVerified: true,
    publishedKolabsCount: 1,
  ),
  DirectoryCommunity(
    id: 'c-4',
    identityMasked: masked,
    displayName: masked ? null : 'Mesa Larga Supper Club',
    communityType: 'supper_club',
    communitySize: 24,
    cityName: 'Barcelona',
  ),
];

void main() {
  setUpAll(_loadFonts);

  for (final masked in <bool>[true, false]) {
    final name = masked
        ? 'community_directory_free'
        : 'community_directory_subscribed';
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityDirectoryProvider.overrideWith(
              () => _FixedDirectory(
                CommunityDirectoryState(
                  currentPage: 1,
                  lastPage: 7,
                  total: 132,
                  items: _rows(masked: masked),
                ),
              ),
            ),
            communityTypesProvider.overrideWith((ref) async => _types),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: KolabingTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SafeArea(child: CommunityDirectoryList()),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }
}
