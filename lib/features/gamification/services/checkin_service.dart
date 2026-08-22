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
  CheckinService({
    required AuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Generate QR check-in token for an event (organizer only)
  ///
  /// POST /api/v1/events/{event_id}/generate-qr
  Future<String> generateQRToken(String eventId) async {
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
      );

      debugPrint('🎫 Generate QR response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return data['checkin_token'] as String;
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
          throw const CheckinException(
            'Already checked in to this event.',
            kind: CheckinFailure.alreadyCheckedIn,
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
  unknown,
}

/// Exception for check-in operations
class CheckinException implements Exception {
  const CheckinException(this.message, {this.kind = CheckinFailure.unknown});

  final String message;

  /// Classified reason, so callers can localize and branch without string
  /// matching on [message].
  final CheckinFailure kind;

  @override
  String toString() => 'CheckinException($kind): $message';
}
