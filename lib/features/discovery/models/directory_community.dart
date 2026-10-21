import 'package:flutter/foundation.dart';

/// One row of the business community directory
/// (`GET /discovery/communities`, kolabing-v2 BE-NF-78).
///
/// The server decides the blur: when [identityMasked] is true it has already
/// withheld [displayName] and [avatarUrl], so the app never holds a name it
/// must hide (ROLES §2.24).
@immutable
class DirectoryCommunity {
  const DirectoryCommunity({
    required this.id,
    required this.identityMasked,
    this.displayName,
    this.avatarUrl,
    this.communityType,
    this.communitySize,
    this.cityName,
    this.isVerified = false,
    this.publishedKolabsCount = 0,
  });

  factory DirectoryCommunity.fromJson(Map<String, dynamic> json) =>
      DirectoryCommunity(
        id: json['id']?.toString() ?? '',
        identityMasked: json['identity_masked'] == true,
        displayName: _nonEmpty(json['display_name']),
        avatarUrl: _nonEmpty(json['avatar_url']),
        communityType: _nonEmpty(json['community_type']),
        communitySize: _toInt(json['community_size']),
        cityName: _nonEmpty(json['city_name']),
        isVerified: json['is_verified'] == true,
        publishedKolabsCount: _toInt(json['published_kolabs_count']) ?? 0,
      );

  final String id;
  final bool identityMasked;
  final String? displayName;
  final String? avatarUrl;
  final String? communityType;
  final int? communitySize;
  final String? cityName;
  final bool isVerified;
  final int publishedKolabsCount;

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
