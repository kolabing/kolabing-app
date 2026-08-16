import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_creator_entitlement.dart';
import '../models/multi_kolab_dashboard.dart';
import '../models/multi_kolab_event.dart';
import '../models/multi_kolab_event_summary.dart';
import 'multi_kolab_repository_provider.dart';

/// Explore listing for a given filter. `autoDispose` + `family` — each
/// distinct filter gets its own cached request, and it's released once no
/// screen is watching it.
final multiKolabExploreProvider = FutureProvider.autoDispose
    .family<List<MultiKolabEventSummary>, MultiKolabExploreFilter>(
      (ref, filter) => ref.watch(multiKolabRepositoryProvider).explore(filter),
    );

/// The signed-in profile's own events (any status) — organizer's "my events"
/// list.
final multiKolabMyEventsProvider =
    FutureProvider.autoDispose<List<MultiKolabEventSummary>>(
      (ref) => ref.watch(multiKolabRepositoryProvider).myEvents(),
    );

/// Event detail, including `viewer_application` for the signed-in profile.
final multiKolabEventDetailProvider = FutureProvider.autoDispose
    .family<MultiKolabEvent, String>(
      (ref, eventId) =>
          ref.watch(multiKolabRepositoryProvider).getEvent(eventId),
    );

/// Organizer dashboard for one event.
final multiKolabDashboardProvider = FutureProvider.autoDispose
    .family<MultiKolabDashboard, String>(
      (ref, eventId) =>
          ref.watch(multiKolabRepositoryProvider).getDashboard(eventId),
    );

/// The signed-in profile's Event Creator entitlement status.
final multiKolabEntitlementProvider =
    FutureProvider.autoDispose<EventCreatorEntitlement>(
      (ref) => ref.watch(multiKolabRepositoryProvider).getEntitlement(),
    );
