import '../models/child_kolab_result.dart';
import '../models/event_creator_entitlement.dart';
import '../models/multi_kolab_creator_summary.dart';
import '../models/multi_kolab_dashboard.dart';
import '../models/multi_kolab_enums.dart';
import '../models/multi_kolab_event.dart';
import '../models/multi_kolab_event_summary.dart';
import '../models/multi_kolab_role.dart';
import '../models/multi_kolab_role_application.dart';
import 'multi_kolab_repository.dart';

/// Deterministic, in-memory implementation used for isolated UI development
/// and widget tests while the real backend endpoints are integrated
/// incrementally. Never selected in a production build (see
/// `multiKolabRepositoryProvider`). Fixtures mirror the frozen API contract
/// exactly, not just "plausible-looking" data.
class MockMultiKolabRepository implements MultiKolabRepository {
  MockMultiKolabRepository({this.simulatedDelay = Duration.zero});

  /// The profile id the mock treats as the signed-in viewer, so fixtures can
  /// exercise "this is my own event" exclusion.
  static const String mockViewerProfileId = 'me';

  final Duration simulatedDelay;

  final Map<String, MultiKolabEvent> _events = {
    'event-1': MultiKolabEvent(
      id: 'event-1',
      status: MultiKolabEventStatus.recruiting,
      creatorProfileId: 'organizer-1',
      creatorProfileType: 'business',
      title: 'Kolabing Launch Weekend',
      description: 'A multi-partner launch event with venue, run, and yoga.',
      valueSummary: 'Free entry, venue + brand partners wanted',
      venueNeeded: true,
      dateMode: MultiKolabDateMode.exact,
      eventDate: DateTime(2026, 9, 12),
      city: 'Barcelona',
      category: 'Music',
      rsvpUrl: 'https://lu.ma/kolabing-launch',
      eligibleAccountType: MultiKolabEligibleAccountType.either,
      roles: [
        // Community-only, single position, specific partner type requested.
        MultiKolabRole(
          id: 'role-1',
          multiKolabEventId: 'event-1',
          status: MultiKolabRoleStatus.open,
          title: 'Run Club Partner',
          eligibleAccountType: MultiKolabEligibleAccountType.community,
          positionsNeeded: 1,
          positionsFilled: 0,
          required_: true,
          need: 'A running route + 20-30 participants',
          receive: 'Free venue, post-run brunch, social tagging',
          compensationType: MultiKolabCompensationType.valueExchange,
        ),
        // FILLED — must never appear as an Explore card.
        MultiKolabRole(
          id: 'role-2',
          multiKolabEventId: 'event-1',
          status: MultiKolabRoleStatus.filled,
          title: 'Venue Partner',
          eligibleAccountType: MultiKolabEligibleAccountType.business,
          positionsNeeded: 1,
          positionsFilled: 1,
          required_: true,
        ),
        // Business-only, open-ended (no specific partner type requested).
        MultiKolabRole(
          id: 'role-3',
          multiKolabEventId: 'event-1',
          status: MultiKolabRoleStatus.open,
          title: 'Coffee Sponsor',
          eligibleAccountType: MultiKolabEligibleAccountType.business,
          positionsNeeded: 1,
          positionsFilled: 0,
          required_: false,
          need: 'Coffee for 60 runners',
          receive: 'Logo on the start banner + social tagging',
          compensationType: MultiKolabCompensationType.sponsoredInKind,
        ),
        // `either` + MULTI-POSITION — one card, "2 spots open".
        MultiKolabRole(
          id: 'role-4',
          multiKolabEventId: 'event-1',
          status: MultiKolabRoleStatus.open,
          title: 'Content Creator',
          eligibleAccountType: MultiKolabEligibleAccountType.either,
          positionsNeeded: 3,
          positionsFilled: 1,
          required_: false,
          need: 'Reels + photo coverage on the day',
          receive: 'Paid day rate',
          compensationType: MultiKolabCompensationType.paid,
        ),
      ],
      roleCounts: (total: 4, open: 3, filled: 1),
      createdAt: DateTime(2026, 8, 12, 9),
      publishedAt: DateTime(2026, 8, 12, 9, 5),
    ),
    // A SECOND recruiting event owned by the mock viewer ("me"). Its role is
    // open and eligible, but must never appear in that viewer's own feed.
    'event-2': MultiKolabEvent(
      id: 'event-2',
      status: MultiKolabEventStatus.recruiting,
      creatorProfileId: mockViewerProfileId,
      creatorProfileType: 'community',
      title: 'My Own Rooftop Session',
      description: 'An event the mock viewer organizes themselves.',
      valueSummary: 'Looking for a venue and a DJ',
      venueNeeded: true,
      dateMode: MultiKolabDateMode.exact,
      eventDate: DateTime(2026, 10, 3),
      city: 'Barcelona',
      category: 'Music',
      eligibleAccountType: MultiKolabEligibleAccountType.either,
      roles: [
        MultiKolabRole(
          id: 'role-5',
          multiKolabEventId: 'event-2',
          status: MultiKolabRoleStatus.open,
          title: 'DJ Partner',
          eligibleAccountType: MultiKolabEligibleAccountType.either,
          positionsNeeded: 1,
          positionsFilled: 0,
          required_: true,
        ),
      ],
      roleCounts: (total: 1, open: 1, filled: 0),
      createdAt: DateTime(2026, 8, 13, 9),
      publishedAt: DateTime(2026, 8, 13, 9, 5),
    ),
  };

