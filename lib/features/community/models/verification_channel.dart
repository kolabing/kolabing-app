/// A community verification channel — a link/handle the community supplies as
/// proof it is real, reviewed by Kolabing to grant the verified tick.
///
/// SHARED CONTRACT with the backend: a channel is
/// `{ "type": "<slug>", "url": "<string>" }`. The eight supported types are the
/// values of [VerificationChannelType]. Never rename the wire slugs without a
/// backend change.
enum VerificationChannelType {
  instagram,
  strava,
  whatsapp,
  telegram,
  flaire,
  skool,
  tiktok,
  website;

  /// The backend wire slug for this type.
  String get slug => name;

  static VerificationChannelType? fromSlug(String? slug) {
    if (slug == null) return null;
    final normalized = slug.trim().toLowerCase();
    for (final type in VerificationChannelType.values) {
      if (type.slug == normalized) return type;
    }
    return null;
  }
}

/// A single verification channel ({type, url}).
class VerificationChannel {
  const VerificationChannel({required this.type, required this.url});

  factory VerificationChannel.fromJson(Map<String, dynamic> json) {
    return VerificationChannel(
      type:
          VerificationChannelType.fromSlug(json['type']?.toString()) ??
          VerificationChannelType.website,
      url: json['url']?.toString() ?? '',
    );
  }

  /// The channel kind (drives the icon + the validation rule).
  final VerificationChannelType type;

  /// The raw URL or handle the community entered.
  final String url;

  Map<String, dynamic> toJson() => {'type': type.slug, 'url': url};

  VerificationChannel copyWith({VerificationChannelType? type, String? url}) =>
      VerificationChannel(type: type ?? this.type, url: url ?? this.url);

  /// Parse a list payload of channel objects, skipping malformed entries.
  static List<VerificationChannel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(VerificationChannel.fromJson)
        .where((c) => c.url.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  bool operator ==(Object other) =>
      other is VerificationChannel && other.type == type && other.url == url;

  @override
  int get hashCode => Object.hash(type, url);
}
