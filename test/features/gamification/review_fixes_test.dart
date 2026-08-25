import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/theme/category_style.dart';
import 'package:kolabing_app/features/gamification/models/challenge_completion.dart';
import 'package:kolabing_app/features/gamification/models/community_challenge.dart';

/// Regressions the code review found, pinned so they cannot come back.
void main() {
  group('the shared screen no longer strands the starter', () {
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

    /// The screen branched only on verified/rejected, so a request that ended
    /// without an answer fell through to "waiting for X" forever. These are the
    /// statuses that branch has to recognise as over.
    test('cancelled and expired are terminal, not still-waiting', () {
      for (final status in ['cancelled', 'expired']) {
        final completion = parse(status);
        expect(completion.isPending, isFalse, reason: status);
        expect(completion.isVerified, isFalse, reason: status);
        expect(completion.isRejected, isFalse, reason: status);
      }
    });
  });

  group('the curation banner reads the server, not the list length', () {
    test('curated is carried through even when the list is empty', () {
      final set = CommunityChallengeSet.fromJson({
        'curated': true,
        'challenges': <dynamic>[],
      });

      expect(set.curated, isTrue);
      expect(set.selections, isEmpty);
    });

    test('not curated stays not curated', () {
      final set = CommunityChallengeSet.fromJson({
        'curated': false,
        'challenges': <dynamic>[],
      });

      expect(set.curated, isFalse);
    });
  });

  group('compound category labels are coloured again', () {
    /// The `.contains(...)` matchers deleted from the card widgets coloured
    /// these; the exact-match resolver that replaced them sent every compound
    /// label to neutral grey.
    test('a qualifier before the head noun does not lose the colour', () {
      expect(
        CategoryStyleResolver.bucketFor('Sports Facility'),
        CategoryBucket.sports,
      );
      expect(
        CategoryStyleResolver.bucketFor('Fitness Community'),
        isNot(CategoryBucket.unknown),
      );
    });

    /// Word-level, not substring: "party" must not become art.
    test('a keyword buried inside another word still does not match', () {
      expect(CategoryStyleResolver.bucketFor('party'), CategoryBucket.unknown);
    });
  });
}
