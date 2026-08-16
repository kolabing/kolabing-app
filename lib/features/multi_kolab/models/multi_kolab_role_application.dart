import 'package:flutter/foundation.dart';

import 'multi_kolab_enums.dart';

/// Matches the frozen API contract §7 exactly. Deliberately has no
/// `withdrawalReason` field — the backend never serializes it (contract §12:
/// never publicly expose it), so there is nothing to parse.
@immutable
class MultiKolabRoleApplication {
  const MultiKolabRoleApplication({
    required this.id,
    required this.multiKolabRoleId,
    required this.applicantProfileId,
    required this.applicantProfileType,
    required this.status,
    this.pitch,
    this.availability,
    this.kolabId,
    this.createdAt,
  });

  factory MultiKolabRoleApplication.fromJson(Map<String, dynamic> json) =>
      MultiKolabRoleApplication(
        id: json['id']?.toString() ?? '',
        multiKolabRoleId: json['multi_kolab_role_id']?.toString() ?? '',
        applicantProfileId: json['applicant_profile_id']?.toString() ?? '',
        applicantProfileType: json['applicant_profile_type']?.toString() ?? '',
        status: MultiKolabRoleApplicationStatus.fromApiValue(
          json['status']?.toString() ?? 'pending',
        ),
        pitch: json['pitch']?.toString(),
        availability: json['availability']?.toString(),
        kolabId: json['kolab_id']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  final String id;
  final String multiKolabRoleId;
  final String applicantProfileId;
  final String applicantProfileType;
  final MultiKolabRoleApplicationStatus status;
  final String? pitch;
  final String? availability;
  final String? kolabId;
  final DateTime? createdAt;

  bool get isAccepted => status == MultiKolabRoleApplicationStatus.accepted;
  bool get isPending => status == MultiKolabRoleApplicationStatus.pending;
  bool get isShortlisted =>
      status == MultiKolabRoleApplicationStatus.shortlisted;
}

/// `POST /multi-kolab-roles/{role}/applications` request body.
@immutable
class CreateMultiKolabApplicationInput {
  const CreateMultiKolabApplicationInput({
    required this.pitch,
    this.availability,
  });

  final String pitch;
  final String? availability;

  Map<String, dynamic> toJson() => {
    'pitch': pitch,
    if (availability != null && availability!.isNotEmpty)
      'availability': availability,
  };
}