  /// Seeded so the organizer applicant-review screens have deterministic
  /// content in every status bucket without the test first having to apply.
  /// They all sit on `role-5`, which belongs to `event-2` — the event the
  /// mock viewer organizes. `role-1` is deliberately left empty so unit
  /// tests can assert on exactly what they filed.
  final Map<String, MultiKolabRoleApplication> _applications = {
    'seed-application-1': MultiKolabRoleApplication(
      id: 'seed-application-1',
      multiKolabRoleId: 'role-5',
      applicantProfileId: 'applicant-1',
      applicantProfileType: 'business',
      status: MultiKolabRoleApplicationStatus.pending,
      pitch: 'We DJ three rooftop nights a month and can bring our own rig.',
      availability: 'Any Friday in October',
      createdAt: DateTime(2026, 8, 14, 10),
    ),
    'seed-application-2': MultiKolabRoleApplication(
      id: 'seed-application-2',
      multiKolabRoleId: 'role-5',
      applicantProfileId: 'applicant-2',
      applicantProfileType: 'community',
      status: MultiKolabRoleApplicationStatus.shortlisted,
      pitch: 'Our collective runs a 200-person monthly session.',
      availability: 'First two weekends of October',
      createdAt: DateTime(2026, 8, 14, 11),
    ),
    'seed-application-3': MultiKolabRoleApplication(
      id: 'seed-application-3',
      multiKolabRoleId: 'role-5',
      applicantProfileId: 'applicant-3',
      applicantProfileType: 'business',
      status: MultiKolabRoleApplicationStatus.declined,
      pitch: 'We do wedding sets.',
      createdAt: DateTime(2026, 8, 14, 12),
    ),
  };
  int _applicationSeq = 0;

  Future<void> _delay() => simulatedDelay == Duration.zero
      ? Future.value()
      : Future.delayed(simulatedDelay);

  @override
  Future<MultiKolabEvent> createDraft(CreateMultiKolabEventInput input) async {
    await _delay();
    final id = 'draft-${_events.length + 1}';
    final event = MultiKolabEvent(
      id: id,
      status: MultiKolabEventStatus.draft,
      creatorProfileId: 'me',
      title: input.title ?? '',
      description: input.description,
      valueSummary: input.valueSummary,
      venueNeeded: input.venueNeeded ?? false,
      dateMode: input.dateMode,
      eventDate: input.eventDate,
      dateRangeStart: input.dateRangeStart,
      dateRangeEnd: input.dateRangeEnd,
      city: input.city,
      category: input.category,
      rsvpUrl: input.rsvpUrl,
      eligibleAccountType:
          input.eligibleAccountType ?? MultiKolabEligibleAccountType.either,
      roles: const [],
      roleCounts: (total: 0, open: 0, filled: 0),
      createdAt: DateTime.now(),
    );
    _events[id] = event;
    return event;
  }

