# Apple Sign In + iOS IAP Subscription — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Apple Sign In entitlement and replace Stripe subscription flow with Apple IAP on iOS while keeping Stripe on Android.

**Architecture:** Platform-aware subscription — `Platform.isIOS` routes to `IAPService` (Apple StoreKit via `in_app_purchase` package), everything else routes to existing Stripe flow. New `IAPService` handles purchase lifecycle; new `IAPProvider` manages state. `SubscriptionPaywall` updated to show native IAP on iOS. Backend API calls for receipt verification use existing `ProfileService` HTTP patterns.

**Tech Stack:** Flutter, `in_app_purchase: ^3.2.0`, Riverpod 2.4, existing `ProfileService` HTTP client pattern

**Backend spec:** `.agent/documentations/apple-iap-backend-spec.md`

---

## Task 1: Add Apple Sign In Entitlement

**Files:**
- Modify: `ios/Runner/Runner.entitlements`

**Step 1:** Add Sign In with Apple capability to the entitlements file.

Current content:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
</dict>
</plist>
```

Change to:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
	<key>com.apple.developer.in-app-payments</key>
	<array>
		<string>merchant.com.serragcvc.kolabing</string>
	</array>
</dict>
</plist>
```

**Step 2:** Verify file is valid XML: `plutil -lint ios/Runner/Runner.entitlements`

**Step 3:** Commit: `feat(ios): add Apple Sign In and IAP entitlements`

---

## Task 2: Add in_app_purchase Package

**Files:**
- Modify: `pubspec.yaml`

**Step 1:** Add the `in_app_purchase` dependency.

Find the dependencies section and add:
```yaml
  in_app_purchase: ^3.2.0
```

**Step 2:** Run: `flutter pub get`

**Step 3:** Verify: `dart analyze lib/` (should have no new errors)

**Step 4:** Commit: `feat: add in_app_purchase dependency`

---

## Task 3: Update Subscription Model with `source` Field

**Files:**
- Modify: `lib/features/business/models/subscription.dart`

**Step 1:** Add `source` field to the `Subscription` class. The backend will return `source: "stripe"` or `source: "apple_iap"`.

Add to constructor:
```dart
this.source = 'stripe',
```

Add to fromJson:
```dart
source: json['source'] as String? ?? 'stripe',
```

Add field declaration:
```dart
final String source;
```

Add to toJson:
```dart
'source': source,
```

Add to copyWith parameter and body.

Add helper getters:
```dart
bool get isAppleIAP => source == 'apple_iap';
bool get isStripe => source == 'stripe';
```

**Step 2:** Verify: `dart analyze lib/features/business/models/subscription.dart`

**Step 3:** Commit: `feat: add source field to Subscription model`

---

## Task 4: Add Apple Verify & Restore API Methods to ProfileService

**Files:**
- Modify: `lib/features/business/services/profile_service.dart`

**Step 1:** Add two new methods at the end of the subscription section (after `reactivateSubscription()`):

```dart
/// Verify Apple IAP transaction with backend
///
/// POST /api/v1/me/subscription/apple-verify
Future<Subscription> verifyApplePurchase({
  required String transactionId,
  required String originalTransactionId,
  required String productId,
}) async {
  final url = '$_baseUrl/me/subscription/apple-verify';
  debugPrint('Profile: POST $url');

  try {
    final response = await _httpClient.post(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode({
        'transaction_id': transactionId,
        'original_transaction_id': originalTransactionId,
        'product_id': productId,
      }),
    );

    debugPrint('Apple verify response status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 409) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return Subscription.fromJson(data);
    } else if (response.statusCode == 401) {
      throw const AuthException('Session expired. Please sign in again.');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        error: ApiError.fromJson(json, statusCode: response.statusCode),
      );
    }
  } on ApiException {
    rethrow;
  } on AuthException {
    rethrow;
  } catch (e) {
    debugPrint('Apple verify error: $e');
    throw NetworkException('Failed to verify Apple purchase: $e');
  }
}

/// Restore Apple purchases
///
/// POST /api/v1/me/subscription/apple-restore
Future<Subscription?> restoreApplePurchases({
  required List<Map<String, String>> transactions,
}) async {
  final url = '$_baseUrl/me/subscription/apple-restore';
  debugPrint('Profile: POST $url');

  try {
    final response = await _httpClient.post(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode({'transactions': transactions}),
    );

    debugPrint('Apple restore response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return Subscription.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else if (response.statusCode == 401) {
      throw const AuthException('Session expired. Please sign in again.');
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        error: ApiError.fromJson(json, statusCode: response.statusCode),
      );
    }
  } on ApiException {
    rethrow;
  } on AuthException {
    rethrow;
  } catch (e) {
    debugPrint('Apple restore error: $e');
    throw NetworkException('Failed to restore Apple purchases: $e');
  }
}
```

