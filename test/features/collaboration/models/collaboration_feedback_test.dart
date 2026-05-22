import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/collaboration/models/collaboration_feedback.dart';

/// Locks the finish-feedback payload to the backend `FinishCollaborationRequest`
/// contract. A mismatch here (e.g. sending `star_rating` instead of `rating`,
/// or a string bucket instead of an int) makes POST /collaborations/{id}/finish
/// return 422 — which is exactly the "can't close the kolab" bug this fixes.
void main() {
  group('CollaborationFeedbackDraft.toPayload (backend contract)', () {
    test('community payload uses the exact backend keys', () {
      const draft = CollaborationFeedbackDraft(
        variant: FeedbackVariant.community,
        starRating: 4,
        postsReels: OutputBucket.sixToTen,
        metExpectationsRating: 5,
        wouldRecommend: true,
        benefits: {BenefitType.freeVenue, BenefitType.discount},
      );

      final payload = draft.toPayload();

      expect(payload['rating'], 4);
      expect(payload['posts_reels'], 6); // bucket lower bound, as an int
      expect(payload['expectation_match'], true);
      expect(payload['would_recommend'], true);
      expect(payload['benefits'], 'Discount, Free venue');
      // Community must NOT send business-only keys.
      expect(payload.containsKey('revenue'), isFalse);
      expect(payload.containsKey('stories_posted'), isFalse);
      // No legacy keys.
      expect(payload.containsKey('star_rating'), isFalse);
      expect(payload.containsKey('posts_reels_bucket'), isFalse);
    });

    test('business payload sends int stories_posted + numeric revenue', () {
      const draft = CollaborationFeedbackDraft(
        variant: FeedbackVariant.business,
        starRating: 5,
        postsReels: OutputBucket.oneToFive,
        storiesPosted: OutputBucket.elevenToFifteen,
        revenueAmountCents: 12300, // €123.00
        metExpectationsRating: 2,
        wouldRecommend: false,
      );

      final payload = draft.toPayload();

      expect(payload['rating'], 5);
      expect(payload['posts_reels'], 1);
      expect(payload['stories_posted'], 11);
      expect(payload['revenue'], 123.0); // cents / 100, EUR units
      expect(payload['expectation_match'], false); // rating < 3
      expect(payload['would_recommend'], false);
      expect(payload.containsKey('benefits'), isFalse);
    });

    test('required-but-skipped numeric fields default to 0', () {
      const draft = CollaborationFeedbackDraft(
        variant: FeedbackVariant.business,
        starRating: 3,
        wouldRecommend: true,
      );

      final payload = draft.toPayload();
      expect(payload['posts_reels'], 0);
      expect(payload['stories_posted'], 0);
      expect(payload['revenue'], 0);
      // No expectation rating answered -> defaults to "met".
      expect(payload['expectation_match'], true);
    });

    test('note is carried from the expectations comment and capped at 200', () {
      final draft = CollaborationFeedbackDraft(
        variant: FeedbackVariant.community,
        starRating: 4,
        wouldRecommend: true,
        benefits: const {BenefitType.freebies},
        metExpectationsComment: 'x' * 250,
      );
      final payload = draft.toPayload();
      expect((payload['note'] as String).length, 200);
    });
  });

  group('CollaborationFeedbackDraft gating', () {
    test('community cannot submit without at least one benefit', () {
      const base = CollaborationFeedbackDraft(
        variant: FeedbackVariant.community,
        starRating: 5,
        wouldRecommend: true,
      );
      expect(base.canSubmit, isFalse);
      expect(base.copyWith(benefits: {BenefitType.freebies}).canSubmit, isTrue);
    });

    test('"Other" benefit requires its text', () {
      const draft = CollaborationFeedbackDraft(
        variant: FeedbackVariant.community,
        starRating: 5,
        wouldRecommend: true,
        benefits: {BenefitType.other},
      );
      expect(draft.hasValidBenefits, isFalse);
      expect(
        draft.copyWith(benefitsOther: 'Free parking').hasValidBenefits,
        isTrue,
      );
      expect(
        draft.copyWith(benefitsOther: 'Free parking').benefitsAsText,
        'Other: Free parking',
      );
    });

    test('business can submit with only star + recommend', () {
      const draft = CollaborationFeedbackDraft(
        variant: FeedbackVariant.business,
        starRating: 4,
        wouldRecommend: true,
      );
      expect(draft.canSubmit, isTrue);
    });
  });
}
