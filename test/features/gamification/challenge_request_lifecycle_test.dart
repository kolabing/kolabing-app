import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/models/challenge_completion.dart';

/// How the app reads a request's state (#154).
///
/// The important one is the fallback. It used to be `pending`, which meant any
/// status a build did not recognise showed up on the poller as a live request
/// that could never be answered — a phantom the person could not clear. An
/// unknown state is one this build cannot act on, so the safe reading is a
/// terminal one.
void main() {
  group('status parsing', () {
    test('the four states it knows', () {
      expect(
        ChallengeCompletionStatus.fromString('pending'),
        ChallengeCompletionStatus.pending,
      );
      expect(
        ChallengeCompletionStatus.fromString('verified'),
        ChallengeCompletionStatus.verified,
      );
      expect(
        ChallengeCompletionStatus.fromString('rejected'),
        ChallengeCompletionStatus.rejected,
      );
      expect(
        ChallengeCompletionStatus.fromString('cancelled'),
        ChallengeCompletionStatus.cancelled,
      );
      expect(
        ChallengeCompletionStatus.fromString('expired'),
        ChallengeCompletionStatus.expired,
      );
    });

    test('an unknown status is terminal, not pending', () {
      final parsed = ChallengeCompletionStatus.fromString('something_new');

      expect(parsed, ChallengeCompletionStatus.expired);
      expect(parsed, isNot(ChallengeCompletionStatus.pending));
    });

    test('it is case-insensitive, as the old parser was', () {
      expect(
        ChallengeCompletionStatus.fromString('CANCELLED'),
        ChallengeCompletionStatus.cancelled,
      );
    });
  });

  group('a completion', () {
    ChallengeCompletion parse(String status) =>
        ChallengeCompletion.fromJson(<String, dynamic>{
          'id': 'cc-1',
          'event_id': 'e-1',
          'challenger_profile_id': 'a',
          'verifier_profile_id': 'b',
          'status': status,
          'points_earned': 0,
          'created_at': '2026-08-23T18:00:00Z',
        });

    /// A cancelled or expired request is not waiting for anyone, so nothing that
    /// looks for something to confirm should find it.
    test('cancelled and expired are not pending', () {
      expect(parse('cancelled').isPending, isFalse);
      expect(parse('expired').isPending, isFalse);
      expect(parse('pending').isPending, isTrue);
    });

    test('neither is a rejection', () {
      // "I changed my mind" and "we did not do that" are different facts, and
      // only the second says something about the pair.
      expect(parse('cancelled').isRejected, isFalse);
      expect(parse('expired').isRejected, isFalse);
      expect(parse('rejected').isRejected, isTrue);
    });

    test('neither earned anything', () {
      expect(parse('cancelled').isVerified, isFalse);
      expect(parse('expired').isVerified, isFalse);
    });
  });
}
