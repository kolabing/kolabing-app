import 'package:flutter/foundation.dart';

/// `GET /me/organizer-entitlement` — matches contract §2 exactly. Deliberately
/// separate from the business subscription models: this is never the
/// business paywall (`hasActiveSubscription`).
@immutable
class EventCreatorEntitlement {
  const EventCreatorEntitlement({
    required this.hasEventCreatorEntitlement,
    this.capability = 'event_creator',
    this.grantedAt,
    this.expiresAt,
    this.source,
  });

  factory EventCreatorEntitlement.fromJson(Map<String, dynamic> json) =>
      EventCreatorEntitlement(
        hasEventCreatorEntitlement:
            json['has_event_creator_entitlement'] as bool? ?? false,
        capability: json['capability']?.toString() ?? 'event_creator',
        grantedAt: json['granted_at'] != null
            ? DateTime.tryParse(json['granted_at'].toString())
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'].toString())
            : null,
        source: json['source']?.toString(),
      );

  final bool hasEventCreatorEntitlement;
  final String capability;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final String? source;
}
