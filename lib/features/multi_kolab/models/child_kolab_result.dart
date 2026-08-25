import 'package:flutter/foundation.dart';

/// `POST /multi-kolab-role-applications/{application}/accept` response —
/// matches contract §8 exactly. On acceptance the app hands off to the
/// *existing* child Kolab / Collaboration detail and chat screens using
/// [kolabId]/[collaborationId] — no new detail UI is built for this shape.
@immutable
class ChildKolabResult {
  const ChildKolabResult({
    required this.applicationId,
    required this.applicationStatus,
    required this.kolabId,
    required this.kolabStatus,
    this.collaborationId,
    this.collaborationStatus,
  });

  factory ChildKolabResult.fromJson(Map<String, dynamic> json) {
    final application = json['application'] as Map<String, dynamic>? ?? {};
    final kolab = json['kolab'] as Map<String, dynamic>? ?? {};
    final collaboration = json['collaboration'] as Map<String, dynamic>?;

    return ChildKolabResult(
      applicationId: application['id']?.toString() ?? '',
      applicationStatus: application['status']?.toString() ?? '',
      kolabId: kolab['id']?.toString() ?? '',
      kolabStatus: kolab['status']?.toString() ?? '',
      collaborationId: collaboration?['id']?.toString(),
      collaborationStatus: collaboration?['status']?.toString(),
    );
  }

  final String applicationId;
  final String applicationStatus;
  final String kolabId;
  final String kolabStatus;
  final String? collaborationId;
  final String? collaborationStatus;
}
