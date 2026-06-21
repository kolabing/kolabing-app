import 'package:flutter/foundation.dart';

/// An admin-managed option from one of the kolab offer taxonomies, served by
/// `GET /lookup/{offerings,deliverables,needs}`.
///
/// - offering    -> what a business offers (`offering[]`)
/// - deliverable -> offered in return (community `offers_in_return[]` /
///   business `expects[]`)
/// - need        -> what a community asks for (`needs[]`)
///
/// `slug` is the wire value (sent in the payload); `name`/`label` is display.
@immutable
class OfferOption {
  const OfferOption({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.iconUrl,
  });

  factory OfferOption.fromJson(Map<String, dynamic> json) {
    // Support both value/label (legacy) and id/name/slug (current).
    final id = (json['id'] ?? json['value'])?.toString() ?? '';
    final name = (json['name'] ?? json['label'])?.toString() ?? '';
    final slug = (json['slug'] ?? json['value'])?.toString() ?? '';

    return OfferOption(
      id: id,
      name: name,
      slug: slug,
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      iconUrl: json['icon_url']?.toString(),
    );
  }

  final String id;
  final String name;
  final String slug;
  final String? description;

  /// Lucide icon name (when the option maps to a bundled icon).
  final String? icon;

  /// Admin-uploaded SVG URL (for options with no bundled asset).
  final String? iconUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferOption &&
          runtimeType == other.runtimeType &&
          slug == other.slug;

  @override
  int get hashCode => slug.hashCode;

  @override
  String toString() => 'OfferOption(slug: $slug, name: $name)';
}
