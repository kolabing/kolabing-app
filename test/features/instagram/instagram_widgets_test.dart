import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/instagram/models/instagram_models.dart';
import 'package:kolabing_app/features/instagram/models/instagram_return_link.dart';
import 'package:kolabing_app/features/instagram/providers/instagram_providers.dart';
import 'package:kolabing_app/features/instagram/screens/instagram_import_screen.dart';
import 'package:kolabing_app/features/instagram/services/instagram_service.dart';
import 'package:kolabing_app/features/instagram/widgets/instagram_connect_card.dart';
import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'fake_instagram_service.dart';

const _notConnected = InstagramStatus(enabled: true, connected: false);
const _connected = InstagramStatus(
  enabled: true,
  connected: true,
  username: 'realrunclub',
  accountType: 'BUSINESS',
);

class _Harness {
  _Harness({InstagramStatus? status}) {
    service = FakeInstagramService(status: status);
    bus = InstagramReturnBus(clock: () => clock);
  }

  late final FakeInstagramService service;
  late final InstagramReturnBus bus;
  final CountingGalleryNotifier gallery = CountingGalleryNotifier();
  DateTime clock = DateTime.utc(2026, 9, 28, 12);
  final List<Uri> launched = [];
  bool launchResult = true;
  int importOpened = 0;

