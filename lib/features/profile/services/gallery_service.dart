import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../providers/gallery_provider.dart';
import '../../../config/constants/api.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Service for gallery API operations
class GalleryService {
  GalleryService({
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
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getJsonHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // GET /api/v1/me/gallery - List own gallery photos
  // ---------------------------------------------------------------------------

  Future<List<GalleryPhoto>> getMyGallery() async {
    final uri = Uri.parse('$_baseUrl/me/gallery');
    debugPrint('GalleryService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getJsonHeaders(),
      );

      debugPrint('GalleryService: getMyGallery response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => GalleryPhoto.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
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
      debugPrint('GalleryService: getMyGallery error: $e');
      throw const NetworkException('Failed to load gallery');
    }
  }

  // ---------------------------------------------------------------------------
  // POST /api/v1/me/gallery - Upload a photo (multipart/form-data)
  // ---------------------------------------------------------------------------

  Future<GalleryPhoto> uploadPhoto({
    required String filePath,
    String? caption,
  }) async {
    final uri = Uri.parse('$_baseUrl/me/gallery');
    debugPrint('GalleryService: POST $uri (multipart)');

    try {
      final request = http.MultipartRequest('POST', uri);

      // Add auth headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add photo file
      request.files.add(
        await http.MultipartFile.fromPath('photo', filePath),
      );

      // Add optional caption
      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('GalleryService: upload response ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          final photo = GalleryPhoto.fromJson(data);
          if (photo.url.isNotEmpty) return photo;
        }
        // Fallback: re-fetch gallery and return last item
        final gallery = await getMyGallery();
        return gallery.last;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 422) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
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
      debugPrint('GalleryService: uploadPhoto error: $e');
      throw const NetworkException('Failed to upload photo');
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE /api/v1/me/gallery/{photo_id} - Delete a photo
  // ---------------------------------------------------------------------------

  Future<void> deletePhoto(String photoId) async {
    final uri = Uri.parse('$_baseUrl/me/gallery/$photoId');
    debugPrint('GalleryService: DELETE $uri');

    try {
      final response = await _httpClient.delete(
        uri,
        headers: await _getJsonHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
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
      debugPrint('GalleryService: deletePhoto error: $e');
      throw const NetworkException('Failed to delete photo');
    }
  }

  // ---------------------------------------------------------------------------
  // GET /api/v1/profiles/{profile_id}/gallery - View other profile's gallery
  // ---------------------------------------------------------------------------

  Future<List<GalleryPhoto>> getProfileGallery(String profileId) async {
    final uri = Uri.parse('$_baseUrl/profiles/$profileId/gallery');
    debugPrint('GalleryService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getJsonHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final dataList = json['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => GalleryPhoto.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
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
      debugPrint('GalleryService: getProfileGallery error: $e');
      throw const NetworkException('Failed to load gallery');
    }
  }
}
