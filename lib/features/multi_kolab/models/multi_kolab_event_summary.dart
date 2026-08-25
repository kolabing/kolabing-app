import 'package:flutter/foundation.dart';

import 'multi_kolab_creator_summary.dart';
import 'multi_kolab_enums.dart';

/// Explore listing item — matches the frozen API contract §6 (summary)
/// exactly.
@immutable
class MultiKolabEventSummary {
  const MultiKolabEventSummary({
    required this.id,
    required this.status,
    required this.title,
    required this.roleCounts,
    required this.eligibleAccountType,
    this.valueSummary,
    this.city,
    this.category,
    this.eventDate,
    this.dateMode,
    this.creatorProfile,
  });

  factory MultiKolabEventSummary.fromJson(Map<String, dynamic> json) =>
      MultiKolabEventSummary(
        id: json['id']?.toString() ?? '',
        status: MultiKolabEventStatus.fromApiValue(
          json['status']?.toString() ?? 'draft',
        ),
        title: json['title']?.toString() ?? '',
        valueSummary: json['value_summary']?.toString(),
        city: json['city']?.toString(),
        category: json['category']?.toString(),
        eventDate: json['event_date'] != null
            ? DateTime.tryParse(json['event_date'].toString())
            : null,
        dateMode: MultiKolabDateMode.fromApiValue(
          json['date_mode']?.toString(),
        ),
        roleCounts: MultiKolabRoleCounts.fromJson(
          json['role_counts'] as Map<String, dynamic>?,
        ),
        eligibleAccountType: MultiKolabEligibleAccountType.fromApiValue(
          json['eligible_account_type']?.toString() ?? 'either',
        ),
        creatorProfile: json['creator_profile'] is Map<String, dynamic>
            ? MultiKolabCreatorSummary.fromJson(
                json['creator_profile'] as Map<String, dynamic>,
              )
            : null,
      );

  final String id;
  final MultiKolabEventStatus status;
  final String title;
  final String? valueSummary;
  final String? city;
  final String? category;
  final DateTime? eventDate;
  final MultiKolabDateMode? dateMode;
  final MultiKolabRoleCounts roleCounts;

  /// **Event-level eligibility is deliberately inert (#171).** Who may apply is a
  /// property of the ROLE, never of the event: `MultiKolabRole.eligibleAccountType`
  /// is the only one that decides eligibility, Explore visibility or the Apply CTA.
  /// This field only mirrors a legacy backend column so the payload round-trips.
  /// Nothing sets it and nothing renders it — verified — and nothing may start to.
  final MultiKolabEligibleAccountType eligibleAccountType;
  final MultiKolabCreatorSummary? creatorProfile;

  bool get isRecruiting => status == MultiKolabEventStatus.recruiting;
}
