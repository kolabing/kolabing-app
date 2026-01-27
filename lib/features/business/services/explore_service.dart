import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/collab_request.dart';

/// API configuration
const String _baseUrl =
    'https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1';

/// Mock mode flag - set to true to use mock data instead of real API
const bool _useMockApi = false;

/// Service for fetching collaboration requests for the Business Explore screen
class ExploreService {
  ExploreService({
    AuthService? authService,
    http.Client? httpClient,
  })  : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Singleton instance for backward compatibility with providers
  static final ExploreService instance = ExploreService();

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetches all available opportunities from the API
  ///
  /// Business users browse opportunities posted by communities.
  /// GET /api/v1/opportunities
  ///
  /// [query] - Optional search query to filter results
  /// [collabType] - Optional filter by collaboration type
  /// [location] - Optional filter by location
  Future<List<CollabRequest>> getCollabRequests({
    String? query,
    CollabType? collabType,
    String? location,
  }) async {
    if (_useMockApi) {
      return _getMockCollabRequests(
        query: query,
        collabType: collabType,
        location: location,
      );
    }

    // Build query parameters
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) {
      queryParams['search'] = query;
    }
    if (collabType != null) {
      queryParams['type'] = collabType.toApiValue();
    }
    if (location != null && location.isNotEmpty) {
      queryParams['location'] = location;
    }

    final uri = Uri.parse('$_baseUrl/opportunities').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    debugPrint('Explore: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Explore response status: ${response.statusCode}');

      debugPrint('Explore response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];

        debugPrint('Explore: Found ${dataList.length} opportunities');

        final results = <CollabRequest>[];
        for (final item in dataList) {
          try {
            results.add(CollabRequest.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Error parsing opportunity: $e');
            debugPrint('Item data: $item');
          }
        }
        return results;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Get collab requests error: $e');
      throw NetworkException('Failed to load collaboration requests: $e');
    }
  }

  /// Returns a list of available cities for filtering
  Future<List<String>> getAvailableLocations() async {
    if (_useMockApi) {
      return _getMockLocations();
    }

    try {
      // Get cities from the lookup endpoint
      final uri = Uri.parse('$_baseUrl/cities');
      debugPrint('Explore: GET $uri');

      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Cities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];

        final cities = dataList
            .map((item) {
              if (item is String) return item;
              if (item is Map<String, dynamic>) {
                return item['name'] as String? ?? item['city'] as String? ?? '';
              }
              return '';
            })
            .where((loc) => loc.isNotEmpty)
            .toList()
          ..sort();

        debugPrint('Found ${cities.length} cities');
        return cities;
      }

      // If dedicated endpoint doesn't exist, get unique locations from collab requests
      debugPrint('Cities endpoint failed, extracting from opportunities');
      final requests = await getCollabRequests();
      return requests
          .map((request) => request.location)
          .where((loc) => loc != 'Unknown')
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      debugPrint('Get locations error: $e');
      // Return empty list instead of mock
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Mock Data (for development and fallback)
  // ---------------------------------------------------------------------------

