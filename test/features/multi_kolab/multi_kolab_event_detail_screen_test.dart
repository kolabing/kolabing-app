import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/multi_kolab/models/child_kolab_result.dart';
import 'package:kolabing_app/features/multi_kolab/models/event_creator_entitlement.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_dashboard.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event_summary.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role_application.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/api_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_detail_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

MultiKolabRole _role({
  required String id,
  required String title,
  MultiKolabRoleStatus status = MultiKolabRoleStatus.open,
  int needed = 1,
  int filled = 0,
  MultiKolabEligibleAccountType eligible =
      MultiKolabEligibleAccountType.community,
}) => MultiKolabRole(
  id: id,
  multiKolabEventId: 'event-1',
  status: status,
  title: title,
  eligibleAccountType: eligible,
  positionsNeeded: needed,
  positionsFilled: filled,
  required_: true,
  need: 'What we need for $title',
);

MultiKolabEvent _event({
  List<MultiKolabRole>? roles,
  String? rsvpUrl,
  MultiKolabRoleApplication? viewerApplication,
}) {
  final resolved =
      roles ??
      [
        _role(id: 'role-1', title: 'Run Club Partner'),
        _role(id: 'role-2', title: 'Yoga Partner'),
        _role(id: 'role-3', title: 'Coffee Partner'),
      ];
  return MultiKolabEvent(
    id: 'event-1',
    status: MultiKolabEventStatus.recruiting,
    creatorProfileId: 'organizer-1',
    creatorProfileType: 'business',
    title: 'Kolabing Launch Weekend',
    description: 'A multi-partner launch event.',
    city: 'Barcelona',
    eventDate: DateTime(2026, 9, 12),
    rsvpUrl: rsvpUrl,
    eligibleAccountType: MultiKolabEligibleAccountType.either,
    roles: resolved,
    roleCounts: (
      total: resolved.length,
      open: resolved.where((r) => r.isOpen).length,
      filled: resolved.where((r) => r.isFilled).length,
    ),
    viewerApplication: viewerApplication,
  );
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required MultiKolabEvent event,
  String? focusedRoleId,
  MultiKolabRepository? repository,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(
    overrides: [
      multiKolabRepositoryProvider.overrideWithValue(
        repository ?? _StubRepository(event),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiKolabEventDetailScreen(
          eventId: 'event-1',
          focusedRoleId: focusedRoleId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('focused role', () {
    testWidgets('the tapped role is rendered and keyed by its role id', (
      tester,
    ) async {
      await _pumpDetail(tester, event: _event(), focusedRoleId: 'role-2');

      expect(
        find.byKey(const Key('multi-kolab-role-card-role-2')),
        findsOneWidget,
      );
      expect(find.text('Yoga Partner'), findsOneWidget);
    });

    testWidgets('the parent event context stays visible above the roles', (
      tester,
    ) async {
      await _pumpDetail(tester, event: _event(), focusedRoleId: 'role-2');

      expect(find.text('Kolabing Launch Weekend'), findsOneWidget);
      expect(find.text('A multi-partner launch event.'), findsOneWidget);
    });

    testWidgets("the event's OTHER roles remain listed", (tester) async {
      await _pumpDetail(tester, event: _event(), focusedRoleId: 'role-2');

      for (final id in ['role-1', 'role-2', 'role-3']) {
        expect(
          find.byKey(Key('multi-kolab-role-card-$id')),
          findsOneWidget,
          reason: '$id should still be listed',
        );
      }
    });

    testWidgets('no focus is required — the screen works without one', (
      tester,
    ) async {
      await _pumpDetail(tester, event: _event());

      expect(
        find.byKey(const Key('multi-kolab-role-card-role-1')),
        findsOneWidget,
      );
    });
  });

  group('apply availability', () {
    testWidgets('an open role offers "Apply to this role"', (tester) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [_role(id: 'role-1', title: 'Run Club Partner')],
        ),
      );

      expect(
        find.byKey(const Key('multi-kolab-role-apply-role-1')),
        findsOneWidget,
      );
      expect(find.text('Apply to this role'), findsOneWidget);
    });

    testWidgets('a FILLED role cannot be applied to', (tester) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [
            _role(
              id: 'role-1',
              title: 'Venue Partner',
              status: MultiKolabRoleStatus.filled,
              needed: 1,
              filled: 1,
            ),
          ],
        ),
      );

      expect(
        find.byKey(const Key('multi-kolab-role-apply-role-1')),
        findsNothing,
      );
    });

    testWidgets('the metadata line leads with availability + eligibility', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [
            _role(
              id: 'role-1',
              title: 'Run Club Partner',
              eligible: MultiKolabEligibleAccountType.community,
            ),
            _role(
              id: 'role-4',
              title: 'Content Creator',
              needed: 3,
              filled: 1,
              eligible: MultiKolabEligibleAccountType.either,
            ),
          ],
        ),
      );

      // Remaining availability first, then who may apply — in product
      // language, singular/plural correct.
      expect(find.text('1 spot open \u00b7 Communities'), findsOneWidget);
      expect(
        find.text('2 spots open \u00b7 Businesses and communities'),
        findsOneWidget,
      );

      // The raw open/filled split and the wire value are gone.
      expect(find.textContaining('0 filled'), findsNothing);
      expect(find.textContaining('Open to:'), findsNothing);
      expect(find.textContaining('community'), findsNothing);

      // "Required" survives as a quieter secondary label.
      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('a filled role shows eligibility only, never a spot count', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [
            _role(
              id: 'role-1',
              title: 'Venue Partner',
              status: MultiKolabRoleStatus.filled,
              needed: 1,
              filled: 1,
              eligible: MultiKolabEligibleAccountType.business,
            ),
          ],
        ),
      );

      expect(find.text('Businesses'), findsOneWidget);
      expect(find.textContaining('spot'), findsNothing);
      expect(
        find.byKey(const Key('multi-kolab-role-apply-role-1')),
        findsNothing,
      );
    });

    testWidgets('a role at capacity cannot be applied to', (tester) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [
            _role(id: 'role-1', title: 'Content Creator', needed: 2, filled: 2),
          ],
        ),
      );

      expect(
        find.byKey(const Key('multi-kolab-role-apply-role-1')),
        findsNothing,
      );
    });

    testWidgets('an already-applied viewer sees their status, not Apply', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [_role(id: 'role-1', title: 'Run Club Partner')],
          viewerApplication: MultiKolabRoleApplication(
            id: 'application-1',
            multiKolabRoleId: 'role-1',
            applicantProfileId: 'me',
            applicantProfileType: 'community',
            status: MultiKolabRoleApplicationStatus.pending,
            createdAt: DateTime(2026, 8, 12),
          ),
        ),
      );

      expect(find.textContaining("You've applied"), findsOneWidget);
      expect(
        find.byKey(const Key('multi-kolab-role-apply-role-1')),
        findsNothing,
      );
    });
  });

  group('RSVP is HTTPS-only', () {
    testWidgets('an https RSVP url shows the RSVP action', (tester) async {
      await _pumpDetail(
        tester,
        event: _event(rsvpUrl: 'https://lu.ma/kolabing-launch'),
      );

      expect(find.text('RSVP'), findsOneWidget);
    });

    for (final url in <String?>[
      'http://lu.ma/kolabing-launch',
      'javascript:alert(1)',
      'lu.ma/kolabing-launch',
      null,
    ]) {
      testWidgets('a non-https RSVP url ($url) shows no RSVP action', (
        tester,
      ) async {
        await _pumpDetail(tester, event: _event(rsvpUrl: url));

        expect(find.text('RSVP'), findsNothing);
      });
    }
  });

  group('application error handling', () {
    Future<void> submitAndExpect(
      WidgetTester tester, {
      required String stableCode,
      required String expectedMessage,
    }) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [_role(id: 'role-1', title: 'Run Club Partner')],
        ),
        repository: _RejectingRepository(
          _event(
            roles: [_role(id: 'role-1', title: 'Run Club Partner')],
          ),
          stableCode: stableCode,
        ),
      );

      await tester.tap(find.byKey(const Key('multi-kolab-role-apply-role-1')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Our pitch');
      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();

      expect(find.text(expectedMessage), findsOneWidget);
    }

    testWidgets('duplicate_application surfaces its message', (tester) async {
      await submitAndExpect(
        tester,
        stableCode: 'duplicate_application',
        expectedMessage: "You've already applied to this role.",
      );
    });

    testWidgets('role_ineligible surfaces its message', (tester) async {
      await submitAndExpect(
        tester,
        stableCode: 'role_ineligible',
        expectedMessage: "Your account type can't apply to this role.",
      );
    });

    testWidgets('role_not_open surfaces its message', (tester) async {
      await submitAndExpect(
        tester,
        stableCode: 'role_not_open',
        expectedMessage: 'This role is no longer open.',
      );
    });

    testWidgets('event_not_recruiting surfaces its message', (tester) async {
      await submitAndExpect(
        tester,
        stableCode: 'event_not_recruiting',
        expectedMessage: "This event isn't accepting applications right now.",
      );
    });

    testWidgets('an unknown code falls back to the generic message', (
      tester,
    ) async {
      await submitAndExpect(
        tester,
        stableCode: 'something_unexpected',
        expectedMessage: 'Something went wrong. Please try again.',
      );
    });
  });

  group('successful application', () {
    testWidgets('submitting a valid pitch confirms success', (tester) async {
      await _pumpDetail(
        tester,
        event: _event(
          roles: [_role(id: 'role-1', title: 'Run Club Partner')],
        ),
      );

      await tester.tap(find.byKey(const Key('multi-kolab-role-apply-role-1')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'We bring 30+ runners.',
      );
      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();

      expect(find.text('Application sent!'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Stub repositories
// ---------------------------------------------------------------------------

class _StubRepository implements MultiKolabRepository {
  _StubRepository(this.event);

  final MultiKolabEvent event;

  @override
  Future<MultiKolabEvent> getEvent(String eventId) async => event;

  @override
  Future<MultiKolabRoleApplication> apply(
    String roleId,
    CreateMultiKolabApplicationInput input,
  ) async => MultiKolabRoleApplication(
    id: 'application-1',
    multiKolabRoleId: roleId,
    applicantProfileId: 'me',
    applicantProfileType: 'community',
    status: MultiKolabRoleApplicationStatus.pending,
    pitch: input.pitch,
    createdAt: DateTime(2026, 8, 12),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');

  // Unused members of the interface, declared so the class is concrete.
  @override
  Future<MultiKolabRole> addRole(String eventId, CreateMultiKolabRoleInput i) =>
      throw UnimplementedError();
  @override
  Future<ChildKolabResult> accept(String applicationId) =>
      throw UnimplementedError();
  @override
  Future<void> cancelEvent(String eventId, String reason) =>
      throw UnimplementedError();
  @override
  Future<MultiKolabEvent> createDraft(CreateMultiKolabEventInput input) =>
      throw UnimplementedError();
  @override
  Future<MultiKolabRoleApplication> decline(String applicationId) =>
      throw UnimplementedError();
  @override
  Future<List<MultiKolabEventSummary>> explore(
    MultiKolabExploreFilter filter,
  ) => throw UnimplementedError();
  @override
  Future<MultiKolabDashboard> getDashboard(String eventId) =>
      throw UnimplementedError();
  @override
  Future<EventCreatorEntitlement> getEntitlement() =>
      throw UnimplementedError();
  @override
  Future<List<MultiKolabEventSummary>> myEvents() => throw UnimplementedError();
  @override
  Future<MultiKolabEvent> publish(String eventId) => throw UnimplementedError();
  @override
  Future<MultiKolabRoleApplication> shortlist(String applicationId) =>
      throw UnimplementedError();
  @override
  Future<MultiKolabEvent> updateDraft(
    String eventId,
    UpdateMultiKolabEventInput input,
  ) => throw UnimplementedError();
  @override
  Future<void> withdraw(String applicationId, String reason) =>
      throw UnimplementedError();
}

/// Rejects every application with a given stable error code (§10 envelope).
class _RejectingRepository extends _StubRepository {
  _RejectingRepository(super.event, {required this.stableCode});

  final String stableCode;

  @override
  Future<MultiKolabRoleApplication> apply(
    String roleId,
    CreateMultiKolabApplicationInput input,
  ) async => throw ApiException(
    error: ApiError.fromJson(<String, dynamic>{
      'success': false,
      'message': 'Rejected',
      'errors': <String, dynamic>{
        'application': <String>[stableCode],
      },
    }, statusCode: 422),
  );
}
