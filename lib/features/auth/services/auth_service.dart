import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../config/constants/api.dart';
import '../../onboarding/models/onboarding_state.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// Storage keys for auth data
const String _tokenKey = 'auth_token';
const String _refreshTokenKey = 'auth_refresh_token';
const String _userKey = 'auth_user';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Mock mode flag - set to false to use real API
const bool _useMockApi = false;

enum AuthSessionChange { cleared }

/// Auth service for handling authentication
class AuthService {
  AuthService({
    FlutterSecureStorage? secureStorage,
    GoogleSignIn? googleSignIn,
    http.Client? httpClient,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             clientId:
                 '729026342484-2hnsoraikrr6cdtot0bl5a7hlhg57r3p.apps.googleusercontent.com',
             scopes: ['email', 'profile'],
           ),
       _httpClient = httpClient ?? http.Client();

  final FlutterSecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;
  final http.Client _httpClient;

  /// Cached token
  String? _cachedToken;

  /// Cached user
  UserModel? _cachedUser;

  /// Cached refresh token
  String? _cachedRefreshToken;

  /// Shared refresh coordination across all auth service instances in-process.
  static Future<String>? _sharedRefreshRequest;

  /// Shared session version. Any login, logout, or token refresh rotates this
  /// so stale instances drop cached credentials and ignore late responses.
  static int _sharedSessionEpoch = 0;
  static final StreamController<AuthSessionChange> _sessionChangesController =
      StreamController<AuthSessionChange>.broadcast(sync: true);

  int _knownSessionEpoch = _sharedSessionEpoch;

  static Stream<AuthSessionChange> get sessionChanges =>
      _sessionChangesController.stream;

  // ---------------------------------------------------------------------------
  // Google Sign In
  // ---------------------------------------------------------------------------

  /// Sign in with Google and get ID token
  Future<String> getGoogleIdToken() async {
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();

      if (account == null) {
        throw const AuthCancelledException();
      }

      final auth = await account.authentication;

      if (auth.idToken == null) {
        throw const AuthException('Failed to get Google ID token');
      }

      return auth.idToken!;
    } on AuthCancelledException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('Google Sign In error: $e');
      throw AuthException('Google Sign In failed: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } on Exception catch (e) {
      debugPrint('Google Sign Out error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // FCM Device Token
  // ---------------------------------------------------------------------------

  /// Register FCM device token with backend.
  ///
  /// POST /api/v1/me/device-token
  /// Call after successful login (any method).
  Future<void> registerDeviceToken(
    String fcmToken, {
    String? appVersion,
    String? locale,
    String? timezone,
    double? lastLocationLat,
    double? lastLocationLng,
    DateTime? locationPermissionGrantedAt,
  }) async {
    final token = await getToken();
    if (token == null) return;

    final url = '$_baseUrl/me/device-token';
    debugPrint('[FCM] Registering device token: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
          if (appVersion != null && appVersion.isNotEmpty)
            'app_version': appVersion,
          if (locale != null && locale.isNotEmpty) 'locale': locale,
          if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
          if (lastLocationLat != null) 'last_location_lat': lastLocationLat,
          if (lastLocationLng != null) 'last_location_lng': lastLocationLng,
          if (locationPermissionGrantedAt != null)
            'location_permission_granted_at': locationPermissionGrantedAt
                .toIso8601String(),
        }),
      );
      debugPrint('[FCM] Register token response: ${response.statusCode}');
    } on Exception catch (e) {
      debugPrint('[FCM] Register token error: $e');
      // Non-fatal: don't throw, just log
    }
  }

