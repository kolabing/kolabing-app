import 'user_model.dart';

/// Auth response from POST /auth/google
class AuthResponse {
  const AuthResponse({
    required this.success,
    required this.token,
    required this.tokenType,
    required this.isNewUser,
    required this.user,
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
      isNewUser: data['is_new_user'] as bool? ?? false,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  final bool success;
  final String? message;
  final String token;
  final String tokenType;
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
          'is_new_user': isNewUser,
          'user': user.toJson(),
        },
      };
}

/// Google auth request body
class GoogleAuthRequest {
  const GoogleAuthRequest({
    required this.idToken,
    required this.userType,
  });

  final String idToken;
  final UserType userType;

  Map<String, dynamic> toJson() => {
        'id_token': idToken,
        'user_type': userType.toApiValue(),
      };
}

/// User me response from GET /auth/me
class UserMeResponse {
  const UserMeResponse({
    required this.success,
    required this.user,
  });

  factory UserMeResponse.fromJson(Map<String, dynamic> json) => UserMeResponse(
        success: json['success'] as bool? ?? false,
        user: UserModel.fromJson(json['data'] as Map<String, dynamic>),
      );

  final bool success;
  final UserModel user;

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': user.toJson(),
      };
}

/// Logout response from POST /auth/logout
class LogoutResponse {
  const LogoutResponse({
    required this.success,
    this.message,
  });

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
  });

  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) =>
      ApiError(
        message: json['message'] as String? ?? 'Unknown error',
        errors: json['errors'] != null
            ? (json['errors'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>).cast<String>(),
                ),
              )
            : null,
        statusCode: statusCode,
      );

  final String message;
  final Map<String, List<String>>? errors;
  final int? statusCode;

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
    if (errors == null || errors!.isEmpty) return message;

    return errors!.entries
        .expand((entry) => entry.value)
        .join('\n');
  }

  @override
  String toString() => 'ApiError(statusCode: $statusCode, message: $message)';
}

/// Exception class for API errors
class ApiException implements Exception {
  const ApiException({
    required this.error,
  });

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
