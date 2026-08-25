import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/gamification/models/community_challenge.dart';
import 'package:kolabing_app/features/gamification/services/challenge_service.dart';

/// A community's challenge choice, as the app reads it (#150).
///
/// The distinction worth a test: an empty list with `curated == false` means the
/// community's events play the WHOLE library, which is the opposite of "no
/// challenges". If the app ever infers that from the list length instead of the
/// flag, a leader's screen will tell them their events are empty when they are
/// not.
void main() {
  group('the set', () {
    test('not curated is not the same as curated to nothing', () {
      final none = CommunityChallengeSet.fromJson({
        'curated': false,
        'challenges': <dynamic>[],
      });

      expect(none.curated, isFalse);
      expect(none.selections, isEmpty);
    });

    test('reads the options off each choice', () {
      final set = CommunityChallengeSet.fromJson({
        'curated': true,
        'challenges': [
          {
            'challenge_id': 'ch-1',
            'allow_repeat_with_same_person': true,
            'requires_new_person': false,
            'challenge': {
              'id': 'ch-1',
              'name': 'Take a selfie together',
              'difficulty': 'easy',
              'points': 5,
              'is_system': true,
              'created_at': '2026-08-23T10:00:00Z',
              'updated_at': '2026-08-23T10:00:00Z',
            },
          },
        ],
      });

      expect(set.curated, isTrue);
      expect(set.selections.single.allowRepeatWithSamePerson, isTrue);
      expect(set.selections.single.requiresNewPerson, isFalse);
      expect(set.selections.single.challenge?.name, 'Take a selfie together');
    });

    test('missing options default to the strict side', () {
      final selection = CommunityChallengeSelection.fromJson({
        'challenge_id': 'ch-1',
      });

      // Both off is the old hard rule: no repeats, no new-person requirement.
      expect(selection.allowRepeatWithSamePerson, isFalse);
      expect(selection.requiresNewPerson, isFalse);
    });

    test('a selection serializes to what the sync endpoint expects', () {
      const selection = CommunityChallengeSelection(
        challengeId: 'ch-1',
        requiresNewPerson: true,
      );

      expect(selection.toJson(), {
        'challenge_id': 'ch-1',
        'allow_repeat_with_same_person': false,
        'requires_new_person': true,
      });
    });
  });

  group('refusal reasons', () {
    /// Each of the three 409s wants different words on screen, so each has to
    /// arrive as a distinct kind rather than one generic conflict.
    test('the backend reasons map to distinct kinds', () {
      const cases = {
        'already_pending': ChallengeFailure.alreadyPending,
        'already_completed': ChallengeFailure.alreadyCompleted,
        'needs_new_person': ChallengeFailure.needsNewPerson,
        'event_limit_reached': ChallengeFailure.eventLimitReached,
      };

      for (final entry in cases.entries) {
        expect(
          challengeFailureForReason(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    /// An older backend sends no reason, and must still behave — it just cannot
    /// be specific.
    test('an absent or unknown reason falls back to the generic conflict', () {
      expect(challengeFailureForReason(null), ChallengeFailure.conflict);
      expect(
        challengeFailureForReason('something_new'),
        ChallengeFailure.conflict,
      );
    });
  });
}