**Step 2:** Verify: `dart analyze lib/features/business/services/profile_service.dart`

**Step 3:** Commit: `feat: add Apple verify and restore API methods`

---

## Task 5: Create IAPService

**Files:**
- Create: `lib/features/subscription/services/iap_service.dart`

**Step 1:** Create the IAP service that wraps `in_app_purchase` for iOS.

```dart
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
    } catch (e) {
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
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        debugPrint('IAP: Purchase ${purchase.status.name} — verifying with backend');
        try {
          final subscription = await _verifyWithBackend(purchase);
          onPurchaseVerified(subscription);
        } catch (e) {
          debugPrint('IAP: Backend verification failed: $e');
          onError('Purchase completed but verification failed. Please try again or contact support.');
        }
        // Complete the transaction with Apple
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.error:
        debugPrint('IAP: Purchase error: ${purchase.error}');
        final errorMessage = purchase.error?.message ?? 'Purchase failed';
        if (!errorMessage.toLowerCase().contains('cancel')) {
          onError(errorMessage);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;

      case PurchaseStatus.canceled:
        debugPrint('IAP: Purchase canceled by user');
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
    }
  }

  /// Verify purchase with backend
  Future<Subscription> _verifyWithBackend(PurchaseDetails purchase) async {
    return await _profileService.verifyApplePurchase(
      transactionId: purchase.purchaseID ?? '',
      originalTransactionId: purchase.purchaseID ?? '',
      productId: purchase.productID,
    );
  }

  /// Dispose resources
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}

/// Provider for IAPService
final iapServiceProvider = Provider<IAPService>((ref) {
  final service = IAPService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

**Step 2:** Verify: `dart analyze lib/features/subscription/services/iap_service.dart`

**Step 3:** Commit: `feat: add IAPService for iOS In-App Purchases`

---

## Task 6: Create IAPProvider

**Files:**
- Create: `lib/features/subscription/providers/iap_provider.dart`

**Step 1:** Create the Riverpod state management for IAP.

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../business/models/subscription.dart';
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
        state = state.copyWith(isPurchasing: false, isRestoring: false, clearError: true);
        // Update profile provider with new subscription
        ref.read(profileProvider.notifier).refreshSubscription();
      },
      onError: (error) {
        state = state.copyWith(isPurchasing: false, isRestoring: false, error: error);
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
```

**Step 2:** Verify: `dart analyze lib/features/subscription/providers/iap_provider.dart`

**Step 3:** Commit: `feat: add IAPProvider for subscription state management`

---

## Task 7: Update SubscriptionPaywall — Platform-Aware

**Files:**
- Modify: `lib/features/subscription/widgets/subscription_paywall.dart`

**Step 1:** Update imports at top of file. Add:

```dart
import 'dart:io';
import '../providers/iap_provider.dart';
```

**Step 2:** Replace `_handleSubscribe` method with platform-aware version:

Replace:
```dart
Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);

    final url = await ref.read(profileProvider.notifier).getCheckoutUrl();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      // After returning from Stripe, refresh subscription and close
      if (mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await ref.read(profileProvider.notifier).refreshSubscription();
        final subscription = ref.read(profileProvider).subscription;
        if (mounted) {
          Navigator.of(context).pop(subscription?.isActive ?? false);
        }
      }
    }
  }
```

With:
```dart
Future<void> _handleSubscribe() async {
    if (Platform.isIOS) {
      await _handleAppleSubscribe();
    } else {
      await _handleStripeSubscribe();
    }
  }

  /// iOS: Use Apple IAP
  Future<void> _handleAppleSubscribe() async {
    final iapNotifier = ref.read(iapProvider.notifier);
    await iapNotifier.purchase();
    // Purchase result handled by listener in build method
  }

  /// Android/Other: Use Stripe (existing flow)
  Future<void> _handleStripeSubscribe() async {
    setState(() => _isLoading = true);

    final url = await ref.read(profileProvider.notifier).getCheckoutUrl();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await ref.read(profileProvider.notifier).refreshSubscription();
        final subscription = ref.read(profileProvider).subscription;
        if (mounted) {
          Navigator.of(context).pop(subscription?.isActive ?? false);
        }
      }
    }
  }
```

