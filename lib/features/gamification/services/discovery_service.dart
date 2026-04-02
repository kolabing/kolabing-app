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
  DiscoveryService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Discover nearby events based on GPS location
  ///
  /// GET /api/v1/events/discover?lat={lat}&lng={lng}&radius_km={radius}&page={page}&limit={limit}
  Future<DiscoveredEventsResponse> discoverEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const DiscoveryException('Not authenticated');
    }

    final queryParams = {
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius_km': radiusKm.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$_baseUrl/events/discover')
        .replace(queryParameters: queryParams);
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
            json['data'] as Map<String, dynamic>);
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
