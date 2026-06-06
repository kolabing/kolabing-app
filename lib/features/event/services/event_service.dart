import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../services/analytics/analytics_service.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/event.dart';
import '../models/event_signup.dart';
import '../../../config/constants/api.dart';

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Service for managing past events via the API
class EventService {
  EventService({AuthService? authService, http.Client? httpClient})
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
  // List Events
  // ---------------------------------------------------------------------------

  /// GET /api/v1/events
  /// Fetch paginated list of events. If [profileId] is null, returns
  /// the authenticated user's events.
  Future<({List<Event> events, EventPagination pagination})> getEvents({
    String? profileId,
    String? communityId,
    String? time, // 'upcoming' | 'past' (Phase-3 filter)
    int page = 1,
    int limit = 10,
  }) async {
    return _getEvents(
      profileId: profileId,
      communityId: communityId,
      time: time,
      page: page,
      limit: limit,
      allowRetry: true,
    );
  }

  Future<({List<Event> events, EventPagination pagination})> _getEvents({
    String? profileId,
    String? communityId,
    String? time,
    required int page,
    required int limit,
    required bool allowRetry,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (profileId != null) 'profile_id': profileId,
      if (communityId != null) 'community_id': communityId,
      if (time != null) 'time': time,
    };

    final uri = Uri.parse(
      '$_baseUrl/events',
    ).replace(queryParameters: queryParams);
    debugPrint('EventService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: allowRetry,
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
              Event.fromJson(eventsRaw[i] as Map<String, dynamic>),
            );
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
    return _getEvent(eventId, allowRetry: true);
  }

  Future<Event> _getEvent(String eventId, {required bool allowRetry}) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId');
    debugPrint('EventService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: allowRetry,
      );

      debugPrint('Get event response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Event.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 404) {
        throw const ApiException(error: ApiError(message: 'Event not found.'));
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
  // Sign-up / RSVP (Phase 3)
  // ---------------------------------------------------------------------------

  /// POST /events/{event}/signup — one-tap "I'm going" (or waitlist when full).
  /// Returns the updated event (my_signup + counts).
  Future<Event> signup(String eventId) async {
    final event = await _signup(eventId, allowRetry: true);
    unawaited(
      AnalyticsService.instance.capture(
        AnalyticsEvents.eventSignup,
        properties: {'event_id': eventId},
      ),
    );
    return event;
  }

  Future<Event> _signup(String eventId, {required bool allowRetry}) async {
    final response = await _sendWithRefresh(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/events/$eventId/signup'),
        headers: await _getHeaders(),
      ),
      allowRetry: allowRetry,
    );
    return _parseSignupResponse(response, eventId);
  }

  /// DELETE /events/{event}/signup — leave / cancel (frees a slot; backend
  /// auto-promotes the next waitlisted member).
  Future<Event> cancelSignup(String eventId) =>
      _cancelSignup(eventId, allowRetry: true);

  Future<Event> _cancelSignup(String eventId, {required bool allowRetry}) async {
    final response = await _sendWithRefresh(
      () async => _httpClient.delete(
        Uri.parse('$_baseUrl/events/$eventId/signup'),
        headers: await _getHeaders(),
      ),
      allowRetry: allowRetry,
    );
    return _parseSignupResponse(response, eventId);
  }

