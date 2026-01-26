/// Notification preferences model
class NotificationPreferences {
  const NotificationPreferences({
    this.emailNotifications = true,
    this.whatsappNotifications = true,
    this.newApplicationAlerts = true,
    this.collaborationUpdates = true,
    this.marketingTips = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        emailNotifications: json['email_notifications'] as bool? ?? true,
        whatsappNotifications: json['whatsapp_notifications'] as bool? ?? true,
        newApplicationAlerts: json['new_application_alerts'] as bool? ?? true,
        collaborationUpdates: json['collaboration_updates'] as bool? ?? true,
        marketingTips: json['marketing_tips'] as bool? ?? false,
      );

  final bool emailNotifications;
  final bool whatsappNotifications;
  final bool newApplicationAlerts;
  final bool collaborationUpdates;
  final bool marketingTips;

  Map<String, dynamic> toJson() => {
        'email_notifications': emailNotifications,
        'whatsapp_notifications': whatsappNotifications,
        'new_application_alerts': newApplicationAlerts,
        'collaboration_updates': collaborationUpdates,
        'marketing_tips': marketingTips,
      };

  NotificationPreferences copyWith({
    bool? emailNotifications,
    bool? whatsappNotifications,
    bool? newApplicationAlerts,
    bool? collaborationUpdates,
    bool? marketingTips,
  }) =>
      NotificationPreferences(
        emailNotifications: emailNotifications ?? this.emailNotifications,
        whatsappNotifications:
            whatsappNotifications ?? this.whatsappNotifications,
        newApplicationAlerts: newApplicationAlerts ?? this.newApplicationAlerts,
        collaborationUpdates: collaborationUpdates ?? this.collaborationUpdates,
        marketingTips: marketingTips ?? this.marketingTips,
      );
}
