import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/models/auth_response.dart';
import 'package:kolabing_app/features/multi_kolab/models/child_kolab_result.dart';
import 'package:kolabing_app/features/multi_kolab/models/event_creator_entitlement.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_creator_summary.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_dashboard.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_event_summary.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role_application.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/api_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_application_form.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_explore_card.dart';
import 'package:kolabing_app/features/multi_kolab/widgets/multi_kolab_role_progress.dart';

void main() {
  group('JSON model parsing — exact frozen-contract fixtures', () {
    test('MultiKolabEventSummary.fromJson parses the §6 summary fixture', () {
      final json = {
        'id': '8f5b6e2a-...-uuid',
        'status': 'recruiting',
        'title': 'Kolabing Launch Weekend',
        'value_summary': 'Free entry, venue + brand partners wanted',
        'city': 'Barcelona',
        'category': 'Music',
        'event_date': '2026-09-12',
        'date_mode': 'exact',
        'role_counts': {'total': 4, 'open': 2, 'filled': 2},
        'eligible_account_type': 'either',
        'creator_profile': {
          'id': 'profile-uuid',
          'display_name': 'Kolabing',
          'avatar_url': 'https://example.test/avatar.jpg',
        },
      };

      final summary = MultiKolabEventSummary.fromJson(json);

      expect(summary.id, '8f5b6e2a-...-uuid');
      expect(summary.status, MultiKolabEventStatus.recruiting);
      expect(summary.title, 'Kolabing Launch Weekend');
      expect(summary.city, 'Barcelona');
      expect(summary.roleCounts.total, 4);
      expect(summary.roleCounts.open, 2);
      expect(summary.roleCounts.filled, 2);
      expect(summary.eligibleAccountType, MultiKolabEligibleAccountType.either);
      expect(summary.creatorProfile?.displayName, 'Kolabing');
      expect(summary.eventDate, DateTime(2026, 9, 12));
    });

    test(
      'MultiKolabEvent.fromJson parses the §3 detail fixture with roles',
      () {
        final json = {
          'id': 'event-uuid',
          'status': 'draft',
          'creator_profile_id': 'profile-uuid',
          'creator_profile_type': 'business',
          'title': 'Kolabing Launch Weekend',
          'description': 'A multi-partner launch event...',
          'value_summary': 'Free entry, venue + brand partners wanted',
          'venue_needed': true,
          'date_mode': 'exact',
          'event_date': '2026-09-12',
          'date_range_start': null,
          'date_range_end': null,
          'city': 'Barcelona',
          'category': 'Music',
          'rsvp_url': 'https://lu.ma/kolabing-launch',
          'eligible_account_type': 'either',
          'roles': [],
          'role_counts': {'total': 0, 'open': 0, 'filled': 0},
          'created_at': '2026-08-12T09:00:00Z',
          'updated_at': '2026-08-12T09:00:00Z',
          'published_at': null,
        };

        final event = MultiKolabEvent.fromJson(json);

        expect(event.id, 'event-uuid');
        expect(event.status, MultiKolabEventStatus.draft);
        expect(event.venueNeeded, true);
        expect(event.dateMode, MultiKolabDateMode.exact);
        expect(event.rsvpUrl, 'https://lu.ma/kolabing-launch');
        expect(event.roles, isEmpty);
        expect(event.publishedAt, isNull);
        expect(event.viewerApplication, isNull);
      },
    );

    test('MultiKolabRole.fromJson parses the §4 role fixture', () {
      final json = {
        'id': 'role-uuid',
        'multi_kolab_event_id': '8f5b6e2a-...-uuid',
        'status': 'open',
        'title': 'Run Club Partner',
        'eligible_account_type': 'community',
        'positions_needed': 1,
        'positions_filled': 0,
        'required': true,
        'need': 'A running route + 20-30 participants',
        'receive': 'Free venue, post-run brunch, social tagging',
        'compensation_type': 'value_exchange',
        'requirements': 'Must be able to commit to the full route',
        'details': 'Meet at 8am, 5k loop',
        'created_at': '2026-08-12T09:05:00Z',
        'updated_at': '2026-08-12T09:05:00Z',
      };

      final role = MultiKolabRole.fromJson(json);

      expect(role.id, 'role-uuid');
      expect(role.status, MultiKolabRoleStatus.open);
      expect(role.eligibleAccountType, MultiKolabEligibleAccountType.community);
      expect(role.positionsNeeded, 1);
      expect(role.positionsFilled, 0);
      expect(role.required_, true);
      expect(role.compensationType, MultiKolabCompensationType.valueExchange);
      expect(role.isOpen, true);
      expect(role.positionsRemaining, 1);
    });

    test(
      'MultiKolabRoleApplication.fromJson parses the §7 application fixture',
      () {
        final json = {
          'id': 'application-uuid',
          'multi_kolab_role_id': 'role-uuid',
          'applicant_profile_id': 'profile-uuid',
          'applicant_profile_type': 'community',
          'status': 'pending',
          'pitch':
              'We run a 150-member Saturday run club and can bring 30+ people.',
          'availability': 'Any Saturday in September',
          'kolab_id': null,
          'created_at': '2026-08-12T09:10:00Z',
        };

        final application = MultiKolabRoleApplication.fromJson(json);

        expect(application.id, 'application-uuid');
        expect(application.status, MultiKolabRoleApplicationStatus.pending);
        expect(application.kolabId, isNull);
        expect(application.isPending, true);
        expect(application.isAccepted, false);
      },
    );

    test('ChildKolabResult.fromJson parses the §8 accept fixture', () {
      final json = {
        'application': {
          'id': 'application-uuid',
          'status': 'accepted',
          'kolab_id': 'kolab-uuid',
        },
        'kolab': {
          'id': 'kolab-uuid',
          'status': 'published',
          'collaboration_id': 'collaboration-uuid',
        },
        'collaboration': {
          'id': 'collaboration-uuid',
          'status': 'scheduled',
          'application_id': 'canonical-application-uuid',
        },
      };

      final result = ChildKolabResult.fromJson(json);

      expect(result.applicationId, 'application-uuid');
      expect(result.applicationStatus, 'accepted');
      expect(result.kolabId, 'kolab-uuid');
      expect(result.kolabStatus, 'published');
      expect(result.collaborationId, 'collaboration-uuid');
      expect(result.collaborationStatus, 'scheduled');
    });

    test('MultiKolabDashboard.fromJson parses the §9 dashboard fixture', () {
      final json = {
        'event_id': '8f5b6e2a-...-uuid',
        'status': 'recruiting',
        'role_counts': {'total': 4, 'open': 2, 'filled': 2},
        'roles': [
          {
            'role_id': 'role-uuid',
            'title': 'Run Club Partner',
            'positions_needed': 1,
            'positions_filled': 1,
            'status': 'filled',
            'application_counts': {
              'pending': 2,
              'shortlisted': 1,
              'accepted': 1,
              'declined': 0,
              'withdrawn': 0,
            },
          },
        ],
      };

      final dashboard = MultiKolabDashboard.fromJson(json);

      expect(dashboard.eventId, '8f5b6e2a-...-uuid');
      expect(dashboard.roleCounts.total, 4);
      expect(dashboard.roles, hasLength(1));
      expect(dashboard.roles.first.applicationCounts.pending, 2);
      expect(dashboard.roles.first.applicationCounts.accepted, 1);
      expect(dashboard.roles.first.status, MultiKolabRoleStatus.filled);
    });

    test(
      'EventCreatorEntitlement.fromJson parses the §2 entitlement fixture',
      () {
        final json = {
          'has_event_creator_entitlement': true,
          'capability': 'event_creator',
          'granted_at': '2026-08-01T10:00:00Z',
          'expires_at': '2027-08-01T10:00:00Z',
          'source': 'maintainer',
        };

        final entitlement = EventCreatorEntitlement.fromJson(json);

        expect(entitlement.hasEventCreatorEntitlement, true);
        expect(entitlement.capability, 'event_creator');
        expect(entitlement.source, 'maintainer');
      },
    );

    test(
      'EventCreatorEntitlement.fromJson parses the absent-entitlement fixture',
      () {
        final json = {
          'has_event_creator_entitlement': false,
          'capability': 'event_creator',
          'granted_at': null,
          'expires_at': null,
          'source': null,
        };

        final entitlement = EventCreatorEntitlement.fromJson(json);

        expect(entitlement.hasEventCreatorEntitlement, false);
        expect(entitlement.grantedAt, isNull);
        expect(entitlement.source, isNull);
      },
    );
  });

  group('MultiKolabApiErrorCode.stableCode', () {
    test('extracts the first stable code from a §10 error envelope', () {
      const error = ApiError(
        message: 'Your account type is not eligible to apply to this role.',
        errors: {
          'role': ['role_ineligible'],
        },
        statusCode: 422,
      );

      expect(error.stableCode, 'role_ineligible');
    });

    test('is null when the errors map is absent', () {
      const error = ApiError(message: 'Unknown error', statusCode: 500);

      expect(error.stableCode, isNull);
    });
  });

  group('Repository selection', () {
    test('production configuration selects ApiMultiKolabRepository', () {
      // The mock is gated by bool.fromEnvironment('MULTI_KOLAB_USE_MOCK')
      // (false unless explicitly passed via --dart-define) AND !kReleaseMode
      // — a real production build never passes that define, so this proves
      // the default/production path always resolves to the API repository.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(multiKolabRepositoryProvider);

      expect(repository, isA<ApiMultiKolabRepository>());
    });
  });

  group('MultiKolabRoleProgress widget', () {
    testWidgets('renders the open/filled counts label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MultiKolabRoleProgress(
              counts: MultiKolabRoleCounts(total: 4, open: 2, filled: 2),
            ),
          ),
        ),
      );

      expect(find.text('2 open · 2 filled'), findsOneWidget);
    });
  });

  group('MultiKolabExploreCard widget', () {
    testWidgets('renders title, city, and role progress', (tester) async {
      const event = MultiKolabEventSummary(
        id: 'event-1',
        status: MultiKolabEventStatus.recruiting,
        title: 'Kolabing Launch Weekend',
        roleCounts: MultiKolabRoleCounts(total: 4, open: 2, filled: 2),
        eligibleAccountType: MultiKolabEligibleAccountType.either,
        city: 'Barcelona',
        creatorProfile: MultiKolabCreatorSummary(
          id: 'organizer-1',
          displayName: 'Kolabing',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MultiKolabExploreCard(event: event)),
        ),
      );

      expect(find.text('Kolabing Launch Weekend'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      expect(find.text('2 open · 2 filled'), findsOneWidget);
      expect(find.text('Kolabing'), findsOneWidget);
    });

    testWidgets('tapping the card invokes onTap', (tester) async {
      const event = MultiKolabEventSummary(
        id: 'event-1',
        status: MultiKolabEventStatus.recruiting,
        title: 'Kolabing Launch Weekend',
        roleCounts: MultiKolabRoleCounts(),
        eligibleAccountType: MultiKolabEligibleAccountType.either,
      );
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MultiKolabExploreCard(
              event: event,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MultiKolabExploreCard));
      expect(tapped, true);
    });
  });

  group('MultiKolabApplicationForm widget', () {
    testWidgets('requires a pitch before submitting', (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MultiKolabApplicationForm(
              onSubmit: (input) async {
                submitted = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();

      expect(find.text('A pitch is required to apply.'), findsOneWidget);
      expect(submitted, false);
    });

    testWidgets('submits the pitch and availability when valid', (
      tester,
    ) async {
      String? capturedPitch;
      String? capturedAvailability;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MultiKolabApplicationForm(
              onSubmit: (input) async {
                capturedPitch = input.pitch;
                capturedAvailability = input.availability;
              },
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'We would love to partner on this.',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Any Saturday in September',
      );
      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();

      expect(capturedPitch, 'We would love to partner on this.');
      expect(capturedAvailability, 'Any Saturday in September');
    });
  });
}