  Future<Event> _parseSignupResponse(
    http.Response response,
    String eventId,
  ) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        if (data['id'] != null && data['name'] != null) {
          return Event.fromJson(data);
        }
        final ev = data['event'];
        if (ev is Map<String, dynamic>) return Event.fromJson(ev);
      }
      // Response wasn't a full event payload — re-fetch for fresh counts.
      return getEvent(eventId);
    }
    var message = 'Could not update your sign-up';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = (body['message'] ?? body['error'] ?? message).toString();
    } catch (_) {}
    throw Exception(message);
  }

  // ---------------------------------------------------------------------------
  // Signups roster (Phase 3 — leader view)
  // ---------------------------------------------------------------------------

  /// GET /events/{event}/signups — the attendee roster (leader only).
  /// Response: `{ data: { going:[…], waitlist:[…] } }`.
  Future<EventSignups> getSignups(String eventId) =>
      _getSignups(eventId, allowRetry: true);

  Future<EventSignups> _getSignups(
    String eventId, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId/signups');
    debugPrint('EventService: GET $uri');
    final response = await _sendWithRefresh(
      () async => _httpClient.get(uri, headers: await _getHeaders()),
      allowRetry: allowRetry,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is Map<String, dynamic>) return EventSignups.fromJson(data);
      return const EventSignups();
    } else if (response.statusCode == 401) {
      throw const AuthException('Session expired. Please sign in again.');
    }
    throw _parseApiError(response);
  }

  // ---------------------------------------------------------------------------
  // Photos (Phase 3 — NEW backend endpoint, ships in parallel)
  // ---------------------------------------------------------------------------

  /// POST /events/{event}/photos — multipart `photos[]`. Returns the updated
  /// [Event] (with the new photos). NOTE: this backend endpoint is being built
  /// in parallel (backend ticket 2026-06-05); coded to the agreed contract so
  /// it works once deployed.
  Future<Event> addEventPhotos(String eventId, List<String> filePaths) =>
      _addEventPhotos(eventId, filePaths, allowRetry: true);

  Future<Event> _addEventPhotos(
    String eventId,
    List<String> filePaths, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId/photos');
    debugPrint('EventService: POST $uri (${filePaths.length} photo(s))');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _getHeaders());
    for (final path in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('photos[]', path));
    }
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    debugPrint('Add event photos status: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final ev = data['event'] is Map<String, dynamic> ? data['event'] : data;
        return Event.fromJson(ev as Map<String, dynamic>);
      }
      throw Exception('Unexpected response uploading photos');
    } else if (response.statusCode == 401) {
      if (allowRetry) {
        await _authService.refreshSession();
        return _addEventPhotos(eventId, filePaths, allowRetry: false);
      }
      throw const AuthException('Session expired. Please sign in again.');
    }
    throw _parseApiError(response);
  }

  // ---------------------------------------------------------------------------
  // Update upcoming event (Phase 3 — JSON; edit an upcoming event)
  // ---------------------------------------------------------------------------

  /// PUT /events/{event} — edit an UPCOMING event (JSON). Mirrors the create
  /// payload; only sends keys that are provided.
  Future<Event> updateUpcomingEvent(
    String eventId, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
    bool clearEndsAt = false,
    String? location,
    int? capacity,
    bool clearCapacity = false,
    List<String>? tierGate,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
      if (endsAt != null)
        'ends_at': endsAt.toUtc().toIso8601String()
      else if (clearEndsAt)
        'ends_at': null,
      if (location != null) 'location': location,
      if (capacity != null)
        'capacity': capacity
      else if (clearCapacity)
        'capacity': null,
      if (tierGate != null) 'tier_gate': tierGate,
    };
    final response = await _sendWithRefresh(
      () async => _httpClient.put(
        Uri.parse('$_baseUrl/events/$eventId'),
        headers: await _getJsonHeaders(),
        body: jsonEncode(payload),
      ),
      allowRetry: true,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final ev = data['event'] is Map<String, dynamic> ? data['event'] : data;
        return Event.fromJson(ev as Map<String, dynamic>);
      }
      throw Exception('Unexpected response updating event');
    }
    var message = 'Could not update the event';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final errs = body['errors'];
      if (errs is Map && errs.isNotEmpty) {
        final first = errs.values.first;
        message = (first is List && first.isNotEmpty)
            ? first.first.toString()
            : (body['message']?.toString() ?? message);
      } else {
        message = body['message']?.toString() ?? message;
      }
    } catch (_) {}
    throw Exception(message);
  }

  // ---------------------------------------------------------------------------
  // Create Event
  // ---------------------------------------------------------------------------

  /// POST /events — UPCOMING mode (PR #20). JSON, no photos required. Auth =
  /// owner / can_manage of the community. `starts_at` keys the upcoming branch.
  Future<Event> createUpcomingEvent({
    required String communityId,
    required String name,
    required DateTime startsAt,
    DateTime? endsAt,
    String? location,
    int? capacity,
    List<String>? tierGate,
    Map<String, dynamic>? recurrence,
  }) async {
    final payload = <String, dynamic>{
      'community_id': communityId,
      'name': name,
      'starts_at': startsAt.toUtc().toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
      if (location != null && location.isNotEmpty) 'location': location,
      if (capacity != null) 'capacity': capacity,
      if (tierGate != null && tierGate.isNotEmpty) 'tier_gate': tierGate,
      // Recurring → backend builds an event_series and returns the first
      // occurrence (carrying series_id). See EventSeriesService.
      if (recurrence != null) 'recurrence': recurrence,
    };
    final response = await _sendWithRefresh(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/events'),
        headers: await _getJsonHeaders(),
        body: jsonEncode(payload),
      ),
      allowRetry: true,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final ev = data['event'] is Map<String, dynamic> ? data['event'] : data;
        final created = Event.fromJson(ev as Map<String, dynamic>);
        unawaited(
          AnalyticsService.instance.capture(
            AnalyticsEvents.eventCreated,
            properties: {
              'event_id': created.id,
              'mode': 'upcoming',
              'is_recurring': recurrence != null,
            },
          ),
        );
        return created;
      }
      throw Exception('Unexpected response creating event');
    }
    // Surface the first validation error if present, else the message.
    var message = 'Could not create the event';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final errs = body['errors'];
      if (errs is Map && errs.isNotEmpty) {
        final first = errs.values.first;
        message = (first is List && first.isNotEmpty)
            ? first.first.toString()
            : (body['message']?.toString() ?? message);
      } else {
        message = body['message']?.toString() ?? message;
      }
    } catch (_) {}
    throw Exception(message);
  }

  /// POST /api/v1/events
  /// Creates a new event with photo files via multipart/form-data.
  Future<Event> createEvent(EventCreateRequest request) async {
    return _createEvent(request, allowRetry: true);
  }

  Future<Event> _createEvent(
    EventCreateRequest request, {
    required bool allowRetry,
  }) async {
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
      multipartRequest.fields['date'] = request.date
          .toIso8601String()
          .split('T')
          .first;
      multipartRequest.fields['attendee_count'] = request.attendeeCount
          .toString();

      // Add photo files
      for (final path in request.photoPaths) {
        final file = await http.MultipartFile.fromPath('photos[]', path);
        multipartRequest.files.add(file);
      }

      // Add optional video files
      for (final path in request.videoPaths) {
        final file = await http.MultipartFile.fromPath('videos[]', path);
        multipartRequest.files.add(file);
      }

      final streamedResponse = await _httpClient.send(multipartRequest);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Create event response status: ${response.statusCode}');
      debugPrint('Create event response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        final created = (data != null && data is Map<String, dynamic>)
            ? Event.fromJson(data)
            // API returned success but no parseable data - build from request
            : Event(
                id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                name: request.name,
                partner: EventPartner(
                  name: request.partnerName,
                  type: request.partnerType,
                ),
                date: request.date,
                attendeeCount: request.attendeeCount,
                photos: const [],
                videos: const [],
                createdAt: DateTime.now(),
              );
        unawaited(
          AnalyticsService.instance.capture(
            AnalyticsEvents.eventCreated,
            properties: {'event_id': created.id, 'mode': 'showcase'},
          ),
        );
        return created;
      } else if (response.statusCode == 401) {
        if (allowRetry) {
          await _authService.refreshSession();
          return _createEvent(request, allowRetry: false);
        }
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
  Future<Event> updateEvent(String eventId, EventUpdateRequest request) async {
    return _updateEvent(eventId, request, allowRetry: true);
  }

  Future<Event> _updateEvent(
    String eventId,
    EventUpdateRequest request, {
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId');
    final body = jsonEncode(request.toJson());

    debugPrint('EventService: PUT $uri');
    debugPrint('Update event body: $body');

    try {
      final response = await _sendWithRefresh(
        () async =>
            _httpClient.put(uri, headers: await _getJsonHeaders(), body: body),
        allowRetry: allowRetry,
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
            message: 'You are not authorized to update this event.',
          ),
        );
      } else if (response.statusCode == 404) {
        throw const ApiException(error: ApiError(message: 'Event not found.'));
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

  /// DELETE /api/v1/events/{id}[?scope=this|following|series]
  /// Deletes an event. Only the owner/manager can delete. `scope` only matters
  /// for events that belong to a recurring series.
  Future<void> deleteEvent(String eventId, {String scope = 'this'}) async {
    return _deleteEvent(eventId, scope: scope, allowRetry: true);
  }

  Future<void> _deleteEvent(
    String eventId, {
    required String scope,
    required bool allowRetry,
  }) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId').replace(
      queryParameters: scope == 'this' ? null : {'scope': scope},
    );
    debugPrint('EventService: DELETE $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.delete(uri, headers: await _getHeaders()),
        allowRetry: allowRetry,
      );

      debugPrint('Delete event response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        throw const ApiException(
          error: ApiError(
            message: 'You are not authorized to delete this event.',
          ),
        );
      } else if (response.statusCode == 404) {
        throw const ApiException(error: ApiError(message: 'Event not found.'));
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
