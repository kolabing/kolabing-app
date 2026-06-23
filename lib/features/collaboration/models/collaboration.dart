import '../../../utils/remote_media_url.dart';
import '../../gamification/models/challenge.dart';
import '../../opportunity/models/opportunity.dart';

// =============================================================================
// Enums
// =============================================================================

/// Status of a collaboration
enum CollaborationStatus {
  scheduled,
  inProgress,
  pendingConfirmation,
  completed,
  cancelled;

  static CollaborationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return CollaborationStatus.scheduled;
      case 'in_progress':
      case 'active':
        return CollaborationStatus.inProgress;
      case 'pending_confirmation':
        return CollaborationStatus.pendingConfirmation;
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
        return 'active';
      case CollaborationStatus.pendingConfirmation:
        return 'pending_confirmation';
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
      case CollaborationStatus.pendingConfirmation:
        return 'Waiting Confirmation';
      case CollaborationStatus.completed:
        return 'Completed';
      case CollaborationStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      this == CollaborationStatus.scheduled ||
      this == CollaborationStatus.inProgress;

  bool get canBeCompleted =>
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

  factory CollaborationPartner.fromJson(Map<String, dynamic> json) {
    return CollaborationPartner(
      // Tolerate null/missing strings from the API — a missing partner name
      // must not crash parsing and silently drop the whole collaboration.
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profilePhoto: normalizeRemoteMediaUrlOrNull(
        json['profile_photo'] as String?,
      ),
      category: json['category'] as String?,
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
    this.completedAt,
    this.isToday = false,
    this.myRole,
    this.viewerMustResubscribe = false,
    this.hasReviewed = false,
    this.viewerMustSubmitFeedback = true,
    this.ownFeedbackSubmitted = false,
    this.partnerFeedbackSubmitted = false,
    this.pendingFeedbackFrom = const [],
  });

  factory Collaboration.fromJson(Map<String, dynamic> json) {
    return Collaboration(
      id: json['id'] as String,
      status: CollaborationStatus.fromString(json['status'] as String),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String?,
      businessPartner: CollaborationPartner.fromJson(
        json['business_partner'] as Map<String, dynamic>,
      ),
      communityPartner: CollaborationPartner.fromJson(
        json['community_partner'] as Map<String, dynamic>,
      ),
      opportunity: json['kolab'] is Map<String, dynamic>
          ? Opportunity.fromJson(json['kolab'] as Map<String, dynamic>)
          : json['opportunity'] is Map<String, dynamic>
          ? Opportunity.fromJson(json['opportunity'] as Map<String, dynamic>)
          : null,
      contactMethods: json['contact_methods'] != null
          ? ContactMethods.fromJson(
              json['contact_methods'] as Map<String, dynamic>,
            )
          : const ContactMethods(),
      businessOffer: json['business_offer'] != null
          ? BusinessOffer.fromJson(
              json['business_offer'] as Map<String, dynamic>,
            )
          : const BusinessOffer(),
      communityDeliverables: json['community_deliverables'] != null
          ? CommunityDeliverables.fromJson(
              json['community_deliverables'] as Map<String, dynamic>,
            )
          : const CommunityDeliverables(),
      eventId: json['event_id'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      challenges: (json['challenges'] as List<dynamic>?)
          ?.map((e) => Challenge.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedChallengeIds: (json['selected_challenge_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      isToday: _isScheduledToday(json['scheduled_date'] as String?),
      myRole: json['my_role'] as String?,
      hasReviewed: json['has_reviewed'] as bool? ?? false,
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
      // Two-sided feedback gate. The Kolab only flips to `completed` once BOTH
      // parties submit feedback; these fields let the UI show a "you confirmed,
      // waiting for partner" state instead of looking like nothing happened.
      // All keys are tolerated as missing (self-gated, safe defaults): when the
      // backend omits them the viewer is treated as still owing feedback so the
      // Complete CTA stays available rather than vanishing.
      viewerMustSubmitFeedback: json.containsKey('viewer_must_submit_feedback')
          ? _parseBool(json['viewer_must_submit_feedback'])
          : true,
      ownFeedbackSubmitted: json['own_feedback'] != null,
      partnerFeedbackSubmitted: json['partner_feedback'] != null,
      pendingFeedbackFrom: (json['pending_feedback_from'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static bool _isScheduledToday(String? dateStr) {
    if (dateStr == null) return false;
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    } catch (_) {
      return false;
    }
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

  final String id;
  final CollaborationStatus status;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final CollaborationPartner businessPartner;
  final CollaborationPartner communityPartner;
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
  final DateTime? completedAt;
  final bool isToday;

  /// 'creator' | 'applicant' | null — set by the API for the authenticated viewer
  final String? myRole;

  /// True when the current viewer has already submitted a review for this collab.
  final bool hasReviewed;

  /// True when the backend still expects post-Kolab feedback from the viewer to
  /// satisfy the completion gate. Defaults to true when the key is absent so the
  /// Complete CTA is never hidden by a missing field.
  final bool viewerMustSubmitFeedback;

  /// True when the viewer has already submitted their own feedback
  /// (`own_feedback != null`). Drives the "you confirmed, waiting for partner"
  /// state once one side has acted but the Kolab is not yet `completed`.
  final bool ownFeedbackSubmitted;

  /// True when the partner has already submitted their feedback
  /// (`partner_feedback != null`).
  final bool partnerFeedbackSubmitted;

  /// `user_type` strings (e.g. `business`, `community`) still owed feedback
  /// before the Kolab can complete. Empty once both sides have submitted.
  final List<String> pendingFeedbackFrom;

  /// True only when the VIEWER is a business whose subscription lapsed while
  /// this collaboration is still ongoing (docs/ROLES-AND-PERMISSIONS.md §2.8).
  /// When true the detail + chat content is blurred behind a "Resubscribe to
  /// continue" prompt. The community counterparty is never re-gated, so this
  /// is always false for a community viewer.
  final bool viewerMustResubscribe;

  /// Get the other party based on current user type
  CollaborationPartner partnerFor({required bool isBusiness}) =>
      isBusiness ? communityPartner : businessPartner;

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
        description: 'Both parties agreed to kolab',
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
