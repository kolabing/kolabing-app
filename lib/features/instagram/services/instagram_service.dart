import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/instagram_models.dart';

/// API configuration.
const String _baseUrl = ApiConfig.baseUrl;

/// Instagram Connect endpoints (kolabing-v2 `feat/instagram-connect`).
///
/// All responses are wrapped `{"success": true, "data": ...}`.
///
/// Graceful degradation: `GET /me/instagram` answering 403/404 (endpoint not
/// deployed yet, or a role without a gallery) resolves to `null`, which the UI
/// treats as "hide the Instagram card". Every other failure throws
/// [InstagramException].
class InstagramService {
  InstagramService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// GET /api/v1/me/instagram
  Future<InstagramStatus?> getStatus() async {
    final data = await _send('GET', '/me/instagram', hideOnMissing: true);
    if (data is! Map) return null;
    return InstagramStatus.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST /api/v1/me/instagram/connect-url → the Instagram authorize URL.
  Future<Uri> getConnectUrl() async {
    final data = await _send('POST', '/me/instagram/connect-url');
    final raw = data is Map ? data['url']?.toString() : null;
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw const InstagramException('Invalid connect URL');
    }
    return uri;
  }

  /// GET /api/v1/me/instagram/media?cursor=
  Future<InstagramMediaPage> getMedia({String? cursor}) async {
    final query = (cursor == null || cursor.isEmpty)
        ? ''
        : '?cursor=${Uri.encodeQueryComponent(cursor)}';
    final data = await _send('GET', '/me/instagram/media$query');
    return InstagramMediaPage.fromJson(data);
  }

  /// POST /api/v1/me/instagram/media/import
  Future<InstagramImportResult> importMedia(
    List<String> ids, {
    String target = 'gallery',
    String? kolabId,
  }) async {
    final data = await _send(
      'POST',
      '/me/instagram/media/import',
      body: <String, dynamic>{
        'ids': ids,
        'target': target,
        if (kolabId != null) 'kolab_id': kolabId,
      },
    );
    return InstagramImportResult.fromJson(data);
  }

  /// POST /api/v1/me/instagram/sync (queued on the backend).
  Future<void> sync() async {
    await _send('POST', '/me/instagram/sync');
  }

  /// DELETE /api/v1/me/instagram. Already-imported media stays.
  Future<void> disconnect() async {
    await _send('DELETE', '/me/instagram');
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Returns the `data` member of a 2xx response. With [hideOnMissing], a
  /// 403/404 returns null instead of throwing.
  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool hideOnMissing = false,
    bool allowRetry = true,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const InstagramException('Not authenticated');
    }

    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };

    debugPrint('Instagram: $method ${uri.path}');
    final http.Response response;
    try {
      switch (method) {
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers);
        default:
          response = await _httpClient.get(uri, headers: headers);
      }
    } catch (e) {
      throw InstagramException('Network error: $e');
    }

    final status = response.statusCode;
    if (status == 401 && allowRetry) {
      await _authService.refreshSession();
      return _send(
        method,
        path,
        body: body,
        hideOnMissing: hideOnMissing,
        allowRetry: false,
      );
    }
    if (hideOnMissing && (status == 403 || status == 404)) {
      debugPrint('Instagram: $status for $path, hiding surface');
      return null;
    }
    if (status < 200 || status >= 300) {
      throw InstagramException(
        _messageFrom(response.body, status),
        statusCode: status,
      );
    }
    if (response.body.trim().isEmpty) return null;

    try {
      final json = jsonDecode(response.body);
      return json is Map ? json['data'] : null;
    } on FormatException {
      throw const InstagramException('Invalid response format');
    }
  }

  String _messageFrom(String body, int status) {
    try {
      final json = jsonDecode(body);
      final message = json is Map ? json['message'] : null;
      if (message is String && message.isNotEmpty) return message;
    } on FormatException {
      // fall through
    }
    return 'Request failed with status $status';
  }
}

/// Exception for Instagram Connect operations.
class InstagramException implements Exception {
  const InstagramException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
