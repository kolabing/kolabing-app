import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../../../services/analytics/analytics_service.dart';
import '../../auth/models/auth_response.dart';
import '../../business/models/subscription.dart';
import '../../business/services/profile_service.dart';

/// App Store product IDs for the monthly subscription
const String kMonthlySubscriptionId = 'com.kolabing.app.subscription.monthly';
const String kBundleMonthlySubscriptionId =
    'com.kolabing.kolabingApp.subscription.monthly';

/// App Store product ID for the 3-month subscription
const String kBundleThreeMonthsSubscriptionId =
    'com.kolabing.kolabingApp.subscription.three_months';

/// Prefer the current bundle-scoped product id first, but keep the legacy
/// identifier as a fallback so existing App Store Connect setups continue to
/// work during migration.
const List<String> kMonthlyProductIdPriority = <String>[
  kBundleMonthlySubscriptionId,
  kMonthlySubscriptionId,
];

/// Product id priority for the 3-month plan.
const List<String> kThreeMonthsProductIdPriority = <String>[
  kBundleThreeMonthsSubscriptionId,
];

/// Backwards-compatible alias for the monthly priority list.
const List<String> kSubscriptionProductIdPriority = kMonthlyProductIdPriority;

/// Set of all subscription product IDs queried from the store.
final Set<String> kSubscriptionProductIds = <String>{
  ...kMonthlyProductIdPriority,
  ...kThreeMonthsProductIdPriority,
};

/// A purchasable subscription plan.
enum SubscriptionPlan {
  monthly(durationMonths: 1, productIdPriority: kMonthlyProductIdPriority),
  threeMonths(
    durationMonths: 3,
    productIdPriority: kThreeMonthsProductIdPriority,
  );

  const SubscriptionPlan({
    required this.durationMonths,
    required this.productIdPriority,
  });

  /// Number of months the plan covers (used for per-month equivalents).
  final int durationMonths;

  /// Ordered list of App Store product ids that fulfil this plan.
  final List<String> productIdPriority;
}

typedef PurchaseStartResult = ({bool started, String? validatedReferralCode});

/// Service for handling iOS In-App Purchase operations
class IAPService {
  IAPService({
    ProfileService? profileService,
    InAppPurchase? iap,
    bool Function()? isIosPlatform,
  }) : _profileService = profileService ?? ProfileService(),
       _iap = iap ?? InAppPurchase.instance,
       _isIosPlatform = isIosPlatform ?? (() => Platform.isIOS);

  final ProfileService _profileService;
  final InAppPurchase _iap;
  final bool Function() _isIosPlatform;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String? _pendingReferralCode;

  /// Whether the store is available
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Loaded products from App Store
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// Resolve the loaded [ProductDetails] for a given plan, honouring the
  /// plan's product-id priority. Null if none of the plan's products loaded.
  ProductDetails? productFor(SubscriptionPlan plan) {
    for (final productId in plan.productIdPriority) {
      for (final product in _products) {
        if (product.id == productId) return product;
      }
    }
    return null;
  }

  /// Get the monthly subscription product
  ProductDetails? get monthlyProduct {
    final byPriority = productFor(SubscriptionPlan.monthly);
    if (byPriority != null) return byPriority;
    // Legacy fallback: any loaded product that isn't the 3-month plan.
    for (final product in _products) {
      if (!kThreeMonthsProductIdPriority.contains(product.id)) return product;
    }
    return null;
  }

  /// Get the 3-month subscription product
  ProductDetails? get threeMonthsProduct =>
      productFor(SubscriptionPlan.threeMonths);

