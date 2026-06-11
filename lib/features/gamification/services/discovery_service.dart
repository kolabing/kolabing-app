import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/discovered_event.dart';
import '../../../config/constants/api.dart';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Service for handling event discovery operations
class DiscoveryService {
  DiscoveryService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Discover events.
  ///
  /// Supports two complementary modes (the backend accepts either; the app
  /// self-gates new params, so an undeployed backend simply ignores them and
  /// still returns a list):
  /// - Geo: `lat` + `lng` (+ `radius_km`).
  /// - City: `city_id` (the attendee's / a browsed city).
  /// Plus optional filters: `date` (`today` | `week` | `weekend` | `month`;
  /// omit for `upcoming` = all future) and `type` (a host community_type slug).
  ///
  /// GET /api/v1/events/discover?lat&lng&radius_km&city_id&date&type&page&limit
  Future<DiscoveredEventsResponse> discoverEvents({
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
    String? cityId,
    String? date,
    String? typeSlug,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const DiscoveryException('Not authenticated');
    }

    final queryParams = <String, String>{
      if (latitude != null) 'lat': latitude.toString(),
      if (longitude != null) 'lng': longitude.toString(),
      if (latitude != null && longitude != null)
        'radius_km': radiusKm.toString(),
      if (cityId != null && cityId.isNotEmpty) 'city_id': cityId,
      if (date != null && date.isNotEmpty) 'date': date,
      if (typeSlug != null && typeSlug.isNotEmpty) 'type': typeSlug,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$_baseUrl/events/discover',
    ).replace(queryParameters: queryParams);
    debugPrint('Discover Events: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('Discover Events response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DiscoveredEventsResponse.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw DiscoveryException(
          json['message'] as String? ?? 'Failed to discover events',
        );
      }
    } on DiscoveryException {
      rethrow;
    } catch (e) {
      debugPrint('Discover Events error: $e');
      throw DiscoveryException('Network error: $e');
    }
  }
}

/// Exception for discovery operations
class DiscoveryException implements Exception {
  const DiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}
