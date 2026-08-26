import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../multi_kolab/models/multi_kolab_enums.dart';
import '../../multi_kolab/models/multi_kolab_event_summary.dart';
import '../../multi_kolab/providers/multi_kolab_providers.dart';

/// The existing sections a My Kolabs card can live in. These are NOT new
/// surfaces: `drafts`/`offers` are the two Offers-tab status filters
/// (Draft / Published) and `active`/`finished` are the hub's Active and
/// Finished tabs.
enum MyKolabsSection { drafts, offers, active, finished }

/// Where an organizer-owned Multi-Kolab event belongs inside My Kolabs.
///
/// A Multi-Kolab Event is still a Kolab, so its lifecycle is mapped onto the
/// sections ordinary kolabs already use rather than getting a surface of its
/// own. The backend lifecycle is untouched — this is presentation only.
MyKolabsSection multiKolabSectionFor(MultiKolabEventStatus status) =>
    switch (status) {
      // Never published — same place an unpublished kolab waits.
      MultiKolabEventStatus.draft => MyKolabsSection.drafts,
      // Published and taking applications — the Offers/Published filter.
      MultiKolabEventStatus.recruiting => MyKolabsSection.offers,
      // Partners locked in, the event is happening — Active.
      MultiKolabEventStatus.confirmed => MyKolabsSection.active,
      // Terminal states all land in Finished: the hub has no separate
      // "Closed" area (the Offers tab only filters Published/Draft), so
      // Finished is the closest existing home for cancelled/expired too.
      MultiKolabEventStatus.completed ||
      MultiKolabEventStatus.cancelled ||
      MultiKolabEventStatus.expired => MyKolabsSection.finished,
    };

/// The signed-in profile's Multi-Kolab events that belong in one My Kolabs
/// section.
///
/// Derived from [multiKolabMyEventsProvider] — the SAME single
/// `GET /multi-kolab-events/me` request the organizer area already makes, so
/// mixing these cards into My Kolabs costs no extra per-card request. While
/// that request is loading or failed, the section simply contributes nothing:
/// ordinary kolabs must never be blocked by the Multi-Kolab call.
final myKolabsMultiKolabEventsProvider = Provider.autoDispose
    .family<List<MultiKolabEventSummary>, MyKolabsSection>((ref, section) {
      final events = ref.watch(multiKolabMyEventsProvider);
      return events.maybeWhen(
        data: (list) => list
            .where((event) => multiKolabSectionFor(event.status) == section)
            .toList(growable: false),
        orElse: () => const <MultiKolabEventSummary>[],
      );
    });
