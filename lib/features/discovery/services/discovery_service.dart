import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/discovery_filters.dart';
import '../models/discovery_item.dart';

const String _baseUrl = ApiConfig.baseUrl;

class DiscoveryService {
  DiscoveryService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  AuthService get authService => _authService;

  Future<PaginatedResponse<DiscoveryItem>> getOpportunities({
    DiscoveryFilters filters = const DiscoveryFilters(),
    int page = 1,
    int perPage = 15,
  }) => _getOpportunities(
    filters: filters,
    page: page,
    perPage: perPage,
    allowRetry: true,
  );

  Future<PaginatedResponse<DiscoveryItem>> _getOpportunities({
    required DiscoveryFilters filters,
    required int page,
    required int perPage,
    required bool allowRetry,
  }) async {
    final baseParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      ...filters.toQueryParameters(),
    };
    final arrayParams = filters.toArrayParameters();

    var uriString = '$_baseUrl/discovery/opportunities?';
    uriString += baseParams.entries
        .map(
          (MapEntry<String, String> entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    if (arrayParams.isNotEmpty) {
      uriString += '&';
      uriString += arrayParams
          .map(
            (MapEntry<String, String> entry) =>
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
          )
          .join('&');
    }

    final uri = Uri.parse(uriString);

    try {
      final response = await _httpClient.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return _parsePaginatedResponse(response.body);
      }
      if (response.statusCode == 401) {
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
      }

      throw _parseApiError(response);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('DiscoveryService error: $e');
      throw NetworkException('Failed to load Kolabs: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  PaginatedResponse<DiscoveryItem> _parsePaginatedResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final payload = (json['data'] as Map<String, dynamic>?) ?? json;
    final items = (payload['data'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DiscoveryItem.fromJson)
        .toList();

    final meta = (payload['meta'] as Map<String, dynamic>?) ?? payload;

    return PaginatedResponse<DiscoveryItem>(
      data: items,
      currentPage: _parseInt(meta['current_page']) ?? 1,
      lastPage: _parseInt(meta['last_page']) ?? 1,
      total: _parseInt(meta['total']) ?? items.length,
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
          message: 'Unexpected error (${response.statusCode})',
          statusCode: response.statusCode,
        ),
      );
    }
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
