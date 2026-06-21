import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/dashboard/widgets/community_xp_summary_card.dart';
import 'package:kolabing_app/features/rewards/models/wallet_model.dart';
import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';

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
}
