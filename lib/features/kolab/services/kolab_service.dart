import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../../../config/constants/api.dart';
import '../models/kolab.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Service for Kolab CRUD operations via REST API.
class KolabService {
  KolabService({
    AuthService? authService,
    http.Client? httpClient,
  })  : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

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
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 402) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: 402),
        );
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
  Future<Kolab> publish(String id, Kolab kolab) async {
    final uri = Uri.parse('$_baseUrl/kolabs/$id/publish');
    debugPrint('KolabService: POST $uri');

    try {
      final response = await _httpClient.post(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Publish kolab response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Kolab.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 402) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: 402),
        );
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
  Future<List<Kolab>> getMyKolabs({String? status}) async {
    final queryParams = <String, String>{
      if (status != null) 'status': status,
    };

    final uri = Uri.parse('$_baseUrl/kolabs/me').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    debugPrint('KolabService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('My kolabs response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List;
        return data
            .map((e) => Kolab.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
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
    final uri = Uri.parse('$_baseUrl/kolabs/$id');
    debugPrint('KolabService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Kolab detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Kolab.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 404) {
        throw const ApiException(
          error: ApiError(message: 'Kolab not found.'),
        );
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

final kolabServiceProvider = Provider<KolabService>((ref) => KolabService());
