import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/src/store_kit_wrappers/sk_payment_queue_wrapper.dart';
import 'package:in_app_purchase_storekit/src/store_kit_wrappers/sk_payment_transaction_wrappers.dart';
import 'package:kolabing_app/features/business/models/subscription.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';
import 'package:kolabing_app/features/subscription/services/iap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restored purchases verify with original transaction id when available',
    () async {
      final profileService = _CapturingProfileService();
      final iap = _TestInAppPurchase();
      addTearDown(iap.dispose);

      final service = IAPService(profileService: profileService, iap: iap);

      final verified = Completer<Subscription>();
      service.listenToPurchases(
        onPurchaseVerified: verified.complete,
        onError: fail,
        onPending: () {},
      );

      iap.emitPurchases(<PurchaseDetails>[
        AppStorePurchaseDetails(
          productID: kMonthlySubscriptionId,
          purchaseID: 'restore-transaction-1',
          verificationData: PurchaseVerificationData(
            localVerificationData: 'receipt',
            serverVerificationData: 'receipt',
            source: 'app_store',
          ),
          transactionDate: '1715256000000',
          skPaymentTransaction: SKPaymentTransactionWrapper(
            payment: const SKPaymentWrapper(
              productIdentifier: kMonthlySubscriptionId,
            ),
            transactionState: SKPaymentTransactionStateWrapper.restored,
            originalTransaction: SKPaymentTransactionWrapper(
              payment: const SKPaymentWrapper(
                productIdentifier: kMonthlySubscriptionId,
              ),
              transactionState: SKPaymentTransactionStateWrapper.purchased,
              transactionIdentifier: 'original-transaction-1',
            ),
            transactionIdentifier: 'restore-transaction-1',
          ),
          status: PurchaseStatus.restored,
        ),
      ]);

      await verified.future;

      expect(profileService.lastTransactionId, 'restore-transaction-1');
      expect(
        profileService.lastOriginalTransactionId,
        'original-transaction-1',
      );
    },
  );
}

class _CapturingProfileService extends ProfileService {
  String? lastTransactionId;
  String? lastOriginalTransactionId;

  @override
  Future<Subscription> verifyApplePurchase({
    required String transactionId,
    required String originalTransactionId,
    required String productId,
    String? referralCode,
  }) async {
    lastTransactionId = transactionId;
    lastOriginalTransactionId = originalTransactionId;
    return const Subscription(
      id: 'sub-1',
      status: SubscriptionStatus.active,
      source: 'apple_iap',
      isActive: true,
    );
  }
}

class _TestInAppPurchase implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  PurchaseParam? lastPurchaseParam;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  void emitPurchases(List<PurchaseDetails> purchases) {
    _controller.add(purchases);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: <ProductDetails>[_monthlyProduct],
    notFoundIDs: <String>[],
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchaseParam = purchaseParam;
    return true;
  }

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

final ProductDetails _monthlyProduct = ProductDetails(
  id: kMonthlySubscriptionId,
  title: 'Premium Monthly',
  description: 'Monthly premium subscription',
  price: '29.99 EUR',
  rawPrice: 29.99,
  currencyCode: 'EUR',
  currencySymbol: 'EUR',
);
