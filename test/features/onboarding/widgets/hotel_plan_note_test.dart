// Picking "hotel" on business onboarding shows what the hotel plan costs
// (SERR-201, Lab22). iOS only: the plan is an App Store subscription.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kolabing_app/features/onboarding/widgets/hotel_plan_note.dart';
import 'package:kolabing_app/features/subscription/providers/iap_provider.dart';
import 'package:kolabing_app/features/subscription/services/iap_service.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

class _IapNotifier extends IAPNotifier {
  _IapNotifier(this._products);

  final List<ProductDetails> _products;

  @override
  IAPState build() => IAPState(isAvailable: true, products: _products);
}

Future<void> _pump(
  WidgetTester tester, {
  required bool isIos,
  List<ProductDetails> products = const <ProductDetails>[],
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [iapProvider.overrideWith(() => _IapNotifier(products))],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HotelPlanNote(isIosOverride: isIos)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the plan price with the fixed fallback before the store', (
    tester,
  ) async {
    await _pump(tester, isIos: true);

    expect(find.text('Hotels: Venue Pro is €299.00 per month'), findsOneWidget);
    expect(find.textContaining('Billed through the App Store'), findsOneWidget);
  });

  testWidgets("uses the store's price once it has answered, in euro", (
    tester,
  ) async {
    await _pump(
      tester,
      isIos: true,
      products: <ProductDetails>[
        ProductDetails(
          id: kBundleProMonthlySubscriptionId,
          title: 'Venue Pro',
          description: 'Venue Pro',
          price: r'$349.99',
          rawPrice: 299,
          currencyCode: 'USD',
          currencySymbol: r'$',
        ),
      ],
    );

    expect(find.text('Hotels: Venue Pro is €299.00 per month'), findsOneWidget);
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('is not shown off iOS, where the plan cannot be bought', (
    tester,
  ) async {
    await _pump(tester, isIos: false);

    expect(find.textContaining('Venue Pro'), findsNothing);
  });

  testWidgets('reads in Spanish and Catalan', (tester) async {
    await _pump(tester, isIos: true, locale: const Locale('es'));
    expect(
      find.text('Hoteles: Venue Pro cuesta €299.00 al mes'),
      findsOneWidget,
    );

    await _pump(tester, isIos: true, locale: const Locale('ca'));
    expect(find.text('Hotels: Venue Pro costa €299.00 al mes'), findsOneWidget);
  });
}
