import 'package:flutter/foundation.dart';

import 'multi_kolab_enums.dart';
import 'multi_kolab_role.dart';
import 'multi_kolab_role_application.dart';

/// Detail shape — matches the frozen API contract §3/§6 exactly, including
/// `roles` and `viewer_application` (the viewer's own application only —
/// never another applicant's, per contract §12).
@immutable
class MultiKolabEvent {
  const MultiKolabEvent({
    required this.id,
    required this.status,
    required this.creatorProfileId,
    required this.title,
    required this.eligibleAccountType,
    required this.roles,
    required this.roleCounts,
    this.creatorProfileType,
    this.description,
    this.valueSummary,
    this.venueNeeded = false,
    this.dateMode,
    this.eventDate,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.city,
    this.category,
    this.rsvpUrl,
    this.viewerApplication,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  factory MultiKolabEvent.fromJson(Map<String, dynamic> json) =>
      MultiKolabEvent(
        id: json['id']?.toString() ?? '',
        status: MultiKolabEventStatus.fromApiValue(
          json['status']?.toString() ?? 'draft',
        ),
        creatorProfileId: json['creator_profile_id']?.toString() ?? '',
        creatorProfileType: json['creator_profile_type']?.toString(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        valueSummary: json['value_summary']?.toString(),
        venueNeeded: json['venue_needed'] as bool? ?? false,
        dateMode: MultiKolabDateMode.fromApiValue(
          json['date_mode']?.toString(),
        ),
        eventDate: _asDate(json['event_date']),
        dateRangeStart: _asDate(json['date_range_start']),
        dateRangeEnd: _asDate(json['date_range_end']),
        city: json['city']?.toString(),
        category: json['category']?.toString(),
        rsvpUrl: json['rsvp_url']?.toString(),
        eligibleAccountType: MultiKolabEligibleAccountType.fromApiValue(
          json['eligible_account_type']?.toString() ?? 'either',
        ),
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .map((e) => MultiKolabRole.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        roleCounts: _RoleCountsFromDetailJson.parse(json['role_counts']),
        viewerApplication: json['viewer_application'] is Map<String, dynamic>
            ? MultiKolabRoleApplication.fromJson(
                json['viewer_application'] as Map<String, dynamic>,
              )
            : null,
        createdAt: _asDateTime(json['created_at']),
        updatedAt: _asDateTime(json['updated_at']),
        publishedAt: _asDateTime(json['published_at']),
      );

  final String id;
  final MultiKolabEventStatus status;
  final String creatorProfileId;
  final String? creatorProfileType;
  final String title;
  final String? description;
  final String? valueSummary;
  final bool venueNeeded;
  final MultiKolabDateMode? dateMode;
  final DateTime? eventDate;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String? city;
  final String? category;

  /// Only ever `https://` — the backend rejects anything else at publish
  /// time (contract §5, §10 `must_be_https`).
  final String? rsvpUrl;
  final MultiKolabEligibleAccountType eligibleAccountType;
  final List<MultiKolabRole> roles;
  final ({int total, int open, int filled}) roleCounts;
  final MultiKolabRoleApplication? viewerApplication;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  /// Field-wise copy. Needed by the organizer flows (and the deterministic
  /// mock repository) which repeatedly derive a new immutable event from an
  /// existing one after a mutation — previously each call site had to
  /// re-list all 20 constructor arguments by hand.
  MultiKolabEvent copyWith({
    MultiKolabEventStatus? status,
    String? title,
    String? description,
    String? valueSummary,
    bool? venueNeeded,
    MultiKolabDateMode? dateMode,
    DateTime? eventDate,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    String? city,
    String? category,
    String? rsvpUrl,
    MultiKolabEligibleAccountType? eligibleAccountType,
    List<MultiKolabRole>? roles,
    ({int total, int open, int filled})? roleCounts,
    MultiKolabRoleApplication? viewerApplication,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return MultiKolabEvent(
      id: id,
      status: status ?? this.status,
      creatorProfileId: creatorProfileId,
      creatorProfileType: creatorProfileType,
      title: title ?? this.title,
      description: description ?? this.description,
      valueSummary: valueSummary ?? this.valueSummary,
      venueNeeded: venueNeeded ?? this.venueNeeded,
      dateMode: dateMode ?? this.dateMode,
      eventDate: eventDate ?? this.eventDate,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      city: city ?? this.city,
      category: category ?? this.category,
      rsvpUrl: rsvpUrl ?? this.rsvpUrl,
      eligibleAccountType: eligibleAccountType ?? this.eligibleAccountType,
      roles: roles ?? this.roles,
      roleCounts: roleCounts ?? this.roleCounts,
      viewerApplication: viewerApplication ?? this.viewerApplication,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  bool get isRecruiting => status == MultiKolabEventStatus.recruiting;
  bool get isDraft => status == MultiKolabEventStatus.draft;
  bool get hasViewerApplied => viewerApplication != null;
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _asDateTime(Object? value) => _asDate(value);

abstract final class _RoleCountsFromDetailJson {
  static ({int total, int open, int filled}) parse(Object? json) {
    if (json is! Map<String, dynamic>) return (total: 0, open: 0, filled: 0);
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return (
      total: asInt(json['total']),
      open: asInt(json['open']),
      filled: asInt(json['filled']),
    );
  }
}

/// `POST /multi-kolab-events` and `PATCH /multi-kolab-events/{event}` request
/// body — every field optional except `title`, matching the backend's
/// lenient draft validation (contract §3).
@immutable
class CreateMultiKolabEventInput {
  const CreateMultiKolabEventInput({
    required this.title,
    this.description,
    this.valueSummary,
    this.venueNeeded,
    this.dateMode,
    this.eventDate,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.city,
    this.category,
    this.rsvpUrl,
    this.eligibleAccountType,
  });

  final String? title;
  final String? description;
  final String? valueSummary;
  final bool? venueNeeded;
  final MultiKolabDateMode? dateMode;
  final DateTime? eventDate;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String? city;
  final String? category;
  final String? rsvpUrl;
  final MultiKolabEligibleAccountType? eligibleAccountType;

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (valueSummary != null) 'value_summary': valueSummary,
    if (venueNeeded != null) 'venue_needed': venueNeeded,
    if (dateMode != null) 'date_mode': dateMode!.toApiValue(),
    if (eventDate != null)
      'event_date': eventDate!.toIso8601String().split('T').first,
    if (dateRangeStart != null)
      'date_range_start': dateRangeStart!.toIso8601String().split('T').first,
    if (dateRangeEnd != null)
      'date_range_end': dateRangeEnd!.toIso8601String().split('T').first,
    if (city != null) 'city': city,
    if (category != null) 'category': category,
    if (rsvpUrl != null) 'rsvp_url': rsvpUrl,
    if (eligibleAccountType != null)
      'eligible_account_type': eligibleAccountType!.toApiValue(),
  };
}

typedef UpdateMultiKolabEventInput = CreateMultiKolabEventInput;

/// `POST /multi-kolab-events/{event}/roles` request body — contract §4.
@immutable
class CreateMultiKolabRoleInput {
  const CreateMultiKolabRoleInput({
    required this.title,
    required this.eligibleAccountType,
    this.positionsNeeded = 1,
    this.required_ = true,
    this.need,
    this.receive,
    this.compensationType,
    this.requirements,
    this.details,
  });

  final String title;
  final MultiKolabEligibleAccountType eligibleAccountType;
  final int positionsNeeded;
  final bool required_;
  final String? need;
  final String? receive;
  final MultiKolabCompensationType? compensationType;
  final String? requirements;
  final String? details;

  Map<String, dynamic> toJson() => {
    'title': title,
    'eligible_account_type': eligibleAccountType.toApiValue(),
    'positions_needed': positionsNeeded,
    'required': required_,
    if (need != null) 'need': need,
    if (receive != null) 'receive': receive,
    if (compensationType != null)
      'compensation_type': compensationType!.toApiValue(),
    if (requirements != null) 'requirements': requirements,
    if (details != null) 'details': details,
  };
}

/// `PATCH /multi-kolab-roles/{role}` request body — every field optional
/// (the backend rules are all `sometimes`), so only what the organizer
/// actually changed is sent. `status` is limited to `open`/`closed`:
/// `filled` is derived by the acceptance service and is rejected by the
/// backend Form Request (contract §4, Task 10 addition).
@immutable
class UpdateMultiKolabRoleInput {
  const UpdateMultiKolabRoleInput({
    this.title,
    this.eligibleAccountType,
    this.positionsNeeded,
    this.required_,
    this.need,
    this.receive,
    this.compensationType,
    this.requirements,
    this.details,
    this.status,
  });

  final String? title;
  final MultiKolabEligibleAccountType? eligibleAccountType;
  final int? positionsNeeded;
  final bool? required_;
  final String? need;
  final String? receive;
  final MultiKolabCompensationType? compensationType;
  final String? requirements;
  final String? details;
  final MultiKolabRoleStatus? status;

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (eligibleAccountType != null)
      'eligible_account_type': eligibleAccountType!.toApiValue(),
    if (positionsNeeded != null) 'positions_needed': positionsNeeded,
    if (required_ != null) 'required': required_,
    if (need != null) 'need': need,
    if (receive != null) 'receive': receive,
    if (compensationType != null)
      'compensation_type': compensationType!.toApiValue(),
    if (requirements != null) 'requirements': requirements,
    if (details != null) 'details': details,
    if (status != null) 'status': status!.toApiValue(),
  };
}

/// GET /multi-kolab-events?... query filters.
@immutable
class MultiKolabExploreFilter {
  const MultiKolabExploreFilter({
    this.status = MultiKolabEventStatus.recruiting,
    this.city,
    this.category,
    this.eligibleAccountType,
    this.page = 1,
    this.perPage = 15,
  });

  final MultiKolabEventStatus status;
  final String? city;
  final String? category;
  final MultiKolabEligibleAccountType? eligibleAccountType;
  final int page;
  final int perPage;

  Map<String, String> toQuery() => {
    'status': status.toApiValue(),
    'per_page': perPage.toString(),
    'page': page.toString(),
    if (city != null && city!.isNotEmpty) 'city': city!,
    if (category != null && category!.isNotEmpty) 'category': category!,
    if (eligibleAccountType != null)
      'eligible_account_type': eligibleAccountType!.toApiValue(),
  };

  // Value equality — required for correct caching as a Riverpod
  // `.family` parameter (otherwise every new instance is a cache miss).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MultiKolabExploreFilter &&
          status == other.status &&
          city == other.city &&
          category == other.category &&
          eligibleAccountType == other.eligibleAccountType &&
          page == other.page &&
          perPage == other.perPage);

  @override
  int get hashCode =>
      Object.hash(status, city, category, eligibleAccountType, page, perPage);
}