  @override
  Future<MultiKolabEvent> updateDraft(
    String eventId,
    UpdateMultiKolabEventInput input,
  ) async {
    await _delay();
    final existing = _mustGet(eventId);
    final updated = MultiKolabEvent(
      id: existing.id,
      status: existing.status,
      creatorProfileId: existing.creatorProfileId,
      creatorProfileType: existing.creatorProfileType,
      title: input.title ?? existing.title,
      description: input.description ?? existing.description,
      valueSummary: input.valueSummary ?? existing.valueSummary,
      venueNeeded: input.venueNeeded ?? existing.venueNeeded,
      dateMode: input.dateMode ?? existing.dateMode,
      eventDate: input.eventDate ?? existing.eventDate,
      dateRangeStart: input.dateRangeStart ?? existing.dateRangeStart,
      dateRangeEnd: input.dateRangeEnd ?? existing.dateRangeEnd,
      city: input.city ?? existing.city,
      category: input.category ?? existing.category,
      rsvpUrl: input.rsvpUrl ?? existing.rsvpUrl,
      eligibleAccountType:
          input.eligibleAccountType ?? existing.eligibleAccountType,
      roles: existing.roles,
      roleCounts: existing.roleCounts,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _events[eventId] = updated;
    return updated;
  }

  @override
  Future<MultiKolabRole> addRole(
    String eventId,
    CreateMultiKolabRoleInput input,
  ) async {
    await _delay();
    final existing = _mustGet(eventId);
    final role = MultiKolabRole(
      id: 'role-${DateTime.now().microsecondsSinceEpoch}',
      multiKolabEventId: eventId,
      status: MultiKolabRoleStatus.open,
      title: input.title,
      eligibleAccountType: input.eligibleAccountType,
      positionsNeeded: input.positionsNeeded,
      positionsFilled: 0,
      required_: input.required_,
      need: input.need,
      receive: input.receive,
      compensationType: input.compensationType,
      requirements: input.requirements,
      details: input.details,
    );
    final roles = [...existing.roles, role];
    _events[eventId] = _withRoles(existing, roles);
    return role;
  }

  @override
  Future<MultiKolabEvent> publish(String eventId) async {
    await _delay();
    final existing = _mustGet(eventId);
    final published = MultiKolabEvent(
      id: existing.id,
      status: MultiKolabEventStatus.recruiting,
      creatorProfileId: existing.creatorProfileId,
      creatorProfileType: existing.creatorProfileType,
      title: existing.title,
      description: existing.description,
      valueSummary: existing.valueSummary,
      venueNeeded: existing.venueNeeded,
      dateMode: existing.dateMode,
      eventDate: existing.eventDate,
      dateRangeStart: existing.dateRangeStart,
      dateRangeEnd: existing.dateRangeEnd,
      city: existing.city,
      category: existing.category,
      rsvpUrl: existing.rsvpUrl,
      eligibleAccountType: existing.eligibleAccountType,
      roles: existing.roles,
      roleCounts: existing.roleCounts,
      createdAt: existing.createdAt,
      publishedAt: DateTime.now(),
    );
    _events[eventId] = published;
    return published;
  }

  @override
  Future<List<MultiKolabEventSummary>> explore(
    MultiKolabExploreFilter filter,
  ) async {
    await _delay();
    return _events.values
        .where((e) => e.status == filter.status)
        .where((e) => filter.city == null || e.city == filter.city)
        .map(
          (e) => MultiKolabEventSummary(
            id: e.id,
            status: e.status,
            title: e.title,
            valueSummary: e.valueSummary,
            city: e.city,
            category: e.category,
            eventDate: e.eventDate,
            dateMode: e.dateMode,
            roleCounts: MultiKolabRoleCounts(
              total: e.roleCounts.total,
              open: e.roleCounts.open,
              filled: e.roleCounts.filled,
            ),
            eligibleAccountType: e.eligibleAccountType,
            creatorProfile: const MultiKolabCreatorSummary(
              id: 'organizer-1',
              displayName: 'Kolabing',
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<MultiKolabEventSummary>> myEvents() async {
    await _delay();
    // Mirrors `GET /multi-kolab-events/me`: every event the viewer created,
    // in ANY status (drafts included) — not the status-filtered Explore
    // listing, which is a different endpoint with different semantics.
    return _events.values
        .where((e) => e.creatorProfileId == mockViewerProfileId)
        .map(_summaryOf)
        .toList(growable: false);
  }

  @override
  Future<MultiKolabRole> updateRole(
    String roleId,
    UpdateMultiKolabRoleInput input,
  ) async {
    await _delay();
    final entry = _findRole(roleId);
    final event = entry.$1;
    final existing = entry.$2;

    if (input.status == MultiKolabRoleStatus.open &&
        existing.positionsFilled >=
            (input.positionsNeeded ?? existing.positionsNeeded)) {
      throw StateError('role_capacity_exceeded');
    }

    final updated = existing.copyWith(
      title: input.title,
      eligibleAccountType: input.eligibleAccountType,
      positionsNeeded: input.positionsNeeded,
      required_: input.required_,
      need: input.need,
      receive: input.receive,
      compensationType: input.compensationType,
      requirements: input.requirements,
      details: input.details,
      status: input.status,
    );

    _events[event.id] = _withRoles(event, [
      for (final role in event.roles) role.id == roleId ? updated : role,
    ]);

    return updated;
  }

  @override
  Future<MultiKolabRole> setRoleStatus(
    String roleId,
    MultiKolabRoleStatus status,
  ) {
    return updateRole(roleId, UpdateMultiKolabRoleInput(status: status));
  }

  @override
  Future<List<MultiKolabRoleApplication>> roleApplications(
    String roleId,
  ) async {
    await _delay();
    return _applications.values
        .where((a) => a.multiKolabRoleId == roleId)
        .toList(growable: false);
  }

  @override
  Future<MultiKolabEvent> confirmEvent(String eventId) async {
    await _delay();
    final updated = _mustGet(
      eventId,
    ).copyWith(status: MultiKolabEventStatus.confirmed);
    _events[eventId] = updated;
    return updated;
  }

  @override
  Future<MultiKolabEvent> completeEvent(String eventId) async {
    await _delay();
    final updated = _mustGet(
      eventId,
    ).copyWith(status: MultiKolabEventStatus.completed);
    _events[eventId] = updated;
    return updated;
  }

  (MultiKolabEvent, MultiKolabRole) _findRole(String roleId) {
    for (final event in _events.values) {
      for (final role in event.roles) {
        if (role.id == roleId) return (event, role);
      }
    }
    throw StateError('MockMultiKolabRepository: no role "$roleId"');
  }

  MultiKolabEventSummary _summaryOf(MultiKolabEvent e) => MultiKolabEventSummary(
    id: e.id,
    status: e.status,
    title: e.title,
    valueSummary: e.valueSummary,
    city: e.city,
    category: e.category,
    eventDate: e.eventDate,
    dateMode: e.dateMode,
    roleCounts: MultiKolabRoleCounts(
      total: e.roleCounts.total,
      open: e.roleCounts.open,
      filled: e.roleCounts.filled,
    ),
    eligibleAccountType: e.eligibleAccountType,
    creatorProfile: const MultiKolabCreatorSummary(
      id: mockViewerProfileId,
      displayName: 'Kolabing',
    ),
  );

  @override
  Future<MultiKolabEvent> getEvent(String eventId) async {
    await _delay();
    return _mustGet(eventId);
  }

  @override
  Future<MultiKolabRoleApplication> apply(
    String roleId,
    CreateMultiKolabApplicationInput input,
  ) async {
    await _delay();
    _applicationSeq++;
    final application = MultiKolabRoleApplication(
      id: 'application-$_applicationSeq',
      multiKolabRoleId: roleId,
      applicantProfileId: 'me',
      applicantProfileType: 'community',
      status: MultiKolabRoleApplicationStatus.pending,
      pitch: input.pitch,
      availability: input.availability,
      createdAt: DateTime.now(),
    );
    _applications[application.id] = application;
    return application;
  }

  @override
  Future<MultiKolabDashboard> getDashboard(String eventId) async {
    await _delay();
    final event = _mustGet(eventId);
    return MultiKolabDashboard(
      eventId: event.id,
      status: event.status,
      roleCounts: MultiKolabRoleCounts(
        total: event.roleCounts.total,
        open: event.roleCounts.open,
        filled: event.roleCounts.filled,
      ),
      roles: event.roles
          .map(
            (r) => MultiKolabDashboardRole(
              roleId: r.id,
              title: r.title,
              positionsNeeded: r.positionsNeeded,
              positionsFilled: r.positionsFilled,
              status: r.status,
              applicationCounts: const MultiKolabApplicationCounts(),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<MultiKolabRoleApplication> shortlist(String applicationId) async {
    await _delay();
    return _transition(
      applicationId,
      MultiKolabRoleApplicationStatus.shortlisted,
    );
  }

  @override
  Future<ChildKolabResult> accept(String applicationId) async {
    await _delay();
    final application = _transition(
      applicationId,
      MultiKolabRoleApplicationStatus.accepted,
    );
    _fillOnePosition(application.multiKolabRoleId);
    return ChildKolabResult(
      applicationId: application.id,
      applicationStatus: 'accepted',
      kolabId: 'kolab-$applicationId',
      kolabStatus: 'published',
      collaborationId: 'collaboration-$applicationId',
      collaborationStatus: 'scheduled',
    );
  }

  @override
  Future<MultiKolabRoleApplication> decline(String applicationId) async {
    await _delay();
    return _transition(applicationId, MultiKolabRoleApplicationStatus.declined);
  }

  @override
  Future<void> withdraw(String applicationId, String reason) async {
    await _delay();
    _transition(applicationId, MultiKolabRoleApplicationStatus.withdrawn);
  }

  @override
  Future<void> cancelEvent(String eventId, String reason) async {
    await _delay();
    // Cancellation never destroys the event or its roles (contract §5) —
    // only the status changes.
    _events[eventId] = _mustGet(
      eventId,
    ).copyWith(status: MultiKolabEventStatus.cancelled);
  }

  @override
  Future<EventCreatorEntitlement> getEntitlement() async {
    await _delay();
    return EventCreatorEntitlement(
      hasEventCreatorEntitlement: true,
      grantedAt: DateTime(2026, 8, 1),
      expiresAt: DateTime(2027, 8, 1),
      source: 'maintainer',
    );
  }

  MultiKolabEvent _mustGet(String eventId) {
    final event = _events[eventId];
    if (event == null) {
      throw StateError('MockMultiKolabRepository: no event "$eventId"');
    }
    return event;
  }

  MultiKolabEvent _withRoles(
    MultiKolabEvent event,
    List<MultiKolabRole> roles,
  ) {
    return MultiKolabEvent(
      id: event.id,
      status: event.status,
      creatorProfileId: event.creatorProfileId,
      creatorProfileType: event.creatorProfileType,
      title: event.title,
      description: event.description,
      valueSummary: event.valueSummary,
      venueNeeded: event.venueNeeded,
      dateMode: event.dateMode,
      eventDate: event.eventDate,
      dateRangeStart: event.dateRangeStart,
      dateRangeEnd: event.dateRangeEnd,
      city: event.city,
      category: event.category,
      rsvpUrl: event.rsvpUrl,
      eligibleAccountType: event.eligibleAccountType,
      roles: roles,
      roleCounts: (
        total: roles.length,
        open: roles.where((r) => r.isOpen).length,
        filled: roles.where((r) => r.isFilled).length,
      ),
      createdAt: event.createdAt,
      updatedAt: DateTime.now(),
      publishedAt: event.publishedAt,
    );
  }

  /// Acceptance is a server-side transaction; the mock mirrors its only
  /// externally visible side effect so the organizer UI's capacity refresh
  /// is exercised end to end.
  void _fillOnePosition(String roleId) {
    final (event, role) = _findRole(roleId);
    final filled = role.positionsFilled + 1;
    final updated = role.copyWith(
      positionsFilled: filled,
      status: filled >= role.positionsNeeded
          ? MultiKolabRoleStatus.filled
          : role.status,
    );
    _events[event.id] = _withRoles(event, [
      for (final r in event.roles) r.id == roleId ? updated : r,
    ]);
  }

  MultiKolabRoleApplication _transition(
    String applicationId,
    MultiKolabRoleApplicationStatus status,
  ) {
    final existing = _applications[applicationId];
    final updated = MultiKolabRoleApplication(
      id: applicationId,
      multiKolabRoleId: existing?.multiKolabRoleId ?? 'role-1',
      applicantProfileId: existing?.applicantProfileId ?? 'me',
      applicantProfileType: existing?.applicantProfileType ?? 'community',
      status: status,
      pitch: existing?.pitch,
      availability: existing?.availability,
      kolabId: status == MultiKolabRoleApplicationStatus.accepted
          ? 'kolab-$applicationId'
          : existing?.kolabId,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    _applications[applicationId] = updated;
    return updated;
  }
}
