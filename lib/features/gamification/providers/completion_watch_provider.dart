import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge_completion.dart';
import 'badge_provider.dart';
import 'challenge_provider.dart';
import 'stats_provider.dart';

/// Timing for [completionWatchProvider]. A provider so tests can shrink it.
@immutable
class CompletionWatchConfig {
  const CompletionWatchConfig({
    this.interval = const Duration(seconds: 3),
    this.timeout = const Duration(minutes: 2),
    this.pageSize = 20,
  });

  /// Gap between polls. 3s keeps the "+XP" reveal feeling immediate while the
  /// two members are standing next to each other.
  final Duration interval;

  /// How long to keep polling before falling back to the "still waiting"
  /// state. The screen can resume from there.
  final Duration timeout;

  /// How many recent completions to scan for the one being watched.
  final int pageSize;
}

final completionWatchConfigProvider = Provider<CompletionWatchConfig>(
  (ref) => const CompletionWatchConfig(),
);

@immutable
class CompletionWatchState {
  const CompletionWatchState({
    this.completion,
    this.polling = false,
    this.timedOut = false,
  });

  /// The watched completion, once it has been seen at least once.
  final ChallengeCompletion? completion;

  final bool polling;

  /// Set when the watch gave up waiting. Not a failure — the completion is
  /// still pending server-side and can be confirmed later.
  final bool timedOut;

  bool get isVerified => completion?.isVerified ?? false;
  bool get isRejected => completion?.isRejected ?? false;
  bool get isSettled => isVerified || isRejected;

  CompletionWatchState copyWith({
    ChallengeCompletion? completion,
    bool? polling,
    bool? timedOut,
  }) => CompletionWatchState(
    completion: completion ?? this.completion,
    polling: polling ?? this.polling,
    timedOut: timedOut ?? this.timedOut,
  );
}

/// Watches one challenge completion until the verifier settles it.
///
/// The backend sends no push when a completion is verified, and
/// `GET /me/challenge-completions` takes no status filter, so the challenger's
/// screen polls the recent list and matches on id. That is enough for the
/// face-to-face flow this feature is built for: the verifier is standing right
/// there, scanning the QR on screen.
class CompletionWatchNotifier extends Notifier<CompletionWatchState> {
  CompletionWatchNotifier(this.completionId);

  final String completionId;

  bool _running = false;
  bool _disposed = false;

  @override
  CompletionWatchState build() {
    ref.onDispose(() {
      _disposed = true;
      _running = false;
    });
    Future.microtask(start);
    return const CompletionWatchState();
  }

  /// Starts (or restarts, after a timeout) polling.
  Future<void> start() async {
    if (_running || _disposed) return;
    _running = true;

    final config = ref.read(completionWatchConfigProvider);
    final deadline = DateTime.now().add(config.timeout);
    state = state.copyWith(polling: true, timedOut: false);

    while (_running && !_disposed) {
      final found = await _fetch(config.pageSize);

      if (_disposed) return;

      if (found != null) {
        if (!found.isPending) {
          state = CompletionWatchState(completion: found);
          _running = false;
          if (found.isVerified) _refreshXpSurfaces();
          return;
        }
        state = state.copyWith(completion: found);
      }

      if (!DateTime.now().isBefore(deadline)) {
        state = state.copyWith(polling: false, timedOut: true);
        _running = false;
        return;
      }

      await Future<void>.delayed(config.interval);
    }
  }

  /// XP has landed in `point_ledger`, so anything showing a total is stale.
  void _refreshXpSurfaces() {
    ref.invalidate(myStatsProvider);
    ref.invalidate(myBadgesProvider);
    ref.invalidate(myChallengeCompletionsProvider);
  }

  /// Reads the recent completions and picks out the watched one.
  ///
  /// A transient failure returns null and the loop simply tries again — losing
  /// one poll is invisible, whereas surfacing every blip would make the wait
  /// screen flicker between error and waiting.
  Future<ChallengeCompletion?> _fetch(int pageSize) async {
    try {
      final response = await ref
          .read(challengeServiceProvider)
          .getMyChallengeCompletions(limit: pageSize);
      for (final completion in response.completions) {
        if (completion.id == completionId) return completion;
      }
      return null;
    } on Object catch (e) {
      debugPrint('completionWatch: poll failed: $e');
      return null;
    }
  }
}

final completionWatchProvider =
    NotifierProvider.family<
      CompletionWatchNotifier,
      CompletionWatchState,
      String
    >(CompletionWatchNotifier.new);
