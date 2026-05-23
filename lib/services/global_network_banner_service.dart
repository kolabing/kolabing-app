import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class GlobalNetworkBannerService {
  GlobalNetworkBannerService._();

  static final GlobalNetworkBannerService instance =
      GlobalNetworkBannerService._();

  bool _offlineBannerVisible = false;

  void showOfflineBanner() {
    if (_offlineBannerVisible) return;

    final messenger = globalScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    _offlineBannerVisible = true;
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFFFFF4D6),
          leading: const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFF8A5A00),
          ),
          content: const Text(
            'No internet connection. Turn off airplane mode or reconnect, then try again.',
          ),
          actions: [
            TextButton(
              onPressed: dismiss,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
  }

  void dismiss() {
    _offlineBannerVisible = false;
    globalScaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
  }
}
