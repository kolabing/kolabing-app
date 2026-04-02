import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../business/models/subscription.dart';
import '../../business/services/profile_service.dart';

/// App Store product ID for the monthly subscription
const String kMonthlySubscriptionId = 'com.kolabing.app.subscription.monthly';

/// Set of all subscription product IDs
const Set<String> kSubscriptionProductIds = {kMonthlySubscriptionId};

/// Service for handling iOS In-App Purchase operations
class IAPService {
  IAPService({
    ProfileService? profileService,
    InAppPurchase? iap,
  })  : _profileService = profileService ?? ProfileService(),
        _iap = iap ?? InAppPurchase.instance;

  final ProfileService _profileService;
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// Whether the store is available
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// Loaded products from App Store
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// Get the monthly subscription product
  ProductDetails? get monthlyProduct =>
      _products.isEmpty ? null : _products.first;

  /// Initialize the IAP service — call once at app start on iOS
  Future<void> initialize() async {
    if (!Platform.isIOS) return;

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Load products
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

  /// Start a subscription purchase
  Future<bool> purchaseSubscription() async {
    if (!_isAvailable || monthlyProduct == null) {
      debugPrint('IAP: Cannot purchase — store not available or no products');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: monthlyProduct!);

    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } on Exception catch (e) {
      debugPrint('IAP: Purchase error: $e');
      return false;
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
            'IAP: Purchase ${purchase.status.name} — verifying with backend');
        try {
          final subscription = await _verifyWithBackend(purchase);
          onPurchaseVerified(subscription);
        } on Exception catch (e) {
          debugPrint('IAP: Backend verification failed: $e');
          onError(
              'Purchase completed but verification failed. Please try again or contact support.');
        }
        // Complete the transaction with Apple
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

      case PurchaseStatus.error:
        debugPrint('IAP: Purchase error: ${purchase.error}');
        final errorMessage = purchase.error?.message ?? 'Purchase failed';
        if (!errorMessage.toLowerCase().contains('cancel')) {
          onError(errorMessage);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

      case PurchaseStatus.canceled:
        debugPrint('IAP: Purchase canceled by user');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
    }
  }

  /// Verify purchase with backend
  Future<Subscription> _verifyWithBackend(PurchaseDetails purchase) =>
      _profileService.verifyApplePurchase(
        transactionId: purchase.purchaseID ?? '',
        originalTransactionId: purchase.purchaseID ?? '',
        productId: purchase.productID,
      );

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
