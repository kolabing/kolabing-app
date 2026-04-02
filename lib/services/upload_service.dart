import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/constants/api.dart';
import '../features/auth/models/auth_response.dart';
import '../features/auth/services/auth_service.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// General file upload service.
///
/// Uploads a file to `POST /api/v1/uploads` and returns the CDN URL.
/// Used by kolab media, event photos, profile photos, etc.
class UploadService {
  UploadService({
    AuthService? authService,
    http.Client? httpClient,
  })  : _authService = authService ?? AuthService(),
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Upload a file and return the CDN URL.
  ///
  /// [filePath] — local file path from ImagePicker
  /// [folder] — "kolabs", "events", or "profiles"
  ///
  /// Returns the URL string on success.
  /// Throws [ApiException] on validation error (422).
  /// Throws [NetworkException] on network failure.
  Future<String> upload({
    required String filePath,
    required String folder,
  }) async {
    final uri = Uri.parse('$_baseUrl/uploads');
    debugPrint('UploadService: POST $uri (folder: $folder)');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(await _getHeaders());
      request.fields['folder'] = folder;
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        final url = data['url'] as String;
        debugPrint('Upload success: $url');
        return url;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: 422),
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Upload error: $e');
      throw NetworkException('Failed to upload file: $e');
    }
  }
}

final uploadServiceProvider = Provider<UploadService>(
  (ref) => UploadService(),
);
