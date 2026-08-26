import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/dashboard_model.dart';
import '../../../config/constants/api.dart';
import '../../auth/models/user_model.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Dashboard API response that holds either business or community data
class DashboardResponse {
  const DashboardResponse({this.businessDashboard, this.communityDashboard});

  final BusinessDashboard? businessDashboard;
  final CommunityDashboard? communityDashboard;

  bool get isBusiness => businessDashboard != null;
  bool get isCommunity => communityDashboard != null;
}

/// Service for dashboard API operations
class DashboardService {
  DashboardService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function() request, {
    required bool allowRetry,
  }) async {
    final response = await request();
    if (response.statusCode == 401 && allowRetry) {
      await _authService.refreshSession();
      return _sendWithRefresh(request, allowRetry: false);
    }
    return response;
  }

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
  /// [userType] decides which shape to parse. It must come from the signed-in
  /// user, NOT from the payload: the previous version keyed off
  /// `data.containsKey('opportunities')`, and when the backend gave communities
  /// an `opportunities` block for parity (kolabing-v2#227) every community
  /// started being parsed as a business. `communityDashboard` came back null,
  /// the screen showed "Unable to load dashboard data", and because the request
  /// was a clean 200 with valid JSON there was no exception anywhere — nothing
  /// in either Sentry project, nothing in the backend logs.
  ///
  /// Sniffing is kept only as a fallback for a null [userType], so a role we
  /// cannot read still renders something.
  Future<DashboardResponse> getDashboard({UserType? userType}) async {
    return _getDashboard(allowRetry: true, userType: userType);
  }

  Future<DashboardResponse> _getDashboard({
    required bool allowRetry,
    UserType? userType,
  }) async {
    final uri = Uri.parse('$_baseUrl/me/dashboard');
    debugPrint('DashboardService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: allowRetry,
      );

      debugPrint('Dashboard response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;

        if (data == null) {
          throw const NetworkException('Invalid response format');
        }

        // The signed-in role decides, because the two payloads are no longer
        // distinguishable by their keys.
        if (userType == UserType.business) {
          return DashboardResponse(
            businessDashboard: BusinessDashboard.fromJson(data),
          );
        }
        if (userType == UserType.community) {
          return DashboardResponse(
            communityDashboard: CommunityDashboard.fromJson(data),
          );
        }

        // Role unknown — fall back to shape. `applications_sent` is checked
        // FIRST because it is the community marker that businesses never send,
        // while `opportunities` is now sent to both.
        if (data.containsKey('applications_sent')) {
          return DashboardResponse(
            communityDashboard: CommunityDashboard.fromJson(data),
          );
        } else if (data.containsKey('opportunities')) {
          return DashboardResponse(
            businessDashboard: BusinessDashboard.fromJson(data),
          );
        } else {
          // Fallback: try to parse as business first, then community
          debugPrint(
            'DashboardService: Unknown dashboard shape, '
            'attempting business parse',
          );
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
