import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../models/business_type.dart';
import '../models/city.dart';
import '../models/community_type.dart';
import '../models/onboarding_state.dart';
import '../models/place_details_import.dart';
import '../models/place_suggestion.dart';
import '../../../config/constants/api.dart';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Mock mode flag - set to false to use real API
const bool _useMockApi = false;

/// Onboarding service for handling onboarding API calls
class OnboardingService {
  OnboardingService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  // ---------------------------------------------------------------------------
  // Lookup APIs
  // ---------------------------------------------------------------------------

  /// Get business types from API
  ///
  /// GET /lookup/business-types (current) or /business-types (future)
  Future<List<BusinessType>> getBusinessTypes() async {
    if (_useMockApi) {
      return _mockBusinessTypes();
    }

    try {
      // Try new endpoint first, fallback to old lookup endpoint
      var response = await _httpClient.get(
        Uri.parse('$_baseUrl/business-types'),
        headers: {'Accept': 'application/json'},
      );

      // Fallback to old lookup endpoint if new one returns 404
      if (response.statusCode == 404) {
        response = await _httpClient.get(
          Uri.parse('$_baseUrl/lookup/business-types'),
          headers: {'Accept': 'application/json'},
        );
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        return data
            .map((e) => BusinessType.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          error: ApiError.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Get business types error: $e');
      throw NetworkException('Failed to load business types: $e');
    }
  }

  /// Get community types from API
  ///
  /// GET /lookup/community-types (current) or /community-types (future)
  Future<List<CommunityType>> getCommunityTypes() async {
    if (_useMockApi) {
      return _mockCommunityTypes();
    }

    try {
      // Try new endpoint first, fallback to old lookup endpoint
      var response = await _httpClient.get(
        Uri.parse('$_baseUrl/community-types'),
        headers: {'Accept': 'application/json'},
      );

      // Fallback to old lookup endpoint if new one returns 404
      if (response.statusCode == 404) {
        response = await _httpClient.get(
          Uri.parse('$_baseUrl/lookup/community-types'),
          headers: {'Accept': 'application/json'},
        );
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        return data
            .map((e) => CommunityType.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          error: ApiError.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Get community types error: $e');
      throw NetworkException('Failed to load community types: $e');
    }
  }

  /// Get cities from API
  ///
  /// GET /cities
  /// Falls back to mock data if API returns empty
  Future<List<OnboardingCity>> getCities() async {
    if (_useMockApi) {
      return _mockCities();
    }

    final url = '$_baseUrl/cities';
    debugPrint('🌍 Cities API Request: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      debugPrint('🌍 Cities API Response Status: ${response.statusCode}');
      debugPrint(
        '🌍 Cities API Response Body (first 300 chars): ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        debugPrint('🌍 Cities parsed count: ${data.length}');

        final cities = data
            .map((e) => OnboardingCity.fromJson(e as Map<String, dynamic>))
            .toList();

        // Fallback to mock data if API returns empty
        if (cities.isEmpty) {
          debugPrint('🌍 Cities API returned empty, using mock data');
          return _mockCities();
        }

        debugPrint('🌍 Cities loaded successfully: ${cities.length} cities');
        return cities;
      } else {
        debugPrint('🌍 Cities API Error: ${response.statusCode}');
        throw ApiException(
          error: ApiError.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('🌍 Get cities error: $e');
      // Fallback to mock data on error
      return _mockCities();
    }
  }

  /// Search places for the business location autocomplete.
  ///
  /// Calls our backend `GET /v1/places/autocomplete?query={query}`.
  /// Returns an empty list if the request fails — no third-party fallback.
  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (_useMockApi) {
      final cities = await _mockCities();
      return cities
          .where(
            (city) =>
                city.name.toLowerCase().contains(query.toLowerCase()) ||
                (city.country?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .map(PlaceSuggestion.fromCity)
          .toList();
    }

    final url =
        '$_baseUrl/places/autocomplete?query=${Uri.encodeQueryComponent(query)}';
    debugPrint('📍 Place autocomplete request: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? const [];
        return data
            .map(
              (item) => PlaceSuggestion.fromJson(item as Map<String, dynamic>),
            )
            .where((item) => item.placeId.isNotEmpty)
            .toList();
      }
      debugPrint('📍 Place autocomplete error: ${response.statusCode}');
    } catch (e) {
      debugPrint('📍 Place autocomplete error: $e');
    }
    return const [];
  }

  /// Fetch full Google Place details via the backend proxy.
  ///
  /// GET /places/details?place_id={placeId}
  Future<PlaceDetailsImport> getPlaceDetails(String placeId) async {
    final url =
        '$_baseUrl/places/details?place_id=${Uri.encodeQueryComponent(placeId)}';
    debugPrint('📍 Place details request: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PlaceDetailsImport.fromJson(json);
      }

      if (response.statusCode == 503) {
        throw const PlaceImportUnavailableException();
      }

      throw ApiException(
        error: ApiError.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
          statusCode: response.statusCode,
        ),
      );
    } on PlaceImportUnavailableException {
      rethrow;
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('📍 Place details error: $e');
      throw NetworkException('Failed to import place details: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Onboarding APIs
  // ---------------------------------------------------------------------------

  /// Complete business onboarding
  ///
  /// PUT /onboarding/business
  /// New onboarding fields whose backend columns are being added separately.
  /// While the migration is in flight a 422 on ONLY these fields is tolerated
  /// by stripping them and retrying once (see [_putOnboarding]).
  static const Set<String> _onboardingFieldsToStrip = {
    'has_venue',
    'target_city_ids',
    'offering',
    'offer_photos',
    'community_size',
  };

  /// PUT an onboarding payload, tolerating not-yet-migrated fields.
  Future<void> _putOnboarding(
    String url,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpClient.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return;

    final apiError = ApiError.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      statusCode: response.statusCode,
    );

    if (response.statusCode == 422 &&
        apiError.errors != null &&
        apiError.errors!.isNotEmpty) {
      final failingKeys = apiError.errors!.keys
          .map((k) => k.split('.').first)
          .toSet();
      final onlyNewFields = failingKeys.isNotEmpty &&
          failingKeys.every(_onboardingFieldsToStrip.contains);
      final bodyHasNewFields =
          body.keys.any(_onboardingFieldsToStrip.contains);

      if (onlyNewFields && bodyHasNewFields) {
        debugPrint(
          'Onboarding PUT 422 on not-yet-migrated fields ($failingKeys) — '
          'stripping and retrying.',
        );
        final retryBody = Map<String, dynamic>.from(body)
          ..removeWhere((key, _) => _onboardingFieldsToStrip.contains(key));
        return _putOnboarding(url, token, retryBody);
      }
    }

    throw ApiException(error: apiError);
  }

  Future<void> completeBusinessOnboarding(
    String token,
    OnboardingData data,
  ) async {
    if (_useMockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      return;
    }

    try {
      await _putOnboarding(
        '$_baseUrl/onboarding/business',
        token,
        data.toBusinessPayload(),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Complete business onboarding error: $e');
      throw NetworkException('Failed to complete onboarding: $e');
    }
  }

  /// Complete community onboarding
  ///
  /// PUT /onboarding/community
  Future<void> completeCommunityOnboarding(
    String token,
    OnboardingData data,
  ) async {
    if (_useMockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      return;
    }

    try {
      await _putOnboarding(
        '$_baseUrl/onboarding/community',
        token,
        data.toCommunityPayload(),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Complete community onboarding error: $e');
      throw NetworkException('Failed to complete onboarding: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Mock Data
  // ---------------------------------------------------------------------------

  Future<List<BusinessType>> _mockBusinessTypes() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      BusinessType(id: '1', name: 'Cafe', slug: 'cafe', icon: '\u2615'),
      BusinessType(
        id: '2',
        name: 'Restaurant',
        slug: 'restaurant',
        icon: '\u{1F37D}',
      ),
      BusinessType(id: '3', name: 'Bar', slug: 'bar', icon: '\u{1F37A}'),
      BusinessType(id: '4', name: 'Bakery', slug: 'bakery', icon: '\u{1F950}'),
      BusinessType(
        id: '5',
        name: 'Coworking',
        slug: 'coworking',
        icon: '\u{1F4BC}',
      ),
      BusinessType(id: '6', name: 'Gym', slug: 'gym', icon: '\u{1F4AA}'),
      BusinessType(id: '7', name: 'Salon', slug: 'salon', icon: '\u{1F487}'),
      BusinessType(id: '8', name: 'Retail', slug: 'retail', icon: '\u{1F6CD}'),
      BusinessType(id: '9', name: 'Hotel', slug: 'hotel', icon: '\u{1F3E8}'),
      BusinessType(id: '10', name: 'Other', slug: 'other', icon: '\u{1F4E6}'),
    ];
  }

  Future<List<CommunityType>> _mockCommunityTypes() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      CommunityType(
        id: '1',
        name: 'Food Blogger',
        slug: 'food-blogger',
        icon: '\u{1F354}',
      ),
      CommunityType(
        id: '2',
        name: 'Lifestyle Influencer',
        slug: 'lifestyle-influencer',
        icon: '\u2728',
      ),
      CommunityType(
        id: '3',
        name: 'Fitness Enthusiast',
        slug: 'fitness-enthusiast',
        icon: '\u{1F4AA}',
      ),
      CommunityType(
        id: '4',
        name: 'Travel Blogger',
        slug: 'travel-blogger',
        icon: '\u2708',
      ),
      CommunityType(
        id: '5',
        name: 'Photographer',
        slug: 'photographer',
        icon: '\u{1F4F8}',
      ),
      CommunityType(
        id: '6',
        name: 'Local Explorer',
        slug: 'local-explorer',
        icon: '\u{1F5FA}',
      ),
      CommunityType(
        id: '7',
        name: 'Student',
        slug: 'student',
        icon: '\u{1F393}',
      ),
      CommunityType(
        id: '8',
        name: 'Professional',
        slug: 'professional',
        icon: '\u{1F4BC}',
      ),
      CommunityType(
        id: '9',
        name: 'Community Organizer',
        slug: 'community-organizer',
        icon: '\u{1F389}',
      ),
      CommunityType(id: '10', name: 'Other', slug: 'other', icon: '\u{1F4E6}'),
    ];
  }

  Future<List<OnboardingCity>> _mockCities() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      OnboardingCity(id: '1', name: 'Barcelona', country: 'Spain'),
      OnboardingCity(id: '2', name: 'Madrid', country: 'Spain'),
      OnboardingCity(id: '3', name: 'Valencia', country: 'Spain'),
      OnboardingCity(id: '4', name: 'Sevilla', country: 'Spain'),
      OnboardingCity(id: '5', name: 'Bilbao', country: 'Spain'),
      OnboardingCity(id: '6', name: 'Malaga', country: 'Spain'),
      OnboardingCity(id: '7', name: 'Granada', country: 'Spain'),
      OnboardingCity(id: '8', name: 'Zaragoza', country: 'Spain'),
      OnboardingCity(id: '9', name: 'Palma', country: 'Spain'),
      OnboardingCity(id: '10', name: 'Alicante', country: 'Spain'),
    ];
  }
}

class PlaceImportUnavailableException implements Exception {
  const PlaceImportUnavailableException();
}
