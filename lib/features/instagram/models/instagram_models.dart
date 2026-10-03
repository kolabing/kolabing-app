import 'package:flutter/foundation.dart';

// =============================================================================
// Instagram Connect models (kolabing-v2 `feat/instagram-connect`)
//
// Every payload is parsed defensively: the backend is being built in parallel,
// and a missing or oddly typed field must degrade to "not shown", never throw.
// =============================================================================

/// `GET /api/v1/me/instagram`.
@immutable
class InstagramStatus {
  const InstagramStatus({
    required this.enabled,
    required this.connected,
    this.username,
    this.accountType,
    this.profilePictureUrl,
    this.connectedAt,
    this.lastSyncedAt,
  });

  factory InstagramStatus.fromJson(Map<String, dynamic> json) {
    final username = _string(json['username']);
    return InstagramStatus(
      enabled: _bool(json['enabled']),
      connected: _bool(json['connected']),
      // Instagram handles never carry the "@"; strip one if the API sends it
      // so the UI can prefix its own.
      username: (username?.startsWith('@') ?? false)
          ? username!.substring(1)
          : username,
      accountType: _string(json['account_type'])?.toUpperCase(),
      profilePictureUrl: _string(json['profile_picture_url']),
      connectedAt: _date(json['connected_at']),
      lastSyncedAt: _date(json['last_synced_at']),
    );
  }

  /// Feature flag (`INSTAGRAM_ENABLED`, or the profile is a Meta app tester).
  /// When false the whole surface is hidden.
  final bool enabled;
  final bool connected;
  final String? username;

  /// `BUSINESS`, `MEDIA_CREATOR` or `PERSONAL` (upper-cased).
  final String? accountType;
  final String? profilePictureUrl;
  final DateTime? connectedAt;
  final DateTime? lastSyncedAt;

  /// Instagram only lets Professional (Business / Creator) accounts use the
  /// API. A connected account reported as personal cannot import anything.
  bool get isPersonalAccount => accountType == 'PERSONAL';
}

/// Instagram `media_type`.
enum InstagramMediaType {
  image,
  video,
  carouselAlbum;

  static InstagramMediaType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'VIDEO':
      case 'REELS':
        return InstagramMediaType.video;
      case 'CAROUSEL_ALBUM':
        return InstagramMediaType.carouselAlbum;
      default:
        return InstagramMediaType.image;
    }
  }
}

/// One item of `GET /api/v1/me/instagram/media`.
@immutable
class InstagramMedia {
  const InstagramMedia({
    required this.id,
    required this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.permalink,
    this.caption,
    this.timestamp,
    this.imported = false,
  });

  factory InstagramMedia.fromJson(Map<String, dynamic> json) => InstagramMedia(
    id: json['id']?.toString() ?? '',
    mediaType: InstagramMediaType.fromString(_string(json['media_type'])),
    mediaUrl: _string(json['media_url']),
    thumbnailUrl: _string(json['thumbnail_url']),
    permalink: _string(json['permalink']),
    caption: _string(json['caption']),
    timestamp: _date(json['timestamp']),
    imported: _bool(json['imported']),
  );

  final String id;
  final InstagramMediaType mediaType;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? permalink;
  final String? caption;
  final DateTime? timestamp;

  /// Already copied into Kolabing by an earlier import.
  final bool imported;

  bool get isVideo => mediaType == InstagramMediaType.video;
  bool get isCarousel => mediaType == InstagramMediaType.carouselAlbum;

  /// What to draw in a grid cell. A video's `media_url` is the mp4, so its
  /// thumbnail comes first; for images it is the other way round.
  String? get previewUrl =>
      isVideo ? (thumbnailUrl ?? mediaUrl) : (mediaUrl ?? thumbnailUrl);

  InstagramMedia copyWith({bool? imported}) => InstagramMedia(
    id: id,
    mediaType: mediaType,
    mediaUrl: mediaUrl,
    thumbnailUrl: thumbnailUrl,
    permalink: permalink,
    caption: caption,
    timestamp: timestamp,
    imported: imported ?? this.imported,
  );
}

/// A page of media, with the cursor for the next one (`null` = last page).
@immutable
class InstagramMediaPage {
  const InstagramMediaPage({required this.items, this.nextCursor});

  factory InstagramMediaPage.fromJson(Object? data) {
    // Accept `{items, next_cursor}` (the contract) and, defensively, a bare
    // list or a `data` list.
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{'items': data};
    final rawItems = map['items'] ?? map['data'];
    final items = <InstagramMedia>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          final media = InstagramMedia.fromJson(Map<String, dynamic>.from(raw));
          if (media.id.isNotEmpty) items.add(media);
        }
      }
    }
    final cursor = _string(map['next_cursor']);
    return InstagramMediaPage(
      items: items,
      nextCursor: (cursor == null || cursor.isEmpty) ? null : cursor,
    );
  }

  final List<InstagramMedia> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Result of `POST /api/v1/me/instagram/media/import`.
@immutable
class InstagramImportResult {
  const InstagramImportResult({required this.importedCount, this.skipped = 0});

  /// The contract returns the created gallery items. Accept a bare list, an
  /// `items` list, or an explicit `imported` count, plus an optional
  /// `skipped` / `failed` (count or list) for items the backend refused
  /// (gallery full, video too long, ...).
  factory InstagramImportResult.fromJson(Object? data) {
    if (data is List) {
      return InstagramImportResult(importedCount: data.length);
    }
    if (data is Map) {
      final items = data['items'] ?? data['gallery'] ?? data['photos'];
      final imported = data['imported'];
      final count = items is List
          ? items.length
          : (imported is List ? imported.length : _int(imported));
      return InstagramImportResult(
        importedCount: count,
        skipped: _countOf(data['skipped']) + _countOf(data['failed']),
      );
    }
    return const InstagramImportResult(importedCount: 0);
  }

  final int importedCount;
  final int skipped;
}

// -----------------------------------------------------------------------------
// Parsing helpers
// -----------------------------------------------------------------------------

String? _string(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return false;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int _countOf(Object? value) => value is List ? value.length : _int(value);

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
