import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../../onboarding/models/city.dart';
import '../models/opportunity.dart';
import '../models/opportunity_filter.dart';
import '../../../config/constants/api.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Service for all opportunity API operations
class OpportunityService {
  OpportunityService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
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
  // Browse published opportunities
  // ---------------------------------------------------------------------------

  /// GET /api/v1/opportunities
  Future<PaginatedResponse<Opportunity>> getOpportunities({
    OpportunityFilters filters = const OpportunityFilters(),
    int page = 1,
    int perPage = 15,
  }) async {
    return _getOpportunities(
      filters: filters,
      page: page,
      perPage: perPage,
      allowRetry: true,
    );
  }

  Future<PaginatedResponse<Opportunity>> _getOpportunities({
    required OpportunityFilters filters,
    required int page,
    required int perPage,
    required bool allowRetry,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      ...filters.toQueryParameters(),
    };

    // Categories need array notation
    final categoryParams = filters.toCategoryParams();

    var uriString = '$_baseUrl/opportunities?';
    uriString += queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    if (categoryParams.isNotEmpty) {
      uriString += '&';
      uriString += categoryParams
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');
    }

    final uri = Uri.parse(uriString);
    debugPrint('OpportunityService: GET $uri');

    try {
      debugPrint('Browse: getting headers...');
      final headers = await _getHeaders();
      debugPrint('Browse: headers ready, making request...');
      final response = await _httpClient.get(uri, headers: headers);

      debugPrint('Browse response status: ${response.statusCode}');
      debugPrint(
        'Browse response body (first 500): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      );

      if (response.statusCode == 200) {
        return _parsePaginatedResponse(response.body);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _getOpportunities(
            filters: filters,
            page: page,
            perPage: perPage,
            allowRetry: false,
          );
        }
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
    } catch (e, st) {
      debugPrint('Browse opportunities error: $e');
      debugPrint('Browse stack: $st');
      throw NetworkException('Failed to load opportunities: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // My opportunities
  // ---------------------------------------------------------------------------

  /// GET /api/v1/me/opportunities
  Future<PaginatedResponse<Opportunity>> getMyOpportunities({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    return _getMyOpportunities(
      status: status,
      page: page,
      perPage: perPage,
      allowRetry: true,
    );
  }

  Future<PaginatedResponse<Opportunity>> _getMyOpportunities({
    String? status,
    required int page,
    required int perPage,
    required bool allowRetry,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null) 'status': status,
    };

    final uri = Uri.parse(
      '$_baseUrl/me/opportunities',
    ).replace(queryParameters: queryParams);
    debugPrint('OpportunityService: GET $uri');

    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      debugPrint('My opportunities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parsePaginatedResponse(response.body);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _getMyOpportunities(
            status: status,
            page: page,
            perPage: perPage,
            allowRetry: false,
          );
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get my opportunities error: $e');
      throw NetworkException('Failed to load your opportunities: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Single opportunity detail
  // ---------------------------------------------------------------------------

  /// GET /api/v1/opportunities/{id}
  Future<Opportunity> getOpportunity(String id) async {
    return _getOpportunity(id, allowRetry: true);
  }

  Future<Opportunity> _getOpportunity(
    String id, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/opportunities/$id');
    debugPrint('OpportunityService: GET $uri');

    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      debugPrint('Opportunity detail response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _getOpportunity(id, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(
            message: 'You are not authorized to view this opportunity.',
          ),
        );
      } else if (response.statusCode == 404) {
        throw const ApiException(
          error: ApiError(message: 'Opportunity not found.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get opportunity error: $e');
      throw NetworkException('Failed to load opportunity: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Create opportunity
  // ---------------------------------------------------------------------------

  /// POST /api/v1/opportunities
  Future<Opportunity> createOpportunity(Opportunity opportunity) async {
    return _createOpportunity(opportunity, allowRetry: true);
  }

  Future<Opportunity> _createOpportunity(
    Opportunity opportunity, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/opportunities');
    final body = jsonEncode(opportunity.toJson());
    debugPrint('OpportunityService: POST $uri');
    debugPrint('Request body: $body');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Create response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        return opportunity.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          status: OpportunityStatus.draft,
        );
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _createOpportunity(opportunity, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Create opportunity error: $e');
      throw NetworkException('Failed to create opportunity: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Update opportunity
  // ---------------------------------------------------------------------------

  /// PUT /api/v1/opportunities/{id}
  Future<Opportunity> updateOpportunity(
    String id,
    Opportunity opportunity,
  ) async {
    return _updateOpportunity(id, opportunity, allowRetry: true);
  }

  Future<Opportunity> _updateOpportunity(
    String id,
    Opportunity opportunity, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/opportunities/$id');
    final body = jsonEncode(opportunity.toJson());
    debugPrint('OpportunityService: PUT $uri');
    debugPrint('PUT body: $body');

    try {
      final response = await _httpClient.put(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Update response status: ${response.statusCode}');
      debugPrint(
        'Update response body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        return opportunity;
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _updateOpportunity(id, opportunity, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Update opportunity error: $e');
      throw NetworkException('Failed to update opportunity: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Publish opportunity
  // ---------------------------------------------------------------------------

  /// POST /api/v1/opportunities/{id}/publish
  ///
  /// Tries the dedicated publish endpoint first.
  /// Falls back to updating status via PUT if the publish endpoint returns 403.
  Future<Opportunity> publishOpportunity(String id) async {
    return _publishOpportunity(id, allowRetry: true);
  }

  Future<Opportunity> _publishOpportunity(
    String id, {
    required bool allowRetry,
  }) async {
    // First try the dedicated publish endpoint
    final uri = Uri.parse('$_baseUrl/opportunities/$id/publish');
    debugPrint('OpportunityService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Publish response status: ${response.statusCode}');
      debugPrint('Publish response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _publishOpportunity(id, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 405) {
        // Some environments expose only inline status updates.
        debugPrint(
          'Publish endpoint returned ${response.statusCode}, trying status update via PUT...',
        );
        return _publishViaStatusUpdate(id, allowRetry: allowRetry);
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
      debugPrint('Publish opportunity error: $e');
      throw NetworkException('Failed to publish opportunity: $e');
    }
  }

  /// Fallback: publish by updating the status field via PUT
  Future<Opportunity> _publishViaStatusUpdate(
    String id, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/opportunities/$id');
    final body = jsonEncode({'status': 'published'});
    debugPrint('OpportunityService: PUT $uri (status update fallback)');

    try {
      final response = await _httpClient.put(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Status update response status: ${response.statusCode}');
      debugPrint(
        'Status update response body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _publishViaStatusUpdate(id, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Status update publish error: $e');
      throw NetworkException('Failed to publish opportunity: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Close opportunity
  // ---------------------------------------------------------------------------

  /// POST /api/v1/opportunities/{id}/close
  Future<Opportunity> closeOpportunity(String id) async {
    return _closeOpportunity(id, allowRetry: true);
  }

  Future<Opportunity> _closeOpportunity(
    String id, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/opportunities/$id/close');
    debugPrint('OpportunityService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Close response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          return Opportunity.fromJson(data);
        }
        throw const NetworkException('Invalid response format');
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _closeOpportunity(id, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Close opportunity error: $e');
      throw NetworkException('Failed to close opportunity: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Delete opportunity
  // ---------------------------------------------------------------------------

  /// DELETE /api/v1/opportunities/{id}
  Future<void> deleteOpportunity(String id) async {
    return _deleteOpportunity(id, allowRetry: true);
  }

  Future<void> _deleteOpportunity(String id, {required bool allowRetry}) async {
    final uri = Uri.parse('$_baseUrl/opportunities/$id');
    debugPrint('OpportunityService: DELETE $uri');

    try {
      final response = await _httpClient.delete(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Delete response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _deleteOpportunity(id, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Delete opportunity error: $e');
      throw NetworkException('Failed to delete opportunity: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Cities
  // ---------------------------------------------------------------------------

  /// GET /api/v1/cities
  Future<List<OnboardingCity>> getCities() async {
    return _getCities(allowRetry: true);
  }

  Future<List<OnboardingCity>> _getCities({required bool allowRetry}) async {
    final uri = Uri.parse('$_baseUrl/cities');
    debugPrint('OpportunityService: GET $uri');

    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];
        return dataList
            .map(
              (item) => OnboardingCity.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _getCities(allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw const NetworkException('Failed to load cities');
      }
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get cities error: $e');
      throw NetworkException('Failed to load cities: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Response parsing helpers
  // ---------------------------------------------------------------------------

  PaginatedResponse<Opportunity> _parsePaginatedResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;

    // The API may return either:
    //   { "data": [...], "meta": { ... } }           — data is a list
    //   { "data": { "data": [...], "current_page": 1, ... } }  — Laravel paginator wrapped
    final rawData = json['data'];
    List<dynamic> dataList;
    Map<String, dynamic>? meta;

    if (rawData is List) {
      // data is directly a list — pagination info may be in "meta" or at root level
      dataList = rawData;
      meta = json['meta'] as Map<String, dynamic>? ?? json;
    } else if (rawData is Map<String, dynamic>) {
      // data is a Laravel paginator object
      dataList = rawData['data'] as List<dynamic>? ?? [];
      meta = rawData;
    } else {
      dataList = [];
      meta = json['meta'] as Map<String, dynamic>?;
    }

    debugPrint(
      'Parse: rawData type=${rawData.runtimeType}, dataList length=${dataList.length}, meta current_page=${meta?['current_page']}, last_page=${meta?['last_page']}, total=${meta?['total']}',
    );

    final opportunities = <Opportunity>[];
    for (var i = 0; i < dataList.length; i++) {
      try {
        final item = dataList[i];
        if (item is Map<String, dynamic>) {
          opportunities.add(Opportunity.fromJson(item));
        } else {
          debugPrint('Item $i is not a Map: ${item.runtimeType} => $item');
        }
      } catch (e, st) {
        final item = dataList[i];
        final title = item is Map ? item['title'] : 'unknown';
        final id = item is Map ? item['id'] : 'unknown';
        debugPrint('Error parsing opportunity[$i] (id=$id, title=$title): $e');
        debugPrint('Stack: $st');
        debugPrint(
          'Raw item keys: ${item is Map ? item.keys.toList() : 'N/A'}',
        );
      }
    }

    debugPrint(
      'Parsed ${opportunities.length} / ${dataList.length} opportunities',
    );

    return PaginatedResponse<Opportunity>(
      data: opportunities,
      currentPage: _safeInt(meta?['current_page']) ?? 1,
      lastPage: _safeInt(meta?['last_page']) ?? 1,
      total: _safeInt(meta?['total']) ?? opportunities.length,
    );
  }

  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
