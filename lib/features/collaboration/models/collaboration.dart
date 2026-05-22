import '../../gamification/models/challenge.dart';
import '../../opportunity/models/opportunity.dart';

// =============================================================================
// Enums
// =============================================================================

/// Status of a collaboration
enum CollaborationStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  static CollaborationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return CollaborationStatus.scheduled;
      // Backend uses 'active' (CollaborationStatus enum); older payloads /
      // mock data used 'in_progress'. Treat both as the in-progress state.
      case 'active':
      case 'in_progress':
        return CollaborationStatus.inProgress;
      case 'completed':
        return CollaborationStatus.completed;
      case 'cancelled':
        return CollaborationStatus.cancelled;
      default:
        return CollaborationStatus.scheduled;
    }
  }

  String toApiValue() {
    switch (this) {
      case CollaborationStatus.scheduled:
        return 'scheduled';
      case CollaborationStatus.inProgress:
        return 'in_progress';
      case CollaborationStatus.completed:
        return 'completed';
      case CollaborationStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case CollaborationStatus.scheduled:
        return 'Scheduled';
      case CollaborationStatus.inProgress:
        return 'In Progress';
      case CollaborationStatus.completed:
        return 'Completed';
      case CollaborationStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      this == CollaborationStatus.scheduled ||
      this == CollaborationStatus.inProgress;
}

/// Timeline step status
enum TimelineStepStatus { completed, current, upcoming }

// =============================================================================
// Value Objects
// =============================================================================

/// Partner info within a collaboration
class CollaborationPartner {
  const CollaborationPartner({
    required this.id,
    required this.name,
    this.profilePhoto,
    this.category,
    this.city,
    required this.userType,
  });

  /// Parses a partner from either the legacy `business_partner`/
  /// `community_partner` shape (`name`, `profile_photo`, `category`) or the
  /// backend `ProfileSummaryResource` shape used by `CollaborationResource`
  /// (`display_name`, `avatar_url`, `business_type`/`community_type`). The
  /// collaboration list + detail endpoints return the latter, so tolerate both.
  factory CollaborationPartner.fromJson(Map<String, dynamic> json) {
    final category =
        json['category'] as String? ??
        json['business_type'] as String? ??
        json['community_type'] as String?;
    return CollaborationPartner(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['display_name'] ?? '') as String,
      profilePhoto: (json['profile_photo'] ?? json['avatar_url']) as String?,
      category: category,
      city: json['city'] is Map
          ? (json['city'] as Map<String, dynamic>)['name'] as String?
          : json['city'] as String?,
      userType: json['user_type'] as String? ?? 'community',
    );
  }

  final String id;
  final String name;
  final String? profilePhoto;
  final String? category;
  final String? city;
  final String userType;

  bool get isBusiness => userType == 'business';
  bool get isCommunity => userType == 'community';

  String get initial =>
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
}

/// Contact methods shared during collaboration
class ContactMethods {
  const ContactMethods({this.whatsapp, this.email, this.instagram});

  factory ContactMethods.fromJson(Map<String, dynamic> json) {
    return ContactMethods(
      whatsapp: json['whatsapp'] as String?,
      email: json['email'] as String?,
      instagram: json['instagram'] as String?,
    );
  }

  final String? whatsapp;
  final String? email;
  final String? instagram;

  bool get hasAny =>
      (whatsapp?.isNotEmpty ?? false) ||
      (email?.isNotEmpty ?? false) ||
      (instagram?.isNotEmpty ?? false);
}

/// A step in the collaboration timeline
class TimelineStep {
  const TimelineStep({
    required this.title,
    required this.description,
    required this.status,
    this.date,
  });

  final String title;
  final String description;
  final TimelineStepStatus status;
  final DateTime? date;
}

/// Challenge selection for gamification setup
class ChallengeSelection {
  const ChallengeSelection({required this.challenge, this.isSelected = false});

  final Challenge challenge;
  final bool isSelected;

  ChallengeSelection copyWith({bool? isSelected}) => ChallengeSelection(
    challenge: challenge,
    isSelected: isSelected ?? this.isSelected,
  );
}

// =============================================================================
// Main Model
// =============================================================================

/// Full collaboration detail model
class Collaboration {
  const Collaboration({
    required this.id,
    required this.status,
    required this.scheduledDate,
    this.scheduledTime,
    required this.businessPartner,
    required this.communityPartner,
    this.creatorPartner,
    this.applicantPartner,
    this.viewerIsCreator,
    this.viewerHasSubmittedFeedback = false,
    required this.opportunity,
    required this.contactMethods,
    required this.businessOffer,
    required this.communityDeliverables,
    this.eventId,
    this.qrCodeUrl,
    this.challenges,
    this.selectedChallengeIds,
    required this.createdAt,
    this.updatedAt,
    this.feedbackSubmittedAt,
    this.viewerMustResubscribe = false,
  });

