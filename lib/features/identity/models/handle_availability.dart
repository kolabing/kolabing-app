import 'package:flutter/foundation.dart';

/// Result of `GET /handle/available?handle=<h>` (identity contract §1):
/// `{ available: bool, suggestions: [..] }`.
@immutable
class HandleAvailability {
  const HandleAvailability({required this.available, this.suggestions = const []});

  factory HandleAvailability.fromJson(Map<String, dynamic> json) =>
      HandleAvailability(
        available: json['available'] as bool? ?? false,
        suggestions:
            (json['suggestions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  final bool available;
  final List<String> suggestions;
}
