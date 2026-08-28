import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/business/models/notification_preferences.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/business/services/profile_service.dart';
import 'package:kolabing_app/features/notification/models/app_notification.dart';
import 'package:kolabing_app/features/notification/providers/notification_provider.dart';
import 'package:kolabing_app/features/notification/screens/notifications_screen.dart';
import 'package:kolabing_app/features/settings/screens/notification_settings_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Visual-QA capture script for Settings ▸ Notifications (#191).
///
/// Deliberately named `..._capture.dart`, not `..._test.dart`, so `flutter
/// test` never collects it — matching
/// `test/features/discovery/screens/explore_mixed_feed_capture.dart` and
/// `test/features/multi_kolab/multi_kolab_organizer_capture.dart`. Run it
/// explicitly to refresh the PNGs under `goldens/`:
///
/// ```
/// flutter test test/features/settings/screens/notification_settings_capture.dart \
///   --update-goldens
/// ```
///
/// Real renders produced by the test binding — no simulator automation.
/// Behaviour is covered by `notification_settings_screen_test.dart`.
///
/// Unlike the repo's older capture scripts, these PNGs are *readable*: see
/// [_loadCaptureFonts]. The `_before` PNG is produced by checking out the
/// pre-toggle version of `notification_settings_screen.dart` (commit `bcbaa0e`),
/// running this script, then restoring — a genuine render of the old code, not
/// a mock-up.
///
/// ⚠️ The script exits non-zero. `google_fonts` throws asynchronously, after
/// each test body has finished, so the exception cannot be drained from inside
/// the test and the reporter marks every case `[E]`. The PNGs are still written
/// and correct — the exit status says nothing about them. Same behaviour as
/// `explore_mixed_feed_capture.dart`.

/// Registers a real local typeface under the family names `google_fonts` leaves
/// unresolved.
///
/// Without this the PNGs are unusable. `google_fonts` cannot reach the network
/// from the test binding, so every `GoogleFonts.inter(...)` style keeps its
/// unresolved family (`Inter_regular`, `Inter_600`, …) and Flutter draws the
/// test-binding fallback — one filled box per glyph. That is what the older
/// capture scripts mean by "the fallback typeface", and it documents layout but
/// not a single word of copy.
///
/// Local-only by design (macOS system fonts + the pub cache); this script is
/// never collected by `flutter test`. If the fonts are missing it warns and
/// carries on — you just get the boxes back.
Future<void> _loadCaptureFonts() async {
  const regular = '/System/Library/Fonts/Supplemental/Arial.ttf';
  const bold = '/System/Library/Fonts/Supplemental/Arial Bold.ttf';

  if (!File(regular).existsSync()) {
    // ignore: avoid_print
    print('WARNING: $regular not found — captures will render tofu boxes.');
    return;
  }
  final regularBytes = await File(regular).readAsBytes();
  final boldBytes = File(bold).existsSync()
      ? await File(bold).readAsBytes()
      : regularBytes;

  // `GoogleFontsFamilyWithVariant.toString()` is `'${family}_$variant'`, where
  // w400 stringifies to 'regular' and every other weight to its numeric value.
  const lightVariants = ['regular', '100', '200', '300', '400', '500'];
  const boldVariants = ['600', '700', '800', '900'];

  // Lucide ships its typeface as a package asset, which the test binding does
  // not resolve either — without this the icons (including the new
  // calendarClock mark this capture exists to show) draw as empty squares.
  final lucide = _findLucideFont();
  if (lucide != null) {
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
          Future.value((await lucide.readAsBytes()).buffer.asByteData()),
        ))
        .load();
  } else {
    // ignore: avoid_print
    print(
      'WARNING: lucide.ttf not found in the pub cache — icons will be boxes.',
    );
  }

  for (final family in ['Inter', 'Anton']) {
    for (final variant in lightVariants) {
      await (FontLoader(
        '${family}_$variant',
      )..addFont(Future.value(regularBytes.buffer.asByteData()))).load();
    }
    for (final variant in boldVariants) {
      await (FontLoader(
        '${family}_$variant',
      )..addFont(Future.value(boldBytes.buffer.asByteData()))).load();
    }
  }
}

