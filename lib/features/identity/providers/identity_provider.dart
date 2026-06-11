import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/handle_availability.dart';
import '../services/identity_service.dart';

/// Shared [IdentityService] instance (handle availability + profile lookup).
final identityServiceProvider = Provider<IdentityService>(
  (ref) => IdentityService(),
);

/// Live handle-availability check, keyed by the candidate handle. Returns a
/// nullable [HandleAvailability]: `null` while the query is too short or when
/// the format is invalid (the caller shows the format hint instead). Self-gates
/// a route 404 to `null` so an undeployed backend never surfaces an error.
final handleAvailabilityProvider = FutureProvider.autoDispose
    .family<HandleAvailability?, String>((ref, handle) async {
      final normalized = handle.trim().toLowerCase();
      if (!IdentityService.isValidHandleFormat(normalized)) {
        return null;
      }
      final service = ref.watch(identityServiceProvider);
      try {
        return await service.checkHandle(normalized);
      } on IdentityException catch (e) {
        if (e.isNotFound) return null;
        rethrow;
      }
    });
