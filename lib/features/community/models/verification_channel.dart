/// A community verification / contact channel — a link, handle, address or
/// number the community supplies. Doubles as proof for the verified tick AND as
/// a public contact link the community may expose on its profile.
///
/// SHARED CONTRACT with the backend: a channel is
/// `{ "type": "<slug>", "url": "<string>", "is_public": <bool> }`. `is_public`
/// defaults to false. `email`/`phone` carry the address / number in `url`. The
/// supported types are the values of [VerificationChannelType]. Never rename the
/// wire slugs without a backend change.
enum VerificationChannelType {
  email,
  phone,
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

  /// Contact channels (email/phone) render in the "Contact" group; the rest
  /// render in the "Channels" group of the manage sheet.
  bool get isContact =>
      this == VerificationChannelType.email ||
      this == VerificationChannelType.phone;

  static VerificationChannelType? fromSlug(String? slug) {
    if (slug == null) return null;
    final normalized = slug.trim().toLowerCase();
    for (final type in VerificationChannelType.values) {
      if (type.slug == normalized) return type;
    }
    return null;
  }
}

/// A single verification/contact channel ({type, url, is_public}).
class VerificationChannel {
  const VerificationChannel({
    required this.type,
    required this.url,
    this.isPublic = false,
  });

  factory VerificationChannel.fromJson(Map<String, dynamic> json) {
    return VerificationChannel(
      type:
          VerificationChannelType.fromSlug(json['type']?.toString()) ??
          VerificationChannelType.website,
      url: json['url']?.toString() ?? '',
      isPublic: json['is_public'] as bool? ?? false,
    );
  }

  /// The channel kind (drives the icon + the validation rule).
  final VerificationChannelType type;

  /// The raw URL / handle / email / phone the community entered.
  final String url;

  /// Whether this channel is shown publicly on the community profile. Defaults
  /// to false — public exposure is opt-in, managed from the profile.
  final bool isPublic;

  Map<String, dynamic> toJson() => {
    'type': type.slug,
    'url': url,
    'is_public': isPublic,
  };

  VerificationChannel copyWith({
    VerificationChannelType? type,
    String? url,
    bool? isPublic,
  }) => VerificationChannel(
    type: type ?? this.type,
    url: url ?? this.url,
    isPublic: isPublic ?? this.isPublic,
  );

  /// Parse a list payload of channel objects, skipping malformed entries.
  /// Used for both `verification_channels` (owner, with is_public) and
  /// `public_channels` (everyone; is_public absent → treated as public here
  /// since the backend only emits public items in that array).
  static List<VerificationChannel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(VerificationChannel.fromJson)
        .where((c) => c.url.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Parse the `public_channels` array ({type,url}, no is_public). Marks every
  /// parsed entry as public so the public-icons row can render uniformly.
  static List<VerificationChannel> publicListFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(VerificationChannel.fromJson)
        .where((c) => c.url.trim().isNotEmpty)
        .map((c) => c.copyWith(isPublic: true))
        .toList(growable: false);
  }

  @override
  bool operator ==(Object other) =>
      other is VerificationChannel &&
      other.type == type &&
      other.url == url &&
      other.isPublic == isPublic;

  @override
  int get hashCode => Object.hash(type, url, isPublic);
}
