import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/dashboard_model.dart';
import '../../../config/constants/api.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Dashboard API response that holds either business or community data
class DashboardResponse {
  const DashboardResponse({
    this.businessDashboard,
    this.communityDashboard,
  });

  final BusinessDashboard? businessDashboard;
  final CommunityDashboard? communityDashboard;

  bool get isBusiness => businessDashboard != null;
  bool get isCommunity => communityDashboard != null;
}

/// Service for dashboard API operations
class DashboardService {
  DashboardService({
    AuthService? authService,
    http.Client? httpClient,
  })  : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  // ---------------------------------------------------------------------------
  // Auth headers
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // GET /me/dashboard
  // ---------------------------------------------------------------------------

  /// Fetch dashboard data for the current user.
  ///
  /// The API returns different payloads depending on user type:
  /// - Business users: contains `opportunities` key
  /// - Community users: contains `applications_sent` key
  Future<DashboardResponse> getDashboard() async {
    final uri = Uri.parse('$_baseUrl/me/dashboard');
    debugPrint('DashboardService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Dashboard response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;

        if (data == null) {
          throw const NetworkException('Invalid response format');
        }

        // Determine user type from the response payload
        if (data.containsKey('opportunities')) {
          return DashboardResponse(
            businessDashboard: BusinessDashboard.fromJson(data),
          );
        } else if (data.containsKey('applications_sent')) {
          return DashboardResponse(
            communityDashboard: CommunityDashboard.fromJson(data),
          );
        } else {
          // Fallback: try to parse as business first, then community
          debugPrint('DashboardService: Unknown dashboard shape, '
              'attempting business parse');
          return DashboardResponse(
            businessDashboard: BusinessDashboard.fromJson(data),
          );
        }
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Dashboard error: $e');
      throw NetworkException('Failed to load dashboard: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ApiException _parseApiError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiException(
        error: ApiError.fromJson(json, statusCode: response.statusCode),
      );
    } on Exception {
      return ApiException(
        error: ApiError(
          message: 'Request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        ),
      );
    }
  }
}
