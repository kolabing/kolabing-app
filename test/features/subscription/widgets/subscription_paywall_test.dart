import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/subscription/providers/iap_provider.dart';
import 'package:kolabing_app/features/subscription/widgets/subscription_paywall.dart';

void main() {
  testWidgets('subscription paywall shows referral code field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(_FakeProfileNotifier.new),
          iapProvider.overrideWith(_FakeIapNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SubscriptionPaywall()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Referral Code (optional)'), findsOneWidget);
    expect(find.text('Paste referral code'), findsOneWidget);
  });
}

class _FakeProfileNotifier extends ProfileNotifier {
  @override
  ProfileState build() => const ProfileState(
    profile: UserModel(
      id: 'business-1',
      email: 'business@example.com',
      userType: UserType.business,
      businessProfile: BusinessProfile(id: 'bp-1', name: 'Venue Works'),
    ),
    isLoading: false,
    isInitialized: true,
  );
}

class _FakeIapNotifier extends IAPNotifier {
  @override
  IAPState build() => const IAPState();
}
