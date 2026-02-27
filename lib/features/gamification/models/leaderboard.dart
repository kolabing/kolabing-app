/// Leaderboard entry model
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.profileId,
    required this.displayName,
    this.profilePhoto,
    required this.totalPoints,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      profileId: json['profile_id'] as String,
      displayName: json['display_name'] as String,
      profilePhoto: json['profile_photo'] as String?,
      totalPoints: json['total_points'] as int,
      rank: json['rank'] as int,
    );
  }

  final String profileId;
  final String displayName;
  final String? profilePhoto;
  final int totalPoints;
  final int rank;

  /// Check if this is the top position
  bool get isFirstPlace => rank == 1;

  /// Check if this is top 3
  bool get isPodium => rank <= 3;

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'display_name': displayName,
        if (profilePhoto != null) 'profile_photo': profilePhoto,
        'total_points': totalPoints,
        'rank': rank,
      };
}

/// User's own rank in the leaderboard
class MyRank {
  const MyRank({
    required this.profileId,
    required this.displayName,
    required this.totalPoints,
    required this.rank,
  });

  factory MyRank.fromJson(Map<String, dynamic> json) {
    return MyRank(
      profileId: json['profile_id'] as String,
      displayName: json['display_name'] as String? ?? 'You',
      totalPoints: json['total_points'] as int,
      rank: json['rank'] as int,
    );
  }

  final String profileId;
  final String displayName;
  final int totalPoints;
  final int rank;

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'display_name': displayName,
        'total_points': totalPoints,
        'rank': rank,
      };
}

/// Leaderboard response containing entries and user's rank
class LeaderboardResponse {
  const LeaderboardResponse({
    required this.leaderboard,
    this.myRank,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final leaderboardJson = json['leaderboard'] as List<dynamic>;
    return LeaderboardResponse(
      leaderboard: leaderboardJson
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myRank: json['my_rank'] != null
          ? MyRank.fromJson(json['my_rank'] as Map<String, dynamic>)
          : null,
    );
  }

  final List<LeaderboardEntry> leaderboard;
  final MyRank? myRank;

  /// Convenience getter for leaderboard entries
  List<LeaderboardEntry> get entries => leaderboard;

  /// Check if user has a rank (has participated)
  bool get hasMyRank => myRank != null;
}
