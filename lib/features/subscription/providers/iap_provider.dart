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

  /// The monthly subscription product from App Store
  ProductDetails? get monthlyProduct =>
      products.isEmpty ? null : products.first;

  /// Formatted price string (from App Store, e.g. "34,99 EUR")
  String get priceString => monthlyProduct?.price ?? 'Loading...';

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
    if (monthlyProduct == null) {
      return 'The subscription product is not available right now. Please try again later.';
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
    );
  }

  /// Purchase the monthly subscription
  Future<PurchaseStartResult> purchase({String? referralCode}) async {
    if (state.isPurchasing) {
      return (started: false, validatedReferralCode: null);
    }

    final purchaseAvailabilityMessage = state.purchaseAvailabilityMessage;
    if (purchaseAvailabilityMessage != null) {
      state = state.copyWith(error: purchaseAvailabilityMessage);
      return (started: false, validatedReferralCode: null);
    }

    state = state.copyWith(isPurchasing: true, clearError: true);

    try {
      final result = await _iapService.purchaseSubscription(
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
