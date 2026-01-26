/// Subscription status enum
enum SubscriptionStatus {
  active,
  cancelled,
  pastDue,
  inactive;

  factory SubscriptionStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      default:
        return SubscriptionStatus.inactive;
    }
  }

  String get label {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.pastDue:
        return 'Past Due';
      case SubscriptionStatus.inactive:
        return 'Inactive';
    }
  }
}

/// Subscription model for business users
class Subscription {
  const Subscription({
    required this.id,
    required this.status,
    this.statusLabel,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.isActive = false,
    this.daysRemaining,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        status: SubscriptionStatus.fromString(json['status'] as String),
        statusLabel: json['status_label'] as String?,
        currentPeriodStart: json['current_period_start'] != null
            ? DateTime.parse(json['current_period_start'] as String)
            : null,
        currentPeriodEnd: json['current_period_end'] != null
            ? DateTime.parse(json['current_period_end'] as String)
            : null,
        cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? false,
        daysRemaining: json['days_remaining'] as int?,
      );

  final String id;
  final SubscriptionStatus status;
  final String? statusLabel;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final bool isActive;
  final int? daysRemaining;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        if (statusLabel != null) 'status_label': statusLabel,
        if (currentPeriodStart != null)
          'current_period_start': currentPeriodStart!.toIso8601String(),
        if (currentPeriodEnd != null)
          'current_period_end': currentPeriodEnd!.toIso8601String(),
        'cancel_at_period_end': cancelAtPeriodEnd,
        'is_active': isActive,
        if (daysRemaining != null) 'days_remaining': daysRemaining,
      };

  Subscription copyWith({
    String? id,
    SubscriptionStatus? status,
    String? statusLabel,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    bool? cancelAtPeriodEnd,
    bool? isActive,
    int? daysRemaining,
  }) =>
      Subscription(
        id: id ?? this.id,
        status: status ?? this.status,
        statusLabel: statusLabel ?? this.statusLabel,
        currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
        cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
        isActive: isActive ?? this.isActive,
        daysRemaining: daysRemaining ?? this.daysRemaining,
      );
}
