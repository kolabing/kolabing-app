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
