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
/// produced. The backend `posts_reels` / `stories_posted` fields are plain
/// integers, so [apiCount] maps each bucket to a representative count (its lower
/// bound) for the wire payload.
enum OutputBucket {
  zero('0', 'None', 0),
  oneToFive('1-5', '1–5', 1),
  sixToTen('6-10', '6–10', 6),
  elevenToFifteen('11-15', '11–15', 11),
  sixteenToThirty('16-30', '16–30', 16),
  thirtyOneToFifty('31-50', '31–50', 31),
  fiftyPlus('50+', '50+', 50);

  const OutputBucket(this.apiValue, this.label, this.apiCount);

  final String apiValue;
  final String label;

  /// Representative integer count sent to the backend (the bucket's lower bound).
  final int apiCount;
}

/// Community-only multiselect: the kinds of benefits the community received from
/// the business. Serialized into the backend's free-text `benefits` field.
enum BenefitType {
  freebies('Freebies'),
  discount('Discount'),
  freeVenue('Free venue'),
  professionalContent('Professional content creator'),
  other('Other');

  const BenefitType(this.label);

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
    this.benefits = const <BenefitType>{},
    this.benefitsOther,
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

  /// Community-only: the benefits the community received from the business,
  /// chosen from [BenefitType]. Serialized to the backend `benefits` string.
  final Set<BenefitType> benefits;

  /// Community-only free text accompanying [BenefitType.other].
  final String? benefitsOther;

  final int? metExpectationsRating;
  final String? metExpectationsComment;

  /// Business: "would recommend this community". Community: "would recommend
  /// this business". Required for both.
  final bool? wouldRecommend;

  /// Gate before the draft can be submitted/finished. Both variants need a star
  /// rating and a recommend answer; a community must also pick at least one
  /// benefit (the backend `benefits` field is required for community reviewers).
  bool get canSubmit {
    if (starRating == null || wouldRecommend == null) return false;
    if (variant.isCommunity && !hasValidBenefits) return false;
    return true;
  }

  /// At least one benefit picked, and if "Other" is chosen its text is filled.
  bool get hasValidBenefits {
    if (benefits.isEmpty) return false;
    if (benefits.contains(BenefitType.other)) {
      return benefitsOther?.trim().isNotEmpty ?? false;
    }
    return true;
  }

  /// The benefits rendered as the backend's free-text `benefits` value.
  String get benefitsAsText {
    final parts = <String>[];
    for (final benefit in BenefitType.values) {
      if (!benefits.contains(benefit)) continue;
      if (benefit == BenefitType.other) {
        final text = benefitsOther?.trim();
        parts.add(text != null && text.isNotEmpty ? 'Other: $text' : 'Other');
      } else {
        parts.add(benefit.label);
      }
    }
    return parts.join(', ');
  }

  CollaborationFeedbackDraft copyWith({
    FeedbackVariant? variant,
    int? starRating,
    OutputBucket? storiesPosted,
    OutputBucket? postsReels,
    int? revenueAmountCents,
    bool? revenueSkipped,
    Set<BenefitType>? benefits,
    String? benefitsOther,
    int? metExpectationsRating,
    String? metExpectationsComment,
    bool? wouldRecommend,
    bool clearStoriesPosted = false,
    bool clearPostsReels = false,
    bool clearRevenueAmount = false,
    bool clearBenefitsOther = false,
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
    benefits: benefits ?? this.benefits,
    benefitsOther: clearBenefitsOther
        ? null
        : (benefitsOther ?? this.benefitsOther),
    metExpectationsRating: clearMetExpectationsRating
        ? null
        : (metExpectationsRating ?? this.metExpectationsRating),
    metExpectationsComment: clearMetExpectationsComment
        ? null
        : (metExpectationsComment ?? this.metExpectationsComment),
    wouldRecommend: wouldRecommend ?? this.wouldRecommend,
  );

  /// Serialize for the `POST /collaborations/{id}/finish` endpoint. Keys MUST
  /// match `FinishCollaborationRequest` exactly:
  ///   shared:    rating, posts_reels, expectation_match, would_recommend, note
  ///   business:  stories_posted (int), revenue (numeric, EUR units)
  ///   community: benefits (string)
  /// Required-but-skippable numeric fields default to 0 so the finish never
  /// 422s on a step the user skipped.
  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'rating': starRating,
      'posts_reels': postsReels?.apiCount ?? 0,
      // The backend wants a boolean. Treat a 3+ rating (or an unanswered step)
      // as "expectations met"; only an explicit 1–2 rating is "not met".
      'expectation_match': (metExpectationsRating ?? 3) >= 3,
      'would_recommend': wouldRecommend,
    };

    final note = metExpectationsComment?.trim();
    if (note != null && note.isNotEmpty) {
      // Backend caps `note` at 200 chars.
      payload['note'] = note.length > 200 ? note.substring(0, 200) : note;
    }

    if (variant.isBusiness) {
      payload['stories_posted'] = storiesPosted?.apiCount ?? 0;
      payload['revenue'] = revenueAmountCents != null
          ? revenueAmountCents! / 100
          : 0;
    } else {
      payload['benefits'] = benefitsAsText;
    }

    return payload;
  }
}
