/// Mission gamification model.
///
/// Mirrors the backend contract returned by `GET /api/v1/me/missions`:
/// ```json
/// { "id","slug","name","description","category","points","difficulty",
///   "target_value","repeat_interval","progress_count","completed",
///   "completed_at","period_key" }
/// ```
///
/// The backend already filters to the viewer's audience + to missions that can
/// actually progress, so the app just displays what it gets. Parsing is
/// deliberately tolerant of missing/null keys (the contract is still being
/// built in parallel).
class Mission {
  const Mission({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.category,
    required this.points,
    this.difficulty,
    required this.targetValue,
    this.repeatInterval,
    required this.progressCount,
    required this.completed,
    this.completedAt,
    this.periodKey,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: _asString(json['id']) ?? '',
      slug: _asString(json['slug']) ?? '',
      name: _asString(json['name']) ?? '',
      description: _asString(json['description']),
      category: _asString(json['category']) ?? 'other',
      points: _asInt(json['points']) ?? 0,
      difficulty: _asString(json['difficulty']),
      targetValue: _asInt(json['target_value']) ?? 0,
      repeatInterval: _asString(json['repeat_interval']),
      progressCount: _asInt(json['progress_count']) ?? 0,
      completed:
          _asBool(json['completed']) || _asDate(json['completed_at']) != null,
      completedAt: _asDate(json['completed_at']),
      periodKey: _asString(json['period_key']),
    );
  }

  /// Stable identifier (DB id).
  final String id;

  /// Machine slug (e.g. `attend_first_event`).
  final String slug;

  /// Display name. Backend copy is shown as-is (seed copy is EN for now).
  final String name;

  /// Optional short description. Shown as-is.
  final String? description;

  /// One of: onboarding/attendance/engagement/content/referral/growth/social/
  /// milestone (or anything else the backend sends — handled gracefully).
  final String category;

  /// Reward points awarded on completion.
  final int points;

  /// Optional difficulty hint (easy/medium/hard).
  final String? difficulty;

  /// How many units complete the mission.
  final int targetValue;

  /// Optional repeat cadence (e.g. `daily`, `weekly`, `monthly`).
  final String? repeatInterval;

  /// Current progress towards [targetValue].
  final int progressCount;

  /// Whether the mission is completed for the current period.
  final bool completed;

  /// When it was completed, if known.
  final DateTime? completedAt;

  /// Period bucket (for repeating missions), if any.
  final String? periodKey;

  /// Progress as a fraction in 0..1. Returns 0 when [targetValue] is not
  /// positive, so the UI never divides by zero or overflows the bar.
  double get progressFraction {
    if (targetValue <= 0) return 0;
    final fraction = progressCount / targetValue;
    if (fraction.isNaN) return 0;
    return fraction.clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Tolerant parse helpers
  // ---------------------------------------------------------------------------

  static String? _asString(Object? value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final str = value?.toString().toLowerCase();
    return str == 'true' || str == '1';
  }

  static DateTime? _asDate(Object? value) {
    final str = _asString(value);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
