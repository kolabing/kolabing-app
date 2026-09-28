import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/dashboard/widgets/community_xp_summary_card.dart';
import 'package:kolabing_app/features/rewards/models/wallet_model.dart';
import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

void main() {
  for (final xp in <int>[-50, 0, 50, 99, 100, 250, 500, 999, 1000, 99999]) {
    for (final dark in <bool>[false, true]) {
      testWidgets('card builds: xp=$xp dark=$dark', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              walletSummaryProvider.overrideWithValue(XpModel(totalXp: xp)),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: dark ? KolabingTheme.darkTheme : KolabingTheme.lightTheme,
              home: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [CommunityXpSummaryCard()],
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('card is tappable only when onTap is given', (tester) async {
    var taps = 0;
    Future<void> pumpCard({VoidCallback? onTap}) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletSummaryProvider.overrideWithValue(const XpModel(totalXp: 181)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(children: [CommunityXpSummaryCard(onTap: onTap)]),
          ),
        ),
      ),
    );

    await pumpCard();
    expect(find.byKey(const Key('xp-summary-card-tap')), findsNothing);

    await pumpCard(onTap: () => taps++);
    await tester.tap(find.byKey(const Key('xp-summary-card-tap')));
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 800));
  });
}
