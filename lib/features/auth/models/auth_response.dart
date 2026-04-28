import 'user_model.dart';

/// Auth response from POST /auth/google
class AuthResponse {
  const AuthResponse({
    required this.success,
    required this.token,
    required this.tokenType,
    required this.isNewUser,
    required this.user,
    this.refreshToken,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw const FormatException('Invalid auth response: missing data');
    }

    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      token: data['token'] as String,
      tokenType: data['token_type'] as String? ?? 'Bearer',
      refreshToken: data['refresh_token'] as String?,
      isNewUser: data['is_new_user'] as bool? ?? false,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  final bool success;
  final String? message;
  final String token;
  final String tokenType;
  final String? refreshToken;
  final bool isNewUser;
  final UserModel user;

  /// Full authorization header value
  String get authorizationHeader => '$tokenType $token';

  Map<String, dynamic> toJson() => {
    'success': success,
    if (message != null) 'message': message,
    'data': {
      'token': token,
      'token_type': tokenType,
      if (refreshToken != null) 'refresh_token': refreshToken,
      'is_new_user': isNewUser,
      'user': user.toJson(),
    },
  };
}

/// Session refresh response from POST /auth/refresh.
class SessionRefreshResponse {
  const SessionRefreshResponse({
    required this.token,
    required this.tokenType,
    this.refreshToken,
    this.user,
  });

  factory SessionRefreshResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    final token = (data['token'] ?? data['access_token']) as String?;
    if (token == null || token.isEmpty) {
      throw const FormatException('Invalid refresh response: missing token');
    }

    return SessionRefreshResponse(
      token: token,
      tokenType: data['token_type'] as String? ?? 'Bearer',
      refreshToken: data['refresh_token'] as String?,
      user: data['user'] is Map<String, dynamic>
          ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
          : null,
    );
  }

  final String token;
  final String tokenType;
  final String? refreshToken;
  final UserModel? user;
}

/// Google auth request body
class GoogleAuthRequest {
  const GoogleAuthRequest({required this.idToken, required this.userType});

  final String idToken;
  final UserType userType;

  Map<String, dynamic> toJson() => {
    'id_token': idToken,
    'user_type': userType.toApiValue(),
  };
}

/// User me response from GET /auth/me
class UserMeResponse {
  const UserMeResponse({required this.success, required this.user});

  factory UserMeResponse.fromJson(Map<String, dynamic> json) => UserMeResponse(
    success: json['success'] as bool? ?? false,
    user: UserModel.fromJson(json['data'] as Map<String, dynamic>),
  );

  final bool success;
  final UserModel user;

  Map<String, dynamic> toJson() => {'success': success, 'data': user.toJson()};
}

/// Logout response from POST /auth/logout
class LogoutResponse {
  const LogoutResponse({required this.success, this.message});

  factory LogoutResponse.fromJson(Map<String, dynamic> json) => LogoutResponse(
    success: json['success'] as bool? ?? false,
    message: json['message'] as String?,
  );

  final bool success;
  final String? message;

  Map<String, dynamic> toJson() => {
    'success': success,
    if (message != null) 'message': message,
  };
}

/// API error response
class ApiError {
  const ApiError({
    required this.message,
    this.errors,
    this.statusCode,
    this.requiresSubscription = false,
  });

  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) =>
      ApiError(
        message: json['message'] as String? ?? 'Unknown error',
        errors: json['errors'] != null
            ? (json['errors'] as Map<String, dynamic>).map(
                (key, value) =>
                    MapEntry(key, (value as List<dynamic>).cast<String>()),
              )
            : null,
        statusCode: statusCode,
        requiresSubscription: json['requires_subscription'] as bool? ?? false,
      );

  final String message;
  final Map<String, List<String>>? errors;
  final int? statusCode;
  final bool requiresSubscription;

  /// Check if this is a user type mismatch error (409)
  bool get isUserTypeMismatch => statusCode == 409;

  /// Check if this is a validation error (422)
  bool get isValidationError => statusCode == 422;

  /// Check if this is an authentication error (401)
  bool get isAuthError => statusCode == 401;

  /// Check if this is a forbidden error (403)
  bool get isForbidden => statusCode == 403;

  /// Get first error message for a field
  String? getFieldError(String field) => errors?[field]?.firstOrNull;

  /// Get all error messages as a single string
  String get allErrorMessages {
    if (errors == null || errors!.isEmpty) return _friendlyMessage(message);

    return errors!.entries
        .expand((entry) => entry.value.map(_friendlyMessage))
        .join('\n');
  }

  /// Get user-friendly first error for a field
  String? getFriendlyFieldError(String field) {
    final raw = errors?[field]?.firstOrNull;
    return raw != null ? _friendlyMessage(raw) : null;
  }

  /// Convert raw Laravel validation messages to user-friendly text
  static String _friendlyMessage(String raw) {
    // Field required patterns
    if (raw.contains('field is required')) {
      final field = _humanizeField(
        raw.split(' field is required').first.replaceAll('The ', ''),
      );
      return '$field is required.';
    }
    // "required unless" pattern
    if (raw.contains('is required unless')) {
      final field = _humanizeField(
        raw
            .split(' field is required')
            .first
            .replaceAll('The ', '')
            .split(' is required')
            .first
            .replaceAll('The ', ''),
      );
      return '$field is required.';
    }
    // "must be" patterns
    if (raw.contains('must be a string')) {
      final field = _humanizeField(
        raw.split(' must be').first.replaceAll('The ', ''),
      );
      return '$field must be text.';
    }
    if (raw.contains('must be an integer') ||
        raw.contains('must be a number')) {
      final field = _humanizeField(
        raw.split(' must be').first.replaceAll('The ', ''),
      );
      return '$field must be a number.';
    }
    if (raw.contains('must not be greater than')) {
      final field = _humanizeField(
        raw.split(' must not').first.replaceAll('The ', ''),
      );
      return '$field is too long.';
    }
    if (raw.contains('must be at least')) {
      final field = _humanizeField(
        raw.split(' must be').first.replaceAll('The ', ''),
      );
      return '$field is too short.';
    }
    // "is invalid" / "format" patterns
    if (raw.contains('is not a valid') ||
        raw.contains('format is invalid') ||
        raw.contains('is invalid')) {
      final field = _humanizeField(
        raw.split(' is ').first.split(' format').first.replaceAll('The ', ''),
      );
      return 'Please enter a valid $field.';
    }
    // Date patterns
    if (raw.contains('must be a date after')) {
      return 'Please select a future date.';
    }
    if (raw.contains('must be a date')) {
      return 'Please enter a valid date.';
    }
    // Already exists
    if (raw.contains('has already been taken')) {
      final field = _humanizeField(
        raw.split(' has already').first.replaceAll('The ', ''),
      );
      return 'This $field is already in use.';
    }
    // Return cleaned up version of raw message
    return raw.replaceAll(RegExp(r'_'), ' ').replaceFirst(RegExp(r'^The '), '');
  }

  /// Convert snake_case field name to human-readable
  static String _humanizeField(String field) {
    return field
        .replaceAll('_', ' ')
        .replaceAll('.', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ')
        .trim();
  }

  @override
  String toString() => 'ApiError(statusCode: $statusCode, message: $message)';
}

/// Exception class for API errors
class ApiException implements Exception {
  const ApiException({required this.error});

  final ApiError error;

  @override
  String toString() => 'ApiException: ${error.message}';
}

/// Exception for network errors
class NetworkException implements Exception {
  const NetworkException([this.message = 'Network error occurred']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}
