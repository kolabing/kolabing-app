import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/services/auth_service.dart';
import '../models/encounter.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// Why an encounter call failed.
///
/// Same shape as [FriendshipException] on purpose: the People Layer ships
/// **dormant** until the backend lands, so every surface self-gates on
/// [isFeatureOff] rather than showing a stranger an error about a feature they
/// have never heard of.
class EncounterException implements Exception {
  const EncounterException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  /// The endpoint is not deployed yet. Hide the surface; never crash, never
  /// spam.
  bool get isFeatureOff => statusCode == 404;

  /// This attendee already has the maximum unclaimed ghosts for this event
  /// (three). Server-enforced — the app shows the reason, it does not count.
  bool get ghostLimitReached => code == 'ghost_limit_reached';

  /// The code was typed wrong, or it never existed.
  bool get invalidClaimCode => code == 'invalid_claim_code';

  /// The 30-day window closed.
  bool get claimExpired => code == 'claim_expired';

  /// Only a genuinely new account may claim a ghost — an existing profile
  /// cannot harvest them.
  bool get claimNotNewAccount => code == 'claim_requires_new_account';

  /// You cannot redeem your own invite.
  bool get claimSelf => code == 'claim_self';

  /// The inviter is not checked in to the event. Without that rule the whole
  /// mechanism is a points faucet you can turn on from your sofa, so the
  /// server refuses it — and this is the most likely refusal in practice.
  bool get notCheckedIn => code == 'not_checked_in';

  @override
  String toString() => 'EncounterException($code: $message)';
}

/// API client for the People Layer (#183).
///
/// Contract: `docs/tickets/2026-08-27-people-layer-backend-contract.md`.
/// Every call self-gates on 404 so the app can ship before the backend does.
class EncounterService {
  EncounterService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const EncounterException(
        'Not authenticated',
        code: 'unauthenticated',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _unwrap(http.Response res) {
    final body = res.body.isEmpty ? <String, dynamic>{} : _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body['data'] ?? body;
    }
    throw EncounterException(
      body['message'] as String? ?? 'Request failed (${res.statusCode})',
      code: body['code'] as String? ?? body['error'] as String?,
      statusCode: res.statusCode,
    );
  }

  /// A 500 behind a proxy answers with an HTML page. Decoding that used to
  /// throw a `FormatException` out of whatever call site was unlucky enough to
  /// hit it (see `ChallengeService`), so a non-JSON body becomes an empty map
  /// and the status code carries the meaning.
  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  Future<T> _guard<T>(Future<T> Function() run, String label) async {
    try {
      return await run();
    } catch (e) {
      if (e is EncounterException) rethrow;
      debugPrint('🤝 Encounters $label error: $e');
      throw EncounterException('Failed to connect to server: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// `GET /me/encounters` — the people you have met, most recent first.
  ///
  /// Private to the viewer by design: seeing whom *someone else* has met would
  /// read as surveillance, so there is deliberately no endpoint for it.
  Future<List<Encounter>> getMyEncounters({int page = 1, int limit = 50}) =>
      _guard(() async {
        final res = await _httpClient.get(
          Uri.parse('$_baseUrl/me/encounters?page=$page&limit=$limit'),
          headers: await _headers(),
        );
        final data = _unwrap(res);
        final raw = data is Map
            ? (data['encounters'] ?? data['data'] ?? const <dynamic>[])
            : data;
        if (raw is! List) return const <Encounter>[];
        return raw
            .whereType<Map<String, dynamic>>()
            .map(Encounter.fromJson)
            .toList(growable: false);
      }, 'list');

  /// `GET /events/{eventId}/recap` — what the night came to.
  ///
  /// The recap is the artifact people actually share, so it is a first-class
  /// endpoint rather than something the app assembles out of three lists.
  Future<NightRecap> getNightRecap(String eventId) => _guard(() async {
    final res = await _httpClient.get(
      Uri.parse('$_baseUrl/events/$eventId/recap'),
      headers: await _headers(),
    );
    return NightRecap.fromJson(_unwrap(res) as Map<String, dynamic>);
  }, 'recap');

  // ---------------------------------------------------------------------------
  // Ghost contact
  // ---------------------------------------------------------------------------

  /// `POST /encounters/ghost` — record a meeting with someone who is not on
  /// Kolabing, and get back the invite that can bring them in.
  ///
  /// [ghostName] is the only required detail. A phone or handle is optional and
  /// exists purely to make the invite easier to send — asking for a stranger's
  /// number at the moment you meet them is both bad manners and a bigger
  /// data-protection surface than this feature needs.
  ///
  /// **No XP is paid here.** It is named on screen and paid to both sides only
  /// when the ghost joins; paying up front would invite imaginary friends.
  Future<GhostInvite> createGhostInvite({
    required String eventId,
    required String challengeId,
    required String ghostName,
    String? ghostContact,
  }) => _guard(() async {
    final res = await _httpClient.post(
      Uri.parse('$_baseUrl/encounters/ghost'),
      headers: await _headers(),
      body: jsonEncode({
        'event_id': eventId,
        'challenge_id': challengeId,
        'ghost_name': ghostName,
        if (ghostContact != null && ghostContact.trim().isNotEmpty)
          'ghost_contact': ghostContact.trim(),
      }),
    );
    return GhostInvite.fromJson(_unwrap(res) as Map<String, dynamic>);
  }, 'ghost');

  /// `POST /encounters/claim` — the new attendee redeems the invite.
  ///
  /// Called from two places for one token: the deep-link handler when the app
  /// was already installed, and the onboarding code field when it was not.
  /// Universal Links do not survive a trip through the App Store, which is
  /// exactly the trip this feature's whole point requires.
  ///
  /// The server decides whether it pays: new accounts only, inside the 30-day
  /// window. Both sides are credited retroactively.
  Future<Encounter> claim(String claimCode) => _guard(() async {
    final res = await _httpClient.post(
      Uri.parse('$_baseUrl/encounters/claim'),
      headers: await _headers(),
      body: jsonEncode({'claim_code': claimCode.trim().toUpperCase()}),
    );
    return Encounter.fromJson(_unwrap(res) as Map<String, dynamic>);
  }, 'claim');
}
