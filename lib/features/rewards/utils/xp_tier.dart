/// XP tier thresholds and display helpers.
///
/// Rising Community  0–99 XP
/// Trusted Community 100–499 XP
/// Local Legend      500+ XP
enum XpTier {
  rising,
  trusted,
  legend;

  static XpTier fromPoints(int points) {
    if (points >= 500) return XpTier.legend;
    if (points >= 100) return XpTier.trusted;
    return XpTier.rising;
  }

  String get displayName {
    switch (this) {
      case XpTier.rising:
        return 'Rising Community';
      case XpTier.trusted:
        return 'Trusted Community';
      case XpTier.legend:
        return 'Local Legend';
    }
  }

  /// XP required to reach the next tier, or null if already at max.
  int? get nextThreshold {
    switch (this) {
      case XpTier.rising:
        return 100;
      case XpTier.trusted:
        return 500;
      case XpTier.legend:
        return null;
    }
  }

  /// Progress (0.0–1.0) within the current tier band.
  double progressFor(int points) {
    switch (this) {
      case XpTier.rising:
        return (points / 100).clamp(0.0, 1.0);
      case XpTier.trusted:
        return ((points - 100) / 400).clamp(0.0, 1.0);
      case XpTier.legend:
        return 1.0;
    }
  }
}
