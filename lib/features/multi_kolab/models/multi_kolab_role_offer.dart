import 'package:flutter/foundation.dart';

import '../../../utils/remote_media_url.dart';
import 'multi_kolab_enums.dart';

/// One OPEN Multi-Kolab partner role, projected as a single Explore feed
/// offer.
///
/// This is the discovery-feed view of a role — deliberately NOT the same
/// thing as [MultiKolabRole] (the event-detail/authoring shape). The feed
/// needs denormalised parent-event context (title, city, date, image) that
/// the detail role object doesn't carry, and it never needs the authoring
/// fields (`details`, `requirements`, timestamps).
///
/// Invariant: one role produces exactly ONE feed item, no matter how many
/// positions it needs — [positionsRemaining] communicates the count instead
/// of the feed duplicating the card.
@immutable
class MultiKolabRoleOffer {
  const MultiKolabRoleOffer({
    required this.roleId,
    required this.eventId,
    required this.roleTitle,
    required this.eventTitle,
    required this.status,
    required this.eligibleAccountType,
    required this.positionsNeeded,
    required this.positionsFilled,
    this.lookingFor,
    this.compensationType,
    this.need,
    this.receive,
    this.valueSummary,
    this.city,
    this.eventDate,
    this.dateRangeEnd,
    this.dateMode,
    this.availabilityLabel,
    this.coverPhotoUrl,
    this.organizerProfileId,
    this.organizerDisplayName,
    this.organizerAvatarUrl,
    this.rsvpUrl,
    this.matchScore,
    this.publishedAt,
    this.required_ = true,
    this.viewerHasApplied = false,
    int? positionsRemainingOverride,
  }) : _positionsRemainingOverride = positionsRemainingOverride;

  /// Parses the `multi_kolab_role` feed item documented in §13 of the
  /// Multi-Kolab API contract (`MultiKolabRoleExploreResource`).
  ///
  /// The backend nests several groups (`looking_for`, `compensation`,
  /// `target_date`, `rsvp`); flatter aliases are also accepted so a fixture
  /// or a future contract tweak that promotes a field to the top level keeps
  /// parsing.
  factory MultiKolabRoleOffer.fromJson(Map<String, dynamic> json) {
    final lookingFor = _asMap(json['looking_for']);
    final compensation = _asMap(json['compensation']);
    final targetDate = _asMap(json['target_date']);
    final rsvp = _asMap(json['rsvp']);
    final event = _asMap(json['multi_kolab_event']);
    final organizer = _firstMap(<Object?>[
      json['creator_profile'],
      json['organizer_profile'],
      event['creator_profile'],
    ]);

    final positionsNeeded = _asInt(json['positions_needed']) ?? 1;
    final positionsFilled = _asInt(json['positions_filled']) ?? 0;

    return MultiKolabRoleOffer(
      roleId: _firstString(<Object?>[json['role_id'], json['id']]) ?? '',
      eventId:
          _firstString(<Object?>[
            json['multi_kolab_event_id'],
            json['event_id'],
            event['id'],
          ]) ??
          '',
      roleTitle:
          _firstString(<Object?>[json['role_title'], json['title']]) ?? '',
      eventTitle:
          _firstString(<Object?>[json['event_title'], event['title']]) ?? '',
      // §13 only ever emits OPEN roles, so `open` is the correct default
      // when the resource omits a status.
      status: MultiKolabRoleStatus.fromApiValue(
        _firstString(<Object?>[json['status'], json['role_status']]) ?? 'open',
      ),
      eligibleAccountType: MultiKolabEligibleAccountType.fromApiValue(
        _firstString(<Object?>[
              lookingFor['eligible_account_type'],
              json['eligible_account_type'],
            ]) ??
            'either',
      ),
      positionsNeeded: positionsNeeded,
      positionsFilled: positionsFilled,
      positionsRemainingOverride: _asInt(json['positions_remaining']),
      required_: _asBool(lookingFor['required'] ?? json['required']) ?? true,
      // §13's `looking_for` carries eligibility, not a partner TYPE. A
      // specific partner type is only rendered when the backend actually
      // names one; otherwise the card falls back to open-ended copy driven
      // by [eligibleAccountType]. Never inferred from free text.
      lookingFor: MultiKolabPartnerTypeRequest.fromJson(
        lookingFor['partner_type'] ??
            lookingFor['community_type'] ??
            lookingFor['business_type'] ??
            json['partner_type'],
      ),
      compensationType: MultiKolabCompensationType.fromApiValue(
        _firstString(<Object?>[
          compensation['type'],
          json['compensation_type'],
        ]),
      ),
      need: _firstString(<Object?>[compensation['need'], json['need']]),
      receive: _firstString(<Object?>[
        compensation['receive'],
        json['receive'],
      ]),
      valueSummary: _firstString(<Object?>[
        compensation['value_summary'],
        json['value_summary'],
        event['value_summary'],
      ]),
      city: _firstString(<Object?>[json['city'], event['city']]),
      eventDate: _asDate(
        targetDate['date'] ??
            targetDate['range_start'] ??
            json['event_date'] ??
            event['event_date'],
      ),
      dateRangeEnd: _asDate(targetDate['range_end']),
      dateMode: MultiKolabDateMode.fromApiValue(
        _firstString(<Object?>[
          targetDate['mode'],
          json['date_mode'],
          event['date_mode'],
        ]),
      ),
      availabilityLabel: _firstString(<Object?>[
        json['availability_label'],
        json['date_label'],
      ]),
      coverPhotoUrl: normalizeRemoteMediaUrlOrNull(
        _firstString(<Object?>[
          json['image_url'],
          json['cover_photo_url'],
          event['cover_photo_url'],
        ]),
      ),
      organizerProfileId: _firstString(<Object?>[
        organizer['id'],
        json['creator_profile_id'],
        json['organizer_profile_id'],
        event['creator_profile_id'],
      ]),
      organizerDisplayName: _firstString(<Object?>[organizer['display_name']]),
      organizerAvatarUrl: normalizeRemoteMediaUrlOrNull(
        _firstString(<Object?>[organizer['avatar_url']]),
      ),
      rsvpUrl: _firstString(<Object?>[
        rsvp['url'],
        json['rsvp_url'],
        event['rsvp_url'],
      ]),
      matchScore: _asInt(
        json['match_score'] ??
            (json['match'] is Map<String, dynamic>
                ? (json['match'] as Map<String, dynamic>)['score']
                : null),
      ),
      publishedAt: _asDate(json['published_at']),
      // §13 does not (yet) expose per-role viewer application state on the
      // feed. Parsed when present so the card's already-applied treatment
      // lights up the moment the backend adds it.
      viewerHasApplied:
          _asBool(json['viewer_has_applied'] ?? json['has_applied']) ??
          (json['viewer_application'] != null),
    );
  }

