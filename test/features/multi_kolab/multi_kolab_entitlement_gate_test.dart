import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/constants/support.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/multi_kolab/models/event_creator_entitlement.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_providers.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_organizer_dashboard_screen.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_entitlement_gate.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Task 11 — "Request access" CTA on the Event Creator gate.
///
/// The CTA is a client-only contact mechanism: it opens the user's mail app
/// at the published Kolabing support address. Nothing here grants the
/// entitlement — that stays a maintainer-only backend action.
void main() {
  const businessUser = UserModel(
    id: 'profile-abc-123',
    email: 'owner@business.test',
    userType: UserType.business,
  );

  const communityUser = UserModel(
    id: 'profile-xyz-789',
    email: 'organizer@community.test',
    userType: UserType.community,
  );

  Widget host(
    Widget child, {
    UserModel? user,
    Future<bool> Function(Uri)? launcher,
    Locale locale = const Locale('en'),
    EventCreatorEntitlement? entitlement,
  }) => ProviderScope(
    overrides: [
      multiKolabRepositoryProvider.overrideWithValue(
        MockMultiKolabRepository(),
      ),
      if (entitlement != null)
        multiKolabEntitlementProvider.overrideWith((ref) async => entitlement),
      if (user != null) authProvider.overrideWith(() => _TestAuthNotifier(user)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('the gate shows the Request access CTA and supporting copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const MultiKolabEntitlementGate(), user: businessUser),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('multiKolabEntitlementGateCta')),
      findsOneWidget,
    );
    expect(find.text('Request access'), findsOneWidget);
    expect(
      find.text("We'll review your request and get back to you."),
      findsOneWidget,
    );
  });

  testWidgets('tapping the CTA launches an encoded mailto for a Business', (
    tester,
  ) async {
    Uri? launched;
    await tester.pumpWidget(
      host(
        MultiKolabEntitlementGate(
          launcher: (uri) async {
            launched = uri;
            return true;
          },
        ),
        user: businessUser,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('multiKolabEntitlementGateCta')));
    await tester.pumpAndSettle();

    expect(launched, isNotNull);
    expect(launched!.scheme, 'mailto');
    expect(launched!.path, KolabingSupport.email);
    expect(launched!.path, 'support@kolabing.com');

    final params = _decodeMailtoQuery(launched!);
    expect(params['subject'], 'Event Creator access request');
    expect(
      params['body'],
      'Hi Kolabing,\n'
      '\n'
      "I'd like to request Event Creator access for my account.\n"
      '\n'
      'Thanks!\n'
      '\n'
      'Account type: Business\n'
      'Profile ID: profile-abc-123',
    );
  });

  testWidgets('the mailto context reflects a Community profile', (
    tester,
  ) async {
    Uri? launched;
    await tester.pumpWidget(
      host(
        MultiKolabEntitlementGate(
          launcher: (uri) async {
            launched = uri;
            return true;
          },
        ),
        user: communityUser,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('multiKolabEntitlementGateCta')));
    await tester.pumpAndSettle();

    final body = _decodeMailtoQuery(launched!)['body']!;
    expect(body, contains('Account type: Community'));
    expect(body, contains('Profile ID: profile-xyz-789'));
  });

  testWidgets('no account context is appended when nobody is signed in', (
    tester,
  ) async {
    Uri? launched;
    await tester.pumpWidget(
      host(
        MultiKolabEntitlementGate(
          launcher: (uri) async {
            launched = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('multiKolabEntitlementGateCta')));
    await tester.pumpAndSettle();

    final body = _decodeMailtoQuery(launched!)['body']!;
    expect(body, isNot(contains('Account type')));
    expect(body, isNot(contains('Profile ID')));
    // Never leak anything else about the account.
    expect(body, isNot(contains('@')));
  });

  testWidgets('a failed launch surfaces the support address', (tester) async {
    await tester.pumpWidget(
      host(
        MultiKolabEntitlementGate(launcher: (uri) async => false),
        user: businessUser,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('multiKolabEntitlementGateCta')));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text(
        "Couldn't open your email app. Contact us at "
        '${KolabingSupport.email} instead.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a throwing launcher is reported, not swallowed', (tester) async {
    await tester.pumpWidget(
      host(
        MultiKolabEntitlementGate(
          launcher: (uri) async => throw Exception('no mail client'),
        ),
        user: businessUser,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('multiKolabEntitlementGateCta')));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('an entitled organizer never sees the gate or its CTA', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(
        const MultiKolabOrganizerDashboardScreen(),
        user: businessUser,
        entitlement: const EventCreatorEntitlement(
          hasEventCreatorEntitlement: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MultiKolabEntitlementGate), findsNothing);
    expect(find.byKey(const Key('multiKolabEntitlementGateCta')), findsNothing);
  });
}

/// Percent-decodes a `mailto:` query into its named parts. Built by hand
/// because `Uri.queryParameters` decodes `+` as a space, which would hide a
/// mis-encoded body.
Map<String, String> _decodeMailtoQuery(Uri uri) {
  final query = uri.query;
  expect(query, isNot(contains('+')), reason: 'body must be %-encoded');
  return <String, String>{
    for (final pair in query.split('&'))
      Uri.decodeComponent(pair.split('=').first): Uri.decodeComponent(
        pair.substring(pair.indexOf('=') + 1),
      ),
  };
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._user);

  final UserModel _user;

  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, user: _user, token: 'tok');
}
