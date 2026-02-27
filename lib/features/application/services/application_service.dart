import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/application.dart';

/// API base URL
const String _baseUrl =
    'https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1';

/// Service for application API operations
class ApplicationService {
  ApplicationService({
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
  // Submit Application
  // ---------------------------------------------------------------------------

  /// POST /api/v1/opportunities/{id}/applications
  /// Apply to an opportunity
  Future<Application> submitApplication({
    required String opportunityId,
    required String message,
    required String availability,
  }) async {
    final uri = Uri.parse('$_baseUrl/opportunities/$opportunityId/applications');
    final body = jsonEncode({
      'message': message,
      'availability': availability,
    });

    debugPrint('ApplicationService: POST $uri');
    debugPrint('Request body: $body');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Submit application response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Application.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 422) {
        throw _parseApiError(response);
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Submit application error: $e');
      throw NetworkException('Failed to submit application: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // My Applications (Sent)
  // ---------------------------------------------------------------------------

  /// GET /api/v1/me/applications
  /// Get list of applications sent by current user
  Future<PaginatedResponse<Application>> getMyApplications({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null) 'status': status,
    };

    final uri = Uri.parse('$_baseUrl/me/applications').replace(
      queryParameters: queryParams,
    );
    debugPrint('ApplicationService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('My applications response status: ${response.statusCode}');

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
      debugPrint('Get my applications error: $e');
      throw NetworkException('Failed to load applications: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Received Applications (For opportunity owners)
  // ---------------------------------------------------------------------------

  /// GET /api/v1/me/received-applications
  /// Get list of applications received for your opportunities
  Future<PaginatedResponse<Application>> getReceivedApplications({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null) 'status': status,
    };

    final uri = Uri.parse('$_baseUrl/me/received-applications').replace(
      queryParameters: queryParams,
    );
    debugPrint('ApplicationService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Received applications response status: ${response.statusCode}');

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
      debugPrint('Get received applications error: $e');
      throw NetworkException('Failed to load received applications: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Single Application Detail
  // ---------------------------------------------------------------------------

  /// GET /api/v1/applications/{id}
  /// Get application details with chat messages
  Future<Application> getApplication(String id) async {
    final uri = Uri.parse('$_baseUrl/applications/$id');
    debugPrint('ApplicationService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Application detail response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Application.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(message: 'You are not authorized to view this application.'),
        );
      } else if (response.statusCode == 404) {
        throw const ApiException(
          error: ApiError(message: 'Application not found.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get application error: $e');
      throw NetworkException('Failed to load application: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Accept Application
  // ---------------------------------------------------------------------------

  /// POST /api/v1/applications/{id}/accept
  /// Accept an application (for opportunity owners)
  /// Requires scheduled_date and contact_methods (object with whatsapp/email/instagram)
  Future<Application> acceptApplication(
    String id, {
    required String scheduledDate,
    required Map<String, String> contactMethods,
  }) async {
    final uri = Uri.parse('$_baseUrl/applications/$id/accept');
    final body = jsonEncode({
      'scheduled_date': scheduledDate,
      'contact_methods': contactMethods,
    });

    debugPrint('ApplicationService: POST $uri');
    debugPrint('Accept request body: $body');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Accept application response status: ${response.statusCode}');
      debugPrint('Accept application response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          // Response nests under data.application
          final appJson = data['application'];
          if (appJson is Map<String, dynamic>) {
            return Application.fromJson(appJson);
          }
          // Fallback: data itself is the application
          return Application.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw _parseApiError(response);
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Accept application error: $e');
      throw NetworkException('Failed to accept application: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Decline Application
  // ---------------------------------------------------------------------------

  /// POST /api/v1/applications/{id}/decline
  /// Decline an application (for opportunity owners)
  Future<Application> declineApplication(String id, {String? reason}) async {
    final uri = Uri.parse('$_baseUrl/applications/$id/decline');
    final body = reason != null ? jsonEncode({'reason': reason}) : null;
    debugPrint('ApplicationService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Decline application response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Application.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(message: 'You are not authorized to decline this application.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Decline application error: $e');
      throw NetworkException('Failed to decline application: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Withdraw Application
  // ---------------------------------------------------------------------------

  /// POST /api/v1/applications/{id}/withdraw
  /// Withdraw your own application
  Future<Application> withdrawApplication(String id) async {
    final uri = Uri.parse('$_baseUrl/applications/$id/withdraw');
    debugPrint('ApplicationService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Withdraw application response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Application.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(message: 'You are not authorized to withdraw this application.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Withdraw application error: $e');
      throw NetworkException('Failed to withdraw application: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Chat Messages
  // ---------------------------------------------------------------------------

  /// GET /api/v1/applications/{id}/messages
  /// Get chat messages for an application (paginated)
  Future<PaginatedResponse<ChatMessage>> getMessages({
    required String applicationId,
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final uri = Uri.parse('$_baseUrl/applications/$applicationId/messages')
        .replace(queryParameters: queryParams);
    debugPrint('ApplicationService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Get messages response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parsePaginatedMessagesResponse(response.body);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(message: 'You are not authorized to view these messages.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get messages error: $e');
      throw NetworkException('Failed to load messages: $e');
    }
  }

  /// POST /api/v1/applications/{id}/messages
  /// Send a message to an application chat
  Future<ChatMessage> sendMessage({
    required String applicationId,
    required String content,
  }) async {
    // Validate content length
    if (content.isEmpty) {
      throw const ApiException(
        error: ApiError(message: 'Message content cannot be empty.'),
      );
    }
    if (content.length > 5000) {
      throw const ApiException(
        error: ApiError(message: 'Message content cannot exceed 5000 characters.'),
      );
    }

    final uri = Uri.parse('$_baseUrl/applications/$applicationId/messages');
    final body = jsonEncode({'content': content});

    debugPrint('ApplicationService: POST $uri');
    debugPrint('Request body: $body');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Send message response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ChatMessage.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(message: 'You are not authorized to send messages.'),
        );
      } else if (response.statusCode == 422) {
        throw _parseApiError(response);
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Send message error: $e');
      throw NetworkException('Failed to send message: $e');
    }
  }

  /// POST /api/v1/applications/{id}/messages/read
  /// Mark all messages as read for an application
  Future<int> markAsRead(String applicationId) async {
    final uri = Uri.parse('$_baseUrl/applications/$applicationId/messages/read');
    debugPrint('ApplicationService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Mark as read response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          return _safeInt(data['marked_count'], 0);
        }
        return 0;
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
      debugPrint('Mark as read error: $e');
      throw NetworkException('Failed to mark messages as read: $e');
    }
  }

  /// GET /api/v1/me/unread-messages-count
  /// Get unread message count across all applications
  Future<UnreadMessagesCount> getUnreadMessagesCount() async {
    final uri = Uri.parse('$_baseUrl/me/unread-messages-count');
    debugPrint('ApplicationService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Unread count response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return UnreadMessagesCount.fromJson(data);
        }
        return const UnreadMessagesCount(total: 0, byApplication: {});
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
  // Response parsing helpers
  // ---------------------------------------------------------------------------

  PaginatedResponse<Application> _parsePaginatedResponse(String body) {
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

    debugPrint('Parse applications: dataList length=${dataList.length}');

    final applications = <Application>[];
    for (var i = 0; i < dataList.length; i++) {
      try {
        final item = dataList[i];
        if (item is Map<String, dynamic>) {
          applications.add(Application.fromJson(item));
        } else {
          debugPrint('Application item $i is not a Map: ${item.runtimeType}');
        }
      } catch (e, st) {
        final item = dataList[i];
        final id = item is Map ? item['id'] : 'unknown';
        debugPrint('Error parsing application[$i] (id=$id): $e');
        debugPrint('Stack: $st');
      }
    }

    debugPrint('Parsed ${applications.length} / ${dataList.length} applications');

    // Use meta if available, otherwise fall back to root json
    final paginationSource = meta ?? json;

    return PaginatedResponse<Application>(
      data: applications,
      currentPage: _safeInt(paginationSource['current_page'], 1),
      lastPage: _safeInt(paginationSource['last_page'], 1),
      total: _safeInt(paginationSource['total'], applications.length),
    );
  }

  PaginatedResponse<ChatMessage> _parsePaginatedMessagesResponse(String body) {
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

    debugPrint('Parse messages: dataList length=${dataList.length}');

    final messages = <ChatMessage>[];
    for (var i = 0; i < dataList.length; i++) {
      try {
        final item = dataList[i];
        if (item is Map<String, dynamic>) {
          messages.add(ChatMessage.fromJson(item));
        } else {
          debugPrint('Message item $i is not a Map: ${item.runtimeType}');
        }
      } catch (e, st) {
        debugPrint('Error parsing message[$i]: $e');
        debugPrint('Stack: $st');
      }
    }

    debugPrint('Parsed ${messages.length} / ${dataList.length} messages');

    final paginationSource = meta ?? json;

    return PaginatedResponse<ChatMessage>(
      data: messages,
      currentPage: _safeInt(paginationSource['current_page'], 1),
      lastPage: _safeInt(paginationSource['last_page'], 1),
      total: _safeInt(paginationSource['total'], messages.length),
    );
  }

  static int _safeInt(dynamic value, int defaultValue) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
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

/// Paginated response wrapper
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
