import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import '../../auth/models/auth_response.dart';
import '../../business/models/subscription.dart';
import '../../business/services/profile_service.dart';

/// App Store product ID for the monthly subscription
const String kMonthlySubscriptionId = 'com.kolabing.app.subscription.monthly';

/// Set of all subscription product IDs
const Set<String> kSubscriptionProductIds = {kMonthlySubscriptionId};

typedef PurchaseStartResult = ({bool started, String? validatedReferralCode});

/// Service for handling iOS In-App Purchase operations
class IAPService {
  IAPService({ProfileService? profileService, InAppPurchase? iap})
    : _profileService = profileService ?? ProfileService(),
      _iap = iap ?? InAppPurchase.instance;

  final ProfileService _profileService;
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String? _pendingReferralCode;

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
  Future<PurchaseStartResult> purchaseSubscription({
    String? referralCode,
  }) async {
    if (!_isAvailable || monthlyProduct == null) {
      debugPrint('IAP: Cannot purchase — store not available or no products');
      return (started: false, validatedReferralCode: null);
    }

    final validatedReferralCode = await _profileService.validateReferralCode(
      referralCode,
    );
    _pendingReferralCode = validatedReferralCode;
    final purchaseParam = PurchaseParam(productDetails: monthlyProduct!);

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
