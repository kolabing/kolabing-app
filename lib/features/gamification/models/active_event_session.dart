import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event_checkin.dart';

/// How long a check-in keeps the event "active" on this device.
///
/// The backend exposes no `events.ends_at` and no `GET /me/checkins`, so the
/// app cannot ask when the event finishes or whether the user is still checked
/// in. A fixed window from the check-in is the honest approximation: long
/// enough to cover an evening event, short enough that yesterday's event never
/// captures today's peer scan. The server stays the authority — `initiate`
/// returns 422 if the pair are not both really checked in.
const Duration kActiveEventSessionTtl = Duration(hours: 12);

/// The event this device is currently "at", established by a check-in scan.
///
/// This is the context for peer pairing: when the attendee scans another
/// attendee's profile QR, [eventId] decides whose challenges get listed.
@immutable
class ActiveEventSession {
  const ActiveEventSession({
    required this.eventId,
    required this.checkedInAt,
    required this.expiresAt,
    this.eventName,
  });

  /// Opens a session from the `POST /checkin` response.
  ///
  /// The TTL is measured from [now] (the device clock) rather than the
  /// server's `checked_in_at`, so clock skew between server and device can
  /// never hand back an already-expired session.
  factory ActiveEventSession.fromCheckin(
    EventCheckin checkin, {
    DateTime? now,
    Duration ttl = kActiveEventSessionTtl,
  }) {
    final start = now ?? DateTime.now();
    return ActiveEventSession(
      eventId: checkin.eventId,
      eventName: checkin.eventName,
      checkedInAt: start,
      expiresAt: start.add(ttl),
    );
  }

  /// Rebuilds a session from persisted JSON. Returns `null` for anything
  /// malformed — a corrupt value must not crash the scanner on open.
  static ActiveEventSession? fromJson(Map<String, dynamic> json) {
    final eventId = json['event_id'];
    final checkedInAt = DateTime.tryParse('${json['checked_in_at']}');
    final expiresAt = DateTime.tryParse('${json['expires_at']}');

    if (eventId is! String ||
        eventId.isEmpty ||
        checkedInAt == null ||
        expiresAt == null) {
      return null;
    }

    return ActiveEventSession(
      eventId: eventId,
      eventName: json['event_name'] as String?,
      checkedInAt: checkedInAt,
      expiresAt: expiresAt,
    );
  }

  final String eventId;
  final String? eventName;
  final DateTime checkedInAt;
  final DateTime expiresAt;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  bool get isExpired => isExpiredAt(DateTime.now());

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    if (eventName != null) 'event_name': eventName,
    'checked_in_at': checkedInAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
  };
}

/// `SharedPreferences`-backed store for the [ActiveEventSession].
///
/// Kept separate from the provider so the persistence rules (drop on expiry,
/// survive corrupt values) are unit-testable without a widget tree.
class ActiveEventSessionStore {
  const ActiveEventSessionStore();

  @visibleForTesting
  static const String storageKey = 'active_event_session';

  /// Reads the stored session, discarding it if it has expired or is corrupt.
  Future<ActiveEventSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;

    ActiveEventSession? session;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        session = ActiveEventSession.fromJson(decoded);
      }
    } on FormatException {
      session = null;
    }

    if (session == null || session.isExpired) {
      await prefs.remove(storageKey);
      return null;
    }
    return session;
  }

  Future<void> save(ActiveEventSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