  /// Wire discriminator emitted by the heterogeneous discovery feed for this
  /// item type. See [isMultiKolabRoleJson].
  static const String itemTypeValue = 'multi_kolab_role';

  /// True when [json] is a Multi-Kolab role entry of the heterogeneous feed.
  /// Branches on the backend's explicit `item_type` discriminator only —
  /// never on title text, id shape, or the presence of a stray field.
  static bool isMultiKolabRoleJson(Map<String, dynamic> json) =>
      json['item_type']?.toString() == itemTypeValue;

  final String roleId;
  final String eventId;
  final String roleTitle;
  final String eventTitle;
  final MultiKolabRoleStatus status;
  final MultiKolabEligibleAccountType eligibleAccountType;
  final int positionsNeeded;
  final int positionsFilled;

  /// Structured partner-type request. `null` means the organizer left the
  /// role open-ended ("open to any business"), which the UI must render from
  /// [eligibleAccountType] — never by parsing free text.
  final MultiKolabPartnerTypeRequest? lookingFor;
  final MultiKolabCompensationType? compensationType;

  /// What the organizer needs from this partner.
  final String? need;

  /// What the partner gets in return.
  final String? receive;

  /// The parent event's headline value proposition.
  final String? valueSummary;
  final String? city;
  final DateTime? eventDate;
  final DateTime? dateRangeEnd;
  final MultiKolabDateMode? dateMode;
  final String? availabilityLabel;
  final String? coverPhotoUrl;
  final String? organizerProfileId;
  final String? organizerDisplayName;
  final String? organizerAvatarUrl;
  final String? rsvpUrl;
  final int? matchScore;
  final DateTime? publishedAt;
  final bool required_;
  final bool viewerHasApplied;

