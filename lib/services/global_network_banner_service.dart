import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(messenger.context);

    _offlineBannerVisible = true;
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: const Color(0xFFFFF4D6),
          leading: const Icon(Icons.wifi_off_rounded, color: Color(0xFF8A5A00)),
          content: Text(l10n.networkOfflineBannerMessage),
          actions: [
            TextButton(onPressed: dismiss, child: Text(l10n.commonDismiss)),
          ],
        ),
      );
  }

  void dismiss() {
    _offlineBannerVisible = false;
    globalScaffoldMessengerKey.currentState?.hideCurrentMaterialBanner();
  }
}
