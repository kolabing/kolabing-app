import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:kolabing_app/features/business/models/subscription.dart';
import 'package:kolabing_app/features/subscription/providers/iap_provider.dart';
import 'package:kolabing_app/features/subscription/services/iap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'purchase reports store unavailability before attempting to buy',
    () async {
      final service = _FakeIAPService();
      final container = ProviderContainer(
        overrides: [iapServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);

      await container.read(iapProvider.notifier).purchase();

      final state = container.read(iapProvider);
      expect(service.purchaseCalls, 0);
      expect(
        state.error,
        'App Store purchases are not available on this device.',
      );
      expect(state.isPurchasing, isFalse);
    },
  );

  test('purchase forwards referral code to the IAP service', () async {
    final service = _ReadyIAPService();
    final container = ProviderContainer(
      overrides: [iapServiceProvider.overrideWith((ref) => service)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(iapProvider.notifier)
      ..state = IAPState(
        isAvailable: true,
        products: <ProductDetails>[_monthlyProduct],
      );

    final result = await notifier.purchase(referralCode: 'kolab-irsc');

    expect(service.purchaseCalls, 1);
    expect(service.lastReferralCode, 'KOLAB-IRSC');
    expect(result.started, isTrue);
    expect(result.validatedReferralCode, 'KOLAB-IRSC');
  });

  test('state exposes loading and product availability guards', () {
    const loadingState = IAPState(isLoadingProducts: true);
    const unavailableProductState = IAPState(isAvailable: true);
    final readyState = IAPState(
      isAvailable: true,
      products: <ProductDetails>[_monthlyProduct],
    );

    expect(loadingState.canPurchase, isFalse);
    expect(
      loadingState.purchaseAvailabilityMessage,
      'Loading subscription options from the App Store...',
    );
    expect(loadingState.priceString, 'Loading...');

    expect(unavailableProductState.canPurchase, isFalse);
    expect(
      unavailableProductState.purchaseAvailabilityMessage,
      'The subscription product is not available right now. Please try again later.',
    );

    expect(readyState.canPurchase, isTrue);
    expect(readyState.purchaseAvailabilityMessage, isNull);
    expect(readyState.priceString, '29.99 EUR');
  });
}

final ProductDetails _monthlyProduct = ProductDetails(
  id: kMonthlySubscriptionId,
  title: 'Premium Monthly',
  description: 'Monthly premium subscription',
  price: '29.99 EUR',
  rawPrice: 29.99,
  currencyCode: 'EUR',
  currencySymbol: 'EUR',
);

class _FakeIAPService extends IAPService {
  _FakeIAPService() : super(iap: _FakeInAppPurchase());

  int purchaseCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  bool get isAvailable => false;

  @override
  List<ProductDetails> get products => const <ProductDetails>[];

  @override
  void listenToPurchases({
    required void Function(Subscription subscription) onPurchaseVerified,
    required void Function(String error) onError,
    required void Function() onPending,
  }) {}

  @override
  Future<({bool started, String? validatedReferralCode})> purchaseSubscription({
    String? referralCode,
  }) async {
    purchaseCalls += 1;
    return (started: false, validatedReferralCode: null);
  }

  @override
  Future<void> restorePurchases() async {}
}

class _ReadyIAPService extends _FakeIAPService {
  String? lastReferralCode;

  @override
  bool get isAvailable => true;

  @override
  List<ProductDetails> get products => <ProductDetails>[_monthlyProduct];

  @override
  Future<({bool started, String? validatedReferralCode})> purchaseSubscription({
    String? referralCode,
  }) async {
    purchaseCalls += 1;
    lastReferralCode = referralCode?.toUpperCase();
    return (started: true, validatedReferralCode: lastReferralCode);
  }
}

class _FakeInAppPurchase implements InAppPurchase {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream =>
      const Stream<List<PurchaseDetails>>.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: const <ProductDetails>[],
    notFoundIDs: identifiers.toList(),
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      false;

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async => false;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<String> countryCode() async => 'ES';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
