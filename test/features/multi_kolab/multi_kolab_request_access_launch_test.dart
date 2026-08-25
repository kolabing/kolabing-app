import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_entitlement_gate.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Exercises the **production** launch path of the Request access CTA — the
/// widget's default `launchUrl`, with no injected test seam — by stubbing the
/// `url_launcher` platform channel the way a real device would answer it.
///
/// This is the harness answer to "does tapping open a mail composer?": a
/// device with a mail handler answers `canLaunch` true and receives the
/// `mailto:`; a device without one answers false, and the user must see the
/// public address instead of a dead button.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/url_launcher');

  const businessUser = UserModel(
    id: 'profile-abc-123',
    email: 'owner@business.test',
    userType: UserType.business,
  );

  final calls = <MethodCall>[];

  void stubPlatform({required bool hasMailHandler}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'canLaunch':
              return hasMailHandler;
            case 'launch':
              return hasMailHandler;
            default:
              return null;
          }
        });
  }

  tearDown(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [
      multiKolabRepositoryProvider.overrideWithValue(
        MockMultiKolabRepository(),
      ),
      authProvider.overrideWith(() => _TestAuthNotifier(businessUser)),
    ],
    child: MaterialApp(
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

  testWidgets('a device with a mail handler receives the info@ mailto', (
    tester,
  ) async {
    stubPlatform(hasMailHandler: true);

    await tester.pumpWidget(host(const MultiKolabEntitlementGate()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('multiKolabEntitlementGateCta')));
    await tester.pumpAndSettle();

    final launch = calls.firstWhere((c) => c.method == 'launch');
    final url = (launch.arguments as Map)['url'] as String;
    expect(url, startsWith('mailto:info@kolabing.com?'));
    expect(url, contains('subject=Event%20Creator%20access%20request'));

    // The mail app opened, so no fallback is shown.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a device with no mail client sees the info@ fallback', (
    tester,
  ) async {
    stubPlatform(hasMailHandler: false);

    await tester.pumpWidget(host(const MultiKolabEntitlementGate()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('multiKolabEntitlementGateCta')));
    await tester.pump();

    expect(
      find.text(
        "Couldn't open your email app. Contact us at "
        'info@kolabing.com instead.',
      ),
      findsOneWidget,
    );
  });
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._user);

  final UserModel _user;

  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, user: _user, token: 'tok');
}
