/// Models for the organiser city league (incentive v1, "A + C").
///
/// Backed by three endpoints (kolabing-v2#359,
/// `feat/organiser-levels-weekly-board`), each wrapped as
/// `{"success": true, "data": {...}}`:
/// - `GET /api/v1/me/community-rank`          -> [CommunityRank]
/// - `GET /api/v1/leagues/{city_id}/current`  -> [LeagueTable]
/// - `GET /api/v1/me/organiser-level`         -> [OrganiserLevel]
///
/// Every field is parsed defensively: a missing, null or differently-typed
/// field must never crash the Home screen. Numbers may arrive as int, double
/// or numeric strings.
library;

// -----------------------------------------------------------------------------
// Parsing helpers
// -----------------------------------------------------------------------------

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.round();
  }
  return null;
}

num? _asNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

String? _asString(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value;
  if (value is num || value is bool) return value.toString();
  return null;
}

bool? _asBoolOrNull(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    if (value == 'true' || value == '1') return true;
    if (value == 'false' || value == '0') return false;
  }
  return null;
}

bool _asBool(Object? value) => _asBoolOrNull(value) ?? false;

DateTime? _asDate(Object? value) {
  final raw = _asString(value);
  return raw == null ? null : DateTime.tryParse(raw);
}

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<dynamic, dynamic>>()
      .map(Map<String, dynamic>.from)
      .toList();
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map(
        (e) => e is Map ? _asString(e['label'] ?? e['message']) : _asString(e),
      )
      .whereType<String>()
      .toList();
}

/// A line that may come as a plain string or as `{message|label: ...}`.
String? _asMessage(Object? value) {
  if (value is Map) return _asString(value['message'] ?? value['label']);
  return _asString(value);
}

// -----------------------------------------------------------------------------
// League city + season helpers
// -----------------------------------------------------------------------------

/// The league's city: a display name and the key for
/// `GET /leagues/{city}/current` (the backend's city id).
class LeagueCity {
  const LeagueCity({required this.name, required this.key});

  /// Human-readable name (e.g. "Barcelona").
  final String name;

  /// Path identifier for the full table: `city_id` when sent, else the
  /// object's id / slug, else the name.
  final String key;

  /// Reads `city` (a name or an object) plus an optional sibling `city_id`.
  /// Returns null when there is no city (the league is off for this user).
  static LeagueCity? fromJson(Object? city, {Object? cityId}) {
    String? name;
    String? key;
    if (city is Map) {
      final map = Map<String, dynamic>.from(city);
      name = _asString(map['name']) ?? _asString(map['slug']);
      key = _asString(map['id']) ?? _asString(map['slug']);
    } else {
      name = _asString(city);
    }
    key = _asString(cityId) ?? key ?? name;
    if (name == null || key == null) return null;
    return LeagueCity(name: name, key: key);
  }
}

/// Whole days (rounded up) between [now] and [end]; never negative.
int? daysUntil(DateTime? end, DateTime now) {
  if (end == null) return null;
  final diff = end.difference(now);
  if (diff.isNegative) return 0;
  return (diff.inMinutes / (24 * 60)).ceil();
}

// -----------------------------------------------------------------------------
// Rows
// -----------------------------------------------------------------------------

/// One row of a city league (communities ranked by monthly league points).
class LeagueRow {
  const LeagueRow({
    required this.rank,
    required this.displayName,
    required this.points,
    this.profileId,
    this.isViewer = false,
    this.promotionZone = false,
    this.relegationZone = false,
  });

  final int rank;
  final String? profileId;
  final String displayName;
  final int points;
  final bool isViewer;

  /// In the promotion / relegation places of a divided league.
  final bool promotionZone;
  final bool relegationZone;

  /// Returns null for a row without a usable rank (it cannot be placed).
  static LeagueRow? fromJson(Map<String, dynamic> json) {
    final rank = _asInt(json['rank'] ?? json['position']);
    if (rank == null) return null;
    return LeagueRow(
      rank: rank,
      profileId: _asString(json['profile_id'] ?? json['id']),
      displayName: _asString(json['display_name'] ?? json['name']) ?? '',
      points: _asInt(json['points'] ?? json['score']) ?? 0,
      isViewer: _asBool(json['is_viewer']),
      promotionZone: _asBool(json['promotion_zone']),
      relegationZone: _asBool(json['relegation_zone']),
    );
  }

  static List<LeagueRow> listFromJson(Object? value) {
    final rows =
        _asMapList(
            value,
          ).map(LeagueRow.fromJson).whereType<LeagueRow>().toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));
    return rows;
  }

  LeagueRow asViewer() => LeagueRow(
    rank: rank,
    profileId: profileId,
    displayName: displayName,
    points: points,
    isViewer: true,
    promotionZone: promotionZone,
    relegationZone: relegationZone,
  );
}

