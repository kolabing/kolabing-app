import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/attendee_profile_detail.dart';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Service for the Batch 4 attendee profile + events-attended endpoints.
class AttendeeProfileService {
  AttendeeProfileService({
    required AuthService authService,
    http.Client? httpClient,
  }) : _authService = authService,
       _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Fetch the rich attendee profile aggregate.
  ///
  /// GET /api/v1/profiles/{profile}/attendee
  Future<AttendeeProfileDetail> getAttendeeProfile(String profileId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AttendeeProfileException('Not authenticated');
    }

    final url = '$_baseUrl/profiles/$profileId/attendee';
    debugPrint('Get Attendee Profile: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'Get Attendee Profile response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AttendeeProfileDetail.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw AttendeeProfileException(
          json['message'] as String? ?? 'Failed to load attendee profile',
        );
      }
    } on AttendeeProfileException {
      rethrow;
    } catch (e) {
      debugPrint('Get Attendee Profile error: $e');
      throw AttendeeProfileException('Network error: $e');
    }
  }

  /// Fetch one page of the current user's events-attended history.
  ///
  /// GET /api/v1/me/events-attended?page={page}&per_page={perPage}
  Future<AttendedEventsPage> getMyEventsAttended({
    int page = 1,
    int perPage = 20,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AttendeeProfileException('Not authenticated');
    }

    final uri = Uri.parse('$_baseUrl/me/events-attended').replace(
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    debugPrint('Get My Events Attended: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'Get My Events Attended response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AttendedEventsPage.fromJson(json);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw AttendeeProfileException(
          json['message'] as String? ?? 'Failed to load events attended',
        );
      }
    } on AttendeeProfileException {
      rethrow;
    } catch (e) {
      debugPrint('Get My Events Attended error: $e');
      throw AttendeeProfileException('Network error: $e');
    }
  }
}

/// Exception for attendee profile operations.
class AttendeeProfileException implements Exception {
  const AttendeeProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
