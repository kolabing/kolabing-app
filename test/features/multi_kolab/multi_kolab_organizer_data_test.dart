import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role_application.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_providers.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/api_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/multi_kolab_repository.dart';

/// Task 10 — organizer data layer. Every fixture below is copied from the
/// frozen API contract (`2026-08-12-multi-kolab-event-api-contract.md`), not
/// invented, so a backend contract drift fails here rather than in the UI.
void main() {
  ApiMultiKolabRepository repoReturning(
    Object body, {
    int status = 200,
    void Function(http.Request request)? onRequest,
  }) {
    return ApiMultiKolabRepository(
      authService: _StubAuthService(),
      httpClient: MockClient((request) async {
        onRequest?.call(request);
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  group('role update / status', () {
    test('updateRole PATCHes the role endpoint and parses §4 back', () async {
      late http.Request captured;
      final repo = repoReturning({
        'success': true,
        'data': {
          'id': 'role-uuid',
          'multi_kolab_event_id': 'event-uuid',
          'status': 'open',
          'title': 'Run Club Partner',
          'eligible_account_type': 'community',
          'positions_needed': 2,
          'positions_filled': 1,
          'required': true,
          'need': 'A running route',
          'receive': 'Free venue',
          'compensation_type': 'value_exchange',
          'requirements': null,
          'details': null,
          'created_at': '2026-08-12T09:05:00Z',
          'updated_at': '2026-08-12T09:06:00Z',
        },
      }, onRequest: (r) => captured = r);

      final role = await repo.updateRole(
        'role-uuid',
        const UpdateMultiKolabRoleInput(positionsNeeded: 2),
      );

      expect(captured.method, 'PATCH');
      expect(captured.url.path, endsWith('/multi-kolab-roles/role-uuid'));
      expect(jsonDecode(captured.body), {'positions_needed': 2});
      expect(role.positionsNeeded, 2);
      expect(role.positionsFilled, 1);
      expect(role.positionsRemaining, 1);
    });

    test('setRoleStatus sends only the status field', () async {
      late http.Request captured;
      final repo = repoReturning({
        'success': true,
        'data': {
          'id': 'role-uuid',
          'multi_kolab_event_id': 'event-uuid',
          'status': 'closed',
          'title': 'Run Club Partner',
          'eligible_account_type': 'community',
          'positions_needed': 1,
          'positions_filled': 0,
          'required': true,
        },
      }, onRequest: (r) => captured = r);

      final role = await repo.setRoleStatus(
        'role-uuid',
        MultiKolabRoleStatus.closed,
      );

      expect(jsonDecode(captured.body), {'status': 'closed'});
      expect(role.status, MultiKolabRoleStatus.closed);
    });

    test(
      'reopening a full role surfaces the stable role_capacity_exceeded code',
      () async {
        final repo = repoReturning({
          'success': false,
          'message': 'This role has no remaining positions.',
          'errors': {
            'role': ['role_capacity_exceeded'],
          },
        }, status: 409);

        await expectLater(
          repo.setRoleStatus('role-uuid', MultiKolabRoleStatus.open),
          throwsA(
            isA<ApiException>().having(
              (e) => e.error.stableCode,
              'stableCode',
              'role_capacity_exceeded',
            ),
          ),
        );
      },
    );
  });

  group('role applications (organizer review)', () {
    test('roleApplications parses the §7 list envelope', () async {
      late http.Request captured;
      final repo = repoReturning({
        'success': true,
        'data': [
          {
            'id': 'application-uuid',
            'multi_kolab_role_id': 'role-uuid',
            'applicant_profile_id': 'profile-uuid',
            'applicant_profile_type': 'community',
            'status': 'pending',
            'pitch': 'We run a 150-member Saturday run club.',
            'availability': 'Any Saturday in September',
            'kolab_id': null,
            'created_at': '2026-08-12T09:10:00Z',
          },
          {
            'id': 'application-2',
            'multi_kolab_role_id': 'role-uuid',
            'applicant_profile_id': 'profile-2',
            'applicant_profile_type': 'business',
            'status': 'accepted',
            'pitch': 'We can host.',
            'availability': null,
            'kolab_id': 'kolab-uuid',
            'created_at': '2026-08-12T09:11:00Z',
          },
        ],
        'meta': {'current_page': 1, 'last_page': 1, 'per_page': 15, 'total': 2},
      }, onRequest: (r) => captured = r);

      final applications = await repo.roleApplications('role-uuid');

      expect(captured.method, 'GET');
      expect(
        captured.url.path,
        endsWith('/multi-kolab-roles/role-uuid/applications'),
      );
      expect(applications, hasLength(2));
      expect(
        applications.first.status,
        MultiKolabRoleApplicationStatus.pending,
      );
      expect(applications.first.pitch, contains('run club'));
      // The organizer resource never carries withdrawal_reason (contract §12).
      expect(applications.last.kolabId, 'kolab-uuid');
      expect(applications.last.isAccepted, isTrue);
    });

    test('a non-owner request surfaces the stable not_owner code', () async {
      final repo = repoReturning({
        'success': false,
        'message': 'Only the organizer may review applications.',
        'errors': {
          'owner': ['not_owner'],
        },
      }, status: 403);

      await expectLater(
        repo.roleApplications('role-uuid'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.error.stableCode,
            'stableCode',
            'not_owner',
          ),
        ),
      );
    });
  });

  group('lifecycle', () {
    test('confirmEvent POSTs /confirm and parses the event back', () async {
      late http.Request captured;
      final repo = repoReturning({
        'success': true,
        'data': {
          'id': 'event-uuid',
          'status': 'confirmed',
          'creator_profile_id': 'profile-uuid',
          'title': 'Kolabing Launch Weekend',
          'eligible_account_type': 'either',
          'roles': [],
          'role_counts': {'total': 0, 'open': 0, 'filled': 0},
        },
      }, onRequest: (r) => captured = r);

      final event = await repo.confirmEvent('event-uuid');

      expect(captured.method, 'POST');
      expect(
        captured.url.path,
        endsWith('/multi-kolab-events/event-uuid/confirm'),
      );
      expect(event.status, MultiKolabEventStatus.confirmed);
    });

    test('completeEvent POSTs /complete', () async {
      late http.Request captured;
      final repo = repoReturning({
        'success': true,
        'data': {
          'id': 'event-uuid',
          'status': 'completed',
          'creator_profile_id': 'profile-uuid',
          'title': 'Kolabing Launch Weekend',
          'eligible_account_type': 'either',
          'roles': [],
          'role_counts': {'total': 0, 'open': 0, 'filled': 0},
        },
      }, onRequest: (r) => captured = r);

      final event = await repo.completeEvent('event-uuid');

      expect(
        captured.url.path,
        endsWith('/multi-kolab-events/event-uuid/complete'),
      );
      expect(event.status, MultiKolabEventStatus.completed);
    });

    test(
      'an invalid transition surfaces the stable invalid_transition code',
      () async {
        final repo = repoReturning({
          'success': false,
          'message': 'Cannot confirm an event with status "draft".',
          'errors': {
            'status': ['invalid_transition'],
          },
        }, status: 422);

        await expectLater(
          repo.confirmEvent('event-uuid'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.error.stableCode,
              'stableCode',
              'invalid_transition',
            ),
          ),
        );
      },
    );

    test(
      'publish without entitlement surfaces event_creator_required',
      () async {
        final repo = repoReturning({
          'success': false,
          'message': 'Event Creator access is required to publish.',
          'errors': {
            'entitlement': ['event_creator_required'],
          },
        }, status: 403);

        await expectLater(
          repo.publish('event-uuid'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.error.stableCode,
              'stableCode',
              'event_creator_required',
            ),
          ),
        );
      },
    );
  });

  group('mock repository — deterministic organizer fixtures', () {
    test('myEvents returns only the viewer-owned events, any status', () async {
      final repo = MockMultiKolabRepository();
      final events = await repo.myEvents();

      expect(events, isNotEmpty);
      expect(
        events.map((e) => e.id),
        contains('event-2'),
        reason: 'event-2 is the fixture owned by the mock viewer',
      );
      expect(
        events.map((e) => e.id),
        isNot(contains('event-1')),
        reason: 'event-1 belongs to another organizer',
      );
    });

    test('a created draft is listed, editable and re-readable', () async {
      final repo = MockMultiKolabRepository();

      final draft = await repo.createDraft(
        const CreateMultiKolabEventInput(title: 'Rooftop Session'),
      );
      expect(draft.status, MultiKolabEventStatus.draft);

      await repo.updateDraft(
        draft.id,
        const UpdateMultiKolabEventInput(
          title: 'Rooftop Session',
          city: 'Barcelona',
        ),
      );

      final reread = await repo.getEvent(draft.id);
      expect(reread.city, 'Barcelona');
      expect((await repo.myEvents()).map((e) => e.id), contains(draft.id));
    });

    test('closing a role is reflected in the event detail', () async {
      final repo = MockMultiKolabRepository();

      await repo.setRoleStatus('role-5', MultiKolabRoleStatus.closed);

      final event = await repo.getEvent('event-2');
      expect(
        event.roles.firstWhere((r) => r.id == 'role-5').status,
        MultiKolabRoleStatus.closed,
      );
    });

    test('accepting an application returns child Kolab identifiers', () async {
      final repo = MockMultiKolabRepository();
      final application = await repo.apply(
        'role-1',
        const CreateMultiKolabApplicationInput(pitch: 'We can bring 30 people'),
      );

      final result = await repo.accept(application.id);

      expect(result.applicationStatus, 'accepted');
      expect(result.kolabId, isNotEmpty);
      expect(result.collaborationId, isNotNull);
    });

    test(
      'roleApplications returns the applications filed for that role',
      () async {
        final repo = MockMultiKolabRepository();
        await repo.apply(
          'role-1',
          const CreateMultiKolabApplicationInput(pitch: 'First'),
        );
        await repo.apply(
          'role-3',
          const CreateMultiKolabApplicationInput(pitch: 'Other role'),
        );

        final applications = await repo.roleApplications('role-1');

        expect(applications, hasLength(1));
        expect(applications.single.pitch, 'First');
      },
    );
  });

  group('repository selection', () {
    test('production builds can never select the mock repository', () {
      // Mirrors the Task 9 regression: the mock is gated on
      // `_mockRequested && !kReleaseMode`, so a release binary always gets
      // the API implementation regardless of the dart-define.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(multiKolabRepositoryProvider);

      if (kReleaseMode) {
        expect(repository, isA<ApiMultiKolabRepository>());
      } else {
        expect(repository, isA<MultiKolabRepository>());
      }
    });

    test(
      'multiKolabRoleApplicationsProvider reads through the repository seam',
      () async {
        final container = ProviderContainer(
          overrides: [
            multiKolabRepositoryProvider.overrideWithValue(
              MockMultiKolabRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        final applications = await container.read(
          multiKolabRoleApplicationsProvider('role-1').future,
        );

        expect(applications, isA<List<MultiKolabRoleApplication>>());
      },
    );
  });

  group('MultiKolabEvent.copyWith', () {
    test('replaces only the named fields', () {
      const event = MultiKolabEvent(
        id: 'e',
        status: MultiKolabEventStatus.draft,
        creatorProfileId: 'me',
        title: 'Original',
        eligibleAccountType: MultiKolabEligibleAccountType.either,
        roles: [],
        roleCounts: (total: 0, open: 0, filled: 0),
        city: 'Barcelona',
      );

      final updated = event.copyWith(
        title: 'Renamed',
        status: MultiKolabEventStatus.recruiting,
      );

      expect(updated.title, 'Renamed');
      expect(updated.status, MultiKolabEventStatus.recruiting);
      expect(updated.city, 'Barcelona');
      expect(updated.id, 'e');
    });
  });
}

/// ApiMultiKolabRepository only ever calls getToken()/refreshSession(); the
/// MockClient below never returns 401, so refreshSession is unreachable.
class _StubAuthService extends AuthService {
  @override
  Future<String?> getToken() async => 'test-token';

  @override
  Future<String> refreshSession() async => 'test-token';
}
