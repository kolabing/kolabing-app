// Regression guardrails for #163.
//
// All three onboarding city steps shipped the same layout: a Column of fixed
// children with one Expanded list, inside a Scaffold that resizes for the
// keyboard. On a 393x852 phone that left the list 27dp; on anything smaller the
// Column overflowed and the Continue button painted ON TOP of the search field,
// so the user could not see what they were typing.
//
// These tests drive the real sequence — field focused, then the keyboard's inset
// arriving — and hold the shell to the two things that fix it: the body never
// resizes, and the keyboard is reserved inside the flexible child so the results
// are the only thing that shrinks.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/onboarding/widgets/onboarding_search_step.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// The keyboard on an iPhone with the suggestion strip up.
const double _keyboardHeight = 336;

/// A deliberately cramped phone: the old layout went negative here first.
const Size _smallPhone = Size(375, 667);
const double _dpr = 3;

void _sizePhone(WidgetTester tester) {
  tester.view.physicalSize = _smallPhone * _dpr;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

/// Raise or drop the keyboard the way the platform does — through the view's
/// insets, which is what `MediaQuery.viewInsetsOf` ends up reading.
void _keyboard(WidgetTester tester, {required bool up}) {
  tester.view.viewInsets = FakeViewPadding(
    bottom: up ? _keyboardHeight * _dpr : 0,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  int rows = 30,
  bool withFooter = true,
}) async {
  _sizePhone(tester);

  await tester.pumpWidget(
    MaterialApp(
      theme: KolabingTheme.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingSearchStep(
        chrome: Container(
          height: 100,
          alignment: Alignment.center,
          child: const Text('Step 3 of 4'),
        ),
        headline: Container(
          height: 90,
          alignment: Alignment.center,
          child: const Text('Where are you located?'),
        ),
        searchHint: 'Search cities',
        onQueryChanged: (_) {},
        aboveResults: const Text('Popular cities'),
        results: ListView.builder(
          itemCount: rows,
          itemExtent: 56,
          itemBuilder: (_, i) => Text('City $i'),
        ),
        footer: withFooter
            ? Container(
                height: 100,
                alignment: Alignment.center,
                child: const Text('Continue'),
              )
            : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Focus the field and let the keyboard come up, as the platform would.
Future<void> _openKeyboard(WidgetTester tester) async {
  await tester.tap(find.byType(TextField));
  await tester.pump();
  _keyboard(tester, up: true);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with the keyboard up, nothing overflows and nothing overlaps '
      'the search field', (tester) async {
    await _pump(tester);
    await _openKeyboard(tester);

    // The overflow that produced the bug would surface here.
    expect(tester.takeException(), isNull);

    final field = tester.getRect(find.byType(TextField));
    expect(field.height, greaterThan(20));
    expect(field.top, greaterThanOrEqualTo(0));
    expect(field.bottom, lessThan(_smallPhone.height - _keyboardHeight));

    // Nothing is drawn across the field.
    for (final other in <Finder>[
      find.text('Popular cities'),
      find.text('City 0'),
    ]) {
      expect(
        tester.getRect(other).top,
        greaterThanOrEqualTo(field.bottom - 1),
        reason: '${other.description} must sit below the search field',
      );
    }
  });

  testWidgets('the chrome and the footer fold away while typing, and come '
      'back after', (tester) async {
    await _pump(tester);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Where are you located?'), findsOneWidget);
    expect(find.text('Step 3 of 4'), findsOneWidget);

    await _openKeyboard(tester);

    // Behind the keyboard the footer cannot be pressed anyway, and folding it
    // is what buys the results their last hundred pixels.
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Where are you located?'), findsNothing);
    expect(find.text('Step 3 of 4'), findsNothing);

    // Losing focus is what picking a city does; everything must return.
    FocusManager.instance.primaryFocus?.unfocus();
    _keyboard(tester, up: false);
    await tester.pumpAndSettle();
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Where are you located?'), findsOneWidget);
    expect(find.text('Step 3 of 4'), findsOneWidget);
  });

  testWidgets('the results keep room for several cities while typing', (
    tester,
  ) async {
    await _pump(tester);
    await _openKeyboard(tester);

    // The old layout had 27dp here on a bigger phone than this one, so even one
    // row was too many. Five 56dp rows is the floor.
    expect(find.textContaining(RegExp(r'^City \d+$')), findsAtLeast(5));
  });

  testWidgets('the keyboard area is reserved, so the list ends above it', (
    tester,
  ) async {
    await _pump(tester, rows: 100);
    await _openKeyboard(tester);

    final listRect = tester.getRect(find.byType(ListView));
    expect(
      listRect.bottom,
      lessThanOrEqualTo(_smallPhone.height - _keyboardHeight + 1),
      reason: 'the list must not run underneath the keyboard',
    );
    expect(listRect.height, greaterThan(0));
  });

  testWidgets('the keyboard arriving before the fold settles still cannot '
      'overflow', (tester) async {
    // The pathological frame: full inset while the chrome is still on screen.
    // A rigid keyboard spacer beside the Expanded overflowed here.
    await _pump(tester);
    _keyboard(tester, up: true);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a step with no footer still lays out', (tester) async {
    await _pump(tester, withFooter: false);
    await _openKeyboard(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('the clear button appears with text and empties the field', (
    tester,
  ) async {
    var lastQuery = 'unset';
    _sizePhone(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: KolabingTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingSearchStep(
          searchHint: 'Search cities',
          onQueryChanged: (v) => lastQuery = v,
          results: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
    await tester.enterText(find.byType(TextField), 'Barc');
    await tester.pumpAndSettle();
    expect(lastQuery, 'Barc');
    expect(find.byType(IconButton), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(lastQuery, '');
    expect(find.byType(IconButton), findsNothing);
  });
}
