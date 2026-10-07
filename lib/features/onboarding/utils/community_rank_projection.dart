import '../models/community_rank.dart';

/// Backend scoring weights (`config/incentives.php` on kolabing-v2,
/// `city_league.weights`). Mirrored here for the slider's client-side
/// projection; keep in sync if the backend weights change.
abstract final class CommunityRankWeights {
  static const int pointsPerKolab = 40;
  static const int pointsPerCheckin = 2;

  /// Trusted requires 1 kolab/month with at least this many check-ins
  /// (`organiser_levels.trusted.min_checkins`).
  static const int trustedMinCheckins = 20;
}

/// Projected points after running one more kolab with [checkins] check-ins.
int projectedPoints(CommunityRank rank, int checkins) =>
    rank.points +
    CommunityRankWeights.pointsPerKolab +
    checkins * CommunityRankWeights.pointsPerCheckin;

/// Best-effort projected rank for [points], using only the windowed
/// `preview` rows the backend already returned (top of division + the
/// organiser's own neighbourhood) — there is no full-table fetch on this
/// screen. Lands one spot behind the best-ranked (lowest rank number) row
/// the projection still trails; when it clears even the best-ranked row
/// shown, reports that row's rank (the window can't see anything better).
/// Falls back to the organiser's current rank when the projection doesn't
/// clear anyone in the preview window.
int? projectedRank(CommunityRank rank, int points) {
  final others = rank.preview.where((r) => !r.isViewer).toList()
    ..sort((a, b) => a.rank.compareTo(b.rank));
  if (others.isEmpty) return rank.rank;

  CommunityRankRow? lastBlocker;
  for (final row in others) {
    if (points >= row.points) break;
    lastBlocker = row;
  }

  if (lastBlocker == null) return others.first.rank;
  return lastBlocker.rank + 1;
}
