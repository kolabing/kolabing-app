import 'package:flutter/foundation.dart';

/// Gates notification-tap navigation across the cold-start splash sequence.
///
/// When the app is launched from a killed state by a notification tap, it boots
/// on the splash screen. Splash resolves the persisted session and then calls
/// `context.go(destination)` — which REPLACES the entire navigation stack. Any
/// route pushed on top of splash before that `go()` is therefore silently
/// discarded, so the tapped notification never opens its target screen.
///
/// This gate holds a tap that arrives while the app is still on splash and
/// replays it once splash signals (via [markReady]) that it has routed to the
/// destination — pushing the target on top so back navigation still works.
/// Taps that arrive after the app is ready (background/foreground taps) are
/// navigated immediately.
class NotificationNavGate {
  NotificationNavGate({required void Function(String route) onNavigate})
    : _onNavigate = onNavigate;

  final void Function(String route) _onNavigate;

  bool _ready = false;
  String? _pending;

  /// Route a notification tap.
  ///
  /// Before the app is ready (still on splash) the latest route is stashed and
  /// replayed by [markReady]; afterwards it navigates immediately. Only the
  /// most recent pending route is kept — a second tap during cold start
  /// supersedes the first.
  void navigate(String route) {
    if (!_ready) {
      _pending = route;
      return;
    }
    _onNavigate(route);
  }

  /// Called once the splash screen has routed to the initial destination.
  /// Marks the app ready and replays any route stashed during cold start.
  void markReady() {
    _ready = true;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      _onNavigate(pending);
    }
  }

  @visibleForTesting
  bool get isReady => _ready;

  @visibleForTesting
  String? get pendingRoute => _pending;
}
