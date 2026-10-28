// A hotel already on a standard App Store plan can move up to Venue Pro
// (ROLES §2.19). Who is offered it is a pure decision, tested here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/business/models/subscription.dart';
import 'package:kolabing_app/features/subscription/widgets/venue_pro_upgrade_card.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

Subscription _sub({String? source = 'apple_iap', String? plan}) => Subscription(
  id: 's',
  status: SubscriptionStatus.active,
  source: source,
  plan: plan,
  isActive: true,
);

bool _offer({
  bool isIos = true,
  bool isActive = true,
  Subscription? subscription,
  bool hasProProduct = true,
  bool isHotel = true,
}) => shouldOfferVenueProUpgrade(
  isIos: isIos,
  isActive: isActive,
  subscription: subscription ?? _sub(),
  hasProProduct: hasProProduct,
  isHotel: isHotel,
);

void main() {
  group('shouldOfferVenueProUpgrade', () {
    test('an active App Store standard hotel is offered the upgrade', () {
      expect(_offer(), isTrue);
      expect(_offer(subscription: _sub(plan: 'standard')), isTrue);
    });

    test('never when it already is Pro', () {
      expect(_offer(subscription: _sub(plan: 'pro')), isFalse);
    });

    test('never for a Stripe subscriber (no link out to the web checkout)', () {
      expect(_offer(subscription: _sub(source: 'stripe')), isFalse);
      expect(_offer(subscription: _sub(source: null)), isFalse);
    });

    test('never off iOS, for a non-hotel, or before the store has Pro', () {
      expect(_offer(isIos: false), isFalse);
      expect(_offer(isHotel: false), isFalse);
      expect(_offer(hasProProduct: false), isFalse);
    });

    test('never without an active subscription', () {
      expect(_offer(isActive: false), isFalse);
      expect(
        shouldOfferVenueProUpgrade(
          isIos: true,
          isActive: true,
          subscription: null,
          hasProProduct: true,
          isHotel: true,
        ),
        isFalse,
      );
    });
  });

  test('Subscription reads the plan from the backend', () {
    final pro = Subscription.fromJson(const {
      'id': 's',
      'status': 'active',
      'plan': 'pro',
      'source': 'apple_iap',
    });
    final standard = Subscription.fromJson(const {
      'id': 's',
      'status': 'active',
      'source': 'apple_iap',
    });

    expect(pro.isPro, isTrue);
    expect(standard.isPro, isFalse);
    expect(pro.copyWith(statusLabel: 'x').isPro, isTrue);
    expect(pro.toJson()['plan'], 'pro');
  });

  testWidgets('the card shows the euro price and starts the upgrade', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VenueProUpgradeCard(price: '€299.00', onUpgrade: () => taps++),
        ),
      ),
    );

    expect(
      find.text('Upgrade to Venue Pro, €299.00 per month'),
      findsOneWidget,
    );
    await tester.tap(find.text('Upgrade to Venue Pro'));
    expect(taps, 1);
  });
}
