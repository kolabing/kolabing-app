import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';
import 'package:kolabing_app/features/rewards/widgets/referral_banner_card.dart';

void main() {
  testWidgets('banner opens referral code sheet from the CTA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [walletProvider.overrideWith(_FakeWalletNotifier.new)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ReferralBannerCard()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SHARE REFERRAL CODE'), findsOneWidget);

    await tester.tap(find.text('SHARE REFERRAL CODE'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR REFERRAL CODE'), findsOneWidget);
    expect(find.text('KOLAB-IRSC'), findsOneWidget);
    expect(find.text('COPY CODE'), findsOneWidget);
    expect(find.text('SHARE CODE'), findsOneWidget);
  });
}

class _FakeWalletNotifier extends WalletNotifier {
  @override
  WalletState build() => const WalletState(
    referralCode: 'KOLAB-IRSC',
    referralLink: 'https://kolabing.com/ref/KOLAB-IRSC',
  );
}
