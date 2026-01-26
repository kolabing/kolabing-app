/// Community type model from GET /community-types
class CommunityType {
  const CommunityType({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory CommunityType.fromJson(Map<String, dynamic> json) {
    // Support both old format (value/label) and new format (id/name/slug)
    final id = (json['id'] ?? json['value'])?.toString() ?? '';
    final name = (json['name'] ?? json['label'])?.toString() ?? '';
    // For old format, use value as slug; for new format, use slug
    final slug = (json['slug'] ?? json['value'])?.toString() ?? '';

    return CommunityType(
      id: id,
      name: name,
      slug: slug,
      icon: json['icon']?.toString(),
    );
  }

  final String id;
  final String name;
  final String slug;
  final String? icon;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        if (icon != null) 'icon': icon,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityType &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CommunityType(id: $id, name: $name, slug: $slug)';
}