  factory Collaboration.fromJson(Map<String, dynamic> json) {
    // The backend `CollaborationResource` (used for BOTH list and detail) does
    // NOT send `business_partner`/`community_partner`/`opportunity`. It sends
    // `creator_profile`/`applicant_profile` (ProfileSummaryResource), an
    // optional `business_profile`/`community_profile`, and `collab_opportunity`.
    // Resolve the two partners from whichever profiles are present, bucketed by
    // `user_type`. (Older mock payloads used the legacy keys; both are
    // tolerated so the detail screen never crashes with "Failed to load Kolab".)
    final partners = _resolvePartners(json);

    // `my_role` ('creator' | 'applicant') is the backend's authoritative,
    // role-aware signal for which side the VIEWER is on in this collaboration.
    // It is the correct basis for "show me the OTHER party" — far more reliable
    // than guessing from the viewer's business/community type (which breaks for
    // either side and has no safe default when the auth user is momentarily null).
    final myRole = json['my_role']?.toString();

    // Has the VIEWER already left feedback? The backend `feedback` array holds
    // one row per reviewer with `reviewer_role` ('creator' | 'applicant');
    // match it against `my_role`. Drives the post-completion "add your feedback"
    // prompt so the second party is never silently skipped.
    final feedbackList = json['feedback'];
    final viewerHasSubmittedFeedback =
        myRole != null &&
        feedbackList is List &&
        feedbackList.any(
          (entry) =>
              entry is Map && entry['reviewer_role']?.toString() == myRole,
        );

    final creatorPartner = json['creator_profile'] is Map<String, dynamic>
        ? CollaborationPartner.fromJson(
            json['creator_profile'] as Map<String, dynamic>,
          )
        : null;
    final applicantPartner = json['applicant_profile'] is Map<String, dynamic>
        ? CollaborationPartner.fromJson(
            json['applicant_profile'] as Map<String, dynamic>,
          )
        : null;

    // `collab_opportunity` (OpportunitySummaryResource) carries the nested
    // `business_offer` + `community_deliverables`, so source them from there
    // when the top-level keys are absent (the real API never sends them top-level).
    final opportunityJson =
        (json['opportunity'] ?? json['collab_opportunity'])
            as Map<String, dynamic>?;

    final businessOfferJson =
        (json['business_offer'] ?? opportunityJson?['business_offer'])
            as Map<String, dynamic>?;
    final communityDeliverablesJson =
        (json['community_deliverables'] ??
                opportunityJson?['community_deliverables'])
            as Map<String, dynamic>?;

    return Collaboration(
      id: json['id'] as String,
      status: CollaborationStatus.fromString(json['status'] as String),
      // Real API only sends a date; legacy mock sent scheduled_time too.
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String?,
      businessPartner: partners.business,
      communityPartner: partners.community,
      creatorPartner: creatorPartner,
      applicantPartner: applicantPartner,
      viewerIsCreator: myRole == 'creator'
          ? true
          : myRole == 'applicant'
          ? false
          : null,
      viewerHasSubmittedFeedback: viewerHasSubmittedFeedback,
      opportunity: opportunityJson != null
          ? Opportunity.fromJson(opportunityJson)
          : null,
      contactMethods: json['contact_methods'] is Map
          ? ContactMethods.fromJson(
              json['contact_methods'] as Map<String, dynamic>,
            )
          : const ContactMethods(),
      businessOffer: businessOfferJson != null
          ? BusinessOffer.fromJson(businessOfferJson)
          : const BusinessOffer(),
      communityDeliverables: communityDeliverablesJson != null
          ? CommunityDeliverables.fromJson(communityDeliverablesJson)
          : const CommunityDeliverables(),
      eventId: json['event_id'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      challenges: (json['challenges'] as List<dynamic>?)
          ?.map((e) => Challenge.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedChallengeIds: (json['selected_challenge_ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // The real API exposes `completed_at` (no `feedback_submitted_at`); the
      // detail screen uses this only to decide whether to show the review CTA.
      feedbackSubmittedAt: json['feedback_submitted_at'] != null
          ? DateTime.parse(json['feedback_submitted_at'] as String)
          : null,
      // Subscription-lapse re-gate (docs/ROLES-AND-PERMISSIONS.md §2.8). The
      // backend sets this true ONLY for a business viewer whose subscription
      // has lapsed on an ongoing collaboration. It is never true for a
      // community viewer, so the client can trust it verbatim. Tolerate a few
      // key spellings while the backend contract settles.
      viewerMustResubscribe: _parseBool(
        json['viewer_must_resubscribe'] ??
            json['must_resubscribe'] ??
            json['viewer_resubscribe_required'],
      ),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  /// Resolve the business + community partner from a `CollaborationResource`
  /// payload. Order of preference:
  ///   1. Legacy explicit keys `business_partner` / `community_partner`.
  ///   2. Backend `business_profile` / `community_profile` (only present on
  ///      some endpoints).
  ///   3. `creator_profile` / `applicant_profile`, bucketed by `user_type`
  ///      (a collaboration is always business <-> community, so exactly one of
  ///      each). This is what the list + detail endpoints actually return.
  /// Falls back to an empty partner so the detail screen renders rather than
  /// throwing if a side is somehow missing.
  static ({CollaborationPartner business, CollaborationPartner community})
  _resolvePartners(Map<String, dynamic> json) {
    CollaborationPartner? business;
    CollaborationPartner? community;

    final explicitBusiness =
        json['business_partner'] ?? json['business_profile'];
    final explicitCommunity =
        json['community_partner'] ?? json['community_profile'];
    if (explicitBusiness is Map<String, dynamic>) {
      business = CollaborationPartner.fromJson(explicitBusiness);
    }
    if (explicitCommunity is Map<String, dynamic>) {
      community = CollaborationPartner.fromJson(explicitCommunity);
    }

    // Fall back to creator/applicant profiles bucketed by user_type.
    for (final key in const ['creator_profile', 'applicant_profile']) {
      final raw = json[key];
      if (raw is! Map<String, dynamic>) continue;
      final partner = CollaborationPartner.fromJson(raw);
      if (partner.isBusiness) {
        business ??= partner;
      } else {
        community ??= partner;
      }
    }

    const empty = CollaborationPartner(id: '', name: '', userType: 'community');
    return (business: business ?? empty, community: community ?? empty);
  }

  final String id;
  final CollaborationStatus status;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final CollaborationPartner businessPartner;
  final CollaborationPartner communityPartner;

  /// The collaboration's creator + applicant sides (from `creator_profile` /
  /// `applicant_profile`). Combined with [viewerIsCreator] these let the UI
  /// show the OTHER party regardless of business/community role.
  final CollaborationPartner? creatorPartner;
  final CollaborationPartner? applicantPartner;

  /// From the backend `my_role`: true if the viewer is the creator, false if
  /// the applicant, null if unknown (e.g. list payloads without `my_role`).
  final bool? viewerIsCreator;

  /// True when the VIEWER has already left feedback for this collaboration
  /// (their row exists in the backend `feedback` array). Drives the
  /// post-completion "add your feedback" prompt — both sides must review.
  final bool viewerHasSubmittedFeedback;

  final Opportunity? opportunity;
  final ContactMethods contactMethods;
  final BusinessOffer businessOffer;
  final CommunityDeliverables communityDeliverables;
  final String? eventId;
  final String? qrCodeUrl;
  final List<Challenge>? challenges;
  final List<String>? selectedChallengeIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Set once the business has submitted post-completion feedback. When null,
  /// the mobile "Leave review" CTA is shown on completed collaborations.
  final DateTime? feedbackSubmittedAt;

  /// True only when the VIEWER is a business whose subscription lapsed while
  /// this collaboration is still ongoing (docs/ROLES-AND-PERMISSIONS.md §2.8).
  /// When true the detail + chat content is blurred behind a "Resubscribe to
  /// continue" prompt. The community counterparty is never re-gated, so this
  /// is always false for a community viewer.
  final bool viewerMustResubscribe;

  /// Get the other party based on current user type
  CollaborationPartner partnerFor({required bool isBusiness}) =>
      isBusiness ? communityPartner : businessPartner;

  /// Resolve the OTHER party to show the viewer. Prefers the backend
  /// `my_role` (role-aware, always correct: a creator sees the applicant and
  /// vice versa) so a community viewer is never shown their own side. Falls
  /// back to the business/community split only when `my_role` is unavailable.
  CollaborationPartner partnerForViewer({required bool isBusinessViewer}) {
    if (viewerIsCreator != null &&
        creatorPartner != null &&
        applicantPartner != null) {
      return viewerIsCreator! ? applicantPartner! : creatorPartner!;
    }
    return partnerFor(isBusiness: isBusinessViewer);
  }

  /// Display date like "Sat, 15 Mar 2026"
  String get formattedDate {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dayNames[scheduledDate.weekday - 1]}, '
        '${scheduledDate.day} '
        '${monthNames[scheduledDate.month - 1]} '
        '${scheduledDate.year}';
  }

  /// Build timeline steps based on status
  List<TimelineStep> get timeline {
    final now = DateTime.now();
    final isBeforeEvent = now.isBefore(scheduledDate);

    return [
      TimelineStep(
        title: 'Application Accepted',
        description: 'Both parties agreed to collaborate',
        status: TimelineStepStatus.completed,
        date: createdAt,
      ),
      TimelineStep(
        title: 'Event Preparation',
        description: 'Set up challenges, QR codes, and logistics',
        status: status == CollaborationStatus.scheduled && isBeforeEvent
            ? TimelineStepStatus.current
            : status == CollaborationStatus.scheduled
            ? TimelineStepStatus.upcoming
            : TimelineStepStatus.completed,
      ),
      TimelineStep(
        title: 'Event Day',
        description: 'Kolab event takes place',
        status: status == CollaborationStatus.inProgress
            ? TimelineStepStatus.current
            : status == CollaborationStatus.completed
            ? TimelineStepStatus.completed
            : TimelineStepStatus.upcoming,
        date: scheduledDate,
      ),
      TimelineStep(
        title: 'Completed',
        description: 'Review and share outcomes',
        status: status == CollaborationStatus.completed
            ? TimelineStepStatus.completed
            : TimelineStepStatus.upcoming,
      ),
    ];
  }
}
