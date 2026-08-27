// Authoring the camera setting from the app (#188).
//
// `proof_type` decided whether the camera opens (kolabing-v2#216) and nothing in
// either client could set it: the admin panel had no field (kolabing-v2#248) and
// the app's challenge form had no control. These tests cover the app half — the
// control exists, it defaults to no camera, and editing an existing challenge
// arrives pre-set to whatever that challenge already says.
//
// Also here: the screen doubles as the editor. `EventChallengesScreen` has
// pushed `/challenges/{id}/edit` since it shipped, and that route was never
// registered, so an organizer tapping their own custom challenge landed on the
// not-found page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/theme.dart';
import 'package:kolabing_app/features/gamification/models/challenge.dart';
import 'package:kolabing_app/features/gamification/screens/create_challenge_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

Challenge _challenge({
  ChallengeProofType proofType = ChallengeProofType.text,
  String name = 'Take a selfie together',
}) => Challenge(
  id: 'c-1',
  name: name,
  description: 'Both of you in one frame',
  difficulty: ChallengeDifficulty.easy,
  points: 15,
  // Custom is the inverse of system, and only a custom challenge is editable.
  isSystem: false,
  createdAt: DateTime(2026, 8, 27),
  updatedAt: DateTime(2026, 8, 27),
  proofType: proofType,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1179, 2556); // iPhone @3x
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: KolabingTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The option's border is 2px wide and primary-coloured when it is the choice.
bool _isSelected(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  final decoration = container.decoration! as BoxDecoration;
  return decoration.border!.top.width > 1.5;
}

void main() {
  testWidgets('creating a challenge offers the camera choice, defaulting off', (
    tester,
  ) async {
    await _pump(tester, const CreateChallengeScreen(eventId: 'e-1'));

    expect(tester.takeException(), isNull);
    expect(find.text('When the pair agrees'), findsOneWidget);
    expect(find.text('No camera'), findsOneWidget);
    expect(find.text('Open the camera'), findsOneWidget);

    // Off by default: a challenge nobody thought about must not open a camera.
    expect(_isSelected(tester, 'No camera'), isTrue);
    expect(_isSelected(tester, 'Open the camera'), isFalse);
  });

  testWidgets('tapping the camera option selects it', (tester) async {
    await _pump(tester, const CreateChallengeScreen(eventId: 'e-1'));

    await tester.tap(find.text('Open the camera'));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'Open the camera'), isTrue);
    expect(_isSelected(tester, 'No camera'), isFalse);
  });

  testWidgets('editing a camera challenge arrives with the camera on', (
    tester,
  ) async {
    await _pump(
      tester,
      CreateChallengeScreen(
        eventId: 'e-1',
        challenge: _challenge(proofType: ChallengeProofType.photo),
      ),
    );

    expect(tester.takeException(), isNull);
    // Edit mode announces itself, rather than looking like a fresh form that
    // would create a second challenge.
    expect(find.text('Edit challenge'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(_isSelected(tester, 'Open the camera'), isTrue);
  });

  testWidgets('editing prefills what the challenge already says', (
    tester,
  ) async {
    await _pump(
      tester,
      CreateChallengeScreen(eventId: 'e-1', challenge: _challenge()),
    );

    expect(find.text('Take a selfie together'), findsOneWidget);
    expect(find.text('Both of you in one frame'), findsOneWidget);
    // Its own points, not the difficulty's default.
    expect(find.text('15'), findsOneWidget);
    expect(_isSelected(tester, 'No camera'), isTrue);
  });

  testWidgets('creating still says create', (tester) async {
    await _pump(tester, const CreateChallengeScreen(eventId: 'e-1'));

    expect(find.text('Edit challenge'), findsNothing);
    expect(find.text('Save changes'), findsNothing);
  });
}
