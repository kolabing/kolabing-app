/// Which side of the collaboration is leaving feedback. The finish flow asks
/// the business and the community slightly different questions (see
/// `docs/ROLES-AND-PERMISSIONS.md` §4 "Feedback"):
///
/// - Business feedback: star rating, stories posted, posts/reels, revenue,
///   expectation match, "would recommend this community".
/// - Community feedback: star rating, benefits received, posts/reels,
///   expectation match, "would recommend this business".
///
/// The variant only changes copy + which optional questions are shown; the
/// submit contract is the same `POST /collaborations/{id}/finish` with the
/// feedback payload (the backend infers the reviewer from the auth token).
enum FeedbackVariant {
  business,
  community;

  bool get isBusiness => this == FeedbackVariant.business;
  bool get isCommunity => this == FeedbackVariant.community;

  String get apiValue => isBusiness ? 'business' : 'community';
}

/// Output volume buckets used by BOTH sides when reporting how much content was
/// produced. Wire values match the backend enum exactly.
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

/// In-memory draft of the feedback as the user steps through the sheet. Holds
/// the union of both variants' fields; the [variant] decides which optional
/// questions the sheet shows and which keys land in [toPayload].
class CollaborationFeedbackDraft {
  const CollaborationFeedbackDraft({
    this.variant = FeedbackVariant.business,
    this.starRating,
    this.storiesPosted,
    this.postsReels,
    this.revenueAmountCents,
    this.revenueSkipped = false,
    this.benefitsReceived,
    this.metExpectationsRating,
    this.metExpectationsComment,
    this.wouldRecommend,
  });

  /// Which side is leaving feedback. Drives copy + payload shape.
  final FeedbackVariant variant;

  /// 1–5; null until the user picks.
  final int? starRating;

  /// Business-only: how many stories the community posted.
  final OutputBucket? storiesPosted;

  /// Both sides: how many posts/reels were published.
  final OutputBucket? postsReels;

  /// Business-only — EUR cents. Null when not provided (skipped or never typed).
  final int? revenueAmountCents;

  /// Business-only: explicit "I'd rather not say" (distinct from "unanswered").
  final bool revenueSkipped;

  /// Community-only: free-text of the benefits the community received from the
  /// business (e.g. "free venue, -20% on drinks, exposure to followers").
  final String? benefitsReceived;

  final int? metExpectationsRating;
  final String? metExpectationsComment;

  /// Business: "would recommend this community". Community: "would recommend
  /// this business". Required for both.
  final bool? wouldRecommend;

  /// The two questions both variants gate on: a star rating and a recommend
  /// answer. Everything else is optional / skippable for either side.
  bool get canSubmit => starRating != null && wouldRecommend != null;

  CollaborationFeedbackDraft copyWith({
    FeedbackVariant? variant,
    int? starRating,
    OutputBucket? storiesPosted,
    OutputBucket? postsReels,
    int? revenueAmountCents,
    bool? revenueSkipped,
    String? benefitsReceived,
    int? metExpectationsRating,
    String? metExpectationsComment,
    bool? wouldRecommend,
    bool clearStoriesPosted = false,
    bool clearPostsReels = false,
    bool clearRevenueAmount = false,
    bool clearBenefitsReceived = false,
    bool clearMetExpectationsRating = false,
    bool clearMetExpectationsComment = false,
  }) => CollaborationFeedbackDraft(
    variant: variant ?? this.variant,
    starRating: starRating ?? this.starRating,
    storiesPosted: clearStoriesPosted
        ? null
        : (storiesPosted ?? this.storiesPosted),
    postsReels: clearPostsReels ? null : (postsReels ?? this.postsReels),
    revenueAmountCents: clearRevenueAmount
        ? null
        : (revenueAmountCents ?? this.revenueAmountCents),
    revenueSkipped: revenueSkipped ?? this.revenueSkipped,
    benefitsReceived: clearBenefitsReceived
        ? null
        : (benefitsReceived ?? this.benefitsReceived),
    metExpectationsRating: clearMetExpectationsRating
        ? null
        : (metExpectationsRating ?? this.metExpectationsRating),
    metExpectationsComment: clearMetExpectationsComment
        ? null
        : (metExpectationsComment ?? this.metExpectationsComment),
    wouldRecommend: wouldRecommend ?? this.wouldRecommend,
  );

  /// Serialize for the finish endpoint. Common keys are sent for both sides;
  /// variant-specific keys are only included for the relevant role so the
  /// backend never receives, e.g., a "revenue" key from a community.
  Map<String, dynamic> toPayload() => <String, dynamic>{
    'reviewer_role': variant.apiValue,
    'star_rating': starRating,
    if (postsReels != null) 'posts_reels_bucket': postsReels!.apiValue,
    if (metExpectationsRating != null)
      'met_expectations_rating': metExpectationsRating,
    if (metExpectationsComment != null &&
        metExpectationsComment!.trim().isNotEmpty)
      'met_expectations_comment': metExpectationsComment!.trim(),
    'would_recommend': wouldRecommend,
    // Business-only keys
    if (variant.isBusiness) ...<String, dynamic>{
      if (storiesPosted != null)
        'stories_posted_bucket': storiesPosted!.apiValue,
      if (revenueAmountCents != null)
        'revenue_amount_cents': revenueAmountCents,
      'revenue_currency': 'EUR',
    },
    // Community-only keys
    if (variant.isCommunity &&
        benefitsReceived != null &&
        benefitsReceived!.trim().isNotEmpty)
      'benefits_received': benefitsReceived!.trim(),
  };
}
