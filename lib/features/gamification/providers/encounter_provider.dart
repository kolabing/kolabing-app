import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/encounter.dart';
import '../services/encounter_service.dart';

/// The People Layer's client (#183).
final encounterServiceProvider = Provider<EncounterService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return EncounterService(authService: authService);
});

/// The people the viewer has met, most recent first.
///
/// Self-gating: while the backend is not deployed the call 404s, and an empty
/// list is the honest answer for a surface that should simply not appear yet.
/// Anything else would put an error in front of someone about a feature they
/// have never heard of.
final myEncountersProvider = FutureProvider.autoDispose<List<Encounter>>((
  ref,
) async {
  try {
    return await ref.watch(encounterServiceProvider).getMyEncounters();
  } on EncounterException catch (e) {
    if (e.isFeatureOff) return const [];
    rethrow;
  }
});
