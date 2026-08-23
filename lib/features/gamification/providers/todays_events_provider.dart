import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';

/// The events the viewer said they were going to, happening **today**.
///
/// This is the list behind "which event are you at?" (#144) — the way into the
/// challenge loop that does not need an organizer standing there with a QR on
/// screen. Today only, on purpose: it is the same window the backend accepts a
/// self check-in for, and a list of next month's events would be a list of
/// things you cannot check in to.
///
/// `autoDispose` because it is read when the picker opens and is worthless a
/// minute later.
final todaysGoingEventsProvider = FutureProvider.autoDispose<List<Event>>((
  ref,
) async {
  final result = await ref
      .read(eventServiceProvider)
      .getEvents(mine: true, time: 'upcoming', limit: 20);

  final now = DateTime.now();

  return result.events
      .where((event) {
        if (!event.isGoing) return false;
        final when = event.startsAt ?? event.date;
        return when.year == now.year &&
            when.month == now.month &&
            when.day == now.day;
      })
      .toList(growable: false);
});
