import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/services/auth_service.dart';
import 'challenge_service.dart';

/// One frame waiting to reach the server.
@immutable
class QueuedPhoto {
  const QueuedPhoto({
    required this.id,
    required this.completionId,
    required this.filePath,
    required this.createdAt,
    this.attempts = 0,
  });

  factory QueuedPhoto.fromJson(Map<String, dynamic> json) => QueuedPhoto(
    id: json['id'] as String,
    completionId: json['completion_id'] as String,
    filePath: json['file_path'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    attempts: json['attempts'] as int? ?? 0,
  );

  final String id;
  final String completionId;
  final String filePath;
  final DateTime createdAt;
  final int attempts;

  Map<String, dynamic> toJson() => {
    'id': id,
    'completion_id': completionId,
    'file_path': filePath,
    'created_at': createdAt.toIso8601String(),
    'attempts': attempts,
  };

  QueuedPhoto withAttempt() => QueuedPhoto(
    id: id,
    completionId: completionId,
    filePath: filePath,
    createdAt: createdAt,
    attempts: attempts + 1,
  );
}

/// Photos captured during a challenge, uploaded when the network allows (#183).
///
/// **The rule this class exists to enforce: XP is paid before the photo
/// uploads.** The challenge is done the moment both people agreed it was done;
/// the evidence follows. Venue wifi is reliably terrible and a person must
/// never lose the moment — or the points — because of their signal.
///
/// So [enqueue] returns immediately and every failure is silent. Nothing here
/// ever throws into the UI, and nothing here ever blocks a reveal.
///
/// Persistence is deliberately [SharedPreferences] rather than a database: the
/// queue holds a handful of small records for minutes, not a dataset. The file
/// paths point at the OS temp directory that `image_picker` writes to, so a
/// path can go stale if the OS reclaims it between launches — [drain] treats a
/// missing file as done rather than as an error, because by then the user has
/// long since been paid and there is nothing left to recover.
class ChallengePhotoQueue {
  ChallengePhotoQueue({ChallengeService? challengeService})
    : _challengeService =
          challengeService ?? ChallengeService(authService: AuthService());

  static const String _storageKey = 'challenge_photo_queue_v1';

  /// After this many failures a frame is abandoned. Five spreads across several
  /// app launches, which is far longer than a bad venue connection lasts.
  static const int _maxAttempts = 5;

  final ChallengeService _challengeService;

  /// The drain currently running, so a second caller JOINS it rather than
  /// silently doing nothing. Awaiting [drain] has to mean the work happened.
  Future<void>? _inFlight;

  /// Take a frame off the user's hands. Returns as soon as it is recorded.
  ///
  /// [filePath] is whatever `image_picker` handed back. Kicks a drain, but does
  /// not wait for it — the caller is mid-reveal.
  Future<void> enqueue({
    required String completionId,
    required String filePath,
  }) async {
    final entry = QueuedPhoto(
      // The path is unique per capture and we must not call DateTime.now() for
      // an id that has to survive a restart; the path already is the identity.
      id: filePath,
      completionId: completionId,
      filePath: filePath,
      createdAt: DateTime.now(),
    );
    final queue = await _read();
    if (queue.any((q) => q.id == entry.id)) return;
    await _write([...queue, entry]);
    unawaited(drain());
  }

  /// Try every waiting frame once. Safe to call at any time — on app resume,
  /// after a capture, or when a screen that cares about photos opens.
  ///
  /// Never throws. A frame that fails keeps its place and its attempt count
  /// until it either lands or gives up.
  Future<void> drain() {
    final existing = _inFlight;
    // Join a drain already running rather than quietly doing nothing: awaiting
    // this has to mean the work happened, or a caller that waits is lied to.
    if (existing != null) return existing;
    final run = _drainOnce();
    _inFlight = run;
    return run.whenComplete(() => _inFlight = null);
  }

  Future<void> _drainOnce() async {
    try {
      final queue = await _read();
      if (queue.isEmpty) return;

      final remaining = <QueuedPhoto>[];
      for (final item in queue) {
        final outcome = await _attempt(item);
        if (outcome != null) remaining.add(outcome);
      }
      await _write(remaining);
    } catch (e) {
      debugPrint('📷 Photo queue drain failed: $e');
    }
  }

  /// Returns the entry to keep, or null when it is finished with — uploaded,
  /// abandoned, or its file is gone.
  Future<QueuedPhoto?> _attempt(QueuedPhoto item) async {
    if (!File(item.filePath).existsSync()) {
      debugPrint('📷 Photo queue: file gone, dropping ${item.id}');
      return null;
    }
    try {
      await _challengeService.attachProofPhoto(
        item.completionId,
        item.filePath,
      );
      debugPrint('📷 Photo queue: uploaded ${item.id}');
      return null;
    } on FileSystemException catch (e) {
      // The file went between the check above and the read. That means the same
      // as a missing file, not a network failure: there is nothing to retry,
      // and retrying would keep a dead entry alive for five more launches.
      debugPrint('📷 Photo queue: file vanished mid-upload, dropping ($e)');
      return null;
    } catch (e) {
      final next = item.withAttempt();
      if (next.attempts >= _maxAttempts) {
        debugPrint('📷 Photo queue: giving up on ${item.id} after $e');
        return null;
      }
      debugPrint('📷 Photo queue: retry ${next.attempts} for ${item.id} ($e)');
      return next;
    }
  }

  /// How many frames are still waiting. Only for surfaces that want to say so.
  Future<int> pendingCount() async => (await _read()).length;

  Future<List<QueuedPhoto>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(QueuedPhoto.fromJson)
          .toList();
    } catch (e) {
      debugPrint('📷 Photo queue: unreadable, resetting ($e)');
      return const [];
    }
  }

  Future<void> _write(List<QueuedPhoto> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (queue.isEmpty) {
        await prefs.remove(_storageKey);
        return;
      }
      await prefs.setString(
        _storageKey,
        jsonEncode(queue.map((q) => q.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('📷 Photo queue: could not persist ($e)');
    }
  }
}
