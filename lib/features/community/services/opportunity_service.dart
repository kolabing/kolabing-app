import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../../onboarding/models/city.dart';
import '../models/opportunity.dart';

/// API configuration
const String _baseUrl =
    'https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1';

/// Service for managing opportunities (collaboration requests)
class OpportunityService {
  OpportunityService({
    AuthService? authService,
    http.Client? httpClient,
  })  : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Singleton instance
  static final OpportunityService instance = OpportunityService();

  /// Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch available cities for the form
  Future<List<OnboardingCity>> getCities() async {
    final uri = Uri.parse('$_baseUrl/cities');
    debugPrint('OpportunityService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Cities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];

        return dataList
            .map((item) => OnboardingCity.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw NetworkException('Failed to load cities');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Get cities error: $e');
      throw NetworkException('Failed to load cities: $e');
    }
  }

  /// Create a new opportunity
  Future<Opportunity> createOpportunity(Opportunity opportunity) async {
    final uri = Uri.parse('$_baseUrl/opportunities');
    debugPrint('OpportunityService: POST $uri');
    debugPrint('Request body: ${jsonEncode(opportunity.toJson())}');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(opportunity.toJson()),
      );

      debugPrint('Create opportunity response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        // If no data returned, return the original with a generated ID
        return opportunity.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          status: OpportunityStatus.published,
        );
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
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
      debugPrint('Create opportunity error: $e');
      throw NetworkException('Failed to create opportunity: $e');
    }
  }

  /// Update an existing opportunity
  Future<Opportunity> updateOpportunity(Opportunity opportunity) async {
    if (opportunity.id == null) {
      throw ArgumentError('Opportunity ID is required for update');
    }

    final uri = Uri.parse('$_baseUrl/opportunities/${opportunity.id}');
    debugPrint('OpportunityService: PUT $uri');

    try {
      final response = await _httpClient.put(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(opportunity.toJson()),
      );

      debugPrint('Update opportunity response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        return opportunity;
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
      debugPrint('Update opportunity error: $e');
      throw NetworkException('Failed to update opportunity: $e');
    }
  }

  /// Get user's opportunities
  Future<List<Opportunity>> getMyOpportunities() async {
    final uri = Uri.parse('$_baseUrl/me/opportunities');
    debugPrint('OpportunityService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('My opportunities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];

        return dataList
            .map((item) => Opportunity.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw NetworkException('Failed to load opportunities');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Get my opportunities error: $e');
      throw NetworkException('Failed to load opportunities: $e');
    }
  }

  /// Delete an opportunity
  Future<void> deleteOpportunity(String id) async {
    final uri = Uri.parse('$_baseUrl/opportunities/$id');
    debugPrint('OpportunityService: DELETE $uri');

    try {
      final response = await _httpClient.delete(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Delete opportunity response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw NetworkException('Failed to delete opportunity');
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Delete opportunity error: $e');
      throw NetworkException('Failed to delete opportunity: $e');
    }
  }
}
