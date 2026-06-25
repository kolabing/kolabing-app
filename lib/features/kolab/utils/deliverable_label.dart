import '../models/offer_option.dart';

/// Resolves a `deliverable` slug (`expects[]` / `offers_in_return[]`) to a
/// display label using the admin-managed options already fetched from
/// `deliverablesProvider`. Falls back to a humanized version of the slug
/// itself for any value not present in that list — never silently relabels
/// an unrecognized slug as a different, unrelated option.
String deliverableLabel(String slug, List<OfferOption> options) {
  for (final option in options) {
    if (option.slug == slug) return option.name;
  }
  return _humanizeSlug(slug);
}

String _humanizeSlug(String slug) => slug
    .split(RegExp('[_-]'))
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
    .join(' ');
