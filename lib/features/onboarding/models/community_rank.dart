/// Response model for `GET /me/community-rank` (incentives v1, A: city
/// league). Organiser onboarding's Direction C live preview is the first
/// consumer; see `CityLeagueController::me` in kolabing-v2.
///
/// All fields are parsed defensively — a city with no league yet (`rank`
/// null, `preview` empty) is a normal, valid response, not an error.
class CommunityRank {
  const CommunityRank({
    required this.city,
    required this.rank,
    required this.total,
    required this.points,
    required this.divisionLabel,
    required this.level,
    required this.preview,
  });

  factory CommunityRank.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['preview'];
    return CommunityRank(
      city: json['city'] as String?,
      rank: (json['rank'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      divisionLabel: json['division_label'] as String?,
      level: json['level'] as String? ?? 'new',
      preview: previewRaw is List
          ? previewRaw
                .whereType<Map<String, dynamic>>()
                .map(CommunityRankRow.fromJson)
                .toList()
          : const [],
    );
  }

  final String? city;

  /// Null when the organiser has 0 points this month (not yet ranked).
  final int? rank;
  final int total;
  final int points;
  final String? divisionLabel;

  /// `new` | `rising` | `trusted` | `top` — see `config/incentives.php`.
  final String level;

  /// Top-of-division rows + the organiser's own neighbourhood, already
  /// windowed server-side (`preview_top` + `preview_neighbours`).
  final List<CommunityRankRow> preview;

  bool get isTrusted => level == 'trusted' || level == 'top';

  /// Whether there's enough league data to render a live preview at all.
  bool get hasLeague => city != null;
}

class CommunityRankRow {
  const CommunityRankRow({
    required this.rank,
    required this.profileId,
    required this.displayName,
    required this.points,
    required this.isViewer,
  });

  factory CommunityRankRow.fromJson(Map<String, dynamic> json) =>
      CommunityRankRow(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        profileId: (json['profile_id'] ?? '').toString(),
        displayName: json['display_name'] as String? ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        isViewer: json['is_viewer'] as bool? ?? false,
      );

  final int rank;
  final String profileId;
  final String displayName;
  final int points;
  final bool isViewer;
}