  /// Initialize the IAP service — call once at app start on iOS
  Future<void> initialize() async {
    if (!_isIosPlatform()) return;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Load products
    debugPrint('IAP: Querying product ids: $kSubscriptionProductIds');
    final response = await _iap.queryProductDetails(kSubscriptionProductIds);
    if (response.error != null) {
      debugPrint('IAP: Error loading products: ${response.error}');
      return;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('IAP: Loaded ${_products.length} products');
    for (final p in _products) {
      debugPrint(
        'IAP: product ${p.id} → price="${p.price}" '
        'symbol="${p.currencySymbol}" code=${p.currencyCode} raw=${p.rawPrice}',
      );
    }
  }

  /// Listen to purchase updates stream
  /// The [onPurchaseVerified] callback is called after successful backend verification
  void listenToPurchases({
    required void Function(Subscription subscription) onPurchaseVerified,
    required void Function(String error) onError,
    required void Function() onPending,
  }) {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          await _handlePurchaseUpdate(
            purchase,
            onPurchaseVerified: onPurchaseVerified,
            onError: onError,
            onPending: onPending,
          );
        }
      },
      onError: (Object error) {
        debugPrint('IAP: Purchase stream error: $error');
        onError('Purchase failed. Please try again.');
      },
    );
  }

  /// Start a subscription purchase for the given [plan].
  Future<PurchaseStartResult> purchaseSubscription({
    SubscriptionPlan plan = SubscriptionPlan.monthly,
    String? referralCode,
  }) async {
    final product =
        productFor(plan) ??
        (plan == SubscriptionPlan.monthly ? monthlyProduct : null);
    if (!_isAvailable || product == null) {
      debugPrint(
        'IAP: Cannot purchase — store not available or no product for $plan',
      );
      return (started: false, validatedReferralCode: null);
    }

    final validatedReferralCode = await _profileService.validateReferralCode(
      referralCode,
    );
    _pendingReferralCode = validatedReferralCode;
    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _pendingReferralCode = null;
      }
      return (
        started: started,
        validatedReferralCode: started ? validatedReferralCode : null,
      );
    } on Exception catch (e) {
      debugPrint('IAP: Purchase error: $e');
      _pendingReferralCode = null;
      return (started: false, validatedReferralCode: null);
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;
    await _iap.restorePurchases();
  }

  /// Handle a purchase update from the stream
  Future<void> _handlePurchaseUpdate(
    PurchaseDetails purchase, {
    required void Function(Subscription) onPurchaseVerified,
    required void Function(String) onError,
    required void Function() onPending,
  }) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        debugPrint('IAP: Purchase pending');
        onPending();

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        debugPrint(
          'IAP: Purchase ${purchase.status.name} — verifying with backend',
        );
        try {
          final subscription = await _verifyWithBackend(purchase);
          _pendingReferralCode = null;
          // Revenue KPI: only a genuine new purchase counts as a conversion;
          // `restored` is a re-entitlement on a fresh install, not a start.
          if (purchase.status == PurchaseStatus.purchased) {
            unawaited(
              AnalyticsService.instance.capture(
                AnalyticsEvents.subscriptionStarted,
                properties: {'product_id': purchase.productID},
              ),
            );
          }
          onPurchaseVerified(subscription);
        } on ApiException catch (e) {
          debugPrint('IAP: Backend verification failed: $e');
          _pendingReferralCode = null;
          onError(
            e.error.getFriendlyFieldError('referral_code') ??
                e.error.allErrorMessages,
          );
        } on Exception catch (e) {
          debugPrint('IAP: Backend verification failed: $e');
          _pendingReferralCode = null;
          onError(
            'Purchase completed but verification failed. Please try again or contact support.',
          );
        }
        // Complete the transaction with Apple
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

      case PurchaseStatus.error:
        debugPrint('IAP: Purchase error: ${purchase.error}');
        _pendingReferralCode = null;
        final errorMessage = purchase.error?.message ?? 'Purchase failed';
        if (!errorMessage.toLowerCase().contains('cancel')) {
          onError(errorMessage);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

      case PurchaseStatus.canceled:
        debugPrint('IAP: Purchase canceled by user');
        _pendingReferralCode = null;
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
    }
  }

  /// Verify purchase with backend
  Future<Subscription> _verifyWithBackend(PurchaseDetails purchase) =>
      _profileService.verifyApplePurchase(
        transactionId: purchase.purchaseID ?? '',
        originalTransactionId: _resolveOriginalTransactionId(purchase),
        productId: purchase.productID,
        referralCode: _pendingReferralCode,
      );

  String _resolveOriginalTransactionId(PurchaseDetails purchase) {
    if (purchase is AppStorePurchaseDetails) {
      return purchase
              .skPaymentTransaction
              .originalTransaction
              ?.transactionIdentifier ??
          purchase.purchaseID ??
          '';
    }
    return purchase.purchaseID ?? '';
  }

  /// Dispose resources
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}

/// Provider for IAPService
final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService();
  ref.onDispose(service.dispose);
  return service;
});
