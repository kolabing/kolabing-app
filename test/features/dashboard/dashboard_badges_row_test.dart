import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/dashboard/widgets/dashboard_badges_row.dart';
import 'package:kolabing_app/features/rewards/models/reward_badge.dart';
import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';

class _FakeWalletNotifier extends WalletNotifier {
  _FakeWalletNotifier(this._fakeState);

  final WalletState _fakeState;

  @override
  WalletState build() => _fakeState;
}

Widget _buildRow(List<RewardBadge> badges) => ProviderScope(
  overrides: [
    walletProvider.overrideWith(
      () => _FakeWalletNotifier(WalletState(badges: badges)),
    ),
  ],
  child: MaterialApp(
    theme: KolabingTheme.lightTheme,
    home: const Scaffold(body: DashboardBadgesRow()),
  ),
);

void main() {
  testWidgets('shows earned badges only — locked placeholders are hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildRow(const [
        RewardBadge(slug: RewardBadgeSlug.firstKolab, isUnlocked: true),
        RewardBadge(slug: RewardBadgeSlug.powerPartner, isUnlocked: false),
        RewardBadge(slug: RewardBadgeSlug.referralPioneer, isUnlocked: false),
      ]),
    );

    expect(find.text('BADGES'), findsOneWidget);
    expect(find.text('1 earned'), findsOneWidget);
    expect(find.text('First Kolab'), findsOneWidget);
    expect(find.text('Trusted Voice'), findsNothing);
    expect(find.text('Referral Pioneer'), findsNothing);
  });

  testWidgets('renders nothing when no badge is earned yet', (tester) async {
    await tester.pumpWidget(
      _buildRow(const [
        RewardBadge(slug: RewardBadgeSlug.firstKolab, isUnlocked: false),
        RewardBadge(slug: RewardBadgeSlug.powerPartner, isUnlocked: false),
      ]),
    );

    expect(find.text('BADGES'), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('renders nothing when the badge list is empty', (tester) async {
    await tester.pumpWidget(_buildRow(const []));

    expect(find.text('BADGES'), findsNothing);
  });
}
