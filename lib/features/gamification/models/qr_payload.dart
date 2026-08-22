/// The three kinds of QR code the attendee scanner understands, plus a fallback
/// for anything else the camera picks up.
///
/// Everything the gamification loop needs travels through a QR code:
///
/// | Kind | Payload | Action |
/// |---|---|---|
/// | [QrCheckinToken] | `https://<host>/checkin/{code}`, or a bare token | `POST /checkin` |
/// | [QrPeerProfile] | `https://<host>/u/{profileRef}` | pair up, list the event's challenges |
/// | [QrVerifyCompletion] | `https://<host>/qr/verify/{completionId}` | `POST /challenge-completions/{id}/verify` |
///
/// Matching is done on the **path only**. `Environment.shareHost` is
/// `kolabing.com` in prod and a `laravel.cloud` host in dev, so keying off the
/// host would make every dev build fail to read a prod QR (and vice versa).
library;

/// Path segment that marks a peer-profile QR (`/u/{profileRef}`).
const String _peerSegment = 'u';

/// Path segment of the backend's canonical check-in link, `/checkin/{code}`.
///
/// `App\Support\CheckinLink` is the single place that decides what a check-in
/// QR points at, and it deliberately encodes a **web URL carrying the short
/// code** rather than the 64-character token: the short code keeps the QR at
/// version 3 (29×29) instead of version 6 (41×41), which is the difference
/// between scanning across a room and having to walk up to the screen. A plain
/// phone camera can open it too.
///
/// So the app has to read this shape, or a code shown by the web panel — or
/// printed on a sheet — would be unreadable in the app. `POST /checkin` accepts
/// either the code or the long token (`CheckinService::checkin` matches on
/// `checkin_token` OR `checkin_code`), so the last path segment goes to the API
/// as-is.
const String _checkinSegment = 'checkin';

/// Path segments that mark a challenge-verification QR (`/qr/verify/{id}`).
const String _verifyFirstSegment = 'qr';
const String _verifySecondSegment = 'verify';

/// A check-in token is opaque, and its exact format is not documented anywhere
/// in this repo — so it is recognised by what it is *not*, rather than by a
/// guessed charset. Guessing risks the worst failure mode available: a real
/// token quietly reading as "unrecognised code", making check-in impossible
/// with nothing to diagnose.
///
/// Rejected: anything containing whitespace (free text), and anything carrying
/// a URI scheme prefix — which is exactly what the non-http QR payloads in the
/// wild are (`WIFI:…`, `mailto:…`, `tel:…`, `BEGIN:VCARD`). Everything else of
/// plausible length is handed to the server, which is the real authority: a
/// wrong token simply comes back as a 404.
final RegExp _tokenShape = RegExp(r'^\S{8,512}$');

/// `scheme:` at the head of the value, per RFC 3986. http(s) is handled earlier
/// as a URL, so anything still matching here is some other scheme entirely.
final RegExp _uriSchemePrefix = RegExp(r'^[A-Za-z][A-Za-z0-9+.\-]*:');

/// A scanned QR code, resolved to the action it should trigger.
sealed class QrPayload {
  const QrPayload();

  /// Classifies [raw] — the exact string the camera decoded.
  ///
  /// Never throws: anything unrecognised comes back as [QrUnknown] so the
  /// scanner can show a localized "unrecognised code" message and keep going.
  static QrPayload parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return QrUnknown(raw);

    final uri = Uri.tryParse(value);
    final isWebUrl =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isWebUrl) {
      final segments = uri.pathSegments
          .where((s) => s.isNotEmpty)
          .toList(growable: false);

      if (segments.length == 2 && segments[0].toLowerCase() == _peerSegment) {
        return QrPeerProfile(segments[1]);
      }

      if (segments.length == 3 &&
          segments[0].toLowerCase() == _verifyFirstSegment &&
          segments[1].toLowerCase() == _verifySecondSegment) {
        return QrVerifyCompletion(segments[2]);
      }

      if (segments.length == 2 &&
          segments[0].toLowerCase() == _checkinSegment) {
        return QrCheckinToken(segments[1]);
      }

      // A URL we recognise the shape of but not the route — never a token.
      return QrUnknown(raw);
    }

    if (_tokenShape.hasMatch(value) && !_uriSchemePrefix.hasMatch(value)) {
      return QrCheckinToken(value);
    }

    return QrUnknown(raw);
  }
}

/// An event check-in credential, minted by the organizer via
/// `POST /events/{event}/generate-qr`.
///
/// Either the short `checkin_code` lifted out of a `/checkin/{code}` link, or a
/// bare long token. `POST /checkin` accepts both, so no distinction is needed
/// past this point.
final class QrCheckinToken extends QrPayload {
  const QrCheckinToken(this.token);

  final String token;

  @override
  String toString() => 'QrCheckinToken(${token.length} chars)';
}

/// Another attendee's profile QR — the one shown by the "My QR" sheet.
///
/// [profileRef] is the universal profile id, or the `@handle` when the profile
/// id is unavailable (see `AttendeeMainScreen`'s My-QR sheet).
final class QrPeerProfile extends QrPayload {
  const QrPeerProfile(this.profileRef);

  final String profileRef;

  @override
  String toString() => 'QrPeerProfile($profileRef)';
}

/// A challenge completion awaiting this scanner's verification.
final class QrVerifyCompletion extends QrPayload {
  const QrVerifyCompletion(this.completionId);

  final String completionId;

  @override
  String toString() => 'QrVerifyCompletion($completionId)';
}

/// Anything the scanner does not understand.
final class QrUnknown extends QrPayload {
  const QrUnknown(this.raw);

  final String raw;

  @override
  String toString() => 'QrUnknown';
}
