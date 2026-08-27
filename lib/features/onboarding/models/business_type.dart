/// Business type model from GET /business-types
class BusinessType {
  const BusinessType({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.iconUrl,
    this.appliesTo = 'both',
  });

  factory BusinessType.fromJson(Map<String, dynamic> json) {
    // Support both old format (value/label) and new format (id/name/slug)
    final id = (json['id'] ?? json['value'])?.toString() ?? '';
    final name = (json['name'] ?? json['label'])?.toString() ?? '';
    // For old format, use value as slug; for new format, use slug
    final slug = (json['slug'] ?? json['value'])?.toString() ?? '';

    return BusinessType(
      id: id,
      name: name,
      slug: slug,
      icon: json['icon']?.toString(),
      iconUrl: json['icon_url']?.toString(),
      appliesTo: (json['applies_to']?.toString() ?? 'both'),
    );
  }

  final String id;
  final String name;
  final String slug;
  final String? icon;

  /// Admin-uploaded SVG URL (for types with no bundled asset).
  final String? iconUrl;

  /// Which onboarding path this category applies to: `venue`, `product`, or
  /// `both` (default). Used to filter category pills so a product/service
  /// business does not see venue-only categories (and vice versa). Backend
  /// source: `business_types.applies_to` (exposed by /lookup/business-types).
  final String appliesTo;

  /// True when this category should be offered on the VENUE onboarding path.
  bool get isForVenue => appliesTo == 'venue' || appliesTo == 'both';

  /// True when this category should be offered on the PRODUCT/service path.
  bool get isForProduct => appliesTo == 'product' || appliesTo == 'both';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    if (icon != null) 'icon': icon,
    if (iconUrl != null) 'icon_url': iconUrl,
    'applies_to': appliesTo,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessType &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BusinessType(id: $id, name: $name, slug: $slug)';
}
