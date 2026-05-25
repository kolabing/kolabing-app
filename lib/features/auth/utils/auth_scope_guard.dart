import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Shared guard for providers that keep user-scoped state mounted across
/// logout/login transitions.
///
/// These providers can outlive an auth session change, so they need two
/// protections:
/// 1. Clear their state immediately when auth is lost.
/// 2. Ignore late async completions that started under an older session.
mixin AuthScopeGuard<T> on Notifier<T> {
  int _activeAuthSessionVersion = 0;
  String? _activeUserId;

  @protected
  int get activeAuthSessionVersion => _activeAuthSessionVersion;

  @protected
  bool isStaleAuthSession(int sessionVersion) =>
      sessionVersion != _activeAuthSessionVersion;

  @protected
  void handleAuthStateChange(
    AuthState? previous,
    AuthState next, {
    required VoidCallback clearSignedOutState,
    required Future<void> Function() reloadAuthenticatedData,
    VoidCallback? onSessionInvalidated,
  }) {
    final nextUserId = next.user?.id;

    if (!next.isAuthenticated || nextUserId == null) {
      _activeUserId = null;
      _invalidateAuthSession(onSessionInvalidated);
      clearSignedOutState();
      return;
    }

    if (_activeUserId != nextUserId) {
      _activeUserId = nextUserId;
      _invalidateAuthSession(onSessionInvalidated);
      clearSignedOutState();
      Future.microtask(reloadAuthenticatedData);
    }
  }

  @protected
  Future<void> loadIfAuthenticated({
    required VoidCallback clearSignedOutState,
    required Future<void> Function() loadAuthenticatedData,
  }) async {
    if (!ensureAuthenticatedUser(clearSignedOutState: clearSignedOutState)) {
      return;
    }

    await loadAuthenticatedData();
  }

  @protected
  bool ensureAuthenticatedUser({
    required VoidCallback clearSignedOutState,
    VoidCallback? onUnauthenticated,
  }) {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      _activeUserId = null;
      _invalidateAuthSession(onUnauthenticated);
      clearSignedOutState();
      return false;
    }

    _activeUserId = authState.user!.id;
    return true;
  }

  void _invalidateAuthSession(VoidCallback? onSessionInvalidated) {
    _activeAuthSessionVersion++;
    onSessionInvalidated?.call();
  }
}
