import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/models/auth_response.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/auth_service.dart';
import '../models/notification_preferences.dart';
import '../models/subscription.dart';
import '../../../config/constants/api.dart';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Profile service for managing user profile, notifications, and subscription
class ProfileService {
  ProfileService({AuthService? authService, http.Client? httpClient})
    : _authService = authService ?? AuthService(),
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  /// Get authorization headers
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
  // Profile APIs
  // ---------------------------------------------------------------------------

  /// Get user profile
  ///
  /// GET /api/v1/me/profile
  Future<UserModel> getProfile() async {
    final url = '$_baseUrl/me/profile';
    debugPrint('Profile: GET $url');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient
            .get(Uri.parse(url), headers: await _getHeaders())
            .timeout(const Duration(seconds: 15)),
        allowRetry: true,
      );

      debugPrint('Profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return UserModel.fromJson(data);
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
      debugPrint('Get profile error: $e');
      throw NetworkException('Failed to get profile: $e');
    }
  }

  /// Update user profile
  ///
  /// PUT /api/v1/me/profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final url = '$_baseUrl/me/profile';
    debugPrint('Profile: PUT $url');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.put(
          Uri.parse(url),
          headers: await _getHeaders(),
          body: jsonEncode(data),
        ),
        allowRetry: true,
      );

      debugPrint('Update profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = json['data'] as Map<String, dynamic>;
        return UserModel.fromJson(responseData);
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
      debugPrint('Update profile error: $e');
      throw NetworkException('Failed to update profile: $e');
    }
  }

  /// Delete account
  ///
  /// DELETE /api/v1/me/account
  Future<void> deleteAccount() async {
    final url = '$_baseUrl/me/account';
    debugPrint('Profile: DELETE $url');

    try {
      final response = await _sendWithRefresh(
        () async =>
            _httpClient.delete(Uri.parse(url), headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Delete account response status: ${response.statusCode}');

      if (response.statusCode == 200) {
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
      debugPrint('Delete account error: $e');
      throw NetworkException('Failed to delete account: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Notification Preferences APIs
  // ---------------------------------------------------------------------------

  /// Get notification preferences
  ///
  /// GET /api/v1/me/notification-preferences
  Future<NotificationPreferences> getNotificationPreferences() async {
    final url = '$_baseUrl/me/notification-preferences';
    debugPrint('Profile: GET $url');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient
            .get(Uri.parse(url), headers: await _getHeaders())
            .timeout(const Duration(seconds: 15)),
        allowRetry: true,
      );

      debugPrint(
        'Get notification preferences response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return NotificationPreferences.fromJson(data);
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
      debugPrint('Get notification preferences error: $e');
      throw NetworkException('Failed to get notification preferences: $e');
    }
  }

  /// Update notification preferences
  ///
  /// PUT /api/v1/me/notification-preferences
  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> prefs,
  ) async {
    final url = '$_baseUrl/me/notification-preferences';
    debugPrint('Profile: PUT $url');

    try {
      final response = await _sendWithRefresh(
        () async => _httpClient.put(
          Uri.parse(url),
          headers: await _getHeaders(),
          body: jsonEncode(prefs),
        ),
        allowRetry: true,
      );

      debugPrint(
        'Update notification preferences response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return NotificationPreferences.fromJson(data);
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
      debugPrint('Update notification preferences error: $e');
      throw NetworkException('Failed to update notification preferences: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Subscription APIs (Business only)
  // ---------------------------------------------------------------------------

  /// Get subscription
  ///
  /// GET /api/v1/me/subscription
  Future<Subscription?> getSubscription() async {
    final url = '$_baseUrl/me/subscription';
    debugPrint('Profile: GET $url');

    try {
      final response = await _sendWithRefresh(
        () async =>
            _httpClient.get(Uri.parse(url), headers: await _getHeaders()),
        allowRetry: true,
      );

      debugPrint('Get subscription response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'];
        if (data == null) return null;
        return Subscription.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw const AuthException('Session expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        // Community users get 403
        return null;
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
      debugPrint('Get subscription error: $e');
      throw NetworkException('Failed to get subscription: $e');
    }
  }

  /// Create checkout session for subscription
  ///
  /// POST /api/v1/me/subscription/checkout
  Future<String> createCheckoutSession({
    required String successUrl,
    required String cancelUrl,
  }) async {
    final url = '$_baseUrl/me/subscription/checkout';
    debugPrint('Profile: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({'success_url': successUrl, 'cancel_url': cancelUrl}),
      );

      debugPrint(
        'Create checkout session response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return data['checkout_url'] as String;
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
      debugPrint('Create checkout session error: $e');
      throw NetworkException('Failed to create checkout session: $e');
    }
  }

  /// Get billing portal URL
  ///
  /// GET /api/v1/me/subscription/portal
  Future<String> getBillingPortalUrl({String? returnUrl}) async {
    var url = '$_baseUrl/me/subscription/portal';
    if (returnUrl != null) {
      url += '?return_url=${Uri.encodeComponent(returnUrl)}';
    }
    debugPrint('Profile: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      debugPrint('Get billing portal response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return data['portal_url'] as String;
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
      debugPrint('Get billing portal error: $e');
      throw NetworkException('Failed to get billing portal: $e');
    }
  }

  /// Cancel subscription
  ///
  /// POST /api/v1/me/subscription/cancel
  Future<Subscription> cancelSubscription() async {
    final url = '$_baseUrl/me/subscription/cancel';
    debugPrint('Profile: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      debugPrint('Cancel subscription response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Subscription.fromJson(data);
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
      debugPrint('Cancel subscription error: $e');
      throw NetworkException('Failed to cancel subscription: $e');
    }
  }

  /// Reactivate subscription (undo scheduled cancellation)
  ///
  /// POST /api/v1/me/subscription/reactivate
  Future<Subscription> reactivateSubscription() async {
    final url = '$_baseUrl/me/subscription/reactivate';
    debugPrint('Profile: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      debugPrint(
        'Reactivate subscription response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Subscription.fromJson(data);
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
      debugPrint('Reactivate subscription error: $e');
      throw NetworkException('Failed to reactivate subscription: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Apple IAP APIs
  // ---------------------------------------------------------------------------

  /// Verify Apple IAP transaction with backend
  ///
  /// POST /api/v1/me/subscription/apple-verify
  Future<Subscription> verifyApplePurchase({
    required String transactionId,
    required String originalTransactionId,
    required String productId,
  }) async {
    final url = '$_baseUrl/me/subscription/apple-verify';
    debugPrint('Profile: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({
          'transaction_id': transactionId,
          'original_transaction_id': originalTransactionId,
          'product_id': productId,
        }),
      );

      debugPrint('Apple verify response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 409) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Subscription.fromJson(data);
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
      debugPrint('Apple verify error: $e');
      throw NetworkException('Failed to verify Apple purchase: $e');
    }
  }

  /// Restore Apple purchases
  ///
  /// POST /api/v1/me/subscription/apple-restore
  Future<Subscription?> restoreApplePurchases({
    required List<Map<String, String>> transactions,
  }) async {
    final url = '$_baseUrl/me/subscription/apple-restore';
    debugPrint('Profile: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({'transactions': transactions}),
      );

      debugPrint('Apple restore response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        return Subscription.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
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
      debugPrint('Apple restore error: $e');
      throw NetworkException('Failed to restore Apple purchases: $e');
    }
  }
}
