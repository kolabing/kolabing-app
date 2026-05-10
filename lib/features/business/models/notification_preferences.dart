/// Notification preferences model
class NotificationPreferences {
  const NotificationPreferences({
    this.emailNotifications = true,
    this.whatsappNotifications = true,
    this.messagesEnabled = true,
    this.applicationsEnabled = true,
    this.collaborationsEnabled = true,
    this.rewardsEnabled = true,
    this.marketingEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.timezone,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        emailNotifications: json['email_notifications'] as bool? ?? true,
        whatsappNotifications: json['whatsapp_notifications'] as bool? ?? true,
        messagesEnabled: json['messages_enabled'] as bool? ?? true,
        applicationsEnabled:
            json['applications_enabled'] as bool? ??
            json['new_application_alerts'] as bool? ??
            true,
        collaborationsEnabled:
            json['collaborations_enabled'] as bool? ??
            json['collaboration_updates'] as bool? ??
            true,
        rewardsEnabled: json['rewards_enabled'] as bool? ?? true,
        marketingEnabled:
            json['marketing_enabled'] as bool? ??
            json['marketing_tips'] as bool? ??
            false,
        quietHoursStart: json['quiet_hours_start'] as String?,
        quietHoursEnd: json['quiet_hours_end'] as String?,
        timezone: json['timezone'] as String?,
      );

  final bool emailNotifications;
  final bool whatsappNotifications;
  final bool messagesEnabled;
  final bool applicationsEnabled;
  final bool collaborationsEnabled;
  final bool rewardsEnabled;
  final bool marketingEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? timezone;

  bool get newApplicationAlerts => applicationsEnabled;
  bool get collaborationUpdates => collaborationsEnabled;
  bool get marketingTips => marketingEnabled;

  Map<String, dynamic> toJson() => {
        'email_notifications': emailNotifications,
        'whatsapp_notifications': whatsappNotifications,
        'messages_enabled': messagesEnabled,
        'applications_enabled': applicationsEnabled,
        'collaborations_enabled': collaborationsEnabled,
        'rewards_enabled': rewardsEnabled,
        'marketing_enabled': marketingEnabled,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'timezone': timezone,
      };

  NotificationPreferences copyWith({
    bool? emailNotifications,
    bool? whatsappNotifications,
    bool? messagesEnabled,
    bool? applicationsEnabled,
    bool? collaborationsEnabled,
    bool? rewardsEnabled,
    bool? marketingEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
  }) =>
      NotificationPreferences(
        emailNotifications: emailNotifications ?? this.emailNotifications,
        whatsappNotifications:
            whatsappNotifications ?? this.whatsappNotifications,
        messagesEnabled: messagesEnabled ?? this.messagesEnabled,
        applicationsEnabled: applicationsEnabled ?? this.applicationsEnabled,
        collaborationsEnabled:
            collaborationsEnabled ?? this.collaborationsEnabled,
        rewardsEnabled: rewardsEnabled ?? this.rewardsEnabled,
        marketingEnabled: marketingEnabled ?? this.marketingEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
        timezone: timezone ?? this.timezone,
      );
}
