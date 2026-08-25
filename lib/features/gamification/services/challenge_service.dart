import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../auth/services/auth_service.dart';
import '../models/challenge.dart';
import '../models/community_challenge.dart';
import '../models/challenge_completion.dart';
import '../../../config/constants/api.dart';

/// API configuration
const String _baseUrl = ApiConfig.baseUrl;

/// Service for handling challenge operations
class ChallengeService {
  ChallengeService({required AuthService authService, http.Client? httpClient})
    : _authService = authService,
      _httpClient = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _httpClient;

  // ---------------------------------------------------------------------------
  // Challenge CRUD
  // ---------------------------------------------------------------------------

  /// Get challenges for an event (system + custom)
  ///
  /// The challenge library — what a leader picks from (#150).
  ///
  /// GET /api/v1/challenge-library
  Future<ChallengesResponse> getLibrary({int page = 1, int limit = 50}) async {
    final token = await _authService.getToken();
    if (token == null) throw const AuthException('Not authenticated');

    final url = '$_baseUrl/challenge-library?page=$page&limit=$limit';
    debugPrint('🎯 Library: GET $url');

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChallengesResponse.fromJson(json['data'] as Map<String, dynamic>);
    }

    // 404 = not deployed yet. Typed, so the screen can say "not available"
    // rather than showing an error for a backend that simply predates it.
    throw ChallengeException(
      'Could not load the challenge library.',
      kind: response.statusCode == 404
          ? ChallengeFailure.notFound
          : ChallengeFailure.unknown,
    );
  }

  /// What a community has chosen, and how strictly (#150).
  ///
  /// GET /api/v1/communities/{id}/challenges
  Future<CommunityChallengeSet> getCommunityChallenges(
    String communityId,
  ) async {
    final token = await _authService.getToken();
    if (token == null) throw const AuthException('Not authenticated');

    final url = '$_baseUrl/communities/$communityId/challenges';
    debugPrint('🎯 Community challenges: GET $url');

    final response = await _httpClient.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CommunityChallengeSet.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    }

    throw ChallengeException(
      'Could not load this community\'s challenges.',
      kind: response.statusCode == 404
          ? ChallengeFailure.notFound
          : ChallengeFailure.unknown,
    );
  }

  /// Replace a community's whole set (#150).
  ///
  /// An empty [selections] is meaningful and allowed: it turns curation off and
  /// returns the community to the whole library.
  ///
  /// PUT /api/v1/communities/{id}/challenges
  Future<CommunityChallengeSet> syncCommunityChallenges(
    String communityId,
    List<CommunityChallengeSelection> selections,
  ) async {
    final token = await _authService.getToken();
    if (token == null) throw const AuthException('Not authenticated');

    final url = '$_baseUrl/communities/$communityId/challenges';
    debugPrint('🎯 Community challenges: PUT $url (${selections.length})');

    final response = await _httpClient.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'challenges': selections.map((s) => s.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CommunityChallengeSet.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    throw ChallengeException(
      json['message'] as String? ?? 'Could not save.',
      kind: response.statusCode == 403
          ? ChallengeFailure.forbidden
          : ChallengeFailure.unknown,
    );
  }

  /// GET /api/v1/events/{event_id}/challenges
  Future<ChallengesResponse> getEventChallenges(
    String eventId, {
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/challenges?page=$page&limit=$limit';
    debugPrint('🎯 Get Challenges: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🎯 Get Challenges response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ChallengesResponse.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ChallengeException(
          json['message'] as String? ?? 'Failed to get challenges',
        );
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Get Challenges error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }

  /// Create a custom challenge for an event (organizer only)
  ///
  /// POST /api/v1/events/{event_id}/challenges
  Future<Challenge> createChallenge(
    String eventId, {
    required String name,
    String? description,
    required ChallengeDifficulty difficulty,
    int? points,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/events/$eventId/challenges';
    debugPrint('🎯 Create Challenge: POST $url');

    try {
      final body = {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        'difficulty': difficulty.toApiValue(),
        if (points != null) 'points': points,
      };

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('🎯 Create Challenge response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Challenge.fromJson(json['data'] as Map<String, dynamic>);
      } else if (response.statusCode == 403) {
        throw ChallengeException(
          'You are not authorized to create challenges for this event.',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ChallengeException(
          json['message'] as String? ?? 'Failed to create challenge',
        );
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Create Challenge error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }

  /// Update a custom challenge (organizer only, cannot update system challenges)
  ///
  /// PUT /api/v1/challenges/{challenge_id}
  Future<Challenge> updateChallenge(
    String challengeId, {
    String? name,
    String? description,
    ChallengeDifficulty? difficulty,
    int? points,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/challenges/$challengeId';
    debugPrint('🎯 Update Challenge: PUT $url');

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (difficulty != null) body['difficulty'] = difficulty.toApiValue();
      if (points != null) body['points'] = points;

      final response = await _httpClient.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('🎯 Update Challenge response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Challenge.fromJson(json['data'] as Map<String, dynamic>);
      } else if (response.statusCode == 403) {
        throw ChallengeException(
          'You are not authorized to update this challenge.',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ChallengeException(
          json['message'] as String? ?? 'Failed to update challenge',
        );
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Update Challenge error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }

  /// Delete a custom challenge (organizer only, cannot delete system challenges)
  ///
  /// DELETE /api/v1/challenges/{challenge_id}
  Future<void> deleteChallenge(String challengeId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/challenges/$challengeId';
    debugPrint('🎯 Delete Challenge: DELETE $url');

    try {
      final response = await _httpClient.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🎯 Delete Challenge response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 403) {
        throw ChallengeException(
          'You are not authorized to delete this challenge.',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ChallengeException(
          json['message'] as String? ?? 'Failed to delete challenge',
        );
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Delete Challenge error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Challenge Completion
  // ---------------------------------------------------------------------------

  /// Initiate a peer-to-peer challenge
  ///
  /// POST /api/v1/challenges/initiate
  Future<ChallengeCompletion> initiateChallenge({
    required String challengeId,
    required String eventId,
    required String verifierProfileId,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/challenges/initiate';
    debugPrint('🎯 Initiate Challenge: POST $url');

    try {
      final body = {
        'challenge_id': challengeId,
        'event_id': eventId,
        'verifier_profile_id': verifierProfileId,
      };

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint(
        '🎯 Initiate Challenge response status: ${response.statusCode}',
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ChallengeCompletion.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String?;

        if (response.statusCode == 422) {
          throw ChallengeException(
            message ?? 'Validation failed',
            kind: ChallengeFailure.bothMustCheckIn,
          );
        } else if (response.statusCode == 409) {
          // The backend names WHICH rule refused it (#150). Falling back to the
          // generic conflict keeps an older backend working — it just says less.
          throw ChallengeException(
            message ?? 'Challenge already initiated or limit exceeded',
            kind: challengeFailureForReason(json['error'] as String?),
          );
        } else if (response.statusCode == 404) {
          throw ChallengeException(
            message ?? 'Challenge or event not found',
            kind: ChallengeFailure.notFound,
          );
        } else {
          throw ChallengeException(message ?? 'Failed to initiate challenge');
        }
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Initiate Challenge error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }

  /// Verify a pending challenge completion
  ///
  /// POST /api/v1/challenge-completions/{id}/verify
  Future<ChallengeCompletion> verifyChallenge(String completionId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/challenge-completions/$completionId/verify';
    debugPrint('🎯 Verify Challenge: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🎯 Verify Challenge response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ChallengeCompletion.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      } else if (response.statusCode == 403) {
        throw const ChallengeException(
          'You are not the designated verifier for this challenge.',
          kind: ChallengeFailure.forbidden,
        );
      } else if (response.statusCode == 409) {
        throw const ChallengeException(
          'This challenge completion has already been processed.',
          kind: ChallengeFailure.conflict,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ChallengeException(
          json['message'] as String? ?? 'Failed to verify challenge',
        );
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Verify Challenge error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }

  /// Reject a pending challenge completion
  ///
  /// POST /api/v1/challenge-completions/{id}/reject
  Future<ChallengeCompletion> rejectChallenge(String completionId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/challenge-completions/$completionId/reject';
    debugPrint('🎯 Reject Challenge: POST $url');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('🎯 Reject Challenge response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ChallengeCompletion.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      } else if (response.statusCode == 403) {
        throw const ChallengeException(
          'You are not the designated verifier for this challenge.',
          kind: ChallengeFailure.forbidden,
        );
      } else if (response.statusCode == 409) {
        throw const ChallengeException(
          'This challenge completion has already been processed.',
          kind: ChallengeFailure.conflict,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ChallengeException(
          json['message'] as String? ?? 'Failed to reject challenge',
        );
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Reject Challenge error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }

  /// Get my challenge completions (as challenger or verifier)
  ///
  /// GET /api/v1/me/challenge-completions
  Future<ChallengeCompletionsResponse> getMyChallengeCompletions({
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AuthException('Not authenticated');
    }

    final url = '$_baseUrl/me/challenge-completions?page=$page&limit=$limit';
    debugPrint('🎯 Get My Completions: GET $url');

    try {
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint(
        '🎯 Get My Completions response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ChallengeCompletionsResponse.fromJson(
          json['data'] as Map<String, dynamic>,
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw ChallengeException(
          json['message'] as String? ?? 'Failed to get challenge completions',
        );
      }
    } catch (e) {
      if (e is ChallengeException || e is AuthException) {
        rethrow;
      }
      debugPrint('🎯 Get My Completions error: $e');
      throw ChallengeException(
        'Failed to connect to server: $e',
        kind: ChallengeFailure.network,
      );
    }
  }
}

/// Response wrapper for challenges list with pagination
class ChallengesResponse {
  const ChallengesResponse({
    required this.challenges,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory ChallengesResponse.fromJson(Map<String, dynamic> json) {
    final challengesJson = json['challenges'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return ChallengesResponse(
      challenges: challengesJson
          .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      totalPages: pagination['total_pages'] as int,
      totalCount: pagination['total_count'] as int,
      perPage: pagination['per_page'] as int,
    );
  }

  final List<Challenge> challenges;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  bool get hasMore => currentPage < totalPages;

  /// Get only custom challenges (not system challenges)
  List<Challenge> get customChallenges =>
      challenges.where((c) => c.isCustom).toList();

  /// Get only system challenges
  List<Challenge> get systemChallenges =>
      challenges.where((c) => c.isSystem).toList();
}

/// Response wrapper for challenge completions with pagination
class ChallengeCompletionsResponse {
  const ChallengeCompletionsResponse({
    required this.completions,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.perPage,
  });

  factory ChallengeCompletionsResponse.fromJson(Map<String, dynamic> json) {
    final completionsJson = json['completions'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;

    return ChallengeCompletionsResponse(
      completions: completionsJson
          .map((e) => ChallengeCompletion.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      totalPages: pagination['total_pages'] as int,
      totalCount: pagination['total_count'] as int,
      perPage: pagination['per_page'] as int,
    );
  }

  final List<ChallengeCompletion> completions;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int perPage;

  bool get hasMore => currentPage < totalPages;
}

/// Exception for challenge operations
/// Why a challenge call failed.
///
/// The UI localizes off this rather than showing [ChallengeException.message],
/// which may be raw backend English. [bothMustCheckIn] is the 422 the backend
/// returns when the challenger and the verifier are not both checked in to the
/// event — the most common failure in the peer flow, and the one that needs a
/// helpful message rather than a generic one.
/// Maps the backend's refusal reason onto something the app can localize.
///
/// An unknown or absent reason falls back to [ChallengeFailure.conflict], which
/// is what every 409 used to be — so a backend without #150 still behaves, it
/// just cannot be specific.
ChallengeFailure challengeFailureForReason(String? reason) => switch (reason) {
  'already_pending' => ChallengeFailure.alreadyPending,
  'already_completed' => ChallengeFailure.alreadyCompleted,
  'needs_new_person' => ChallengeFailure.needsNewPerson,
  'event_limit_reached' => ChallengeFailure.eventLimitReached,
  _ => ChallengeFailure.conflict,
};

enum ChallengeFailure {
  bothMustCheckIn,
  conflict,

  /// You have already asked this person to confirm this challenge (#150).
  alreadyPending,

  /// The two of you have already completed this one — and this community does
  /// not allow repeating it.
  alreadyCompleted,

  /// The challenge is for meeting someone you have not played with before.
  needsNewPerson,

  /// You have used up this event's allowance.
  eventLimitReached,

  forbidden,
  notFound,
  network,
  unknown,
}

class ChallengeException implements Exception {
  const ChallengeException(
    this.message, {
    this.kind = ChallengeFailure.unknown,
  });

  final String message;

  /// Classified reason, so callers can localize and branch without string
  /// matching on [message].
  final ChallengeFailure kind;

  @override
  String toString() => 'ChallengeException($kind): $message';
}
