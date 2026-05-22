/// Output volume buckets the business chooses from when reporting how much
/// content the community produced. Wire values match the backend enum exactly.
enum OutputBucket {
  zero('0', 'None'),
  oneToFive('1-5', '1–5'),
  sixToTen('6-10', '6–10'),
  elevenToFifteen('11-15', '11–15'),
  sixteenToThirty('16-30', '16–30'),
  thirtyOneToFifty('31-50', '31–50'),
  fiftyPlus('50+', '50+');

  const OutputBucket(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// In-memory draft of the feedback as the business steps through the sheet.
class CollaborationFeedbackDraft {
  const CollaborationFeedbackDraft({
    this.starRating,
    this.storiesPosted,
    this.postsReels,
    this.revenueAmountCents,
    this.revenueSkipped = false,
    this.metExpectationsRating,
    this.metExpectationsComment,
    this.wouldRecommend,
  });

  /// 1–5; null until the user picks.
  final int? starRating;

  final OutputBucket? storiesPosted;
  final OutputBucket? postsReels;

  /// EUR cents. Null when not provided (skipped or never typed).
  final int? revenueAmountCents;

  /// Explicit "I'd rather not say" — distinct from "haven't answered yet".
  final bool revenueSkipped;

  final int? metExpectationsRating;
  final String? metExpectationsComment;

  final bool? wouldRecommend;

  bool get canSubmit => starRating != null && wouldRecommend != null;

  CollaborationFeedbackDraft copyWith({
    int? starRating,
    OutputBucket? storiesPosted,
    OutputBucket? postsReels,
    int? revenueAmountCents,
    bool? revenueSkipped,
    int? metExpectationsRating,
    String? metExpectationsComment,
    bool? wouldRecommend,
    bool clearStoriesPosted = false,
    bool clearPostsReels = false,
    bool clearRevenueAmount = false,
    bool clearMetExpectationsRating = false,
    bool clearMetExpectationsComment = false,
  }) => CollaborationFeedbackDraft(
    starRating: starRating ?? this.starRating,
    storiesPosted: clearStoriesPosted
        ? null
        : (storiesPosted ?? this.storiesPosted),
    postsReels: clearPostsReels ? null : (postsReels ?? this.postsReels),
    revenueAmountCents: clearRevenueAmount
        ? null
        : (revenueAmountCents ?? this.revenueAmountCents),
    revenueSkipped: revenueSkipped ?? this.revenueSkipped,
    metExpectationsRating: clearMetExpectationsRating
        ? null
        : (metExpectationsRating ?? this.metExpectationsRating),
    metExpectationsComment: clearMetExpectationsComment
        ? null
        : (metExpectationsComment ?? this.metExpectationsComment),
    wouldRecommend: wouldRecommend ?? this.wouldRecommend,
  );

  Map<String, dynamic> toPayload() => <String, dynamic>{
    'star_rating': starRating,
    if (storiesPosted != null) 'stories_posted_bucket': storiesPosted!.apiValue,
    if (postsReels != null) 'posts_reels_bucket': postsReels!.apiValue,
    if (revenueAmountCents != null) 'revenue_amount_cents': revenueAmountCents,
    'revenue_currency': 'EUR',
    if (metExpectationsRating != null)
      'met_expectations_rating': metExpectationsRating,
    if (metExpectationsComment != null &&
        metExpectationsComment!.trim().isNotEmpty)
      'met_expectations_comment': metExpectationsComment!.trim(),
    'would_recommend': wouldRecommend,
  };
}
