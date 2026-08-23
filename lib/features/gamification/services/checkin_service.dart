import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../services/analytics/analytics_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/event_checkin.dart';
import '../../../config/constants/api.dart';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Service for handling event check-in operations
class CheckinService {
  CheckinService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Generate the check-in credentials for an event (organizer only).
  ///
  /// POST /api/v1/events/{event_id}/generate-qr
  ///
  /// [rotate] retires the current code and mints a new one. Without it the
  /// endpoint is idempotent — `CheckinService::openDoor` returns the existing
  /// code while it is still valid, deliberately, so a host pressing this on a
  /// phone does not kill a QR a laptop is still showing to a queue.
  Future<EventCheckinQr> generateQr(
    String eventId, {
    bool rotate = false,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/generate-qr';
    debugPrint('🎫 Generate QR: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'rotate': rotate}),
      );

      debugPrint('🎫 Generate QR response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return EventCheckinQr.fromJson(data);
      } else if (response.statusCode == 403) {
        throw const CheckinException(
          'You are not authorized to generate a QR token for this event.',
          kind: CheckinFailure.unauthorized,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw CheckinException(
          json['message'] as String? ?? 'Failed to generate QR token',
        );
      }
    } catch (e) {
      if (e is CheckinException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎫 Generate QR error: $e');
      throw CheckinException(
        'Failed to connect to server: $e',
        kind: CheckinFailure.network,
      );
    }
  }

  /// Check in to an event via QR token
  ///
  /// POST /api/v1/checkin
  Future<EventCheckin> checkIn(String qrToken) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/checkin';
    debugPrint('🎫 Check In: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'token': qrToken}),
      );

      debugPrint('🎫 Check In response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        unawaited(
          AnalyticsService.instance.capture(AnalyticsEvents.eventCheckedIn),
        );
        return EventCheckin.fromJson(data);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String?;

        if (response.statusCode == 404) {
          throw const CheckinException(
            'Invalid check-in token.',
            kind: CheckinFailure.invalidToken,
          );
        } else if (response.statusCode == 409) {
          throw CheckinException(
            'Already checked in to this event.',
            kind: CheckinFailure.alreadyCheckedIn,
            checkin: _tryParseCheckin(json['data']),
          );
        } else if (response.statusCode == 422) {
          throw CheckinException(
            message ?? 'This event is not currently accepting check-ins.',
            kind: CheckinFailure.notAcceptingCheckins,
          );
        } else {
          throw CheckinException(
            message ?? 'Failed to check in',
            kind: CheckinFailure.unknown,
          );
        }
      }
    } catch (e) {
      if (e is CheckinException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎫 Check In error: $e');
      throw CheckinException(
        'Failed to connect to server: $e',
        kind: CheckinFailure.network,
      );
    }
  }

  /// Check the caller in to an event they said they were going to, with no
  /// organizer and no QR (#144).
  ///
  /// The second door into the same room. The QR one needs another person present
  /// with their phone out, and when nobody is, the whole challenge loop is
  /// unreachable — the backend requires a check-in row for *both* attendees
  /// before a challenge can start, so there is no client-side way around it.
  ///
  /// A 409 ("already checked in") is returned as a success here rather than
  /// thrown: the caller's intent is satisfied, and the only reason to distinguish
  /// them is to say something different on screen, which is not worth a branch.
  /// The event id is what the session needs, and we already have it.
  ///
  /// POST /api/v1/events/{event}/checkin
  Future<EventCheckin?> selfCheckIn(String eventId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/checkin';
    debugPrint('🎫 Self check-in: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('🎫 Self check-in status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        unawaited(
          AnalyticsService.instance.capture(AnalyticsEvents.eventCheckedIn),
        );
        return _tryParseCheckin(json['data']);
      }

      if (response.statusCode == 409) {
        // Already in. Nothing to do, nothing to apologise for.
        return _tryParseCheckin(
          (jsonDecode(response.body) as Map<String, dynamic>)['data'],
        );
      }

      // 404 means the route is not deployed yet, which must not read as "this
      // event refused you" — the caller falls back to the QR door.
      if (response.statusCode == 404) {
        throw const CheckinException(
          'Self check-in is not available yet.',
          kind: CheckinFailure.unavailable,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw CheckinException(
        json['message'] as String? ?? 'Could not check you in.',
        kind: CheckinFailure.notAcceptingCheckins,
      );
    } catch (e) {
      if (e is CheckinException || e is AuthException) rethrow;
      debugPrint('🎫 Self check-in error: $e');
      throw CheckinException(
        'Failed to connect to server: $e',
        kind: CheckinFailure.network,
      );
    }
  }

  /// Reads an [EventCheckin] out of a payload that may or may not carry one.
  ///
  /// Used for the 409 body, whose shape is not guaranteed — a miss is fine, it
  /// just means the session cannot be recovered from the response.
  static EventCheckin? _tryParseCheckin(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    try {
      return EventCheckin.fromJson(data);
    } on Object {
      return null;
    }
  }

  /// Get list of check-ins for an event
  ///
  /// GET /api/v1/events/{event_id}/checkins
  Future<CheckinsResponse> getEventCheckins(
    String eventId, {
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/checkins?page=$page&limit=$limit';
    debugPrint('🎫 Get Checkins: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🎫 Get Checkins response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CheckinsResponse.fromJson(json['data'] as Map<String, dynamic>);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw CheckinException(
          json['message'] as String? ?? 'Failed to get check-ins',
        );
      }
    } catch (e) {
      if (e is CheckinException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎫 Get Checkins error: $e');
      throw CheckinException(
        'Failed to connect to server: $e',
        kind: CheckinFailure.network,
      );
    }
  }
}

/// What the organizer's check-in QR screen needs.
///
/// The backend returns three related things and the QR must encode [url], not
/// [token]: `App\Support\CheckinLink` is the one place that decides what a
/// check-in QR points at, and it picks a web URL carrying the short [code]
/// because that keeps the QR at version 3 (29×29) instead of version 6 (41×41)
/// — the difference between scanning across a room and walking up to the
/// screen. It is also openable by a plain phone camera.
///
/// [code] is the typable twin, for when scanning will not cooperate.
@immutable
class EventCheckinQr {
  const EventCheckinQr({
    required this.token,
    this.code,
    this.url,
    this.expiresAt,
  });

