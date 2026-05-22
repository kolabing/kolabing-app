String formatProfileTypeLabel(String value) {
  final normalized = value.replaceAll(RegExp('[_-]+'), ' ').trim();
  if (normalized.isEmpty) {
    return value.trim();
  }

  return normalized
      .split(RegExp(r'\s+'))
      .map(_formatProfileTypeWord)
      .join(' ');
}

String _formatProfileTypeWord(String word) {
  if (word.isEmpty) {
    return word;
  }

  if (word == word.toLowerCase() || word == word.toUpperCase()) {
    final lower = word.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  return '${word[0].toUpperCase()}${word.substring(1)}';
}
