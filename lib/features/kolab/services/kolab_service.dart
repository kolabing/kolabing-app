import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/kolab.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Service for Kolab CRUD operations via REST API.
class KolabService {
  KolabService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  @visibleForTesting
  AuthService get authService => _authService;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------

  /// POST /api/v1/kolabs
  Future<Kolab> create(Kolab kolab) async {
    return _create(kolab, allowRetry: true);
  }

  Future<Kolab> _create(Kolab kolab, {required bool allowRetry}) async {
    final uri = Uri.parse('$_baseUrl/kolabs');
    final body = jsonEncode(kolab.toJson());
    debugPrint('KolabService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Create kolab response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Kolab.fromJson(data);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _create(kolab, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 402) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(error: ApiError.fromJson(json, statusCode: 402));
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Create kolab error: $e');
      throw NetworkException('Failed to create kolab: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  /// PUT /api/v1/kolabs/{id}
  Future<Kolab> update(String id, Kolab kolab) async {
    return _update(id, kolab, allowRetry: true);
  }

  Future<Kolab> _update(
    String id,
    Kolab kolab, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/kolabs/$id');
    final body = jsonEncode(kolab.toJson());
    debugPrint('KolabService: PUT $uri');

    try {
      final response = await _httpClient.put(
        uri,
        headers: await _getHeaders(),
        body: body,
      );

      debugPrint('Update kolab response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Kolab.fromJson(data);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _update(id, kolab, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Update kolab error: $e');
      throw NetworkException('Failed to update kolab: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Publish
  // ---------------------------------------------------------------------------

  /// POST /api/v1/kolabs/{id}/publish
  ///
  /// [recipientCommunityId] scopes the publish to a direct proposal to that
  /// community (Send-Kolab CTA from a public community profile, C9).
  Future<Kolab> publish(
    String id,
    Kolab kolab, {
    String? recipientCommunityId,
  }) async {
    return _publish(
      id,
      kolab,
      recipientCommunityId: recipientCommunityId,
      allowRetry: true,
    );
  }

  Future<Kolab> _publish(
    String id,
    Kolab kolab, {
    String? recipientCommunityId,
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/kolabs/$id/publish');
    debugPrint(
      'KolabService: POST $uri '
      '(recipient=${recipientCommunityId ?? '-'})',
    );

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
        body: recipientCommunityId == null || recipientCommunityId.isEmpty
            ? null
            : jsonEncode({'recipient_community_id': recipientCommunityId}),
      );

      debugPrint('Publish kolab response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Kolab.fromJson(data);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _publish(
            id,
            kolab,
            recipientCommunityId: recipientCommunityId,
            allowRetry: false,
          );
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 402) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(error: ApiError.fromJson(json, statusCode: 402));
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Publish kolab error: $e');
      throw NetworkException('Failed to publish kolab: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Close
  // ---------------------------------------------------------------------------

  /// POST /api/v1/kolabs/{id}/close
  Future<Kolab> close(String id, Kolab kolab) async {
    return _close(id, kolab, allowRetry: true);
  }

  Future<Kolab> _close(
    String id,
    Kolab kolab, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/kolabs/$id/close');
    debugPrint('KolabService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Close kolab response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Kolab.fromJson(data);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _close(id, kolab, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Close kolab error: $e');
      throw NetworkException('Failed to close kolab: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // My Kolabs
  // ---------------------------------------------------------------------------

  /// GET /api/v1/kolabs/me
  Future<PaginatedKolabResponse> getMyKolabs({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    return _getMyKolabs(
      status: status,
      page: page,
      perPage: perPage,
      allowRetry: true,
    );
  }

  Future<PaginatedKolabResponse> _getMyKolabs({
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
      '$_baseUrl/kolabs/me',
    ).replace(queryParameters: queryParams);
    debugPrint('KolabService: GET $uri');

    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      debugPrint('My kolabs response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parsePaginatedResponse(response.body);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _getMyKolabs(
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
    } catch (e) {
      debugPrint('My kolabs error: $e');
      throw NetworkException('Failed to load kolabs: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Detail
  // ---------------------------------------------------------------------------

  /// GET /api/v1/kolabs/{id}
  Future<Kolab> getDetail(String id) async {
    return _getDetail(id, allowRetry: true);
  }

  Future<Kolab> _getDetail(String id, {required bool allowRetry}) async {
    final uri = Uri.parse('$_baseUrl/kolabs/$id');
    debugPrint('KolabService: GET $uri');

    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      debugPrint('Kolab detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Kolab.fromJson(data);
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _getDetail(id, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 404) {
        throw const ApiException(error: ApiError(message: 'Kolab not found.'));
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Kolab detail error: $e');
      throw NetworkException('Failed to load kolab: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  /// DELETE /api/v1/kolabs/{id}
  Future<void> delete(String id) async {
    return _delete(id, allowRetry: true);
  }

  Future<void> _delete(String id, {required bool allowRetry}) async {
    final uri = Uri.parse('$_baseUrl/kolabs/$id');
    debugPrint('KolabService: DELETE $uri');

    try {
      final response = await _httpClient.delete(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Delete kolab response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _delete(id, allowRetry: false);
        }
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(message: 'Cannot delete a published kolab.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Delete kolab error: $e');
      throw NetworkException('Failed to delete kolab: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Error parsing
  // ---------------------------------------------------------------------------

  PaginatedKolabResponse _parsePaginatedResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final rawData = json['data'];

    List<dynamic> dataList;
    Map<String, dynamic>? meta;

    if (rawData is List) {
      dataList = rawData;
      meta = json['meta'] as Map<String, dynamic>? ?? json;
    } else if (rawData is Map<String, dynamic>) {
      dataList = rawData['data'] as List<dynamic>? ?? const <dynamic>[];
      meta = rawData;
    } else {
      dataList = const <dynamic>[];
      meta = json['meta'] as Map<String, dynamic>?;
    }

    final kolabs = dataList
        .whereType<Map<String, dynamic>>()
        .map(Kolab.fromJson)
        .toList();

    return PaginatedKolabResponse(
      data: kolabs,
      currentPage: _safeInt(meta?['current_page']) ?? 1,
      lastPage: _safeInt(meta?['last_page']) ?? 1,
      total: _safeInt(meta?['total']) ?? kolabs.length,
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
    } catch (_) {
      return ApiException(
        error: ApiError(
          message: 'Server error (${response.statusCode})',
          statusCode: response.statusCode,
        ),
      );
    }
  }
}

class PaginatedKolabResponse {
  const PaginatedKolabResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<Kolab> data;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

final kolabServiceProvider = Provider<KolabService>(
  (ref) => KolabService(authService: ref.watch(authServiceProvider)),
);
