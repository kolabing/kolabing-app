import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/subscription/providers/iap_provider.dart';
import 'package:kolabing_app/features/subscription/widgets/subscription_paywall.dart';

void main() {
  testWidgets('subscription paywall has no referral code field (Apple 3.1.1)', (
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

    // The referral-code input must not appear next to the IAP purchase
    // options — Apple rejected the build for exactly this (Guideline
    // 3.1.1). It stays only on the register/signup screen.
    expect(find.text('Referral Code (optional)'), findsNothing);
    expect(find.text('Paste referral code'), findsNothing);

    // Guideline 3.1.2: the paywall must expose the EULA + Privacy links.
    expect(find.text('Terms of Use (EULA)'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
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
