import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/event.dart';

/// API base URL
const String _baseUrl =
    'https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1';

/// Service for managing past events via the API
class EventService {
  EventService({
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
  // List Events
  // ---------------------------------------------------------------------------

  /// GET /api/v1/events
  /// Fetch paginated list of events. If [profileId] is null, returns
  /// the authenticated user's events.
  Future<({List<Event> events, EventPagination pagination})> getEvents({
    String? profileId,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (profileId != null) 'profile_id': profileId,
    };

    final uri = Uri.parse('$_baseUrl/events').replace(
      queryParameters: queryParams,
    );
    debugPrint('EventService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('List events response status: ${response.statusCode}');
      debugPrint('List events response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final rawData = json['data'];

        // Handle both { data: { events: [...], pagination: {...} } }
        // and { data: [...] } formats
        List<dynamic> eventsRaw;
        Map<String, dynamic>? paginationRaw;

        if (rawData is Map<String, dynamic>) {
          eventsRaw = (rawData['events'] as List<dynamic>?) ?? [];
          paginationRaw = rawData['pagination'] as Map<String, dynamic>?;
        } else if (rawData is List) {
          eventsRaw = rawData;
        } else {
          eventsRaw = [];
        }

        final eventsList = <Event>[];
        for (var i = 0; i < eventsRaw.length; i++) {
          try {
            eventsList.add(
                Event.fromJson(eventsRaw[i] as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Error parsing event[$i]: $e');
            debugPrint('Raw event data: ${eventsRaw[i]}');
          }
        }

        final pagination = paginationRaw != null
            ? EventPagination.fromJson(paginationRaw)
            : EventPagination(
                currentPage: 1,
                totalPages: 1,
                totalCount: eventsList.length,
                perPage: limit,
              );

        return (events: eventsList, pagination: pagination);
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
      debugPrint('List events error: $e');
      throw NetworkException('Failed to load events: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Get Single Event
  // ---------------------------------------------------------------------------

  /// GET /api/v1/events/{id}
  Future<Event> getEvent(String eventId) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId');
    debugPrint('EventService: GET $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Get event response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Event.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 404) {
        throw const ApiException(
          error: ApiError(message: 'Event not found.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Get event error: $e');
      throw NetworkException('Failed to load event: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Create Event
  // ---------------------------------------------------------------------------

  /// POST /api/v1/events
  /// Creates a new event with photo files via multipart/form-data.
  Future<Event> createEvent(EventCreateRequest request) async {
    final uri = Uri.parse('$_baseUrl/events');
    debugPrint('EventService: POST $uri');

    try {
      final multipartRequest = http.MultipartRequest('POST', uri);

      // Add auth headers
      final headers = await _getHeaders();
      multipartRequest.headers.addAll(headers);

      // Add form fields
      multipartRequest.fields['name'] = request.name;
      multipartRequest.fields['partner_name'] = request.partnerName;
      multipartRequest.fields['partner_type'] = request.partnerType.name;
      multipartRequest.fields['date'] =
          request.date.toIso8601String().split('T').first;
      multipartRequest.fields['attendee_count'] =
          request.attendeeCount.toString();

      // Add photo files
      for (final path in request.photoPaths) {
        final file = await http.MultipartFile.fromPath('photos[]', path);
        multipartRequest.files.add(file);
      }

      final streamedResponse = await _httpClient.send(multipartRequest);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Create event response status: ${response.statusCode}');
      debugPrint('Create event response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data != null && data is Map<String, dynamic>) {
          return Event.fromJson(data);
        }
        // API returned success but no parseable data - build from request
        return Event(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          name: request.name,
          partner: EventPartner(
            name: request.partnerName,
            type: request.partnerType,
          ),
          date: request.date,
          attendeeCount: request.attendeeCount,
          photos: const [],
          createdAt: DateTime.now(),
        );
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
      debugPrint('Create event error: $e');
      throw NetworkException('Failed to create event: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Update Event
  // ---------------------------------------------------------------------------

  /// PUT /api/v1/events/{id}
  /// Updates an event. Only the owner can update. Photos cannot be updated.
  Future<Event> updateEvent(
    String eventId,
    EventUpdateRequest request,
  ) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId');
    final body = jsonEncode(request.toJson());

    debugPrint('EventService: PUT $uri');
    debugPrint('Update event body: $body');

    try {
      final response = await _httpClient.put(
        uri,
        headers: await _getJsonHeaders(),
        body: body,
      );

      debugPrint('Update event response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Event.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(
              message: 'You are not authorized to update this event.'),
        );
      } else if (response.statusCode == 404) {
        throw const ApiException(
          error: ApiError(message: 'Event not found.'),
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
      debugPrint('Update event error: $e');
      throw NetworkException('Failed to update event: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Event
  // ---------------------------------------------------------------------------

  /// DELETE /api/v1/events/{id}
  /// Deletes an event. Only the owner can delete.
  Future<void> deleteEvent(String eventId) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId');
    debugPrint('EventService: DELETE $uri');

    try {
      final response = await _httpClient.delete(
        uri,
        headers: await _getHeaders(),
      );

      debugPrint('Delete event response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(
              message: 'You are not authorized to delete this event.'),
        );
      } else if (response.statusCode == 404) {
        throw const ApiException(
          error: ApiError(message: 'Event not found.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Delete event error: $e');
      throw NetworkException('Failed to delete event: $e');
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
