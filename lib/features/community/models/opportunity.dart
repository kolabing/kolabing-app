import 'package:flutter/foundation.dart';

/// Types of collaboration opportunities
enum OpportunityType {
  event,
  partnership,
  campaign;

  String get displayName {
    switch (this) {
      case OpportunityType.event:
        return 'Event';
      case OpportunityType.partnership:
        return 'Partnership';
      case OpportunityType.campaign:
        return 'Campaign';
    }
  }

  String get description {
    switch (this) {
      case OpportunityType.event:
        return 'A one-time or recurring event looking for sponsors';
      case OpportunityType.partnership:
        return 'An ongoing collaboration with businesses';
      case OpportunityType.campaign:
        return 'A marketing campaign or promotional activity';
    }
  }

  String get icon {
    switch (this) {
      case OpportunityType.event:
        return 'calendar';
      case OpportunityType.partnership:
        return 'handshake';
      case OpportunityType.campaign:
        return 'megaphone';
    }
  }

  static OpportunityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'event':
        return OpportunityType.event;
      case 'partnership':
        return OpportunityType.partnership;
      case 'campaign':
        return OpportunityType.campaign;
      default:
        return OpportunityType.event;
    }
  }

  String toApiValue() => name;
}

/// Status of an opportunity
enum OpportunityStatus {
  draft,
  published,
  closed;

  String get displayName {
    switch (this) {
      case OpportunityStatus.draft:
        return 'Draft';
      case OpportunityStatus.published:
        return 'Published';
      case OpportunityStatus.closed:
        return 'Closed';
    }
  }

  static OpportunityStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return OpportunityStatus.draft;
      case 'published':
        return OpportunityStatus.published;
      case 'closed':
        return OpportunityStatus.closed;
      default:
        return OpportunityStatus.draft;
    }
  }

  String toApiValue() => name;
}

/// Opportunity model for creating collaboration requests
@immutable
class Opportunity {
  const Opportunity({
    this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.cityId,
    this.cityName,
    required this.startDate,
    this.endDate,
    this.expectedAttendees,
    this.hasReward = false,
    this.rewardDescription,
    this.budget,
    this.requirements,
    this.status = OpportunityStatus.draft,
    this.createdAt,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : rawId as String?;

    final cityData = json['city'] as Map<String, dynamic>?;

    return Opportunity(
      id: id,
      title: json['title'] as String? ?? '',
      type: OpportunityType.fromString(
          json['type'] as String? ?? json['collab_type'] as String? ?? 'event'),
      description: json['description'] as String? ?? '',
      cityId: cityData?['id']?.toString() ?? json['city_id']?.toString() ?? '',
      cityName: cityData?['name'] as String? ?? json['location'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      expectedAttendees: json['expected_attendees'] as int?,
      hasReward: json['has_reward'] as bool? ?? false,
      rewardDescription: json['reward_description'] as String?,
      budget: json['budget'] as String?,
      requirements: json['requirements'] as String?,
      status:
          OpportunityStatus.fromString(json['status'] as String? ?? 'draft'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'type': type.toApiValue(),
        'description': description,
        'city_id': cityId,
        'start_date': startDate.toIso8601String().split('T').first,
        if (endDate != null)
          'end_date': endDate!.toIso8601String().split('T').first,
        if (expectedAttendees != null) 'expected_attendees': expectedAttendees,
        'has_reward': hasReward,
        if (hasReward && rewardDescription != null)
          'reward_description': rewardDescription,
        if (budget != null && budget!.isNotEmpty) 'budget': budget,
        if (requirements != null && requirements!.isNotEmpty)
          'requirements': requirements,
        'status': status.toApiValue(),
      };

  final String? id;
  final String title;
  final OpportunityType type;
  final String description;
  final String cityId;
  final String? cityName;
  final DateTime startDate;
  final DateTime? endDate;
  final int? expectedAttendees;
  final bool hasReward;
  final String? rewardDescription;
  final String? budget;
  final String? requirements;
  final OpportunityStatus status;
  final DateTime? createdAt;

  Opportunity copyWith({
    String? id,
    String? title,
    OpportunityType? type,
    String? description,
    String? cityId,
    String? cityName,
    DateTime? startDate,
    DateTime? endDate,
    int? expectedAttendees,
    bool? hasReward,
    String? rewardDescription,
    String? budget,
    String? requirements,
    OpportunityStatus? status,
    DateTime? createdAt,
    bool clearEndDate = false,
    bool clearReward = false,
  }) =>
      Opportunity(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        description: description ?? this.description,
        cityId: cityId ?? this.cityId,
        cityName: cityName ?? this.cityName,
        startDate: startDate ?? this.startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        expectedAttendees: expectedAttendees ?? this.expectedAttendees,
        hasReward: clearReward ? false : (hasReward ?? this.hasReward),
        rewardDescription: clearReward
            ? null
            : (rewardDescription ?? this.rewardDescription),
        budget: budget ?? this.budget,
        requirements: requirements ?? this.requirements,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Check if all required fields are filled
  bool get isValid =>
      title.isNotEmpty &&
      description.isNotEmpty &&
      cityId.isNotEmpty &&
      (!hasReward || (rewardDescription?.isNotEmpty ?? false));

  @override
  String toString() => 'Opportunity(id: $id, title: $title, type: $type)';
}
