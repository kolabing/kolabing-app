import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/child_kolab_result.dart';
import '../models/event_creator_entitlement.dart';
import '../models/multi_kolab_dashboard.dart';
import '../models/multi_kolab_event.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event_summary.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';
import 'multi_kolab_repository.dart';

const String _baseUrl = ApiConfig.baseUrl;

/// The production path — talks to the real
/// `/api/v1/multi-kolab-events`/`/api/v1/multi-kolab-roles`/
/// `/api/v1/multi-kolab-role-applications` endpoints (`kolabing-v2` Task 7).
class ApiMultiKolabRepository implements MultiKolabRepository {
  ApiMultiKolabRepository({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<T> _request<T>(
    Future<http.Response> Function() send,
    T Function(Map<String, dynamic> json) onSuccess, {
    bool allowRetry = true,
  }) async {
    late final http.Response response;
    try {
      response = await send();
    } catch (e) {
      debugPrint('MultiKolabRepository network error: $e');
      throw NetworkException(e.toString());
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // `withdraw` and `cancelEvent` are Future<void> and the backend answers
      // them with 204 / an empty 200. Decoding that threw a FormatException,
      // which is neither ApiException nor NetworkException — so the organizer
      // saw the cancel fail while the event was in fact cancelled.
      final body = response.body.trim();
      if (body.isEmpty) return onSuccess(const <String, dynamic>{});
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return onSuccess(decoded);
      // A top-level list is not what any caller expects, but crashing on the
      // cast is worse than handing it over under `data`.
      return onSuccess(<String, dynamic>{'data': decoded});
    }

    if (response.statusCode == 401 && allowRetry) {
      await _authService.refreshSession();
      return _request(send, onSuccess, allowRetry: false);
    }

    throw ApiException(error: _parseError(response));
  }

  ApiError _parseError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiError.fromJson(json, statusCode: response.statusCode);
    } catch (_) {
      return ApiError(
        message: 'Server error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> json) =>
      json['data'] as Map<String, dynamic>? ?? const {};

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> json) =>
      (json['data'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  @override
  Future<MultiKolabEvent> createDraft(CreateMultiKolabEventInput input) {
    return _request(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/multi-kolab-events'),
        headers: await _headers(),
        body: jsonEncode(input.toJson()),
      ),
      (json) => MultiKolabEvent.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabEvent> updateDraft(
    String eventId,
    UpdateMultiKolabEventInput input,
  ) {
    return _request(
      () async => _httpClient.patch(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId'),
        headers: await _headers(),
        body: jsonEncode(input.toJson()),
      ),
      (json) => MultiKolabEvent.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabRole> addRole(
    String eventId,
    CreateMultiKolabRoleInput input,
  ) {
    return _request(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId/roles'),
        headers: await _headers(),
        body: jsonEncode(input.toJson()),
      ),
      (json) => MultiKolabRole.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabRole> updateRole(
    String roleId,
    UpdateMultiKolabRoleInput input,
  ) {
    return _request(
      () async => _httpClient.patch(
        Uri.parse('$_baseUrl/multi-kolab-roles/$roleId'),
        headers: await _headers(),
        body: jsonEncode(input.toJson()),
      ),
      (json) => MultiKolabRole.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabRole> setRoleStatus(
    String roleId,
    MultiKolabRoleStatus status,
  ) {
    return updateRole(roleId, UpdateMultiKolabRoleInput(status: status));
  }

  @override
  Future<List<MultiKolabRoleApplication>> roleApplications(String roleId) {
    return _request(
      () async => _httpClient.get(
        Uri.parse('$_baseUrl/multi-kolab-roles/$roleId/applications'),
        headers: await _headers(),
      ),
      (json) => _dataList(
        json,
      ).map(MultiKolabRoleApplication.fromJson).toList(growable: false),
    );
  }

  @override
  Future<MultiKolabEvent> confirmEvent(String eventId) {
    return _request(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId/confirm'),
        headers: await _headers(),
      ),
      (json) => MultiKolabEvent.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabEvent> completeEvent(String eventId) {
    return _request(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId/complete'),
        headers: await _headers(),
      ),
      (json) => MultiKolabEvent.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabEvent> publish(String eventId) {
    return _request(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId/publish'),
        headers: await _headers(),
      ),
      (json) => MultiKolabEvent.fromJson(_data(json)),
    );
  }

  @override
  Future<List<MultiKolabEventSummary>> explore(MultiKolabExploreFilter filter) {
    final uri = Uri.parse(
      '$_baseUrl/multi-kolab-events',
    ).replace(queryParameters: filter.toQuery());
    return _request(
      () async => _httpClient.get(uri, headers: await _headers()),
      (json) => _dataList(
        json,
      ).map(MultiKolabEventSummary.fromJson).toList(growable: false),
    );
  }

  @override
  Future<List<MultiKolabEventSummary>> myEvents() {
    return _request(
      () async => _httpClient.get(
        Uri.parse('$_baseUrl/multi-kolab-events/me'),
        headers: await _headers(),
      ),
      (json) => _dataList(
        json,
      ).map(MultiKolabEventSummary.fromJson).toList(growable: false),
    );
  }

  @override
  Future<MultiKolabEvent> getEvent(String eventId) {
    return _request(
      () async => _httpClient.get(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId'),
        headers: await _headers(),
      ),
      (json) => MultiKolabEvent.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabRoleApplication> apply(
    String roleId,
    CreateMultiKolabApplicationInput input,
  ) {
    return _request(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/multi-kolab-roles/$roleId/applications'),
        headers: await _headers(),
        body: jsonEncode(input.toJson()),
      ),
      (json) => MultiKolabRoleApplication.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabDashboard> getDashboard(String eventId) {
    return _request(
      () async => _httpClient.get(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId/dashboard'),
        headers: await _headers(),
      ),
      (json) => MultiKolabDashboard.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabRoleApplication> shortlist(String applicationId) {
    return _request(
      () async => _httpClient.post(
        Uri.parse(
          '$_baseUrl/multi-kolab-role-applications/$applicationId/shortlist',
        ),
        headers: await _headers(),
      ),
      (json) => MultiKolabRoleApplication.fromJson(_data(json)),
    );
  }

  @override
  Future<ChildKolabResult> accept(String applicationId) {
    return _request(
      () async => _httpClient.post(
        Uri.parse(
          '$_baseUrl/multi-kolab-role-applications/$applicationId/accept',
        ),
        headers: await _headers(),
      ),
      (json) => ChildKolabResult.fromJson(_data(json)),
    );
  }

  @override
  Future<MultiKolabRoleApplication> decline(String applicationId) {
    return _request(
      () async => _httpClient.post(
        Uri.parse(
          '$_baseUrl/multi-kolab-role-applications/$applicationId/decline',
        ),
        headers: await _headers(),
      ),
      (json) => MultiKolabRoleApplication.fromJson(_data(json)),
    );
  }

  @override
  Future<void> withdraw(String applicationId, String reason) {
    return _request(
      () async => _httpClient.post(
        Uri.parse(
          '$_baseUrl/multi-kolab-role-applications/$applicationId/withdraw',
        ),
        headers: await _headers(),
        body: jsonEncode({'reason': reason}),
      ),
      (_) => null,
    );
  }

  @override
  Future<void> cancelEvent(String eventId, String reason) {
    return _request(
      () async => _httpClient.post(
        Uri.parse('$_baseUrl/multi-kolab-events/$eventId/cancel'),
        headers: await _headers(),
        body: jsonEncode({'reason': reason}),
      ),
      (_) => null,
    );
  }

  @override
  Future<EventCreatorEntitlement> getEntitlement() {
    return _request(
      () async => _httpClient.get(
        Uri.parse('$_baseUrl/me/organizer-entitlement'),
        headers: await _headers(),
      ),
      (json) => EventCreatorEntitlement.fromJson(_data(json)),
    );
  }
}

/// The stable, machine-readable error code from an [ApiException] thrown by
/// this repository — e.g. `role_ineligible`, `event_not_recruiting`,
/// `role_not_open`, `duplicate_application`, `role_capacity_exceeded`,
/// `event_creator_required`, `not_owner`, `invalid_transition`. Screens
/// should switch on this, never on [ApiError.message] (contract §10).
extension MultiKolabApiErrorCode on ApiError {
  String? get stableCode {
    final values = errors?.values;
    if (values == null || values.isEmpty) return null;
    final first = values.first;
    return first.isEmpty ? null : first.first;
  }
}
