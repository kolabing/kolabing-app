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

/// Provider for generating QR tokens (organizer)
final qrTokenProvider =
    FutureProvider.family<String, String>((ref, eventId) async {
  final service = ref.watch(checkinServiceProvider);
  return service.generateQRToken(eventId);
});

// =============================================================================
// Check-in Provider
// =============================================================================

/// State for check-in operation
class CheckinState {
  const CheckinState({
    this.checkin,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  final EventCheckin? checkin;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  CheckinState copyWith({
    EventCheckin? checkin,
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) =>
      CheckinState(
        checkin: checkin ?? this.checkin,
        isLoading: isLoading ?? this.isLoading,
        error: error,
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
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to check in');
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
final eventCheckinsProvider =
    FutureProvider.family<CheckinsResponse, String>((ref, eventId) async {
  final service = ref.watch(checkinServiceProvider);
  return service.getEventCheckins(eventId);
});
