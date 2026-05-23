import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../application/services/application_service.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/app_notification.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Service for notification API operations.
class NotificationService {
  NotificationService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  @visibleForTesting
  AuthService get authService => _authService;

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
  // GET /api/v1/me/notifications
  // ---------------------------------------------------------------------------

  /// Fetch paginated notifications for the current user.
  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final uri = Uri.parse(
      '$_baseUrl/me/notifications',
    ).replace(queryParameters: queryParams);
    debugPrint('NotificationService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Notifications response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parsePaginatedResponse(response.body);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get notifications error: $e');
      throw NetworkException('Failed to load notifications: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // GET /api/v1/me/notifications/unread-count
  // ---------------------------------------------------------------------------

  /// Get unread notification count for badge display.
  Future<int> getUnreadCount() async {
    final uri = Uri.parse('$_baseUrl/me/notifications/unread-count');
    debugPrint('NotificationService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Unread count response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        return data?['count'] as int? ?? 0;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get unread count error: $e');
      throw NetworkException('Failed to get unread count: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // POST /api/v1/me/notifications/{id}/read
  // ---------------------------------------------------------------------------

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    final uri = Uri.parse('$_baseUrl/me/notifications/$notificationId/read');
    debugPrint('NotificationService: POST $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.post(
          uri,
          headers: await _getHeaders(),
        ),
        allowRetry: true,
      );

      debugPrint('Mark as read response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(
            message: 'You are not authorized to access this notification.',
          ),
        );
      } else if (response.statusCode == 404) {
        throw const ApiException(
          error: ApiError(message: 'Notification not found.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Mark as read error: $e');
      throw NetworkException('Failed to mark notification as read: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // POST /api/v1/me/notifications/read-all
  // ---------------------------------------------------------------------------

  /// Mark all notifications as read. Returns the number of updated notifications.
  Future<int> markAllAsRead() async {
    final uri = Uri.parse('$_baseUrl/me/notifications/read-all');
    debugPrint('NotificationService: POST $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.post(
          uri,
          headers: await _getHeaders(),
        ),
        allowRetry: true,
      );

      debugPrint('Mark all as read response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        return data?['updated_count'] as int? ?? 0;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Mark all as read error: $e');
      throw NetworkException('Failed to mark all notifications as read: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Response parsing helpers
  // ---------------------------------------------------------------------------

  PaginatedResponse<AppNotification> _parsePaginatedResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    // Handle Laravel pagination structure
    final rawData = json['data'];
    List<dynamic> dataList;
    Map<String, dynamic>? meta;

    if (rawData is List) {
      dataList = rawData;
      meta = json['meta'] as Map<String, dynamic>?;
    } else if (rawData is Map<String, dynamic>) {
      dataList = rawData['data'] as List<dynamic>? ?? [];
      meta = rawData;
    } else {
      dataList = [];
      meta = json['meta'] as Map<String, dynamic>?;
    }

    debugPrint('Parse notifications: dataList length=${dataList.length}');

    final notifications = <AppNotification>[];
    for (final item in dataList) {
      try {
        notifications.add(
          AppNotification.fromJson(item as Map<String, dynamic>),
        );
      } catch (e, st) {
        debugPrint('Error parsing notification: $e');
        debugPrint('Stack: $st');
      }
    }

    debugPrint(
      'Parsed ${notifications.length} / ${dataList.length} notifications',
    );

    return PaginatedResponse<AppNotification>(
      data: notifications,
      currentPage: meta?['current_page'] as int? ?? 1,
      lastPage: meta?['last_page'] as int? ?? 1,
      total: meta?['total'] as int? ?? notifications.length,
    );
  }

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
