import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/auth/screens/forgot_password_screen.dart';
import 'package:kolabing_app/features/auth/screens/login_screen.dart';
import 'package:kolabing_app/features/auth/widgets/auth_page.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Visual-QA capture for the sign-in screen (#193).
///
/// The screen is a port of `Mobile Login v2.dc.html`, variant 1a, from the
/// Claude Design project *Kolabing web platform tasarımı*. These renders are
/// what a reviewer diffs against that source.
///
/// Deliberately `..._capture.dart`, so `flutter test` never collects it:
/// ```
/// flutter test test/features/auth/screens/login_capture.dart --update-goldens
/// ```
///
/// The script exits non-zero — google_fonts throws asynchronously when it
/// cannot fetch, after each test body has finished, so the reporter marks every
/// case `[E]`. The PNGs are still written and correct.
Future<void> _loadCaptureFonts() async {
  const regular = '/System/Library/Fonts/Supplemental/Arial.ttf';
  const bold = '/System/Library/Fonts/Supplemental/Arial Bold.ttf';
  if (!File(regular).existsSync()) return;

  final regularBytes = await File(regular).readAsBytes();
  final boldBytes = File(bold).existsSync()
      ? await File(bold).readAsBytes()
      : regularBytes;

  final lucide = _findPackageFont('lucide_icons', 'lucide.ttf');
  if (lucide != null) {
    await (FontLoader('packages/lucide_icons/Lucide')..addFont(
          Future.value((await lucide.readAsBytes()).buffer.asByteData()),
        ))
        .load();
  }

  const light = ['regular', '100', '200', '300', '400', '500'];
  const heavy = ['600', '700', '800', '900'];
  // Caveat joins Anton and Inter on this screen — the handwritten subtitle.
  for (final family in ['Inter', 'Anton', 'Caveat']) {
    for (final v in light) {
      await (FontLoader(
        '${family}_$v',
      )..addFont(Future.value(regularBytes.buffer.asByteData()))).load();
    }
    for (final v in heavy) {
      await (FontLoader(
        '${family}_$v',
      )..addFont(Future.value(boldBytes.buffer.asByteData()))).load();
    }
  }
}

File? _findPackageFont(String package, String file) {
  final home = Platform.environment['HOME'];
  if (home == null) return null;
  final dir = Directory('$home/.pub-cache/hosted/pub.dev');
  if (!dir.existsSync()) return null;
  for (final entry in dir.listSync().whereType<Directory>()) {
    if (!entry.path.split('/').last.startsWith('$package-')) continue;
    final font = File('${entry.path}/assets/$file');
    if (font.existsSync()) return font;
  }
  return null;
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadCaptureFonts();
  });

  const size = Size(430, 932);

  /// The keyboard height iOS reports on this device. `resizeToAvoidBottomInset`
  /// reads `viewInsets`, so this is what the screen sees on a field tap — and
  /// it is the state the old layout could not survive.
  const keyboardInset = 336.0;

  Future<void> pump(
    WidgetTester tester, {
    double bottomInset = 0,
    Locale locale = const Locale('en'),
    Widget screen = const LoginScreen(),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
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
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: size,
                viewInsets: EdgeInsets.only(bottom: bottomInset),
                padding: const EdgeInsets.only(top: 59, bottom: 34),
              ),
              child: screen,
            ),
          ),
        ),
      ),
    );
    // Let the K mark's waterline fill and the fade-in finish.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // The mark is an Image.asset, and image decoding is a real async job the
    // test binding fakes away — without this the golden shows an empty slot
    // where the K should be, which would make the capture a lie.
    await tester.runAsync(() async {
      final element = tester.element(find.byType(AuthPageScaffold));
      await precacheImage(
        const AssetImage('assets/brand/kolabing-k-mark.png'),
        element,
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle(const Duration(seconds: 3));

    while (tester.takeException() != null) {}
  }

  testWidgets('sign-in — idle', (tester) async {
    await pump(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_v2_idle.png'),
    );
  });

  testWidgets('sign-in — keyboard up', (tester) async {
    await pump(tester, bottomInset: keyboardInset);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_v2_keyboard.png'),
    );
  });

  testWidgets('forgot password — the same page furniture', (tester) async {
    await pump(tester, screen: const ForgotPasswordScreen());
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/forgot_password_v2.png'),
    );
  });

  testWidgets('sign-in — Spanish', (tester) async {
    await pump(tester, locale: const Locale('es'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_v2_es.png'),
    );
  });

  testWidgets('sign-in — Catalan', (tester) async {
    await pump(tester, locale: const Locale('ca'));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/login_v2_ca.png'),
    );
  });
}
