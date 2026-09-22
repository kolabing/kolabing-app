import 'package:flutter/foundation.dart';

/// A Kolab's application window, resolved from a payload that may omit either
/// end of it.
@immutable
class AvailabilityWindow {
  const AvailabilityWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

/// How long a Kolab with NO window at all stays offerable to the client.
///
/// The server treats a Kolab with neither `availability_start` nor
/// `availability_end` as always bookable (`applyActiveAvailabilityFilter()`
/// lets it through unconditionally), and `Kolab::hasSelectableDatesFrom()` caps
/// its own open-ended look-ahead at 90 days. This mirrors that cap.
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
///  * `end` absent → `COALESCE(end, start)` — the server's own expiry rule, so
///    the two agree about which Kolabs are still open;
///  * `start` absent → the window is open from today until `end`;
///  * both absent → no window at all, i.e. always bookable; represented here as
///    today plus [kOpenEndedAvailabilityHorizon], because the models this feeds
///    hold non-nullable dates. This is the one case that cannot be expressed
///    exactly, and it errs towards "open", never towards "expired".
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
  if (start != null) {
    return AvailabilityWindow(start: start, end: start);
  }

  final from = _dateOnly(today ?? DateTime.now());
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