  /// Mock implementation for collaboration requests
  Future<List<CollabRequest>> _getMockCollabRequests({
    String? query,
    CollabType? collabType,
    String? location,
  }) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 800));

    var results = _mockCollabRequests;

    // Apply search query filter
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results
          .where((request) =>
              request.title.toLowerCase().contains(lowerQuery) ||
              request.description.toLowerCase().contains(lowerQuery) ||
              request.communityName.toLowerCase().contains(lowerQuery) ||
              request.location.toLowerCase().contains(lowerQuery))
          .toList();
    }

    // Apply collab type filter
    if (collabType != null) {
      results =
          results.where((request) => request.collabType == collabType).toList();
    }

    // Apply location filter
    if (location != null && location.isNotEmpty) {
      final lowerLocation = location.toLowerCase();
      results = results
          .where((request) =>
              request.location.toLowerCase().contains(lowerLocation))
          .toList();
    }

    return results;
  }

  /// Mock locations
  Future<List<String>> _getMockLocations() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockCollabRequests
        .map((request) => request.location)
        .toSet()
        .toList()
      ..sort();
  }

  /// Mock data for collaboration requests
  static final List<CollabRequest> _mockCollabRequests = [
    CollabRequest(
      id: 'collab_001',
      communityName: 'Barcelona Foodies',
      communityUsername: 'bcn_foodies',
      title: 'Restaurant Week Promotion',
      description:
          'Looking for restaurants to participate in our annual Barcelona Restaurant Week. We have 50K+ engaged food enthusiasts ready to discover new culinary experiences in the city.',
      collabType: CollabType.event,
      location: 'Barcelona',
      startDate: DateTime(2026, 3, 15),
      endDate: DateTime(2026, 3, 22),
      status: CollabStatus.active,
      hasReward: true,
      rewardDescription: 'Featured spotlight on our social channels (200K reach)',
    ),
    CollabRequest(
      id: 'collab_002',
      communityName: 'FitLife Madrid',
      communityUsername: 'fitlife_madrid',
      title: 'Gym Partnership for Monthly Challenges',
      description:
          'Seeking fitness centers and gyms to partner with for our monthly fitness challenges. Our community of 30K members are always looking for new places to train.',
      collabType: CollabType.partnership,
      location: 'Madrid',
      startDate: DateTime(2026, 2, 1),
      status: CollabStatus.published,
    ),
    CollabRequest(
      id: 'collab_003',
      communityName: 'Valencia Dance Collective',
      communityUsername: 'valencia_dance',
      title: 'Summer Dance Festival Sponsors',
      description:
          'Our annual summer dance festival needs sponsors! Join 5,000+ dance enthusiasts for an unforgettable weekend of performances, workshops, and networking.',
      collabType: CollabType.event,
      location: 'Valencia',
      startDate: DateTime(2026, 7, 10),
      endDate: DateTime(2026, 7, 12),
      status: CollabStatus.active,
      hasReward: true,
      rewardDescription: 'Logo placement and VIP booth at the festival',
    ),
    CollabRequest(
      id: 'collab_004',
      communityName: 'Tech Nomads BCN',
      communityUsername: 'technomads_bcn',
      title: 'Co-working Space Partnership',
      description:
          'Looking for co-working spaces to offer exclusive deals to our community of 15K+ digital nomads and remote workers based in Barcelona.',
      collabType: CollabType.partnership,
      location: 'Barcelona',
      startDate: DateTime(2026, 2, 15),
      status: CollabStatus.active,
      hasReward: true,
      rewardDescription: 'Monthly newsletter feature to our 15K subscribers',
    ),
    CollabRequest(
      id: 'collab_005',
      communityName: 'Sustainable Living ES',
      communityUsername: 'sustainable_es',
      title: 'Eco-Friendly Product Launch Campaign',
      description:
          'We are launching a campaign to promote sustainable businesses in Spain. Looking for eco-friendly brands to feature in our content series.',
      collabType: CollabType.campaign,
      location: 'Barcelona',
      startDate: DateTime(2026, 4, 22),
      endDate: DateTime(2026, 5, 22),
      status: CollabStatus.published,
      hasReward: true,
      rewardDescription: 'Dedicated video review and social media coverage',
    ),
    CollabRequest(
      id: 'collab_006',
      communityName: 'Madrid Wine Club',
      communityUsername: 'madrid_wine',
      title: 'Wine Tasting Event Series',
      description:
          'Looking for wineries and wine bars to host our monthly wine tasting events. Our members are passionate wine lovers with high purchasing power.',
      collabType: CollabType.event,
      location: 'Madrid',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 12, 31),
      status: CollabStatus.active,
    ),
    CollabRequest(
      id: 'collab_007',
      communityName: 'Pet Parents Valencia',
      communityUsername: 'petparents_vlc',
      title: 'Pet-Friendly Businesses Directory',
      description:
          'Building a comprehensive directory of pet-friendly establishments in Valencia. Restaurants, hotels, and shops that welcome pets are invited to join.',
      collabType: CollabType.partnership,
      location: 'Valencia',
      startDate: DateTime(2026, 2, 1),
      status: CollabStatus.active,
      hasReward: true,
      rewardDescription: 'Featured listing and social media promotion',
    ),
    CollabRequest(
      id: 'collab_008',
      communityName: 'Barcelona Runners',
      communityUsername: 'bcn_runners',
      title: 'Marathon Training Camp Sponsors',
      description:
          'Our annual marathon training camp needs sponsors for hydration stations, nutrition, and gear. Join 2,000+ runners preparing for the Barcelona Marathon.',
      collabType: CollabType.campaign,
      location: 'Barcelona',
      startDate: DateTime(2026, 1, 15),
      endDate: DateTime(2026, 3, 15),
      status: CollabStatus.active,
      hasReward: true,
      rewardDescription: 'Brand visibility at all training sessions and finish line',
    ),
    CollabRequest(
      id: 'collab_009',
      communityName: 'Flamenco Sevilla',
      communityUsername: 'flamenco_sevilla',
      title: 'Cultural Partnership for Dance Shows',
      description:
          'Traditional flamenco dance group seeking venues and cultural centers for regular performances. We bring authentic Spanish culture to your establishment.',
      collabType: CollabType.partnership,
      location: 'Sevilla',
      startDate: DateTime(2026, 2, 1),
      status: CollabStatus.published,
    ),
    CollabRequest(
      id: 'collab_010',
      communityName: 'Healthy Eats Malaga',
      communityUsername: 'healthyeats_malaga',
      title: 'Health Food Week Campaign',
      description:
          'Organizing a week-long campaign promoting healthy eating in Malaga. Looking for restaurants, cafes, and health food stores to participate with special menus.',
      collabType: CollabType.campaign,
      location: 'Malaga',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 5, 7),
      status: CollabStatus.active,
      hasReward: true,
      rewardDescription: 'Coverage across our 25K follower Instagram account',
    ),
  ];
}
