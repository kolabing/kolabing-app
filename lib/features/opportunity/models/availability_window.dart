import 'package:flutter/foundation.dart';

/// A Kolab's application window, resolved from a payload that may omit either
/// end of it.
@immutable
class AvailabilityWindow {
  const AvailabilityWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// How far ahead an open-ended Kolab (no `availability_end`) is offerable.
///
/// The server treats a Kolab with no `availability_end` as open-ended
/// (`Kolab::scopeWithSelectableDates()`), and `Kolab::hasSelectableDatesFrom()`
/// — the apply-time guard — caps its open-ended look-ahead at 90 days. This
/// mirrors that cap.
const Duration kOpenEndedAvailabilityHorizon = Duration(days: 90);

/// Reads an availability window the way the server reads it, and never invents
/// a date the payload did not imply.
///
/// `_parseDate(null)` used to return `DateTime.now()` in both
/// `DiscoveryAvailability.fromJson` and `Opportunity.fromJson`, so an ABSENT
/// bound silently became "today". FX-57 was that bug on `end`: an open-ended
/// Kolab starting tomorrow parsed as `end = today`, which is before its own
/// start, and the Explore deck dropped a card the API had counted. The same
/// invention still sat one field over — a null or malformed `start` produced
/// `start = end = today`, a Kolab bookable for exactly one day and then gone.
///
/// The four cases, each read as the server reads it:
///
///  * both present → the window as given;
///  * `end` absent → open-ended from `start`: offerable until
///    [kOpenEndedAvailabilityHorizon] after `start` or today, whichever is
///    later. This used to be `COALESCE(end, start)`, a one-day window, so every
///    business's onboarding Kolab (`flexible`, starting tomorrow, no end) read
///    as closed the day after it started (BE-FX-74, kolabing-app#213);
///  * `start` absent → the window is open from today until `end`;
///  * both absent → no window at all, i.e. always bookable; represented here as
///    today plus [kOpenEndedAvailabilityHorizon].
///
/// The two open-ended cases cannot be expressed exactly, because the models this
/// feeds hold non-nullable dates; both err towards "open", never towards
/// "expired".
///
/// [today] is injectable so tests do not depend on the wall clock.
AvailabilityWindow resolveAvailabilityWindow({
  required Object? rawStart,
  required Object? rawEnd,
  DateTime? today,
}) {
  final start = parseAvailabilityDate(rawStart);
  final end = parseAvailabilityDate(rawEnd);

  if (start != null && end != null) {
    return AvailabilityWindow(start: start, end: end);
  }

  final from = _dateOnly(today ?? DateTime.now());
  if (start != null) {
    final horizonFrom = start.isAfter(from) ? start : from;
    return AvailabilityWindow(
      start: start,
      end: horizonFrom.add(kOpenEndedAvailabilityHorizon),
    );
  }

  if (end != null) {
    // A window that ends but never started: offerable from today. If it has
    // already ended, leave it ended rather than stretching it forward — the
    // feed excludes it server-side anyway.
    return AvailabilityWindow(start: from.isAfter(end) ? end : from, end: end);
  }

  return AvailabilityWindow(
    start: from,
    end: from.add(kOpenEndedAvailabilityHorizon),
  );
}

/// Parses one availability bound, or null when the payload does not carry one.
/// Unlike the parsers this replaces, an unreadable value is an absent value —
/// never `DateTime.now()`.
DateTime? parseAvailabilityDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

/// Local copy of `DateUtils.dateOnly` so this file stays free of a Material
/// import — it is model code, used by parsers that never build a widget.
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