**Step 3:** Update the `build` method to listen for IAP state changes. Add this at the start of `build`, before the `return Container(...)`:

```dart
    // Listen for IAP purchase completion on iOS
    if (Platform.isIOS) {
      final iapState = ref.watch(iapProvider);

      // Listen for successful purchase
      ref.listen<IAPState>(iapProvider, (prev, next) {
        if (prev?.isPurchasing == true && !next.isPurchasing && next.error == null) {
          // Purchase succeeded — close paywall
          final subscription = ref.read(profileProvider).subscription;
          if (mounted) {
            Navigator.of(context).pop(subscription?.isActive ?? true);
          }
        }
      });

      // Use IAP loading state on iOS
      if (iapState.isPurchasing || iapState.isRestoring) {
        _isLoading = true;
      }
    }
```

**Step 4:** Update the price display to be platform-aware. Replace the price container:

Replace:
```dart
                    Text(
                      '29 EUR',
                      style: KolabingTextStyles.headlineLarge.copyWith(
                        color: KolabingColors.textPrimary,
                      ),
                    ),
```

With:
```dart
                    Text(
                      Platform.isIOS
                          ? ref.watch(iapProvider).priceString
                          : '29 EUR',
                      style: KolabingTextStyles.headlineLarge.copyWith(
                        color: KolabingColors.textPrimary,
                      ),
                    ),
```

**Step 5:** Add "Restore Purchases" button on iOS. After the "Not Now" TextButton, add:

```dart
              // Restore Purchases (iOS only — Apple requires this)
              if (Platform.isIOS) ...[
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => ref.read(iapProvider.notifier).restore(),
                  child: Text(
                    'Restore Purchases',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
```

**Step 6:** Add IAP error display. After the "Not Now" button block, add:

```dart
              // IAP error message
              if (Platform.isIOS) ...[
                Builder(builder: (context) {
                  final iapError = ref.watch(iapProvider).error;
                  if (iapError == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: KolabingSpacing.xs),
                    child: Text(
                      iapError,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: KolabingColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ],
```

**Step 7:** Verify: `dart analyze lib/features/subscription/widgets/subscription_paywall.dart`

**Step 8:** Commit: `feat: make SubscriptionPaywall platform-aware (iOS IAP / Android Stripe)`

---

## Task 8: Initialize IAP on App Start

**Files:**
- Modify: `lib/main.dart`

**Step 1:** The IAP provider auto-initializes in its `build()` method when first accessed. However, we should ensure it's accessed early so products are loaded by the time the paywall is shown.

Find the `main()` function or `MyApp` widget. After the `ProviderScope` is created and the app starts, add an eager initialization.

In the root widget's build or initState, add:
```dart
// Pre-initialize IAP on iOS
if (Platform.isIOS) {
  ref.read(iapProvider);
}
```

This triggers the IAPNotifier.build() → _initialize() → loads products from App Store.

**Step 2:** Add import: `import 'dart:io';` and `import 'features/subscription/providers/iap_provider.dart';`

**Step 3:** Verify: `dart analyze lib/main.dart`

**Step 4:** Commit: `feat: initialize IAP service on app start for iOS`

---

## Task 9: Full Analysis & Verification

**Step 1:** Run full analysis: `dart analyze lib/`

**Step 2:** Fix any issues found.

**Step 3:** Verify file structure:
```
lib/features/subscription/
├── services/
│   └── iap_service.dart          ← NEW
├── providers/
│   └── iap_provider.dart         ← NEW
└── widgets/
    └── subscription_paywall.dart  ← UPDATED
```

**Step 4:** Final commit: `feat: complete Apple IAP subscription integration`

---

## Summary

| Task | Files | Action |
|------|-------|--------|
| 1 | `ios/Runner/Runner.entitlements` | Add Apple Sign In + IAP entitlements |
| 2 | `pubspec.yaml` | Add `in_app_purchase: ^3.2.0` |
| 3 | `lib/features/business/models/subscription.dart` | Add `source` field |
| 4 | `lib/features/business/services/profile_service.dart` | Add `verifyApplePurchase()` + `restoreApplePurchases()` |
| 5 | `lib/features/subscription/services/iap_service.dart` | **NEW** — IAP service |
| 6 | `lib/features/subscription/providers/iap_provider.dart` | **NEW** — IAP state |
| 7 | `lib/features/subscription/widgets/subscription_paywall.dart` | Platform-aware paywall |
| 8 | `lib/main.dart` | Eager IAP initialization on iOS |
| 9 | — | Full analysis + verification |

**Total: 2 new files, 5 modified files, 9 tasks**
