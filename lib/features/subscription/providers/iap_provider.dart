import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../auth/models/auth_response.dart';
import '../../business/providers/profile_provider.dart';
import '../services/iap_service.dart';

/// IAP state
@immutable
class IAPState {
  const IAPState({
    this.isAvailable = false,
    this.products = const [],
    this.isLoadingProducts = false,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.error,
  });

  final bool isAvailable;
  final List<ProductDetails> products;
  final bool isLoadingProducts;
  final bool isPurchasing;
  final bool isRestoring;
  final String? error;

  /// Resolve the loaded product for a plan, honouring its id priority.
  ProductDetails? _productByPriority(SubscriptionPlan plan) {
    for (final id in plan.productIdPriority) {
      for (final p in products) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  /// The monthly subscription product from App Store
  ProductDetails? get monthlyProduct {
    final byPriority = _productByPriority(SubscriptionPlan.monthly);
    if (byPriority != null) return byPriority;
    for (final p in products) {
      if (!kThreeMonthsProductIdPriority.contains(p.id)) return p;
    }
    return null;
  }

  /// The 3-month subscription product from App Store
  ProductDetails? get threeMonthsProduct =>
      _productByPriority(SubscriptionPlan.threeMonths);

  /// Resolve the product for a given plan.
  ProductDetails? productFor(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.monthly ? monthlyProduct : threeMonthsProduct;

  /// Shown when the store has not returned a product yet (and on the non-iOS /
  /// Stripe path, which really is euro-priced). Kolabing's base price is
  /// €49.99; every storefront's actual number comes from the store itself.
  static const String kFallbackMonthlyPrice = '€49.99';
  static const String kFallbackThreeMonthsPrice = '€99.99';

  /// The price string the store itself will charge, already localized by
  /// StoreKit — "49,99 €" on a euro storefront, "\$44.99" on a US one.
  ///
  /// Never re-format this with a hardcoded symbol: Apple converts the euro base
  /// price per storefront, so prefixing "€" onto [ProductDetails.rawPrice]
  /// shows a currency the user is not actually charged in.
  String? displayPriceFor(SubscriptionPlan plan) => productFor(plan)?.price;

  /// Monthly price as the store formats it, falling back to the euro base price
  /// while products are still loading.
  String get priceString => monthlyProduct?.price ?? kFallbackMonthlyPrice;

  /// Per-month equivalent for a multi-month plan (e.g. "€33.33"). This number
  /// is derived, so it has no store-formatted string of its own — it is built
  /// from the product's own currency symbol, never a hardcoded one.
  /// Null for the monthly plan or if not loaded.
  String? perMonthEquivalent(SubscriptionPlan plan) {
    final product = productFor(plan);
    if (product == null || plan.durationMonths <= 1) return null;
    final perMonth = (product.rawPrice / plan.durationMonths).toStringAsFixed(
      2,
    );
    return '${product.currencySymbol}$perMonth';
  }

  /// Savings percent of [plan] vs paying monthly for the same duration.
  /// Null if either product is missing or there is no saving.
  int? savingsPercent(SubscriptionPlan plan) {
    final monthly = monthlyProduct;
    final product = productFor(plan);
    if (monthly == null || product == null || plan.durationMonths <= 1) {
      return null;
    }
    final fullPrice = monthly.rawPrice * plan.durationMonths;
    if (fullPrice <= 0) return null;
    final saving = (fullPrice - product.rawPrice) / fullPrice * 100;
    if (saving <= 0) return null;
    return saving.round();
  }

  /// Whether a purchase can be started immediately.
  bool get canPurchase =>
      purchaseAvailabilityMessage == null && !isPurchasing && !isRestoring;

  /// User-facing reason why purchase is blocked.
  String? get purchaseAvailabilityMessage {
    if (isLoadingProducts) {
      return 'Loading subscription options from the App Store...';
    }
    if (!isAvailable) {
      return 'App Store purchases are not available on this device.';
    }
    return null;
  }

  IAPState copyWith({
    bool? isAvailable,
    List<ProductDetails>? products,
    bool? isLoadingProducts,
    bool? isPurchasing,
    bool? isRestoring,
    String? error,
    bool clearError = false,
  }) => IAPState(
    isAvailable: isAvailable ?? this.isAvailable,
    products: products ?? this.products,
    isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
    isPurchasing: isPurchasing ?? this.isPurchasing,
    isRestoring: isRestoring ?? this.isRestoring,
    error: clearError ? null : (error ?? this.error),
  );
}

/// IAP Notifier
class IAPNotifier extends Notifier<IAPState> {
  late final IAPService _iapService;

  @override
  IAPState build() {
    _iapService = ref.read(iapServiceProvider);

    // Initialize on iOS
    if (Platform.isIOS) {
      _initialize();
    }

    return IAPState(isLoadingProducts: Platform.isIOS);
  }

  Future<void> _initialize() async {
    await _iapService.initialize();

    state = state.copyWith(
      isAvailable: _iapService.isAvailable,
      products: _iapService.products,
      isLoadingProducts: false,
    );

    // Listen to purchase stream
    _iapService.listenToPurchases(
      onPurchaseVerified: (subscription) {
        state = state.copyWith(
          isPurchasing: false,
          isRestoring: false,
          clearError: true,
        );
        // Update profile provider with new subscription
        ref.read(profileProvider.notifier).refreshSubscription();
      },
      onError: (error) {
        state = state.copyWith(
          isPurchasing: false,
          isRestoring: false,
          error: error,
        );
      },
      onPending: () {
        state = state.copyWith(isPurchasing: true);
      },
      onCancelled: () {
        // User dismissed the App Store sheet — drop the loading state without
        // showing an error so the Subscribe button returns to normal.
        state = state.copyWith(
          isPurchasing: false,
          isRestoring: false,
          clearError: true,
        );
      },
    );
  }

  Future<void> refreshProducts() async {
    state = state.copyWith(isLoadingProducts: true, clearError: true);
    await _iapService.initialize();
    state = state.copyWith(
      isAvailable: _iapService.isAvailable,
      products: _iapService.products,
      isLoadingProducts: false,
    );
  }

  /// Purchase the given subscription [plan].
  Future<PurchaseStartResult> purchase({
    SubscriptionPlan plan = SubscriptionPlan.monthly,
    String? referralCode,
  }) async {
    if (state.isPurchasing) {
      return (started: false, validatedReferralCode: null);
    }

    if (state.isAvailable && state.productFor(plan) == null) {
      await refreshProducts();
    }

    final purchaseAvailabilityMessage = state.purchaseAvailabilityMessage;
    if (purchaseAvailabilityMessage != null) {
      state = state.copyWith(error: purchaseAvailabilityMessage);
      return (started: false, validatedReferralCode: null);
    }

    state = state.copyWith(isPurchasing: true, clearError: true);

    try {
      final result = await _iapService.purchaseSubscription(
        plan: plan,
        referralCode: referralCode,
      );
      if (!result.started) {
        state = state.copyWith(
          isPurchasing: false,
          error: 'Could not start purchase. Please try again.',
        );
      }
      return result;
    } on ApiException {
      state = state.copyWith(isPurchasing: false, clearError: true);
      rethrow;
    } on NetworkException {
      state = state.copyWith(isPurchasing: false, clearError: true);
      rethrow;
    } on Exception {
      state = state.copyWith(isPurchasing: false, clearError: true);
      rethrow;
    }
    // If started, the purchase stream will handle the result
  }

  /// Restore purchases
  Future<void> restore() async {
    if (state.isRestoring) return;

    state = state.copyWith(isRestoring: true, clearError: true);
    await _iapService.restorePurchases();

    // Wait a bit for restore results to come through the stream
    await Future<void>.delayed(const Duration(seconds: 3));

    if (state.isRestoring) {
      // No restore callback received — likely no purchases to restore
      state = state.copyWith(
        isRestoring: false,
        error: 'No active subscription found to restore.',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// IAP provider
final iapProvider = NotifierProvider<IAPNotifier, IAPState>(IAPNotifier.new);
