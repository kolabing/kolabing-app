import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';

/// The events the viewer said they were going to, soonest first.
///
/// `GET /events?attendee=me&time=upcoming` — the events the viewer has a
/// check-in or a non-cancelled sign-up for. This is the top of the attendee
/// feed (#161): before the redesign the home screen knew nothing about what
/// the attendee had signed up for, which meant the one thing they opened the
/// app to check was the one thing the page could not tell them.
///
/// Distinct from [todaysGoingEventsProvider], which narrows the same call to
/// today for the check-in picker.
final myUpcomingEventsProvider = FutureProvider<List<Event>>((ref) async {
  final result = await ref
      .read(eventServiceProvider)
      .getEvents(mine: true, time: 'upcoming', limit: 20);

  DateTime when(Event e) => e.startsAt ?? e.date;
  return [...result.events]..sort((a, b) => when(a).compareTo(when(b)));
});