  /// Remove FCM device token from backend.
  ///
  /// DELETE /api/v1/me/device-token
  Future<void> removeDeviceToken(String fcmToken) async {
    final token = await getToken();
    if (token == null) return;

    final url = '$_baseUrl/me/device-token';
    debugPrint('[FCM] Removing device token: DELETE $url');

    try {
      final request = http.Request('DELETE', Uri.parse(url))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        })
        ..body = jsonEncode({'token': fcmToken});

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint('[FCM] Remove token response: ${response.statusCode}');
    } on Exception catch (e) {
      debugPrint('[FCM] Remove token error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Registration APIs
  // ---------------------------------------------------------------------------

  /// Register business user with all onboarding data
  ///
  /// POST /api/v1/auth/register/business
  Future<AuthResponse> registerBusiness({
    required String email,
    required String password,
    required OnboardingData onboardingData,
  }) async {
    if (_useMockApi) {
      return _mockRegister(email, password, UserType.business);
    }

    final url = '$_baseUrl/auth/register/business';
    debugPrint('🔐 Register Business: POST $url');

    try {
      final body = {
        'email': email,
        'password': password,
        'password_confirmation': password,
        ...onboardingData.toBusinessPayload(),
      };

      debugPrint('🔐 Request body keys: ${body.keys.toList()}');

      // [B6] Audit photo-shape mix — backend rejects mixed shapes silently.
      final photos = onboardingData.venuePhotos;
      final uploadCount = photos.where((p) => p.isUploaded).length;
      final googleCount = photos.where((p) => p.isGoogleImported).length;
      final hostedCount = photos.where((p) => p.isHosted).length;
      debugPrint(
        '[B6] venue photos: total=${photos.length} '
        'upload=$uploadCount google=$googleCount hosted=$hostedCount',
      );

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('🔐 Response status: ${response.statusCode}');
      debugPrint(
        '🔐 Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(json);
        await _saveAuthData(authResponse);
        return authResponse;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('🔐 Register business error: $e');
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Register community user with all onboarding data
  ///
  /// POST /api/v1/auth/register/community
  Future<AuthResponse> registerCommunity({
    required String email,
    required String password,
    required OnboardingData onboardingData,
  }) async {
    if (_useMockApi) {
      return _mockRegister(email, password, UserType.community);
    }

    final url = '$_baseUrl/auth/register/community';
    debugPrint('🔐 Register Community: POST $url');

    try {
      final body = {
        'email': email,
        'password': password,
        'password_confirmation': password,
        'name': onboardingData.name?.trim(),
        'community_type': onboardingData.typeSlug,
        'city_id': onboardingData.cityId,
        if (onboardingData.about != null && onboardingData.about!.isNotEmpty)
          'about': onboardingData.about,
        if (onboardingData.phone != null && onboardingData.phone!.isNotEmpty)
          'phone_number': onboardingData.phone,
        if (onboardingData.instagram != null &&
            onboardingData.instagram!.isNotEmpty)
          'instagram': onboardingData.instagram,
        if (onboardingData.tiktok != null && onboardingData.tiktok!.isNotEmpty)
          'tiktok': onboardingData.tiktok,
        if (onboardingData.website != null &&
            onboardingData.website!.isNotEmpty)
          'website': onboardingData.website,
        if (onboardingData.photoBase64 != null)
          'profile_photo': _buildProfilePhotoDataUri(onboardingData),
      };

      debugPrint('🔐 Request body keys: ${body.keys.toList()}');

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('🔐 Response status: ${response.statusCode}');
      debugPrint(
        '🔐 Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(json);
        await _saveAuthData(authResponse);
        return authResponse;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('🔐 Register community error: $e');
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Build profile photo data URI
  String? _buildProfilePhotoDataUri(OnboardingData data) {
    if (data.photoBase64 == null) return null;
    final mimeType = data.photoMimeType ?? 'image/jpeg';
    return 'data:$mimeType;base64,${data.photoBase64}';
  }

  /// Register attendee user (minimal payload)
  ///
  /// POST /api/v1/auth/register/attendee
  Future<AuthResponse> registerAttendee({
    required String email,
    required String password,
  }) async {
    if (_useMockApi) {
      return _mockRegister(email, password, UserType.attendee);
    }

    final url = '$_baseUrl/auth/register/attendee';
    debugPrint('🔐 Register Attendee: POST $url');

    try {
      final body = {
        'email': email,
        'password': password,
        'password_confirmation': password,
      };

      debugPrint('🔐 Request body keys: ${body.keys.toList()}');

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('🔐 Response status: ${response.statusCode}');
      debugPrint(
        '🔐 Response body (first 500 chars): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(json);
        await _saveAuthData(authResponse);
        return authResponse;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('🔐 Register attendee error: $e');
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Mock registration for development
  Future<AuthResponse> _mockRegister(
    String email,
    String password,
    UserType userType,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final mockUser = UserModel(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      userType: userType,
      createdAt: DateTime.now(),
    );

    final authResponse = AuthResponse(
      success: true,
      message: 'Registration successful',
      token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'Bearer',
      isNewUser: true,
      user: mockUser,
    );

    await _saveAuthData(authResponse);
    return authResponse;
  }

  // ---------------------------------------------------------------------------
  // Password Reset APIs
  // ---------------------------------------------------------------------------

  /// Send password reset email
  ///
  /// POST /api/v1/auth/forgot-password
  Future<void> forgotPassword({required String email}) async {
    final url = '$_baseUrl/auth/forgot-password';
    debugPrint('🔐 Forgot Password: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      debugPrint('🔐 Forgot password response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('🔐 Forgot password error: $e');
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Reset password with token from email
  ///
  /// POST /api/v1/auth/reset-password
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = '$_baseUrl/auth/reset-password';
    debugPrint('🔐 Reset Password: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      debugPrint('🔐 Reset password response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('🔐 Reset password error: $e');
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Login APIs
  // ---------------------------------------------------------------------------

  /// Login with email and password
  ///
  /// POST /api/v1/auth/login
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (_useMockApi) {
      return _mockLogin(email, password);
    }

    final url = '$_baseUrl/auth/login';
    debugPrint('🔐 Login: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('🔐 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(json);
        await _saveAuthData(authResponse);
        debugPrint(
          '[AUTH] login success: userType=${authResponse.user.userType} '
          'hasRefreshToken=${authResponse.refreshToken != null && authResponse.refreshToken!.isNotEmpty}',
        );
        return authResponse;
      } else {
        debugPrint('[AUTH] login non-200: ${response.statusCode}');
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('[AUTH] login network error: $e');
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Mock login for development
  Future<AuthResponse> _mockLogin(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Simulate invalid credentials
    if (password.length < 8) {
      throw ApiException(
        error: ApiError(
          message: 'Invalid credentials',
          errors: {
            'email': ['The provided credentials are incorrect.'],
          },
          statusCode: 401,
        ),
      );
    }

    final mockUser = UserModel(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      userType: UserType.business,
      createdAt: DateTime.now(),
    );

    final authResponse = AuthResponse(
      success: true,
      message: 'Login successful',
      token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'Bearer',
      isNewUser: false,
      user: mockUser,
    );

    await _saveAuthData(authResponse);
    return authResponse;
  }

  /// Login with Google (existing users only)
  ///
  /// POST /api/v1/auth/google
  Future<AuthResponse> loginWithGoogle({String? userType}) async {
    try {
      final idToken = await getGoogleIdToken();

      // If userType not provided, try to resolve from stored user data.
      final resolvedUserType =
          userType ?? (await getStoredUser())?.userType.toApiValue();

      return await _authenticateWithGoogle(idToken, userType: resolvedUserType);
    } on AuthCancelledException {
      rethrow;
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw AuthException('Google login failed: $e');
    }
  }

  /// Authenticate with backend using Google ID token
  Future<AuthResponse> _authenticateWithGoogle(
    String idToken, {
    String? userType,
  }) async {
    if (_useMockApi) {
      return _mockAuthenticateWithGoogle(idToken);
    }

    final url = '$_baseUrl/auth/google';
    debugPrint('🔐 Google Login: POST $url');

    try {
      final body = <String, dynamic>{'id_token': idToken};
      if (userType != null) body['user_type'] = userType;

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('🔐 Google login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(json);
        await _saveAuthData(authResponse);
        return authResponse;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  /// Mock Google authentication for development
  Future<AuthResponse> _mockAuthenticateWithGoogle(String idToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final random = Random();

    // 10% chance of user not found error (for testing)
    if (random.nextDouble() < 0.1) {
      throw ApiException(
        error: ApiError(
          message: 'User not found',
          errors: {
            'email': [
              'No account found with this Google email. Please register first.',
            ],
          },
          statusCode: 404,
        ),
      );
    }

    final mockUser = UserModel(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: 'user@example.com',
      userType: UserType.business,
      avatarUrl: 'https://lh3.googleusercontent.com/a/default-user',
      createdAt: DateTime.now(),
    );

    final authResponse = AuthResponse(
      success: true,
      message: 'Login successful',
      token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'Bearer',
      isNewUser: false,
      user: mockUser,
    );

    await _saveAuthData(authResponse);
    return authResponse;
  }

  // ---------------------------------------------------------------------------
  // Apple Sign In
  // ---------------------------------------------------------------------------

  /// Sign in with Apple and get identity token.
  Future<({String identityToken, String? fullName})>
  getAppleCredential() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw const AuthException('Failed to get Apple identity token');
      }

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((n) => n != null && n.isNotEmpty).join(' ');

      return (
        identityToken: credential.identityToken!,
        fullName: fullName.isEmpty ? null : fullName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      throw AuthException('Apple Sign In failed: ${e.message}');
    } on AuthCancelledException {
      rethrow;
    } on Exception catch (e) {
      throw AuthException('Apple Sign In failed: $e');
    }
  }

  /// Login with Apple.
  ///
  /// POST /api/v1/auth/apple
  Future<AuthResponse> loginWithApple() async {
    try {
      final credential = await getAppleCredential();
      return await _authenticateWithApple(
        credential.identityToken,
        credential.fullName,
      );
    } on AuthCancelledException {
      rethrow;
    } on Exception catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      debugPrint('Apple login error: $e');
      throw AuthException('Apple login failed: $e');
    }
  }

  Future<AuthResponse> _authenticateWithApple(
    String identityToken,
    String? fullName,
  ) async {
    final url = '$_baseUrl/auth/apple';
    debugPrint('[Apple] Login: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'identity_token': identityToken,
          if (fullName != null) 'name': fullName,
        }),
      );

      debugPrint('[Apple] Login response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(json);
        await _saveAuthData(authResponse);
        return authResponse;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException) {
        rethrow;
      }
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // User APIs
  // ---------------------------------------------------------------------------

  /// Get current user from API
  ///
  /// GET /api/v1/auth/me
  Future<UserModel> getCurrentUser() async {
    return _getCurrentUser(allowRefresh: true);
  }

  Future<UserModel> _getCurrentUser({required bool allowRefresh}) async {
    final token = await getToken();
    final sessionEpoch = _sharedSessionEpoch;

    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    if (_useMockApi) {
      return _mockGetCurrentUser();
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (sessionEpoch != _sharedSessionEpoch) {
          throw const AuthException('Session expired. Please sign in again.');
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data);
        await _saveUser(user);
        _cachedUser = user;
        return user;
      } else if (response.statusCode == 401) {
        if (allowRefresh) {
          await refreshSession();
          return _getCurrentUser(allowRefresh: false);
        }
        await _purgeSession();
        throw const AuthException('Session expired. Please sign in again.');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          error: ApiError.fromJson(json, statusCode: response.statusCode),
        );
      }
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException('Failed to get user: $e');
    }
  }

  /// Mock get current user for development
  Future<UserModel> _mockGetCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_cachedUser != null) {
      return _cachedUser!;
    }

    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson != null) {
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      _cachedUser = UserModel.fromJson(json);
      return _cachedUser!;
    }

    throw const AuthException('No user data found');
  }

  /// Logout user
  ///
  /// POST /api/v1/auth/logout
  Future<void> logout() async {
    final token = await getToken();
    await _purgeSession();

    try {
      await signOutGoogle();

      if (_useMockApi || token == null) {
        return;
      }

      await _httpClient.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } on Exception catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Token Management
  // ---------------------------------------------------------------------------

  /// Get stored auth token
  Future<String?> getToken() async {
    _syncLocalCachesWithSharedSession();
    if (_cachedToken != null) {
      return _cachedToken;
    }

    return _cachedToken = await _secureStorage.read(key: _tokenKey);
  }

  /// Get stored refresh token.
  Future<String?> getRefreshToken() async {
    _syncLocalCachesWithSharedSession();
    if (_cachedRefreshToken != null) {
      return _cachedRefreshToken;
    }

    return _cachedRefreshToken = await _secureStorage.read(
      key: _refreshTokenKey,
    );
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  /// Restore the best available authenticated user without destroying
  /// persisted auth on transient refresh failures.
  Future<UserModel?> restoreSessionUser() async {
    final token = await getToken();
    if (token == null) {
      return null;
    }

    final storedUser = await getStoredUser();

    try {
      return await getCurrentUser();
    } on AuthException {
      await _purgeSession();
      return null;
    } on NetworkException {
      return storedUser;
    } on ApiException {
      return storedUser;
    }
  }

  /// Refresh the access token using the persisted refresh token.
  Future<String> refreshSession() async {
    final existingRequest = _sharedRefreshRequest;
    if (existingRequest != null) {
      return existingRequest;
    }

    final refreshRequest = _performRefreshSession();
    _sharedRefreshRequest = refreshRequest;

    try {
      return await refreshRequest;
    } finally {
      if (identical(_sharedRefreshRequest, refreshRequest)) {
        _sharedRefreshRequest = null;
      }
    }
  }

  Future<String> _performRefreshSession() async {
    _syncLocalCachesWithSharedSession();
    final sessionEpoch = _sharedSessionEpoch;
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint('[AUTH] refresh aborted: no refresh token stored');
      await _purgeSession();
      throw const AuthException('Session expired. Please sign in again.');
    }

    final url = '$_baseUrl/auth/refresh';
    final tokenTail = refreshToken.length >= 6
        ? refreshToken.substring(refreshToken.length - 6)
        : refreshToken;
    final startedAt = DateTime.now();
    debugPrint('[AUTH] refresh start: tokenTail=…$tokenTail url=$url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint(
        '[AUTH] refresh done: status=${response.statusCode} elapsed=${elapsed}ms',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final refreshResponse = SessionRefreshResponse.fromJson(json);
        if (sessionEpoch != _sharedSessionEpoch) {
          throw const AuthException('Session expired. Please sign in again.');
        }
        await _saveSessionRefreshData(refreshResponse);
        return refreshResponse.token;
      }

      if (response.statusCode == 401) {
        await _purgeSession();
        throw const AuthException('Session expired. Please sign in again.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        error: ApiError.fromJson(json, statusCode: response.statusCode),
      );
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      debugPrint('🔐 Refresh session error: $e');
      throw NetworkException('Failed to refresh session: $e');
    }
  }

  /// Save auth data to secure storage
  Future<void> _saveAuthData(AuthResponse response) async {
    _invalidateSharedSession();
    await _saveTokens(
      token: response.token,
      refreshToken: response.refreshToken,
    );
    await _saveUser(response.user);
  }

  Future<void> _saveSessionRefreshData(SessionRefreshResponse response) async {
    _invalidateSharedSession();
    await _saveTokens(
      token: response.token,
      refreshToken: response.refreshToken,
    );
    if (response.user != null) {
      await _saveUser(response.user!);
    }
  }

  Future<void> _saveTokens({
    required String token,
    String? refreshToken,
  }) async {
    _cachedToken = token;
    await _secureStorage.write(key: _tokenKey, value: token);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      _cachedRefreshToken = refreshToken;
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> _saveUser(UserModel user) async {
    _cachedUser = user;
    await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  /// Get cached user
  UserModel? get cachedUser {
    _syncLocalCachesWithSharedSession();
    return _cachedUser;
  }

  /// Get stored user from secure storage
  Future<UserModel?> getStoredUser() async {
    _syncLocalCachesWithSharedSession();
    if (_cachedUser != null) return _cachedUser;

    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null) {
        final json = jsonDecode(userJson) as Map<String, dynamic>;
        _cachedUser = UserModel.fromJson(json);
        return _cachedUser;
      }
    } on Exception catch (e) {
      debugPrint('Get stored user error: $e');
    }
    return null;
  }

  void _syncLocalCachesWithSharedSession() {
    if (_knownSessionEpoch == _sharedSessionEpoch) {
      return;
    }

    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
    _knownSessionEpoch = _sharedSessionEpoch;
  }

  void _invalidateSharedSession() {
    _sharedSessionEpoch++;
    _sharedRefreshRequest = null;
    _knownSessionEpoch = _sharedSessionEpoch;
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUser = null;
  }

  Future<void> _purgeSession() async {
    _invalidateSharedSession();
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _userKey);
    _sessionChangesController.add(AuthSessionChange.cleared);
  }
}

/// Exception thrown when authentication is cancelled by user
class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'AuthCancelledException: User cancelled sign in';
}

/// Generic authentication exception
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
