import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/offer_option.dart';
import '../services/offer_option_service.dart';

/// Service provider for the kolab offer taxonomies.
final offerOptionServiceProvider = Provider<OfferOptionService>(
  (ref) => OfferOptionService(),
);

/// Business "offering" options — what a business offers (`offering[]`).
///
/// Admin-managed via /admin/offer-options; fetched from `GET /lookup/offerings`,
/// self-gating to the hardcoded launch list when the endpoint isn't deployed.
final offeringsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getOfferings(),
);

/// "Deliverable" options — offered in return (community `offers_in_return[]` /
/// business `expects[]`). From `GET /lookup/deliverables`.
final deliverablesProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getDeliverables(),
);

/// "Need" options — what a community asks for (`needs[]`). From `GET /lookup/needs`.
final needsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getNeeds(),
);

/// "Product type" options — the category of product/service a business promotes
/// (kolab `product_type`, business onboarding product path). From
/// `GET /lookup/product-types`. Self-gating to the hardcoded list on 404/empty.
final productTypesProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getProductTypes(),
);

/// "Venue type" options — the kind of venue a business runs (business
/// onboarding venue path, kolab `venue_type`). From `GET /lookup/venue-types`.
final venueTypesProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getVenueTypes(),
);
