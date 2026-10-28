import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/subscription/providers/iap_provider.dart';
import 'package:kolabing_app/features/subscription/services/iap_service.dart';
import 'package:kolabing_app/features/subscription/widgets/subscription_paywall.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('subscription paywall has no referral code field (Apple 3.1.1)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(_FakeProfileNotifier.new),
          iapProvider.overrideWith(_FakeIapNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SubscriptionPaywall()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The referral-code input must not appear next to the IAP purchase
    // options — Apple rejected the build for exactly this (Guideline
    // 3.1.1). It stays only on the register/signup screen.
    expect(find.text('Referral Code (optional)'), findsNothing);
    expect(find.text('Paste referral code'), findsNothing);

    // Guideline 3.1.2: the paywall must expose the EULA + Privacy links.
    expect(find.text('Terms of Use (EULA)'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  group('Venue Pro for hotels', () {
    testWidgets('a hotel on iOS sees the EUR 299 plan first, selected', (
      tester,
    ) async {
      await _pump(tester, types: const ['hotel'], products: _allProducts);

      expect(find.text('Venue Pro'), findsOneWidget);
      expect(find.text('€299.00'), findsOneWidget);
      expect(find.text('For hotels'), findsOneWidget);
      // The standard plans stay available underneath.
      expect(find.text('€49.99'), findsOneWidget);
      expect(find.text('€99.99'), findsOneWidget);
      // The Pro card is the selected one: its check icon is the filled one.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Venue Pro'),
            matching: find.byType(AnimatedContainer),
          ),
          matching: find.byIcon(LucideIcons.checkCircle2),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a hotel can still pick a standard plan instead', (
      tester,
    ) async {
      await _pump(tester, types: const ['hotel'], products: _allProducts);

      await tester.tap(find.text('€49.99'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Venue Pro'),
            matching: find.byType(AnimatedContainer),
          ),
          matching: find.byIcon(LucideIcons.checkCircle2),
        ),
        findsNothing,
      );
    });

    testWidgets('a cafe never sees Venue Pro', (tester) async {
      await _pump(tester, types: const ['cafe'], products: _allProducts);

      expect(find.text('Venue Pro'), findsNothing);
      expect(find.text('€299.00'), findsNothing);
      expect(find.text('€99.99'), findsOneWidget);
    });

    testWidgets('a hotel sees the standard plans until the store has Pro', (
      tester,
    ) async {
      await _pump(
        tester,
        types: const ['hotel'],
        products: <ProductDetails>[_monthly, _threeMonths],
      );

      expect(find.text('Venue Pro'), findsNothing);
      expect(find.text('€99.99'), findsOneWidget);
    });

    testWidgets('a hotel off iOS (Stripe path) does not get the Pro card', (
      tester,
    ) async {
      await _pump(
        tester,
        types: const ['hotel'],
        products: _allProducts,
        isIos: false,
      );

      expect(find.text('Venue Pro'), findsNothing);
    });

    testWidgets('a community is never shown a paywall plan picker', (
      tester,
    ) async {
      // checkAndShow is a no-op for non-business viewers; the widget itself
      // never reads a hotel type from a community profile.
      await _pump(tester, types: const [], products: _allProducts);

      expect(find.text('Venue Pro'), findsNothing);
    });
  });

  test('BusinessProfile.isHotel reads the hotel type, whatever the case', () {
    expect(
      const BusinessProfile(
        id: 'b',
        name: 'x',
        businessTypes: ['Hotel'],
      ).isHotel,
      isTrue,
    );
    expect(
      const BusinessProfile(id: 'b', name: 'x', businessType: 'hotel').isHotel,
      isTrue,
    );
    expect(
      const BusinessProfile(
        id: 'b',
        name: 'x',
        businessTypes: ['cafe', 'hotel'],
      ).isHotel,
      isTrue,
    );
    expect(
      const BusinessProfile(
        id: 'b',
        name: 'x',
        businessTypes: ['cafe'],
      ).isHotel,
      isFalse,
    );
    expect(const BusinessProfile(id: 'b', name: 'x').isHotel, isFalse);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required List<String> types,
  required List<ProductDetails> products,
  bool isIos = true,
}) async {
  tester.view.physicalSize = const Size(1179, 6600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(() => _TypedProfileNotifier(types)),
        iapProvider.overrideWith(() => _ProductsIapNotifier(products)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SubscriptionPaywall(isIosOverride: isIos)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TypedProfileNotifier extends ProfileNotifier {
  _TypedProfileNotifier(this._types);

  final List<String> _types;

  @override
  ProfileState build() => ProfileState(
    profile: UserModel(
      id: 'business-1',
      email: 'business@example.com',
      userType: UserType.business,
      businessProfile: BusinessProfile(
        id: 'bp-1',
        name: 'Lab22',
        businessTypes: _types,
      ),
    ),
    isLoading: false,
    isInitialized: true,
  );
}

class _ProductsIapNotifier extends IAPNotifier {
  _ProductsIapNotifier(this._products);

  final List<ProductDetails> _products;

  @override
  IAPState build() => IAPState(isAvailable: true, products: _products);

  @override
  Future<void> refreshProducts() async {}
}

final ProductDetails _monthly = ProductDetails(
  id: kBundleMonthlySubscriptionId,
  title: 'Monthly',
  description: 'Monthly',
  price: '49,99 €',
  rawPrice: 49.99,
  currencyCode: 'EUR',
  currencySymbol: '€',
);

final ProductDetails _threeMonths = ProductDetails(
  id: kBundleThreeMonthsSubscriptionId,
  title: '3 months',
  description: '3 months',
  price: '99,99 €',
  rawPrice: 99.99,
  currencyCode: 'EUR',
  currencySymbol: '€',
);

final ProductDetails _pro = ProductDetails(
  id: kBundleProMonthlySubscriptionId,
  title: 'Venue Pro',
  description: 'Venue Pro',
  price: '299,00 €',
  rawPrice: 299,
  currencyCode: 'EUR',
  currencySymbol: '€',
);

final List<ProductDetails> _allProducts = <ProductDetails>[
  _monthly,
  _threeMonths,
  _pro,
];

class _FakeProfileNotifier extends ProfileNotifier {
  @override
  ProfileState build() => const ProfileState(
    profile: UserModel(
      id: 'business-1',
      email: 'business@example.com',
      userType: UserType.business,
      businessProfile: BusinessProfile(id: 'bp-1', name: 'Venue Works'),
    ),
    isLoading: false,
    isInitialized: true,
  );
}

class _FakeIapNotifier extends IAPNotifier {
  @override
  IAPState build() => const IAPState();
}
