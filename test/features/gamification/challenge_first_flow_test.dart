import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/routes/routes.dart';

/// Choose the challenge, then scan the person (#152).
///
/// The reversal is mostly navigation, so what a test can hold still is that the
/// challenge list is reachable and the screen it replaced is really gone.
void main() {
  test('the event challenge list is reachable by path', () {
    expect(
      KolabingRoutes.buildEventChallengesPath('e-1'),
      '/attendee/events/e-1/challenges',
    );
  });

  /// The typed-UUID initiate screen is retired. It asked someone standing in a
  /// room to type another attendee's profile id into a text field — which is
  /// why the flow it belonged to could not be completed by anyone, and why
  /// leaving it reachable would be leaving a dead end in the app.
  test('nothing in lib still routes to the typed-id initiate screen', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) {
          final source = f.readAsStringSync();
          return source.contains('InitiateChallengeScreen') ||
              source.contains('challenges/:challengeId/initiate');
        })
        .map((f) => f.path)
        .toList();

    expect(offenders, isEmpty, reason: 'retired in #152');
  });

  test('the screen file itself is gone', () {
    expect(
      File(
        'lib/features/gamification/screens/initiate_challenge_screen.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