  List<dynamic> get overrides => [
    instagramServiceProvider.overrideWithValue(service),
    // Same shape as the real provider, minus the role gate (that needs a
    // signed-in AuthNotifier). Goes through the fake service so a 404 (null)
    // and refreshes are exercised.
    instagramStatusProvider.overrideWith(
      (ref) => ref.watch(instagramServiceProvider).getStatus(),
    ),
    instagramUrlLauncherProvider.overrideWithValue((url) async {
      launched.add(url);
      return launchResult;
    }),
    instagramReturnBusProvider.overrideWithValue(bus),
    galleryProvider.overrideWith(() => gallery),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  _Harness h, {
  required Widget child,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: h.overrides.cast(),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: KolabingTheme.lightTheme,
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Widget _cardHost(_Harness h) => Scaffold(
  body: ListView(
    children: [InstagramConnectCard(onOpenImport: () => h.importOpened++)],
  ),
);

// A zero-size hidden card in a ListView counts as offstage for finders, hence
// `skipOffstage: false` on the hidden-state checks.
void main() {
  group('InstagramConnectCard visibility', () {
    testWidgets('hidden when the endpoint is not deployed (404 -> null)', (
      tester,
    ) async {
      final h = _Harness();
      await _pump(tester, h, child: _cardHost(h));
      expect(
        find.byKey(const Key('instagram-card-hidden'), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byKey(const Key('instagram-card')), findsNothing);
    });

    testWidgets('hidden when the backend flag is off (enabled: false)', (
      tester,
    ) async {
      final h = _Harness(
        status: const InstagramStatus(enabled: false, connected: true),
      );
      await _pump(tester, h, child: _cardHost(h));
      expect(
        find.byKey(const Key('instagram-card-hidden'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('hidden when the status call fails', (tester) async {
      final h = _Harness(status: _notConnected);
      h.service.statusError = const InstagramException('boom');
      await _pump(tester, h, child: _cardHost(h));
      expect(
        find.byKey(const Key('instagram-card-hidden'), skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('InstagramConnectCard connect flow', () {
    testWidgets('Connect fetches the URL and opens it in the browser', (
      tester,
    ) async {
      final h = _Harness(status: _notConnected);
      await _pump(tester, h, child: _cardHost(h));

      expect(find.text('Connect Instagram'), findsOneWidget);
      await tester.tap(find.byKey(const Key('instagram-connect-button')));
      await tester.pump();
      await tester.pump();

      expect(h.service.connectUrlCalls, 1);
      expect(h.launched.single, h.service.connectUrl);
    });

    testWidgets('a browser that does not open shows an error', (tester) async {
      final h = _Harness(status: _notConnected)..launchResult = false;
      await _pump(tester, h, child: _cardHost(h));

      await tester.tap(find.byKey(const Key('instagram-connect-button')));
      await tester.pump();
      await tester.pump();

      expect(
        find.text("Couldn't open Instagram. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets('the return deep link refreshes the status in place', (
      tester,
    ) async {
      final h = _Harness(status: _notConnected);
      await _pump(tester, h, child: _cardHost(h));
      expect(h.service.statusCalls, 1);

      // The backend connected the account; the app is sent back.
      h.service.status = _connected;
      h.bus.add(
        InstagramReturnLink.tryParse(
          Uri.parse('kolabing://instagram/connected?status=ok'),
        )!,
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(h.service.statusCalls, 2);
      expect(find.text('Connected as @realrunclub'), findsOneWidget);
      expect(find.text('Instagram connected'), findsOneWidget); // snackbar
    });

    testWidgets('a personal-account failure opens the switch helper', (
      tester,
    ) async {
      final h = _Harness(status: _notConnected);
      await _pump(tester, h, child: _cardHost(h));

      h.bus.add(
        const InstagramReturnLink(ok: false, reason: 'not_professional'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("Instagram didn't connect. Please try again."),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('instagram-professional-helper')),
        findsOneWidget,
      );
      expect(find.text('Switch to a professional account'), findsOneWidget);
    });

    testWidgets('the personal-account link opens the helper', (tester) async {
      final h = _Harness(status: _notConnected);
      await _pump(tester, h, child: _cardHost(h));

      await tester.tap(find.byKey(const Key('instagram-personal-help')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('instagram-professional-helper')),
        findsOneWidget,
      );
    });

    testWidgets('app resume after a connect attempt re-reads the status', (
      tester,
    ) async {
      final h = _Harness(status: _notConnected);
      await _pump(tester, h, child: _cardHost(h));
      await tester.tap(find.byKey(const Key('instagram-connect-button')));
      await tester.pump();
      await tester.pump();
      final before = h.service.statusCalls;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();

      expect(h.service.statusCalls, before + 1);
    });
  });

  group('InstagramConnectCard connected', () {
    testWidgets('shows @username and opens the importer', (tester) async {
      final h = _Harness(status: _connected);
      await _pump(tester, h, child: _cardHost(h));

      expect(find.text('Connected as @realrunclub'), findsOneWidget);
      await tester.tap(find.byKey(const Key('instagram-import-button')));
      expect(h.importOpened, 1);
    });

    testWidgets('Disconnect asks first, then disconnects', (tester) async {
      final h = _Harness(status: _connected);
      await _pump(tester, h, child: _cardHost(h));

      await tester.tap(find.byKey(const Key('instagram-disconnect-button')));
      await tester.pumpAndSettle();
      expect(find.text('Disconnect Instagram?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(h.service.disconnectCalls, 0);

      await tester.tap(find.byKey(const Key('instagram-disconnect-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('instagram-disconnect-confirm')));
      await tester.pumpAndSettle();

      expect(h.service.disconnectCalls, 1);
      expect(find.text('Connect Instagram'), findsOneWidget);
      expect(find.text('Instagram disconnected'), findsOneWidget);
    });

    testWidgets('renders in Spanish and Catalan', (tester) async {
      final es = _Harness(status: _connected);
      await _pump(tester, es, child: _cardHost(es), locale: const Locale('es'));
      expect(find.text('Conectado como @realrunclub'), findsOneWidget);
      expect(find.text('Importar fotos y vídeos'), findsOneWidget);

      final ca = _Harness(status: _notConnected);
      await _pump(tester, ca, child: _cardHost(ca), locale: const Locale('ca'));
      expect(find.text('Connectar Instagram'), findsOneWidget);
    });
  });

  group('InstagramImportScreen', () {
    _Harness withMedia() {
      final h = _Harness(status: _connected);
      h.service.pages = {
        null: InstagramMediaPage(
          items: [
            media('1'),
            media('2', type: InstagramMediaType.video),
            media('3', type: InstagramMediaType.carouselAlbum),
            media('4', imported: true),
          ],
        ),
      };
      h.service.importResult = const InstagramImportResult(
        importedCount: 2,
        skipped: 1,
      );
      return h;
    }

    testWidgets('grid with video, carousel and imported badges', (
      tester,
    ) async {
      final h = withMedia();
      await _pump(tester, h, child: const InstagramImportScreen());

      expect(find.byType(InstagramMediaTile), findsNWidgets(4));
      expect(find.byKey(const Key('instagram-badge-video')), findsOneWidget);
      expect(find.byKey(const Key('instagram-badge-carousel')), findsOneWidget);
      expect(find.byKey(const Key('instagram-badge-imported')), findsOneWidget);
      expect(find.text('Select photos and videos'), findsOneWidget);
    });

    testWidgets('multi-select, import, then the result', (tester) async {
      final h = withMedia();
      await _pump(tester, h, child: const InstagramImportScreen());

      await tester.tap(find.byKey(const Key('instagram-media-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('instagram-media-2')));
      await tester.pump();
      // Already imported: tapping does nothing.
      await tester.tap(find.byKey(const Key('instagram-media-4')));
      await tester.pump();

      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byKey(const Key('instagram-import-submit')));
      await tester.pumpAndSettle();

      expect(h.service.importedIds.single, ['1', '2']);
      expect(h.gallery.loads, 1);
      expect(find.byKey(const Key('instagram-import-result')), findsOneWidget);
      expect(find.text('2 items were added to your gallery.'), findsOneWidget);
      expect(
        find.textContaining("1 item couldn't be imported"),
        findsOneWidget,
      );
    });

    testWidgets('empty account', (tester) async {
      final h = _Harness(status: _connected);
      await _pump(tester, h, child: const InstagramImportScreen());
      expect(find.byKey(const Key('instagram-import-empty')), findsOneWidget);
    });

    testWidgets('load error with Retry', (tester) async {
      final h = _Harness(status: _connected);
      h.service.mediaError = const InstagramException('down');
      await _pump(tester, h, child: const InstagramImportScreen());
      expect(find.byKey(const Key('instagram-import-error')), findsOneWidget);

      h.service.mediaError = null;
      h.service.pages = {
        null: InstagramMediaPage(items: [media('9')]),
      };
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(InstagramMediaTile), findsOneWidget);
    });

    testWidgets('a short first page pulls the next page by cursor', (
      tester,
    ) async {
      final h = _Harness(status: _connected);
      h.service.pages = {
        null: InstagramMediaPage(items: [media('1')], nextCursor: 'c2'),
        'c2': InstagramMediaPage(items: [media('2')]),
      };
      await _pump(tester, h, child: const InstagramImportScreen());
      await tester.pump();
      await tester.pump();

      expect(h.service.mediaCursors, [null, 'c2']);
      expect(find.byType(InstagramMediaTile), findsNWidgets(2));
    });
  });
}