// -----------------------------------------------------------------------------
// Next reward
// -----------------------------------------------------------------------------

/// The next reward the organiser can reach (drives the Home banner).
/// `message` is backend copy and is shown as sent.
class NextReward {
  const NextReward({
    required this.message,
    this.type,
    this.level,
    this.remaining = const {},
    this.daysLeft,
  });

  static NextReward? fromJson(Object? value) {
    if (value is String) {
      return value.trim().isEmpty ? null : NextReward(message: value);
    }
    final json = _asMap(value);
    if (json == null) return null;
    final message = _asString(json['message']);
    if (message == null) return null;
    return NextReward(
      type: _asString(json['type']),
      level: _asString(json['level']),
      message: message,
      remaining: _asMap(json['remaining']) ?? const {},
      daysLeft: _asInt(json['days_left']),
    );
  }

  /// "level" (reach the next level) or "keep" (hold the current one).
  final String? type;
  final String? level;
  final String message;
  final Map<String, dynamic> remaining;
  final int? daysLeft;
}

// -----------------------------------------------------------------------------
// GET /me/community-rank
// -----------------------------------------------------------------------------

/// The signed-in community's position in its city league this month.
class CommunityRank {
  const CommunityRank({
    this.city,
    this.month,
    this.division,
    this.divisionKey,
    this.seasonEndsAt,
    this.rank,
    this.total,
    this.points = 0,
    this.scoreBreakdown = const {},
    this.preview = const [],
    this.promotionZone = false,
    this.relegationZone = false,
    this.levelRaw,
    this.nextReward,
    this.topReward,
  });

  factory CommunityRank.fromJson(Map<String, dynamic> json) {
    final breakdown = <String, num>{};
    _asMap(json['score_breakdown'])?.forEach((key, value) {
      final n = _asNum(value);
      if (n != null) breakdown[key] = n;
    });
    return CommunityRank(
      city: LeagueCity.fromJson(json['city'], cityId: json['city_id']),
      month: _asString(json['month']),
      division:
          _asMessage(json['division_label']) ?? _asMessage(json['division']),
      divisionKey: _asString(json['division']),
      seasonEndsAt: _asDate(json['season_ends_at']),
      rank: _asInt(json['rank']),
      total: _asInt(json['total']),
      points: _asInt(json['points']) ?? 0,
      scoreBreakdown: breakdown,
      preview: LeagueRow.listFromJson(json['preview']),
      promotionZone: _asBool(json['promotion_zone']),
      relegationZone: _asBool(json['relegation_zone']),
      levelRaw: _asString(json['level']),
      nextReward: NextReward.fromJson(json['next_reward']),
      topReward: _asMessage(json['top_reward']),
    );
  }

  /// Null when the league is off for this organiser (flag off, or no city):
  /// Home then shows only the next-reward banner.
  final LeagueCity? city;

  /// Raw month from the API ("2026-09"); see `formatLeagueMonth`.
  final String? month;

  /// Division label (e.g. "Division 2 (50 to 199 members)").
  final String? division;
  final String? divisionKey;
  final DateTime? seasonEndsAt;

  /// Null while the community has no league points this month.
  final int? rank;

  /// Communities in the viewer's division.
  final int? total;
  final int points;
  final Map<String, num> scoreBreakdown;

  /// Top 3 + the viewer ± 1 within their division, sorted by rank.
  final List<LeagueRow> preview;
  final bool promotionZone;
  final bool relegationZone;
  final String? levelRaw;
  final NextReward? nextReward;
  final String? topReward;

  bool get isRanked => rank != null && rank! > 0;
  bool get hasLeague => city != null;
}

// -----------------------------------------------------------------------------
// GET /leagues/{city}/current
// -----------------------------------------------------------------------------

/// One division of a city league table.
class LeagueDivision {
  const LeagueDivision({required this.rows, this.key, this.label});

  final String? key;
  final String? label;
  final List<LeagueRow> rows;
}

/// The full current season table for one city, grouped by division.
class LeagueTable {
  const LeagueTable({
    this.city,
    this.month,
    this.seasonEndsAt,
    this.divisionsEnabled = false,
    this.divisions = const [],
  });

