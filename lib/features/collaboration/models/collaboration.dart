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
enum TimelineStepStatus {
  completed,
  current,
  upcoming;
}

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
      id: json['id'] as String,
      name: json['name'] as String,
      profilePhoto: json['profile_photo'] as String?,
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
  const ContactMethods({
    this.whatsapp,
    this.email,
    this.instagram,
  });

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
  const ChallengeSelection({
    required this.challenge,
    this.isSelected = false,
  });

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
  });

  factory Collaboration.fromJson(Map<String, dynamic> json) {
    return Collaboration(
      id: json['id'] as String,
      status: CollaborationStatus.fromString(json['status'] as String),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String?,
      businessPartner: CollaborationPartner.fromJson(
          json['business_partner'] as Map<String, dynamic>),
      communityPartner: CollaborationPartner.fromJson(
          json['community_partner'] as Map<String, dynamic>),
      opportunity: json['opportunity'] != null
          ? Opportunity.fromJson(json['opportunity'] as Map<String, dynamic>)
          : null,
      contactMethods: json['contact_methods'] != null
          ? ContactMethods.fromJson(
              json['contact_methods'] as Map<String, dynamic>)
          : const ContactMethods(),
      businessOffer: json['business_offer'] != null
          ? BusinessOffer.fromJson(
              json['business_offer'] as Map<String, dynamic>)
          : const BusinessOffer(),
      communityDeliverables: json['community_deliverables'] != null
          ? CommunityDeliverables.fromJson(
              json['community_deliverables'] as Map<String, dynamic>)
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
    );
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

  /// Get the other party based on current user type
  CollaborationPartner partnerFor({required bool isBusiness}) =>
      isBusiness ? communityPartner : businessPartner;

  /// Display date like "Sat, 15 Mar 2026"
  String get formattedDate {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
        description: 'Collaboration event takes place',
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
