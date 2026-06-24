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

/// "Goal" options — what a business Kolab is meant to achieve. From
/// `GET /lookup/goals`.
final goalsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getGoals(),
);

/// "Product interaction" options — how communities can engage with a product
/// promotion. From `GET /lookup/product-interactions`.
final productInteractionsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getProductInteractions(),
);

/// "Venue fit" options — the venue-promotion "Best for:" chips. From
/// `GET /lookup/venue-fits`.
final venueFitsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getVenueFits(),
);

/// "Kolab highlight" options — "Why communities will like this" chips. From
/// `GET /lookup/kolab-highlights`.
final kolabHighlightsProvider = FutureProvider.autoDispose<List<OfferOption>>(
  (ref) => ref.watch(offerOptionServiceProvider).getKolabHighlights(),
);
