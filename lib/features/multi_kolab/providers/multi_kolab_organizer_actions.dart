import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../models/child_kolab_result.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';
import '../repositories/api_multi_kolab_repository.dart';
import '../repositories/multi_kolab_repository.dart';
import 'multi_kolab_providers.dart';
import 'multi_kolab_repository_provider.dart';

/// Which mutation is in flight, and against which id.
///
/// Keyed by `(kind, targetId)` rather than a single global boolean so two
/// different applicant rows can never block each other, while a double tap
/// on the *same* row is a guaranteed no-op.
@immutable
class MultiKolabActionState {
  const MultiKolabActionState({this.inFlight = const {}, this.lastErrorCode});

  /// `"<kind>:<targetId>"` for every mutation currently running.
  final Set<String> inFlight;

  /// The stable backend error code of the most recent failure, or null.
  /// Screens map this to localized copy; the human-readable message is
  /// never matched on (contract §10).
  final String? lastErrorCode;

  bool isBusy(String kind, String targetId) => inFlight.contains('$kind:$targetId');

  /// True while ANY mutation runs — used to disable whole-screen actions.
  bool get isAnyBusy => inFlight.isNotEmpty;

  MultiKolabActionState copyWith({
    Set<String>? inFlight,
    String? lastErrorCode,
    bool clearError = false,
  }) {
    return MultiKolabActionState(
      inFlight: inFlight ?? this.inFlight,
      lastErrorCode: clearError ? null : (lastErrorCode ?? this.lastErrorCode),
    );
  }
}

/// Every organizer mutation, in one place.
///
/// Responsibilities kept deliberately narrow: run the call, prevent a
/// duplicate submission for the same target, record the stable error code,
/// and invalidate exactly the server-backed providers the mutation
/// invalidated — never more. Read state (lists, detail, dashboard) stays in
/// the existing `FutureProvider`s.
class MultiKolabOrganizerActions extends Notifier<MultiKolabActionState> {
  @override
  MultiKolabActionState build() => const MultiKolabActionState();

  MultiKolabRepository get _repository => ref.read(multiKolabRepositoryProvider);

  Future<T?> _run<T>(
    String kind,
    String targetId,
    Future<T> Function(MultiKolabRepository repository) action, {
    void Function()? onSuccess,
  }) async {
    if (state.isBusy(kind, targetId)) return null;

    state = state.copyWith(
      inFlight: <String>{...state.inFlight, '$kind:$targetId'},
      clearError: true,
    );

    try {
      final result = await action(_repository);
      onSuccess?.call();
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(
        lastErrorCode: e.error.stableCode ?? 'unknown',
      );
      return null;
    } on NetworkException {
      state = state.copyWith(lastErrorCode: 'network');
      return null;
    } finally {
      state = state.copyWith(
        inFlight: <String>{...state.inFlight}..remove('$kind:$targetId'),
      );
    }
  }

  void _refreshEvent(String eventId) {
    ref
      ..invalidate(multiKolabEventDetailProvider(eventId))
      ..invalidate(multiKolabDashboardProvider(eventId))
      ..invalidate(multiKolabMyEventsProvider);
  }

  // --- roles ---------------------------------------------------------------

  Future<MultiKolabRole?> addRole(
    String eventId,
    CreateMultiKolabRoleInput input,
  ) {
    return _run(
      'addRole',
      eventId,
      (r) => r.addRole(eventId, input),
      onSuccess: () => _refreshEvent(eventId),
    );
  }

  Future<MultiKolabRole?> updateRole(
    String eventId,
    String roleId,
    UpdateMultiKolabRoleInput input,
  ) {
    return _run(
      'updateRole',
      roleId,
      (r) => r.updateRole(roleId, input),
      onSuccess: () => _refreshEvent(eventId),
    );
  }

  Future<MultiKolabRole?> setRoleStatus(
    String eventId,
    String roleId,
    MultiKolabRoleStatus status,
  ) {
    return _run(
      'roleStatus',
      roleId,
      (r) => r.setRoleStatus(roleId, status),
      onSuccess: () => _refreshEvent(eventId),
    );
  }

  // --- event lifecycle -----------------------------------------------------

  Future<MultiKolabEvent?> publish(String eventId) {
    return _run(
      'publish',
      eventId,
      (r) => r.publish(eventId),
      onSuccess: () => _refreshEvent(eventId),
    );
  }

  Future<MultiKolabEvent?> confirm(String eventId) {
    return _run(
      'confirm',
      eventId,
      (r) => r.confirmEvent(eventId),
      onSuccess: () => _refreshEvent(eventId),
    );
  }

  Future<MultiKolabEvent?> complete(String eventId) {
    return _run(
      'complete',
      eventId,
      (r) => r.completeEvent(eventId),
      onSuccess: () => _refreshEvent(eventId),
    );
  }

  Future<bool> cancel(String eventId, String reason) async {
    final result = await _run<bool>(
      'cancel',
      eventId,
      (r) async {
        await r.cancelEvent(eventId, reason);
        return true;
      },
      onSuccess: () => _refreshEvent(eventId),
    );
    return result ?? false;
  }

  // --- applications --------------------------------------------------------

  Future<MultiKolabRoleApplication?> shortlist(
    String roleId,
    String applicationId,
  ) {
    return _run(
      'shortlist',
      applicationId,
      (r) => r.shortlist(applicationId),
      onSuccess: () => ref.invalidate(multiKolabRoleApplicationsProvider(roleId)),
    );
  }

  Future<MultiKolabRoleApplication?> decline(
    String roleId,
    String applicationId,
  ) {
    return _run(
      'decline',
      applicationId,
      (r) => r.decline(applicationId),
      onSuccess: () => ref.invalidate(multiKolabRoleApplicationsProvider(roleId)),
    );
  }

  /// Acceptance is a backend transaction (contract §8) — this never
  /// fabricates a local accepted state or a local Kolab. On success the
  /// role's applications AND the event/dashboard are refreshed so
  /// `positions_filled` and the role status come back from the server.
  Future<ChildKolabResult?> accept({
    required String eventId,
    required String roleId,
    required String applicationId,
  }) {
    return _run(
      'accept',
      applicationId,
      (r) => r.accept(applicationId),
      onSuccess: () {
        ref.invalidate(multiKolabRoleApplicationsProvider(roleId));
        _refreshEvent(eventId);
      },
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final multiKolabOrganizerActionsProvider =
    NotifierProvider<MultiKolabOrganizerActions, MultiKolabActionState>(
      MultiKolabOrganizerActions.new,
    );
