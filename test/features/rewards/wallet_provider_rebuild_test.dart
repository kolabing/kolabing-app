import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';
import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';

void main() {
  // session_reset.dart invalidates these providers on auth changes. Riverpod
  // re-runs build() on the SAME Notifier instance, so build() must be
  // idempotent — a `late final` field assigned in build() throws
  // LateInitializationError on the second build, putting the provider in an
  // error state and breaking every widget that watches it.
  test('walletProvider survives invalidate + rebuild', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(walletProvider).wallet, isNull);
    container.invalidate(walletProvider);
    expect(() => container.read(walletProvider), returnsNormally);
  });

  test('galleryProvider survives invalidate + rebuild', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
      ..read(galleryProvider)
      ..invalidate(galleryProvider);
    expect(() => container.read(galleryProvider), returnsNormally);
  });
}
