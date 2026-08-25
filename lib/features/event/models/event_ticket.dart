/// A sign-up with a code: the holder carries it, the host scans it.
///
/// Mirrors `TicketResource` (`GET /me/tickets`, `GET /tickets/{code}`). The QR
/// arrives as an inline SVG rather than a URL, deliberately — the door is
/// exactly where the network is worst, and a ticket that needs another round
/// trip to become scannable is a ticket that fails in a basement bar. The app
/// never draws its own QR from [code] for the same reason it never invents a
/// field: a locally-rendered code could disagree with the one the door expects.
class EventTicket {
  const EventTicket({
    required this.id,
    required this.code,
    required this.status,
    required this.qrSvg,
    this.issuedAt,
    this.admitUrl,
    this.usedAt,
    this.holderName,
    this.event,
  });

  factory EventTicket.fromJson(Map<String, dynamic> json) => EventTicket(
    id: json['id'] as String,
    code: json['code'] as String? ?? '',
    status: json['status'] as String? ?? 'going',
    qrSvg: json['qr_svg'] as String?,
    issuedAt: json['issued_at'] != null
        ? DateTime.tryParse(json['issued_at'] as String)
        : null,
    admitUrl: json['admit_url'] as String?,
    usedAt: json['used_at'] != null
        ? DateTime.tryParse(json['used_at'] as String)
        : null,
    holderName: json['holder_name'] as String?,
    event: json['event'] is Map<String, dynamic>
        ? EventTicketEvent.fromJson(json['event'] as Map<String, dynamic>)
        : null,
  );

  final String id;
  final String code;

  /// The sign-up's status: `going` | `waitlisted` | `cancelled`.
  final String status;

  /// Inline SVG of the admit link. Null only on a payload that predates it.
  final String? qrSvg;

  final DateTime? issuedAt;
  final String? admitUrl;

  /// When the holder was admitted, if they have been. Read server-side from
  /// `event_checkins`, so it agrees with attendance however someone got in.
  final DateTime? usedAt;

  /// Who is being let in — the doorkeeper needs it, because the person scanning
  /// is not the person authenticated.
  final String? holderName;

  final EventTicketEvent? event;

  bool get isAdmitted => usedAt != null;
  bool get isWaitlisted => status == 'waitlisted';
  bool get isScannable => qrSvg != null && qrSvg!.isNotEmpty;
}

/// The slice of the event a ticket carries, so a ticket read from the wallet
/// can name itself without a second fetch.
class EventTicketEvent {
  const EventTicketEvent({
    required this.id,
    required this.name,
    this.hostName,
    this.startsAt,
    this.eventDate,
    this.address,
    this.location,
  });

  factory EventTicketEvent.fromJson(Map<String, dynamic> json) =>
      EventTicketEvent(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        hostName: json['host_name'] as String?,
        startsAt: json['starts_at'] != null
            ? DateTime.tryParse(json['starts_at'] as String)
            : null,
        eventDate: json['event_date'] != null
            ? DateTime.tryParse(json['event_date'] as String)
            : null,
        address: json['address'] as String?,
        location: json['location'] as String?,
      );

  final String id;
  final String name;
  final String? hostName;
  final DateTime? startsAt;
  final DateTime? eventDate;
  final String? address;
  final String? location;
}
