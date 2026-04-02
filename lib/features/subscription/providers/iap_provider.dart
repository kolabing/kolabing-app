import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../business/providers/profile_provider.dart';
import '../services/iap_service.dart';

/// IAP state
@immutable
class IAPState {
  const IAPState({
    this.isAvailable = false,
    this.products = const [],
    this.isPurchasing = false,
    this.isRestoring = false,
    this.error,
  });

  final bool isAvailable;
  final List<ProductDetails> products;
  final bool isPurchasing;
  final bool isRestoring;
  final String? error;

  /// The monthly subscription product from App Store
  ProductDetails? get monthlyProduct =>
      products.isEmpty ? null : products.first;

  /// Formatted price string (from App Store, e.g. "34,99 EUR")
  String get priceString => monthlyProduct?.price ?? '34.99 EUR';

  IAPState copyWith({
    bool? isAvailable,
    List<ProductDetails>? products,
    bool? isPurchasing,
    bool? isRestoring,
    String? error,
    bool clearError = false,
  }) =>
      IAPState(
        isAvailable: isAvailable ?? this.isAvailable,
        products: products ?? this.products,
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

    return const IAPState();
  }

  Future<void> _initialize() async {
    await _iapService.initialize();

    state = state.copyWith(
      isAvailable: _iapService.isAvailable,
      products: _iapService.products,
    );

    // Listen to purchase stream
    _iapService.listenToPurchases(
      onPurchaseVerified: (subscription) {
        state = state.copyWith(
            isPurchasing: false, isRestoring: false, clearError: true);
        // Update profile provider with new subscription
        ref.read(profileProvider.notifier).refreshSubscription();
      },
      onError: (error) {
        state = state.copyWith(
            isPurchasing: false, isRestoring: false, error: error);
      },
      onPending: () {
        state = state.copyWith(isPurchasing: true);
      },
    );
  }

  /// Purchase the monthly subscription
  Future<void> purchase() async {
    if (state.isPurchasing) return;

    state = state.copyWith(isPurchasing: true, clearError: true);

    final started = await _iapService.purchaseSubscription();
    if (!started) {
      state = state.copyWith(
        isPurchasing: false,
        error: 'Could not start purchase. Please try again.',
      );
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
