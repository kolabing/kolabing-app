import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/handle_availability.dart';
import '../models/profile_lookup_result.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Typed error for identity endpoints (handle availability + profile lookup).
/// A 404 on lookup means "no match"; a 404 on a route means the feature is not
/// deployed yet. Callers self-gate via [isFeatureOff] / [isNotFound].
class IdentityException implements Exception {
  const IdentityException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'IdentityException($code: $message)';
}

/// Client for the shared identity contract (handle + lookup), reused by
/// onboarding, edit-profile, friends add-by-identifier and leader member-add.
///
/// Contract: docs/tickets/2026-06-10-attendee-onboarding-identity-contract.md
/// §1 (`GET /handle/available`) + §4 (`GET /profiles/lookup`). Every call
/// self-gates: a route 404 surfaces as an [IdentityException] the caller can
/// treat as "feature off" rather than crashing.
class IdentityService {
  IdentityService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// `^[a-z0-9_]{3,20}$` — lowercased, 3-20 chars, letters/digits/underscore.
  static final RegExp handleFormat = RegExp(r'^[a-z0-9_]{3,20}$');

  /// Whether [handle] (already lowercased/trimmed) matches the wire format.
  static bool isValidHandleFormat(String handle) =>
      handleFormat.hasMatch(handle);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// `GET /handle/available?handle=<h>` → `{available, suggestions}`.
  /// Throws [IdentityException] with [IdentityException.isFeatureOff]/`isNotFound`
  /// on a route 404 so the caller can skip the availability hint silently.
  Future<HandleAvailability> checkHandle(String handle) async {
    final normalized = handle.trim().toLowerCase();
    final uri = Uri.parse(
      '$_baseUrl/handle/available',
    ).replace(queryParameters: {'handle': normalized});
    try {
      final res = await _httpClient.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;
        return HandleAvailability.fromJson(data);
      }
      throw IdentityException(
        'Handle check failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is IdentityException) rethrow;
      debugPrint('🪪 checkHandle error: $e');
      throw IdentityException('Failed to check handle: $e');
    }
  }

  /// `GET /profiles/lookup?q=<email-or-@handle>` → the matched public card, or
  /// `null` on a 404 (no match). A leading `@` on a handle is stripped by the
  /// backend; we strip it here too for a clean query.
  Future<ProfileLookupResult?> lookup(String query) async {
    final q = query.trim();
    final cleaned = q.startsWith('@') ? q.substring(1) : q;
    final uri = Uri.parse(
      '$_baseUrl/profiles/lookup',
    ).replace(queryParameters: {'q': cleaned});
    try {
      final res = await _httpClient.get(uri, headers: await _headers());
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;
        return ProfileLookupResult.fromJson(data);
      }
      if (res.statusCode == 404) {
        return null;
      }
      throw IdentityException(
        'Lookup failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    } catch (e) {
      if (e is IdentityException) rethrow;
      debugPrint('🪪 lookup error: $e');
      throw IdentityException('Failed to look up profile: $e');
    }
  }
}
