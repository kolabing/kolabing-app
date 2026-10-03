import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/instagram/models/instagram_return_link.dart';

/// The Instagram return link arriving through Flutter's own deep linking
/// (`handlePushRoute`, what the engine calls for `kolabing://...`), against a
/// router wired like `kolabingRouter`: the top-level redirect hook plus an
/// error page for unknown routes.
void main() {
  late InstagramReturnBus bus;
  late List<InstagramReturnLink> received;
  late GoRouter router;

  setUp(() {
    bus = InstagramReturnBus();
    received = [];
    bus.stream.listen(received.add);
    router = GoRouter(
      initialLocation: '/home',
      redirect: (context, state) => instagramReturnRedirect(
        state.uri,
        currentLocation: () {
          final current = router.routerDelegate.currentConfiguration;
          return current.isEmpty ? null : current.uri.toString();
        },
        fallback: '/home',
        bus: bus,
      ),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('profile')),
                  ),
                ),
                child: const Text('open profile'),
              ),
            ),
          ),
        ),
      ],
      errorBuilder: (context, state) => const Text('page not found'),
    );
  });

  tearDown(() => router.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  for (final link in [
    'kolabing://instagram/connected?status=ok',
    '/instagram/connected?status=ok',
    '/connected?status=ok',
  ]) {
    testWidgets('$link: event published, the person stays where they are', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('open profile'));
      await tester.pumpAndSettle();
      expect(find.text('profile'), findsOneWidget);

      await tester.binding.handlePushRoute(link);
      await tester.pumpAndSettle();

      expect(find.text('page not found'), findsNothing);
      expect(find.text('profile'), findsOneWidget);
      expect(received.single.ok, isTrue);
    });
  }

  testWidgets('an error status is published as a failure', (tester) async {
    await pumpApp(tester);
    await tester.binding.handlePushRoute(
      'kolabing://instagram/connected?status=error&reason=not_professional',
    );
    await tester.pumpAndSettle();

    expect(received.single.ok, isFalse);
    expect(received.single.isPersonalAccountError, isTrue);
    expect(find.text('open profile'), findsOneWidget);
  });

  testWidgets('other links still route normally', (tester) async {
    await pumpApp(tester);
    await tester.binding.handlePushRoute('/nowhere');
    await tester.pumpAndSettle();

    expect(find.text('page not found'), findsOneWidget);
    expect(received, isEmpty);
  });

  test('cold start (no current location) falls back', () {
    final target = instagramReturnRedirect(
      Uri.parse('kolabing://instagram/connected?status=ok'),
      currentLocation: () => null,
      fallback: '/splash',
      bus: InstagramReturnBus(),
    );
    expect(target, '/splash');
    expect(
      instagramReturnRedirect(
        Uri.parse('/business'),
        currentLocation: () => '/x',
        fallback: '/splash',
      ),
      isNull,
    );
  });
}