/// Drains whatever `google_fonts` throws synchronously. Best-effort only — most
/// of its failures surface after the test body completes, which is why the
/// script still exits non-zero (see the note on the library docstring).
void _drainFontExceptions(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

/// Resolves `lucide.ttf` out of the pub cache without pinning the version.
File? _findLucideFont() {
  final home = Platform.environment['HOME'];
  if (home == null) return null;
  final dir = Directory('$home/.pub-cache/hosted/pub.dev');
  if (!dir.existsSync()) return null;
  for (final entry in dir.listSync().whereType<Directory>()) {
    if (!entry.path.split('/').last.startsWith('lucide_icons-')) continue;
    final font = File('${entry.path}/assets/lucide.ttf');
    if (font.existsSync()) return font;
  }
  return null;
}

void main() {
  setUpAll(() async {
    // Disabled so google_fonts fails fast against assets instead of timing out
    // against the network. It still throws ("not found in the application
    // assets") — drained by `_drainFontExceptions` below — but the families
    // registered here are what actually get used for the render.
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadCaptureFonts();
  });

  Future<void> capture(
    WidgetTester tester,
    String name, {
    required Locale locale,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileServiceProvider.overrideWithValue(_StubProfileService()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: KolabingTheme.lightTheme,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _drainFontExceptions(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('notification settings — English', (tester) async {
    await capture(tester, 'notif_settings_en', locale: const Locale('en'));
  });

  testWidgets('notification settings — Spanish (Castilian)', (tester) async {
    await capture(tester, 'notif_settings_es', locale: const Locale('es'));
  });

  testWidgets('notification settings — Catalan', (tester) async {
    await capture(tester, 'notif_settings_ca', locale: const Locale('ca'));
  });

  // The other UI change in #191: event reminders get their own calendarClock
  // mark on the notifications list, next to a Kolab notification for contrast.
  testWidgets('notifications list — the event reminder mark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AppNotification notif({
      required String id,
      required String rawType,
      required String title,
      required String body,
      bool isRead = false,
    }) => AppNotification(
      id: id,
      notificationId: id,
      type: NotificationType.fromString(rawType),
      rawType: rawType,
      title: title,
      body: body,
      createdAt: DateTime.utc(2026, 8, 28, 9),
      isRead: isRead,
      targetId: 'event-1',
      targetType: 'event',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationProvider.overrideWith(
            () => _FakeNotificationNotifier(
              NotificationState(
                notifications: [
                  notif(
                    id: 'n1',
                    rawType: 'event_reminder_1h',
                    title: 'Starting in 45 minutes',
                    body: 'Sunset Run — Barceloneta Beach',
                  ),
                  notif(
                    id: 'n2',
                    rawType: 'event_reminder_24h',
                    title: 'Tomorrow at 19:00',
                    body: 'Real Run Club · Weekly 10K',
                  ),
                  notif(
                    id: 'n3',
                    rawType: 'collaboration_activated',
                    title: 'Your Kolab is active',
                    body: 'Sunset rooftop collab with Bar Nou',
                    isRead: true,
                  ),
                ],
                unreadCount: 2,
                total: 3,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: KolabingTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _drainFontExceptions(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/notif_list_event_reminders.png'),
    );
  });
}

class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier(this._state);

  final NotificationState _state;

  @override
  NotificationState build() => _state;

  // `NotificationsScreen.initState` fires `loadNotifications()`, which would
  // otherwise hit the real service and wipe the fixture back to the empty state.
  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> loadUnreadCount() async {}

  @override
  Future<void> refresh() async {}
}

class _StubProfileService extends ProfileService {
  @override
  Future<NotificationPreferences> getNotificationPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async => const NotificationPreferences();
}
