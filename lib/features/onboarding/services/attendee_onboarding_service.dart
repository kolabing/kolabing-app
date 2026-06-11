import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../models/attendee_onboarding_state.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Service for `PUT /onboarding/attendee` (identity contract §3).
///
/// Authenticated, re-runnable: stores name/handle/city/interests on the
/// attendee's `profiles` row, uploads the photo, and auto-joins each open
/// community in `community_ids`. Self-gates a route 404 via
/// [OnboardingFeatureOffException] so the caller can fall through to the
/// dashboard rather than blocking the user on an undeployed backend.
class AttendeeOnboardingService {
  AttendeeOnboardingService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// `PUT /onboarding/attendee`. Returns the updated [UserModel] from the
  /// `data` envelope. Throws [OnboardingFeatureOffException] on 404,
  /// [ApiException] on a validation/other failure (e.g. handle taken → 422).
  Future<void> submit(String token, AttendeeOnboardingData data) async {
    const url = '$_baseUrl/onboarding/attendee';
    debugPrint('🎯 Attendee onboarding: PUT $url');

    try {
      final response = await _httpClient.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data.toPayload()),
      );

      debugPrint('🎯 Attendee onboarding status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }
      if (response.statusCode == 404) {
        throw const OnboardingFeatureOffException();
      }
      throw ApiException(
        error: ApiError.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
          statusCode: response.statusCode,
        ),
      );
    } catch (e) {
      if (e is ApiException || e is OnboardingFeatureOffException) rethrow;
      debugPrint('🎯 Attendee onboarding error: $e');
      throw NetworkException('Failed to complete onboarding: $e');
    }
  }
}

/// `PUT /onboarding/attendee` is not deployed yet (404). Callers treat the flow
/// as skippable and route straight to the dashboard.
class OnboardingFeatureOffException implements Exception {
  const OnboardingFeatureOffException();
}
