import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/challenge.dart';
import '../models/challenge_completion.dart';
import '../services/challenge_service.dart';

/// Provider for ChallengeService
final challengeServiceProvider = Provider<ChallengeService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ChallengeService(authService: authService);
});

// =============================================================================
// Event Challenges Provider
// =============================================================================

/// Provider for event challenges (simple FutureProvider)
final eventChallengesProvider =
    FutureProvider.family<ChallengesResponse, String>((ref, eventId) async {
  final service = ref.watch(challengeServiceProvider);
  return service.getEventChallenges(eventId);
});

// =============================================================================
// Challenge Completion Providers
// =============================================================================

/// State for initiating a challenge
class InitiateChallengeState {
  const InitiateChallengeState({
    this.completion,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  final ChallengeCompletion? completion;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  InitiateChallengeState copyWith({
    ChallengeCompletion? completion,
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) =>
      InitiateChallengeState(
        completion: completion ?? this.completion,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

/// Notifier for initiating challenges
class InitiateChallengeNotifier extends Notifier<InitiateChallengeState> {
  @override
  InitiateChallengeState build() => const InitiateChallengeState();

  ChallengeService get _service => ref.read(challengeServiceProvider);

  Future<ChallengeCompletion?> initiate({
    required String challengeId,
    required String eventId,
    required String verifierProfileId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final completion = await _service.initiateChallenge(
        challengeId: challengeId,
        eventId: eventId,
        verifierProfileId: verifierProfileId,
      );
      state = InitiateChallengeState(completion: completion, isSuccess: true);
      return completion;
    } on ChallengeException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initiate challenge',
      );
      return null;
    }
  }

  void reset() {
    state = const InitiateChallengeState();
  }
}

/// Provider for initiating challenges
final initiateChallengeProvider =
    NotifierProvider<InitiateChallengeNotifier, InitiateChallengeState>(
  InitiateChallengeNotifier.new,
);

// =============================================================================
// My Challenge Completions Provider
// =============================================================================

/// State for my challenge completions
class MyChallengeCompletionsState {
  const MyChallengeCompletionsState({
    this.completions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  final List<ChallengeCompletion> completions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;

  /// Get pending completions where I am the verifier
  List<ChallengeCompletion> pendingForVerification(String myProfileId) =>
      completions
          .where((c) => c.isPending && c.verifierProfileId == myProfileId)
          .toList();

  /// Get pending completions where I am the challenger
  List<ChallengeCompletion> myPendingChallenges(String myProfileId) =>
      completions
          .where((c) => c.isPending && c.challengerProfileId == myProfileId)
          .toList();

  MyChallengeCompletionsState copyWith({
    List<ChallengeCompletion>? completions,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) =>
      MyChallengeCompletionsState(
        completions: completions ?? this.completions,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
      );
}

/// Notifier for my challenge completions
class MyChallengeCompletionsNotifier
    extends Notifier<MyChallengeCompletionsState> {
  @override
  MyChallengeCompletionsState build() => const MyChallengeCompletionsState();

  ChallengeService get _service => ref.read(challengeServiceProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getMyChallengeCompletions();
      state = MyChallengeCompletionsState(
        completions: response.completions,
        currentPage: response.currentPage,
        hasMore: response.hasMore,
      );
    } on ChallengeException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load challenge completions',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final response = await _service.getMyChallengeCompletions(
        page: state.currentPage + 1,
      );
      state = state.copyWith(
        completions: [...state.completions, ...response.completions],
        currentPage: response.currentPage,
        hasMore: response.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    state = const MyChallengeCompletionsState();
    await load();
  }

  /// Verify a pending challenge
  Future<bool> verifyChallenge(String completionId) async {
    try {
      final updated = await _service.verifyChallenge(completionId);
      // Update in list
      state = state.copyWith(
        completions: state.completions
            .map((c) => c.id == completionId ? updated : c)
            .toList(),
      );
      return true;
    } on ChallengeException {
      rethrow;
    }
  }

  /// Reject a pending challenge
  Future<bool> rejectChallenge(String completionId) async {
    try {
      final updated = await _service.rejectChallenge(completionId);
      // Update in list
      state = state.copyWith(
        completions: state.completions
            .map((c) => c.id == completionId ? updated : c)
            .toList(),
      );
      return true;
    } on ChallengeException {
      rethrow;
    }
  }
}

/// Provider for my challenge completions
final myChallengeCompletionsProvider =
    NotifierProvider<MyChallengeCompletionsNotifier, MyChallengeCompletionsState>(
  MyChallengeCompletionsNotifier.new,
);

// =============================================================================
// Challenge CRUD for Organizers
// =============================================================================

/// Create a new custom challenge
Future<Challenge> createChallenge(
  WidgetRef ref,
  String eventId, {
  required String name,
  String? description,
  required ChallengeDifficulty difficulty,
  int? points,
}) async {
  final service = ref.read(challengeServiceProvider);
  final challenge = await service.createChallenge(
    eventId,
    name: name,
    description: description,
    difficulty: difficulty,
    points: points,
  );
  // Invalidate the challenges provider to refresh the list
  ref.invalidate(eventChallengesProvider(eventId));
  return challenge;
}

/// Update a custom challenge
Future<Challenge> updateChallenge(
  WidgetRef ref,
  String eventId,
  String challengeId, {
  String? name,
  String? description,
  ChallengeDifficulty? difficulty,
  int? points,
}) async {
  final service = ref.read(challengeServiceProvider);
  final challenge = await service.updateChallenge(
    challengeId,
    name: name,
    description: description,
    difficulty: difficulty,
    points: points,
  );
  // Invalidate the challenges provider to refresh the list
  ref.invalidate(eventChallengesProvider(eventId));
  return challenge;
}

/// Delete a custom challenge
Future<void> deleteChallenge(
  WidgetRef ref,
  String eventId,
  String challengeId,
) async {
  final service = ref.read(challengeServiceProvider);
  await service.deleteChallenge(challengeId);
  // Invalidate the challenges provider to refresh the list
  ref.invalidate(eventChallengesProvider(eventId));
}
