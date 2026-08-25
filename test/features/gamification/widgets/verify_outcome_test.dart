import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/widgets/verify_completion_sheet.dart';

/// Regression lock for the verify sheet's result.
///
/// This started life as four booleans with
/// `isConfirmed => !rejected && !notForYou && !failed`, which made a *dismissal*
/// read as a successful confirmation: dragging the sheet down or pressing back
/// returned all-false and the scanner then showed "Confirmed, +0 XP" without any
/// verify call having been made. The enum makes each outcome its own case, and
/// these tests keep it that way.
void main() {
  test('a dismissal is not a confirmation', () {
    const outcome = VerifyOutcome(VerifyResult.dismissed);

    expect(outcome.result, VerifyResult.dismissed);
    expect(outcome.result == VerifyResult.confirmed, isFalse);
    expect(outcome.points, isNull);
    expect(outcome.challengerName, isNull);
  });

  test('only a confirmation carries the awarded points', () {
    const confirmed = VerifyOutcome(
      VerifyResult.confirmed,
      challengerName: 'Ana',
      points: 15,
    );

    expect(confirmed.result, VerifyResult.confirmed);
    expect(confirmed.points, 15);
    expect(confirmed.challengerName, 'Ana');
  });

  test('every non-confirmed outcome is distinguishable', () {
    const outcomes = [
      VerifyResult.rejected,
      VerifyResult.notForYou,
      VerifyResult.unreachable,
      VerifyResult.failed,
      VerifyResult.dismissed,
    ];

    for (final result in outcomes) {
      expect(
        VerifyOutcome(result).result == VerifyResult.confirmed,
        isFalse,
        reason: '$result must not read as confirmed',
      );
    }

    // A transport failure has to stay distinct from a foreign code: they need
    // different copy, and conflating them tells the user to give up when the
    // right move is to retry.
    expect(VerifyResult.unreachable == VerifyResult.notForYou, isFalse);
  });
}
