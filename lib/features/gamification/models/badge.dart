/// Badge model for milestone achievements
class GamificationBadge {
  const GamificationBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.milestoneType,
    required this.milestoneValue,
    this.slug,
    this.iconUrl,
  });

  factory GamificationBadge.fromJson(Map<String, dynamic> json) {
    return GamificationBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      milestoneType: json['milestone_type'] as String,
      milestoneValue: json['milestone_value'] as int,
      slug: json['slug'] as String? ?? json['name']?.toString().toLowerCase().replaceAll(' ', '-'),
      iconUrl: json['icon_url'] as String?,
    );
  }

  final String id;
  final String name;
  final String description;
  final String icon;
  final String milestoneType;
  final int milestoneValue;
  final String? slug;
  final String? iconUrl;

  /// Convenience getters for threshold
  String get thresholdType => milestoneType;
  int get thresholdValue => milestoneValue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'milestone_type': milestoneType,
        'milestone_value': milestoneValue,
        if (slug != null) 'slug': slug,
        if (iconUrl != null) 'icon_url': iconUrl,
      };
}

/// Badge award model - when a user earns a badge
class BadgeAward {
  const BadgeAward({
    required this.id,
    required this.badge,
    required this.awardedAt,
  });

  factory BadgeAward.fromJson(Map<String, dynamic> json) {
    return BadgeAward(
      id: json['id'] as String,
      badge: GamificationBadge.fromJson(json['badge'] as Map<String, dynamic>),
      awardedAt: DateTime.parse(json['awarded_at'] as String),
    );
  }

  final String id;
  final GamificationBadge badge;
  final DateTime awardedAt;

  /// Get badge name (convenience getter)
  String get badgeName => badge.name;

  /// Get badge icon (convenience getter)
  String get badgeIcon => badge.icon;

  Map<String, dynamic> toJson() => {
        'id': id,
        'badge': badge.toJson(),
        'awarded_at': awardedAt.toIso8601String(),
      };
}

/// Response for badges list
class BadgesResponse {
  const BadgesResponse({
    required this.badges,
  });

  factory BadgesResponse.fromJson(Map<String, dynamic> json) {
    final badgesJson = json['badges'] as List<dynamic>;
    return BadgesResponse(
      badges: badgesJson
          .map((e) => GamificationBadge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<GamificationBadge> badges;
}

/// Response for user's earned badges
class MyBadgesResponse {
  const MyBadgesResponse({
    required this.badges,
  });

  factory MyBadgesResponse.fromJson(Map<String, dynamic> json) {
    final badgesJson = json['badges'] as List<dynamic>;
    return MyBadgesResponse(
      badges: badgesJson
          .map((e) => BadgeAward.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<BadgeAward> badges;
}
