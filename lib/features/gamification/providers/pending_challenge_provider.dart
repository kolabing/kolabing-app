import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge_completion.dart';
import '../../auth/providers/auth_provider.dart';
import 'active_event_session_provider.dart';
import 'challenge_provider.dart';

/// Timing for [pendingChallengeProvider]. A provider so tests can shrink it.
@immutable
class PendingChallengeConfig {
  const PendingChallengeConfig({
    this.interval = const Duration(seconds: 4),
    this.pageSize = 20,
  });

  final Duration interval;
  final int pageSize;
}

final pendingChallengeConfigProvider = Provider<PendingChallengeConfig>(
  (ref) => const PendingChallengeConfig(),
);

/// The challenge someone has just asked this device to confirm.
///
/// This is what replaces the second QR scan (kolabing-app#140). One person
/// scans the other and picks a challenge; the other person's phone finds out on
/// its own and shows the same screen. Two people completing a challenge
/// together now involves exactly **one** scan between them, and for the rest of
/// it the phones are out of the way.
///
/// Polling rather than push: both people are standing in the same room with the
/// app open, so a few seconds is invisible, and it needs no new notification
/// type on the backend. It only runs while there is an active event session —
/// there is nothing to confirm when you are not at an event.
class PendingChallengeNotifier extends Notifier<ChallengeCompletion?> {
  bool _running = false;
  bool _disposed = false;

  /// Completions this device has already surfaced, so dismissing one does not
  /// make it pop straight back on the next poll.
  final Set<String> _handled = <String>{};

  @override
  ChallengeCompletion? build() {
    ref.onDispose(() {
      _disposed = true;
      _running = false;
    });

    // Restart whenever the active event changes: leaving an event should stop
    // the polling, arriving at one should start it.
    ref.listen(activeEventSessionProvider, (previous, next) {
      if (next == null) {
        state = null;
        _running = false;
        _generation++; // retire whatever loop is still sleeping
      } else {
        Future.microtask(start);
      }
    });

    Future.microtask(start);
    return null;
  }

  /// Stops surfacing [completionId] — it has been acted on or dismissed.
  void resolve(String completionId) {
    _handled.add(completionId);
    if (state?.id == completionId) state = null;
  }

  /// Bumped every time a loop is asked to stop, so a loop that is mid-`await`
  /// when the next one starts knows it is no longer the current one.
  ///
  /// `_running` alone was not enough: the session going null then non-null
  /// inside one 4-second interval set `_running = false` and then called
  /// `start()` again, which saw `false` and began a SECOND loop while the first
  /// was still sleeping — two pollers, both writing `state`.
  int _generation = 0;

  Future<void> start() async {
    if (_running || _disposed) return;
    _running = true;
    final generation = ++_generation;

    final config = ref.read(pendingChallengeConfigProvider);

    while (_running && !_disposed && generation == _generation) {
      if (ref.read(activeEventSessionProvider) == null) {
        _running = false;
        return;
      }

      final found = await _poll(config.pageSize);
      if (_disposed || generation != _generation) return;
      if (found != null && state?.id != found.id) state = found;

      await Future<void>.delayed(config.interval);
    }
  }

  /// The oldest pending completion where this device's owner is the one being
  /// asked. A transient failure just skips a tick.
  Future<ChallengeCompletion?> _poll(int pageSize) async {
    final myProfileId = ref.read(authProvider).user?.id;
    if (myProfileId == null || myProfileId.isEmpty) return null;

    try {
      final response = await ref
          .read(challengeServiceProvider)
          .getMyChallengeCompletions(limit: pageSize);

      for (final completion in response.completions.reversed) {
        if (completion.isPending &&
            completion.verifierProfileId == myProfileId &&
            !_handled.contains(completion.id)) {
          return completion;
        }
      }
      return null;
    } on Object catch (e) {
      debugPrint('pendingChallenge: poll failed: $e');
      return null;
    }
  }
}

final pendingChallengeProvider =
    NotifierProvider<PendingChallengeNotifier, ChallengeCompletion?>(
      PendingChallengeNotifier.new,
    );