  factory EventCheckinQr.fromJson(Map<String, dynamic> json) => EventCheckinQr(
    token: json['checkin_token'] as String,
    code: json['checkin_code'] as String?,
    url: json['checkin_url'] as String?,
    expiresAt: json['checkin_expires_at'] != null
        ? DateTime.tryParse(json['checkin_expires_at'] as String)
        : null,
  );

  /// The long opaque token. Accepted by `POST /checkin`, but too large to make
  /// a comfortably scannable QR.
  final String token;

  /// Short, typable code. Also accepted by `POST /checkin`
  /// (`CheckinService::checkin` matches `checkin_token` OR `checkin_code`).
  final String? code;

  /// The URL the QR should carry. Falls back to [token] only on an older
  /// backend that does not return it.
  final String? url;

  final DateTime? expiresAt;

  /// What to render in the QR.
  String get qrData => (url != null && url!.isNotEmpty) ? url! : token;

  /// What to show as the typable fallback under the QR.
  String get displayCode => (code != null && code!.isNotEmpty) ? code! : token;
}

/// Response wrapper for check-ins list with pagination
class CheckinsResponse {
  const CheckinsResponse({
    required this.checkins,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory CheckinsResponse.fromJson(Map<String, dynamic> json) {
    final checkinsJson = json['checkins'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return CheckinsResponse(
      checkins: checkinsJson
          .map((e) => EventCheckin.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      totalPages: pagination['total_pages'] as int,
      totalCount: pagination['total_count'] as int,
      perPage: pagination['per_page'] as int,
    );
  }

  final List<EventCheckin> checkins;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  bool get hasMore => currentPage < totalPages;
}

/// Why a check-in failed.
///
/// The UI localizes off this instead of showing [CheckinException.message],
/// which may be raw backend English. [alreadyCheckedIn] is deliberately not an
/// error state in the scanner: the user is where they wanted to be.
enum CheckinFailure {
  invalidToken,
  alreadyCheckedIn,
  notAcceptingCheckins,
  unauthorized,
  network,

  /// The endpoint is not on this backend yet (404 on the route itself). Distinct
  /// from a refusal, because the caller should offer the QR door rather than
  /// telling the attendee the event turned them away.
  unavailable,
  unknown,
}

/// Exception for check-in operations
class CheckinException implements Exception {
  const CheckinException(
    this.message, {
    this.kind = CheckinFailure.unknown,
    this.checkin,
  });

  final String message;

  /// The existing check-in, when the backend returns one alongside a 409.
  ///
  /// Without it a duplicate scan leaves the member checked in server-side but
  /// with no local event session, and nothing in the app can recover it.
  final EventCheckin? checkin;

  /// Classified reason, so callers can localize and branch without string
  /// matching on [message].
  final CheckinFailure kind;

  @override
  String toString() => 'CheckinException($kind): $message';
}
