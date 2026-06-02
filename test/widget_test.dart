// Smoke test: the app boots to the splash screen and then completes its
// startup navigation without throwing.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/providers/auth_state_provider.dart';
import 'package:kolabing_app/features/auth/screens/splash_screen.dart';
import 'package:kolabing_app/main.dart';

/// Routes the splash to a static screen so the boot test does not navigate into
/// a screen with an endless animation (e.g. the welcome hero), which would
/// leave a timer pending forever.
class _LoginRouteSplashStateNotifier extends SplashStateNotifier {
  @override
  Future<String> initialize() async => KolabingRoutes.login;
}

void main() {
  testWidgets('Kolabing app boots', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashStateProvider.overrideWith(_LoginRouteSplashStateNotifier.new),
        ],
        child: const KolabingApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Drive the splash sequence (entry → hold → exit) and let it navigate.
    // Over-pump each phase so the awaited hold/exit timers fire deterministically.
    await tester.pump(const Duration(milliseconds: 300)); // entry completes
    await tester.pump(const Duration(seconds: 3)); // hold timer (2s) fires
    await tester.pump(const Duration(seconds: 1)); // exit anim completes
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