  /// The backend's own `positions_remaining`, trusted over the local
  /// subtraction when present.
  final int? _positionsRemainingOverride;

  bool get isOpen => status == MultiKolabRoleStatus.open;
  bool get isFilled => status == MultiKolabRoleStatus.filled;

  int get positionsRemaining =>
      _positionsRemainingOverride ??
      (positionsNeeded - positionsFilled).clamp(0, positionsNeeded);

  /// Whether the organizer left this role open to any partner of the
  /// eligible account type, rather than requesting a specific partner type.
  bool get isOpenEnded => lookingFor == null;

  /// Only an `https://` RSVP link is ever surfaced. Anything else (http,
  /// javascript:, a bare domain, empty) yields null so the RSVP action is
  /// simply not offered.
  String? get safeRsvpUrl {
    final raw = rsvpUrl?.trim();
    if (raw == null || !raw.startsWith('https://')) return null;
    final parsed = Uri.tryParse(raw);
    if (parsed == null || parsed.host.isEmpty) return null;
    return raw;
  }

  /// Whether this role can still receive an application from the viewer.
  /// Applying is blocked for filled/closed roles, roles with no remaining
  /// position, and roles the viewer already applied to.
  bool get canApply => isOpen && positionsRemaining > 0 && !viewerHasApplied;

  /// Eligibility routing for the two Explore feeds: a Community role shows
  /// only in Community Explore, a Business role only in Business Explore,
  /// and an `either` role in both.
  bool isEligibleFor({required bool isCommunityViewer}) =>
      switch (eligibleAccountType) {
        MultiKolabEligibleAccountType.either => true,
        MultiKolabEligibleAccountType.community => isCommunityViewer,
        MultiKolabEligibleAccountType.business => !isCommunityViewer,
      };

  /// Whether the role belongs to the viewer's own event — an organizer must
  /// never see their own role offered back to them in Explore.
  bool isOwnedBy(String? viewerProfileId) {
    final organizerId = organizerProfileId;
    if (viewerProfileId == null || viewerProfileId.isEmpty) return false;
    if (organizerId == null || organizerId.isEmpty) return false;
    return organizerId == viewerProfileId;
  }

  /// The single visibility gate for the Explore feed. A role appears only
  /// when it is OPEN, has a remaining position, matches the viewer's feed,
  /// and isn't the viewer's own.
  bool isVisibleInExplore({
    required bool isCommunityViewer,
    required String? viewerProfileId,
  }) =>
      isOpen &&
      positionsRemaining > 0 &&
      isEligibleFor(isCommunityViewer: isCommunityViewer) &&
      !isOwnedBy(viewerProfileId);
}

/// A structured partner-type request on a role ("looking for a run club").
/// Always `{key, label}` from the backend so the UI never has to parse
/// free-text copy to know what kind of partner is wanted.
@immutable
class MultiKolabPartnerTypeRequest {
  const MultiKolabPartnerTypeRequest({required this.key, required this.label});

  static MultiKolabPartnerTypeRequest? fromJson(Object? raw) {
    if (raw is Map<String, dynamic>) {
      final key = raw['key']?.toString() ?? '';
      final rawLabel = (raw['label'] ?? raw['type_label'])?.toString().trim();
      final label = (rawLabel != null && rawLabel.isNotEmpty)
          ? rawLabel
          : _labelFromKey(key);
      if (label.isEmpty) return null;
      return MultiKolabPartnerTypeRequest(key: key, label: label);
    }
    final slug = raw?.toString().trim();
    if (slug == null || slug.isEmpty) return null;
    return MultiKolabPartnerTypeRequest(key: slug, label: _labelFromKey(slug));
  }

  final String key;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is MultiKolabPartnerTypeRequest &&
      other.key == key &&
      other.label == label;

  @override
  int get hashCode => Object.hash(key, label);
}

String _labelFromKey(String key) => key
    .split(RegExp(r'[_\s]+'))
    .where((String part) => part.isNotEmpty)
    .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

Map<String, dynamic> _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

Map<String, dynamic> _firstMap(List<Object?> candidates) {
  for (final candidate in candidates) {
    if (candidate is Map<String, dynamic> && candidate.isNotEmpty) {
      return candidate;
    }
  }
  return const <String, dynamic>{};
}

String? _firstString(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _asBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
