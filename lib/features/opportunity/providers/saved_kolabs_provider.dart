import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/opportunity.dart';
import 'opportunity_provider.dart';

/// The set of kolab ids the viewer has saved — the single source of truth for
/// bookmark state across the Explore deck and the Saved tab.
///
/// Seeded from [savedKolabsProvider] (so a previously-saved kolab shows as saved
/// while browsing, even though the discovery feed itself does not carry an
/// `is_saved` flag) and updated optimistically on every toggle.
class SavedKolabIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void seed(Iterable<String> ids) => state = {...state, ...ids};
  void add(String id) => state = {...state, id};
  void remove(String id) {
    if (!state.contains(id)) return;
    state = {...state}..remove(id);
  }
}

final savedKolabIdsProvider =
    NotifierProvider<SavedKolabIdsNotifier, Set<String>>(
      SavedKolabIdsNotifier.new,
    );

/// The viewer's saved kolabs — `GET /api/v1/kolabs?saved=1`.
///
/// Backs the Explore "Saved" tab. On load it seeds [savedKolabIdsProvider] so
/// the bookmark state is consistent everywhere.
class SavedKolabsNotifier extends AsyncNotifier<List<Opportunity>> {
  @override
  Future<List<Opportunity>> build() async {
    final service = ref.read(opportunityServiceProvider);
    final res = await service.getOpportunities(savedOnly: true, perPage: 50);
    final ids = res.data.map((o) => o.id).whereType<String>().toList();
    // Defer the cross-provider seed so we never mutate another provider while
    // this one is still building.
    Future.microtask(() {
      if (!ref.mounted) return;
      ref.read(savedKolabIdsProvider.notifier).seed(ids);
    });
    return res.data;
  }

  /// Drop an item from the in-memory list without a refetch (optimistic unsave).
  void removeLocally(String id) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.where((o) => o.id != id).toList());
  }
}

final savedKolabsProvider =
    AsyncNotifierProvider<SavedKolabsNotifier, List<Opportunity>>(
      SavedKolabsNotifier.new,
    );

/// Toggle the saved state of a kolab with an optimistic UI update + revert on
/// failure. Updates [savedKolabIdsProvider] immediately, calls the backend, and
/// keeps [savedKolabsProvider] (the Saved tab list) in sync.
Future<void> toggleKolabSaved(WidgetRef ref, String id) async {
  final wasSaved = ref.read(savedKolabIdsProvider).contains(id);
  final ids = ref.read(savedKolabIdsProvider.notifier);

  wasSaved ? ids.remove(id) : ids.add(id);
  if (wasSaved) {
    ref.read(savedKolabsProvider.notifier).removeLocally(id);
  }

  try {
    await ref.read(opportunityServiceProvider).setSaved(id, !wasSaved);
    if (!wasSaved) {
      // Pull the newly-saved kolab into the Saved tab list.
      ref.invalidate(savedKolabsProvider);
    }
  } catch (e) {
    // Revert the optimistic change.
    wasSaved ? ids.add(id) : ids.remove(id);
    if (wasSaved) ref.invalidate(savedKolabsProvider);
    rethrow;
  }
}
