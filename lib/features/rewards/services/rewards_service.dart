import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../config/constants/api.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/ledger_entry.dart';
import '../models/reward_badge.dart';
import '../models/wallet_model.dart' show XpModel;

/// API base URL
const String _baseUrl = ApiConfig.baseUrl;

/// Service for Rewards/Gamification API endpoints.
class RewardsService {
  RewardsService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  @visibleForTesting
  AuthService get authService => _authService;

  Future<Map<String, String>> _getHeaders() async {
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
  // Wallet
  // ---------------------------------------------------------------------------

  /// GET /api/v1/gamification/wallet
  Future<XpModel> getWallet() async {
    final uri = Uri.parse('$_baseUrl/gamification/wallet');
    debugPrint('RewardsService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Wallet response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return XpModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Get wallet error: $e');
      throw NetworkException('Failed to load wallet: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Ledger
  // ---------------------------------------------------------------------------

  /// GET /api/v1/gamification/ledger?page=1&per_page=20
  Future<List<LedgerEntry>> getLedger({int page = 1, int perPage = 20}) async {
    final uri = Uri.parse('$_baseUrl/gamification/ledger').replace(
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );
    debugPrint('RewardsService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Ledger response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List;
        return data
            .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Get ledger error: $e');
      throw NetworkException('Failed to load points history: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Badges
  // ---------------------------------------------------------------------------

  /// GET /api/v1/gamification/badges
  Future<List<RewardBadge>> getBadges() async {
    final uri = Uri.parse('$_baseUrl/gamification/badges');
    debugPrint('RewardsService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Badges response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List;
        return data
            .map((e) => RewardBadge.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Get badges error: $e');
      throw NetworkException('Failed to load badges: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Referral Code
  // ---------------------------------------------------------------------------

  /// GET /api/v1/gamification/referral-code
  /// Returns code, referral link, and total qualified conversions.
  Future<({String code, String link, int totalConversions})> getReferralCode() async {
    final uri = Uri.parse('$_baseUrl/gamification/referral-code');
    debugPrint('RewardsService: GET $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.get(uri, headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Referral code response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        final rawConversions = data['total_conversions'];
        return (
          code: data['code'] as String,
          link:
              data['referral_link'] as String? ??
              'https://kolabing.com/ref/${data['code']}',
          totalConversions: rawConversions is int
              ? rawConversions
              : int.tryParse(rawConversions?.toString() ?? '') ?? 0,
        );
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Get referral code error: $e');
      throw NetworkException('Failed to load referral code: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Withdrawal
  // ---------------------------------------------------------------------------

  /// POST /api/v1/gamification/withdrawal
  Future<void> requestWithdrawal({
    required String iban,
    required String accountHolder,
  }) async {
    final uri = Uri.parse('$_baseUrl/gamification/withdrawal');
    debugPrint('RewardsService: POST $uri');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.post(
          uri,
          headers: await _getHeaders(),
          body: jsonEncode({'iban': iban, 'account_holder': accountHolder}),
        ),
        allowRetry: true,
      );

      debugPrint('Withdrawal response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(error: ApiError.fromJson(json, statusCode: 400));
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 409) {
        throw const ApiException(
          error: ApiError(message: 'A withdrawal is already pending.'),
        );
      } else {
        throw _parseApiError(response);
      }
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Withdrawal error: $e');
      throw NetworkException('Failed to request withdrawal: $e');
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
    } catch (_) {
      return ApiException(
        error: ApiError(
          message: 'Server error (${response.statusCode})',
          statusCode: response.statusCode,
        ),
      );
    }
  }
}

/// Provider for the rewards service.
final rewardsServiceProvider = Provider<RewardsService>(
  (ref) => RewardsService(authService: ref.watch(authServiceProvider)),
);
