import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../models/business_type.dart';
import '../models/city.dart';
import '../models/community_type.dart';
import '../models/onboarding_state.dart';
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
        headers: {
          'Accept': 'application/json',
        },
      );

      // Fallback to old lookup endpoint if new one returns 404
      if (response.statusCode == 404) {
        response = await _httpClient.get(
          Uri.parse('$_baseUrl/lookup/business-types'),
          headers: {
            'Accept': 'application/json',
          },
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
        headers: {
          'Accept': 'application/json',
        },
      );

      // Fallback to old lookup endpoint if new one returns 404
      if (response.statusCode == 404) {
        response = await _httpClient.get(
          Uri.parse('$_baseUrl/lookup/community-types'),
          headers: {
            'Accept': 'application/json',
          },
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
        headers: {
          'Accept': 'application/json',
        },
      );

      debugPrint('🌍 Cities API Response Status: ${response.statusCode}');
      debugPrint('🌍 Cities API Response Body (first 300 chars): ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');

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

  // ---------------------------------------------------------------------------
  // Onboarding APIs
  // ---------------------------------------------------------------------------

  /// Complete business onboarding
  ///
  /// POST /onboarding/business
  Future<void> completeBusinessOnboarding(
    String token,
    OnboardingData data,
  ) async {
    if (_useMockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      return;
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/onboarding/business'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data.toBusinessPayload()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          error: ApiError.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('Complete business onboarding error: $e');
      throw NetworkException('Failed to complete onboarding: $e');
    }
  }

  /// Complete community onboarding
  ///
  /// POST /onboarding/community
  Future<void> completeCommunityOnboarding(
    String token,
    OnboardingData data,
  ) async {
    if (_useMockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      return;
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/onboarding/community'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data.toCommunityPayload()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          error: ApiError.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            statusCode: response.statusCode,
          ),
        );
      }
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
      BusinessType(id: '2', name: 'Restaurant', slug: 'restaurant', icon: '\u{1F37D}'),
      BusinessType(id: '3', name: 'Bar', slug: 'bar', icon: '\u{1F37A}'),
      BusinessType(id: '4', name: 'Bakery', slug: 'bakery', icon: '\u{1F950}'),
      BusinessType(id: '5', name: 'Coworking', slug: 'coworking', icon: '\u{1F4BC}'),
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
      CommunityType(id: '1', name: 'Food Blogger', slug: 'food-blogger', icon: '\u{1F354}'),
      CommunityType(id: '2', name: 'Lifestyle Influencer', slug: 'lifestyle-influencer', icon: '\u2728'),
      CommunityType(id: '3', name: 'Fitness Enthusiast', slug: 'fitness-enthusiast', icon: '\u{1F4AA}'),
      CommunityType(id: '4', name: 'Travel Blogger', slug: 'travel-blogger', icon: '\u2708'),
      CommunityType(id: '5', name: 'Photographer', slug: 'photographer', icon: '\u{1F4F8}'),
      CommunityType(id: '6', name: 'Local Explorer', slug: 'local-explorer', icon: '\u{1F5FA}'),
      CommunityType(id: '7', name: 'Student', slug: 'student', icon: '\u{1F393}'),
      CommunityType(id: '8', name: 'Professional', slug: 'professional', icon: '\u{1F4BC}'),
      CommunityType(id: '9', name: 'Community Organizer', slug: 'community-organizer', icon: '\u{1F389}'),
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
