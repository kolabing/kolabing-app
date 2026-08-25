import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/event_checkin.dart';
import '../services/checkin_service.dart';

/// Provider for CheckinService
final checkinServiceProvider = Provider<CheckinService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CheckinService(authService: authService);
});

// =============================================================================
// QR Token Provider
// =============================================================================

/// Provider for the organizer's check-in QR (token + short code + link).
final qrTokenProvider = FutureProvider.family<EventCheckinQr, String>((
  ref,
  eventId,
) async {
  final service = ref.watch(checkinServiceProvider);
  return service.generateQr(eventId);
});

/// Rotates the event's check-in code, retiring the current one.
///
/// Kept separate from [qrTokenProvider] because a plain re-read must NOT
/// rotate: `CheckinService::openDoor` is idempotent by design, so reopening the
/// screen does not invalidate a QR people are queuing in front of. Rotating is
/// the deliberate act of retiring a leaked code.
/// Returns whether it worked, so the caller can say so.
///
/// It used to be `Future<void>` with no try/catch, wired straight into an
/// `onPressed` that discarded the future: a failed rotate became an unhandled
/// async error, `invalidate` never ran, and the organizer kept looking at the
/// old QR with no indication that anything had gone wrong. The
/// `ref.invalidate` this replaced was synchronous and surfaced failures through
/// the `AsyncValue` error state, so silence was a regression.
Future<bool> rotateEventCheckinCode(WidgetRef ref, String eventId) async {
  try {
    await ref.read(checkinServiceProvider).generateQr(eventId, rotate: true);
    ref.invalidate(qrTokenProvider(eventId));
    return true;
  } on Object catch (e) {
    debugPrint('rotateEventCheckinCode failed: $e');
    return false;
  }
}

// =============================================================================
// Check-in Provider
// =============================================================================

/// State for check-in operation
class CheckinState {
  const CheckinState({
    this.checkin,
    this.isLoading = false,
    this.error,
    this.failure,
    this.isSuccess = false,
  });

  final EventCheckin? checkin;
  final bool isLoading;

  /// Raw message from the service. May be backend English — prefer [failure]
  /// for anything shown to the user.
  final String? error;

  /// Classified reason the check-in failed, for localized messaging.
  final CheckinFailure? failure;

  final bool isSuccess;

  CheckinState copyWith({
    EventCheckin? checkin,
    bool? isLoading,
    String? error,
    CheckinFailure? failure,
    bool? isSuccess,
  }) => CheckinState(
    checkin: checkin ?? this.checkin,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    failure: failure,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

/// Notifier for check-in operation (attendee)
class CheckinNotifier extends Notifier<CheckinState> {
  @override
  CheckinState build() => const CheckinState();

  CheckinService get _service => ref.read(checkinServiceProvider);

  Future<bool> checkIn(String qrToken) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final checkin = await _service.checkIn(qrToken);
      state = CheckinState(checkin: checkin, isSuccess: true);
      return true;
    } on CheckinException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        failure: e.kind,
        // A 409 may still tell us which event they are at.
        checkin: e.checkin,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check in',
        failure: CheckinFailure.unknown,
      );
      return false;
    }
  }

  void reset() {
    state = const CheckinState();
  }
}

/// Provider for check-in operation (attendee)
final checkinProvider = NotifierProvider<CheckinNotifier, CheckinState>(
  CheckinNotifier.new,
);

// =============================================================================
// Event Check-ins Provider
// =============================================================================

/// Provider for event check-ins list
final eventCheckinsProvider = FutureProvider.family<CheckinsResponse, String>((
  ref,
  eventId,
) async {
  final service = ref.watch(checkinServiceProvider);
  return service.getEventCheckins(eventId);
});