  /// Accepts `data` as `{divisions: [{key, label, rows}]}` (the contract),
  /// a flat `{rows: [...]}`, or a bare row list.
  factory LeagueTable.fromJson(Object? data) {
    if (data is List) {
      return LeagueTable(
        divisions: [LeagueDivision(rows: LeagueRow.listFromJson(data))],
      );
    }
    final json = _asMap(data) ?? const <String, dynamic>{};
    final divisions = _asMapList(json['divisions'])
        .map(
          (d) => LeagueDivision(
            key: _asString(d['key']),
            label: _asMessage(d['label']) ?? _asString(d['key']),
            rows: LeagueRow.listFromJson(d['rows']),
          ),
        )
        .toList();
    if (divisions.isEmpty && json['rows'] != null) {
      divisions.add(LeagueDivision(rows: LeagueRow.listFromJson(json['rows'])));
    }
    return LeagueTable(
      city: LeagueCity.fromJson(json['city'], cityId: json['city_id']),
      month: _asString(json['month']),
      seasonEndsAt: _asDate(json['season_ends_at']),
      divisionsEnabled: _asBool(json['divisions_enabled']),
      divisions: divisions,
    );
  }

  final LeagueCity? city;
  final String? month;
  final DateTime? seasonEndsAt;
  final bool divisionsEnabled;
  final List<LeagueDivision> divisions;

  bool get isEmpty => divisions.every((d) => d.rows.isEmpty);

  /// Show division headers only when the city is actually divided.
  bool get showDivisionHeaders => divisionsEnabled || divisions.length > 1;
}

// -----------------------------------------------------------------------------
// GET /me/organiser-level
// -----------------------------------------------------------------------------

/// Known organiser levels. Unknown wire values fall back to [unknown] and are
/// shown with their raw text.
enum OrganiserLevelKind {
  newcomer,
  rising,
  trusted,
  top,
  unknown;

  static OrganiserLevelKind fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'new':
        return OrganiserLevelKind.newcomer;
      case 'rising':
        return OrganiserLevelKind.rising;
      case 'trusted':
        return OrganiserLevelKind.trusted;
      case 'top':
        return OrganiserLevelKind.top;
      default:
        return OrganiserLevelKind.unknown;
    }
  }
}

/// One requirement row (e.g. "Kolab this month with 20+ check-ins").
class LevelCriterion {
  const LevelCriterion({
    required this.key,
    required this.label,
    required this.met,
    this.value,
    this.target,
    this.unit,
    this.required = true,
  });

  final String key;

  /// Backend copy, shown as sent.
  final String label;
  final num? value;
  final num? target;
  final bool met;

  /// "checkins", "rank", "ratio", "hours", or null (a count).
  final String? unit;

  /// Whether this row gates the next level; informative rows are false.
  /// Absent on the wire = true.
  final bool required;

  static LevelCriterion? fromJson(Map<String, dynamic> json) {
    final key = _asString(json['key']);
    final label = _asString(json['label']) ?? key;
    if (key == null || label == null) return null;
    return LevelCriterion(
      key: key,
      label: label,
      value: _asNum(json['value']),
      target: _asNum(json['target']),
      met: _asBool(json['met']),
      unit: _asString(json['unit']),
      required: _asBoolOrNull(json['required']) ?? true,
    );
  }
}

/// The organiser's current level, what the next one needs, and the perks.
class OrganiserLevel {
  const OrganiserLevel({
    required this.levelRaw,
    this.nextLevelRaw,
    this.criteria = const [],
    this.perks = const [],
    this.nextPerks = const [],
    this.month,
    this.daysLeft,
    this.nextReward,
    this.evaluatedAt,
  });

  factory OrganiserLevel.fromJson(Map<String, dynamic> json) => OrganiserLevel(
    levelRaw: _asString(json['level']) ?? 'new',
    nextLevelRaw: _asString(json['next_level']),
    criteria: _asMapList(
      json['criteria'],
    ).map(LevelCriterion.fromJson).whereType<LevelCriterion>().toList(),
    perks: _asStringList(json['perks']),
    nextPerks: _asStringList(json['next_perks']),
    month: _asString(json['month']),
    daysLeft: _asInt(json['days_left']),
    nextReward: NextReward.fromJson(json['next_reward']),
    evaluatedAt: _asDate(json['evaluated_at']),
  );

  final String levelRaw;
  final String? nextLevelRaw;
  final List<LevelCriterion> criteria;

  /// Everything the current level holds (backend copy).
  final List<String> perks;

  /// What the next level adds on top (backend copy).
  final List<String> nextPerks;
  final String? month;
  final int? daysLeft;
  final NextReward? nextReward;
  final DateTime? evaluatedAt;

  OrganiserLevelKind get level => OrganiserLevelKind.fromString(levelRaw);
  OrganiserLevelKind? get nextLevel =>
      nextLevelRaw == null ? null : OrganiserLevelKind.fromString(nextLevelRaw);
}
