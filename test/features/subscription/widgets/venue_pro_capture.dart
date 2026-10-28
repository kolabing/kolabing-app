import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/onboarding/widgets/hotel_plan_note.dart';
import 'package:kolabing_app/features/subscription/providers/iap_provider.dart';
import 'package:kolabing_app/features/subscription/services/iap_service.dart';
import 'package:kolabing_app/features/subscription/widgets/subscription_paywall.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Visual-QA capture for the hotel paywall and onboarding note (SERR-201).
/// Named `..._capture.dart` so `flutter test` never collects it. Refresh with:
///
/// ```
/// flutter test test/features/subscription/widgets/venue_pro_capture.dart --update-goldens
/// ```
///
/// Liberation Sans stands in for Inter (the test binding cannot fetch Google
/// Fonts), so the PNGs document layout, copy and state.
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

ProductDetails _p(String id, double raw) => ProductDetails(
  id: id,
  title: id,
  description: id,
  price: '$raw',
  rawPrice: raw,
  currencyCode: 'EUR',
  currencySymbol: '€',
);

class _Profile extends ProfileNotifier {
  @override
  ProfileState build() => const ProfileState(
    profile: UserModel(
      id: 'b',
      email: 'b@example.com',
      userType: UserType.business,
      businessProfile: BusinessProfile(
        id: 'bp',
        name: 'Lab22',
        businessTypes: ['hotel'],
      ),
    ),
    isLoading: false,
    isInitialized: true,
  );
}

class _Iap extends IAPNotifier {
  @override
  IAPState build() => IAPState(
    isAvailable: true,
    products: <ProductDetails>[
      _p(kBundleMonthlySubscriptionId, 49.99),
      _p(kBundleThreeMonthsSubscriptionId, 99.99),
      _p(kBundleProMonthlySubscriptionId, 299),
    ],
  );

  @override
  Future<void> refreshProducts() async {}
}

void main() {
  setUpAll(_loadFonts);

  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget child,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(_Profile.new),
          iapProvider.overrideWith(_Iap.new),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: KolabingTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('venue_pro_paywall_hotel', (tester) async {
    await shot(
      tester,
      'venue_pro_paywall_hotel',
      const Scaffold(
        backgroundColor: Colors.black54,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SubscriptionPaywall(isIosOverride: true),
        ),
      ),
      const Size(1242, 2688),
    );
  });

  testWidgets('hotel_plan_note_onboarding', (tester) async {
    await shot(
      tester,
      'hotel_plan_note_onboarding',
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: HotelPlanNote(isIosOverride: true),
          ),
        ),
      ),
      const Size(1179, 700),
    );
  });
}
