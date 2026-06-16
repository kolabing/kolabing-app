import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../models/offer_option.dart';

/// Fetches the three admin-managed kolab offer taxonomies from the public
/// lookup endpoints:
///   - GET /lookup/offerings
///   - GET /lookup/deliverables
///   - GET /lookup/needs
///
/// SELF-GATING: each method falls back to the hardcoded launch list when the
/// endpoint isn't deployed yet (404) or the request fails, so the app keeps
/// working pre-deploy. The fallback slugs MUST match the backend seeder.
class OfferOptionService {
  OfferOptionService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const String _baseUrl = ApiConfig.baseUrl;

  Future<List<OfferOption>> getOfferings() =>
      _fetch('lookup/offerings', _fallbackOfferings);

  Future<List<OfferOption>> getDeliverables() =>
      _fetch('lookup/deliverables', _fallbackDeliverables);

  Future<List<OfferOption>> getNeeds() => _fetch('lookup/needs', _fallbackNeeds);

  Future<List<OfferOption>> getProductTypes() =>
      _fetch('lookup/product-types', _fallbackProductTypes);

  Future<List<OfferOption>> getVenueTypes() =>
      _fetch('lookup/venue-types', _fallbackVenueTypes);

  Future<List<OfferOption>> _fetch(
    String path,
    List<OfferOption> fallback,
  ) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/$path'),
        headers: {'Accept': 'application/json'},
      );

      // Endpoint not deployed yet -> use the hardcoded list.
      if (response.statusCode == 404) {
        return fallback;
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (json['data'] as List<dynamic>? ?? [])
            .map((e) => OfferOption.fromJson(e as Map<String, dynamic>))
            .toList();
        // Never let a successful-but-empty response blank the picker.
        return data.isNotEmpty ? data : fallback;
      }

      return fallback;
    } on Exception catch (e) {
      debugPrint('OfferOptionService.$path error: $e — using fallback');
      return fallback;
    }
  }

  // ---------------------------------------------------------------------------
  // Hardcoded fallbacks (slugs identical to the backend OfferOptionSeeder).
  // ---------------------------------------------------------------------------

  static const List<OfferOption> _fallbackOfferings = [
    OfferOption(id: 'venue', slug: 'venue', name: 'Venue'),
    OfferOption(id: 'venue_space', slug: 'venue_space', name: 'Venue Space'),
    OfferOption(id: 'food_drink', slug: 'food_drink', name: 'Food & Drink'),
    OfferOption(id: 'free_drinks', slug: 'free_drinks', name: 'Free Drinks'),
    OfferOption(id: 'discount', slug: 'discount', name: 'Discount'),
    OfferOption(id: 'products', slug: 'products', name: 'Products'),
    OfferOption(id: 'social_media', slug: 'social_media', name: 'Social Media'),
    OfferOption(
      id: 'content_creation',
      slug: 'content_creation',
      name: 'Content Creation',
    ),
    OfferOption(id: 'sponsorship', slug: 'sponsorship', name: 'Sponsorship'),
    OfferOption(id: 'other', slug: 'other', name: 'Other'),
  ];

  static const List<OfferOption> _fallbackDeliverables = [
    OfferOption(id: 'social_media', slug: 'social_media', name: 'Social Media'),
    OfferOption(
      id: 'event_activation',
      slug: 'event_activation',
      name: 'Event Activation',
    ),
    OfferOption(
      id: 'product_placement',
      slug: 'product_placement',
      name: 'Product Placement',
    ),
    OfferOption(
      id: 'community_reach',
      slug: 'community_reach',
      name: 'Community Reach',
    ),
    OfferOption(
      id: 'review_feedback',
      slug: 'review_feedback',
      name: 'Review & Feedback',
    ),
  ];

  static const List<OfferOption> _fallbackNeeds = [
    OfferOption(id: 'venue', slug: 'venue', name: 'Venue'),
    OfferOption(id: 'food_drink', slug: 'food_drink', name: 'Food & Drink'),
    OfferOption(id: 'sponsor', slug: 'sponsor', name: 'Sponsor'),
    OfferOption(id: 'products', slug: 'products', name: 'Products'),
    OfferOption(id: 'discount', slug: 'discount', name: 'Discount'),
    OfferOption(id: 'other', slug: 'other', name: 'Other'),
  ];

  // Slugs identical to ProductType.toApiValue() so storage never regresses
  // when the endpoint isn't deployed yet.
  static const List<OfferOption> _fallbackProductTypes = [
    OfferOption(id: 'food_product', slug: 'food_product', name: 'Food Product'),
    OfferOption(id: 'beverage', slug: 'beverage', name: 'Beverage'),
    OfferOption(
      id: 'health_beauty',
      slug: 'health_beauty',
      name: 'Health & Beauty',
    ),
    OfferOption(
      id: 'sports_equipment',
      slug: 'sports_equipment',
      name: 'Sports Equipment',
    ),
    OfferOption(id: 'fashion', slug: 'fashion', name: 'Fashion'),
    OfferOption(id: 'tech_gadget', slug: 'tech_gadget', name: 'Tech Gadget'),
    OfferOption(
      id: 'experience_service',
      slug: 'experience_service',
      name: 'Experience / Service',
    ),
    OfferOption(id: 'other', slug: 'other', name: 'Other'),
  ];

  // Slugs identical to VenueType.toApiValue().
  static const List<OfferOption> _fallbackVenueTypes = [
    OfferOption(id: 'restaurant', slug: 'restaurant', name: 'Restaurant'),
    OfferOption(id: 'cafe', slug: 'cafe', name: 'Cafe'),
    OfferOption(id: 'bar_lounge', slug: 'bar_lounge', name: 'Bar & Lounge'),
    OfferOption(id: 'hotel', slug: 'hotel', name: 'Hotel'),
    OfferOption(id: 'coworking', slug: 'coworking', name: 'Coworking'),
    OfferOption(
      id: 'sports_facility',
      slug: 'sports_facility',
      name: 'Sports Facility',
    ),
    OfferOption(id: 'event_space', slug: 'event_space', name: 'Event Space'),
    OfferOption(id: 'rooftop', slug: 'rooftop', name: 'Rooftop'),
    OfferOption(id: 'beach_club', slug: 'beach_club', name: 'Beach Club'),
    OfferOption(id: 'retail_store', slug: 'retail_store', name: 'Retail Store'),
    OfferOption(id: 'other', slug: 'other', name: 'Other'),
  ];
}
