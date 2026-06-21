import '../config/constants/api.dart';

String normalizeRemoteMediaUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  if (trimmed.startsWith('data:')) {
    return trimmed;
  }

  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) {
    return trimmed;
  }

  final origin = Uri.parse('${ApiConfig.baseUrl}/');
  return origin.resolve(trimmed).toString();
}

/// Nullable variant for model fields: returns null for null/empty input,
/// otherwise the absolute URL. Use in `fromJson` so relative photo paths
/// (profile photos, avatars, offer photos) render instead of failing.
String? normalizeRemoteMediaUrlOrNull(String? rawUrl) {
  if (rawUrl == null) return null;
  final normalized = normalizeRemoteMediaUrl(rawUrl);
  return normalized.isEmpty ? null : normalized;
}
