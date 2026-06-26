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

  Future<List<OfferOption>> getGoals() =>
      _fetch('lookup/goals', _fallbackGoals);

  Future<List<OfferOption>> getProductInteractions() =>
      _fetch('lookup/product-interactions', _fallbackProductInteractions);

  Future<List<OfferOption>> getVenueFits() =>
      _fetch('lookup/venue-fits', _fallbackVenueFits);

  Future<List<OfferOption>> getKolabHighlights() =>
      _fetch('lookup/kolab-highlights', _fallbackKolabHighlights);

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

  static const List<OfferOption> _fallbackGoals = [
    OfferOption(
      id: 'more_visits',
      slug: 'more_visits',
      name: 'More Visits',
      description: 'Bring a community to your space.',
    ),
    OfferOption(
      id: 'product_awareness',
      slug: 'product_awareness',
      name: 'Product Awareness',
      description: 'Get your product discovered by the right people.',
    ),
    OfferOption(
      id: 'content_tagged_posts',
      slug: 'content_tagged_posts',
      name: 'Content / Tagged Posts',
      description: 'Turn real experiences into social content.',
    ),
    OfferOption(
      id: 'reviews',
      slug: 'reviews',
      name: 'Reviews',
      description: 'Get honest feedback and social proof.',
    ),
    OfferOption(
      id: 'sales_revenue',
      slug: 'sales_revenue',
      name: 'Sales / Revenue',
      description: 'Drive direct spend or purchases.',
    ),
    OfferOption(
      id: 'community_event',
      slug: 'community_event',
      name: 'Community Event',
      description: 'Host a real-life moment with a group.',
    ),
    OfferOption(
      id: 'product_testing',
      slug: 'product_testing',
      name: 'Product Testing',
      description: 'Let people try it and share feedback.',
    ),
    OfferOption(
      id: 'recurring_partnership',
      slug: 'recurring_partnership',
      name: 'Recurring Partnership',
      description: 'Build an ongoing community relationship.',
    ),
    OfferOption(
      id: 'community_perk',
      slug: 'community_perk',
      name: 'Community Perk / Member Discount',
      description: 'Offer a discount or benefit to members.',
    ),
    OfferOption(
      id: 'open_to_ideas',
      slug: 'open_to_ideas',
      name: 'Open to Ideas',
      description: 'Let communities suggest the best format.',
    ),
  ];

  static const List<OfferOption> _fallbackProductInteractions = [
    OfferOption(id: 'try_samples', slug: 'try_samples', name: 'Try Samples'),
    OfferOption(id: 'review_it', slug: 'review_it', name: 'Review It'),
    OfferOption(id: 'create_content', slug: 'create_content', name: 'Create Content'),
    OfferOption(
      id: 'use_during_event',
      slug: 'use_during_event',
      name: 'Use During an Event',
    ),
    OfferOption(id: 'give_feedback', slug: 'give_feedback', name: 'Give Feedback'),
    OfferOption(id: 'giveaway', slug: 'giveaway', name: 'Offer as a Giveaway'),
    OfferOption(
      id: 'discount_code',
      slug: 'discount_code',
      name: 'Promote a Discount Code',
    ),
    OfferOption(
      id: 'sell_during_event',
      slug: 'sell_during_event',
      name: 'Sell During an Event',
    ),
    OfferOption(id: 'open_to_ideas', slug: 'open_to_ideas', name: 'Open to Ideas'),
  ];

  static const List<OfferOption> _fallbackVenueFits = [
    OfferOption(id: 'coffee', slug: 'coffee', name: 'Coffee'),
    OfferOption(id: 'brunch', slug: 'brunch', name: 'Brunch'),
    OfferOption(id: 'dinner', slug: 'dinner', name: 'Dinner'),
    OfferOption(id: 'drinks', slug: 'drinks', name: 'Drinks'),
    OfferOption(id: 'wellness', slug: 'wellness', name: 'Wellness'),
    OfferOption(id: 'shopping', slug: 'shopping', name: 'Shopping'),
    OfferOption(id: 'workshops', slug: 'workshops', name: 'Workshops'),
    OfferOption(id: 'content', slug: 'content', name: 'Content'),
    OfferOption(id: 'after_run', slug: 'after_run', name: 'After-Run'),
    OfferOption(id: 'after_work', slug: 'after_work', name: 'After-Work'),
    OfferOption(id: 'networking', slug: 'networking', name: 'Networking'),
    OfferOption(id: 'pop_ups', slug: 'pop_ups', name: 'Pop-Ups'),
    OfferOption(id: 'recurring_plans', slug: 'recurring_plans', name: 'Recurring Plans'),
  ];

  static const List<OfferOption> _fallbackKolabHighlights = [
    OfferOption(id: 'good_location', slug: 'good_location', name: 'Good Location'),
    OfferOption(
      id: 'nice_space_for_groups',
      slug: 'nice_space_for_groups',
      name: 'Nice Space for Groups',
    ),
    OfferOption(
      id: 'great_photo_spot',
      slug: 'great_photo_spot',
      name: 'Great Photo Spot',
    ),
    OfferOption(
      id: 'healthy_sporty_offer',
      slug: 'healthy_sporty_offer',
      name: 'Healthy / Sporty Offer',
    ),
    OfferOption(id: 'free_samples', slug: 'free_samples', name: 'Free Samples'),
    OfferOption(
      id: 'discount_for_members',
      slug: 'discount_for_members',
      name: 'Discount for Members',
    ),
    OfferOption(
      id: 'good_for_after_work',
      slug: 'good_for_after_work',
      name: 'Good for After-Work Plans',
    ),
    OfferOption(
      id: 'good_after_workout',
      slug: 'good_after_workout',
      name: 'Good After a Workout',
    ),
    OfferOption(
      id: 'recurring_kolabs',
      slug: 'recurring_kolabs',
      name: 'Can Host Recurring Kolabs',
    ),
    OfferOption(
      id: 'unique_experience',
      slug: 'unique_experience',
      name: 'Unique Experience',
    ),
    OfferOption(
      id: 'new_product_to_try',
      slug: 'new_product_to_try',
      name: 'New Product to Try',
    ),
    OfferOption(
      id: 'premium_experience',
      slug: 'premium_experience',
      name: 'Premium Experience',
    ),
    OfferOption(
      id: 'easy_public_transport',
      slug: 'easy_public_transport',
      name: 'Easy to Reach by Public Transport',
    ),
    OfferOption(
      id: 'outdoor_friendly',
      slug: 'outdoor_friendly',
      name: 'Outdoor-Friendly',
    ),
    OfferOption(
      id: 'cozy_indoor_space',
      slug: 'cozy_indoor_space',
      name: 'Cozy Indoor Space',
    ),
    OfferOption(id: 'good_for_content', slug: 'good_for_content', name: 'Good for Content'),
  ];
}
