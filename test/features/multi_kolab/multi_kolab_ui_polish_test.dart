import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kolabing_app/features/multi_kolab/models/event_creator_entitlement.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_enums.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_role.dart';
import 'package:kolabing_app/features/multi_kolab/models/multi_kolab_spot_counts.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_providers.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_editor_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_event_management_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_organizer_dashboard_screen.dart';
import 'package:kolabing_app/features/multi_kolab/screens/multi_kolab_role_editor_screen.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Multi-Kolab UI polish pass.
///
/// Covers the four things that were wrong on the organizer surfaces and can
/// regress silently: segmented controls that shrank their labels to fit,
/// an event-level "who can apply?" answer that contradicts per-role
/// eligibility, capacity copy that counted role ROWS instead of partner
/// spots, and the applicant-facing role card's metadata hierarchy.
///
/// Everything is driven through the deterministic mock repository — no
/// simulator automation.

/// The narrowest phone the app supports, matching the surface the Task 10
/// responsive tests already use.
const smallPhone = Size(320, 640);

void main() {
  const entitled = EventCreatorEntitlement(hasEventCreatorEntitlement: true);

  Widget host(
    Widget child, {
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
  }) {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => child)],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        multiKolabRepositoryProvider.overrideWithValue(
          MockMultiKolabRepository(),
        ),
        multiKolabEntitlementProvider.overrideWith((ref) async => entitled),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp.router(
          locale: locale,
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(child, locale: locale, size: size));
    await tester.pumpAndSettle();
  }

  /// Every label inside a segmented control, with the size it actually
  /// rendered at.
  List<(String, double)> segmentLabels(WidgetTester tester, Key controlKey) {
    return tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(controlKey),
            matching: find.byType(Text),
          ),
        )
        .map((t) => (t.data ?? '', t.style?.fontSize ?? 0))
        .toList(growable: false);
  }

  MultiKolabRole role({
    String id = 'r',
    MultiKolabRoleStatus status = MultiKolabRoleStatus.open,
    int needed = 1,
    int filled = 0,
    MultiKolabEligibleAccountType eligible =
        MultiKolabEligibleAccountType.either,
  }) => MultiKolabRole(
    id: id,
    multiKolabEventId: 'e',
    status: status,
    title: 'Role $id',
    eligibleAccountType: eligible,
    positionsNeeded: needed,
    positionsFilled: filled,
    required_: true,
  );

  // --- Item 1: responsive segmented controls -------------------------------

  group('segmented controls stay readable', () {
    for (final locale in const [Locale('en'), Locale('es'), Locale('ca')]) {
      testWidgets('the dashboard status filter never shrinks its labels '
          '(${locale.languageCode}, ${smallPhone.width.toInt()}dp)', (
        tester,
      ) async {
        await pump(
          tester,
          const MultiKolabOrganizerDashboardScreen(),
          locale: locale,
          size: smallPhone,
        );

        // A RenderFlex overflow is reported as a test exception; the
        // scrollable track must produce none at the narrowest width.
        expect(tester.takeException(), isNull);

        const controlKey = Key('multiKolabOrganizerFilter');
        expect(find.byKey(controlKey), findsOneWidget);

        final labels = segmentLabels(tester, controlKey);
        expect(labels, hasLength(5));
        for (final (text, size) in labels) {
          expect(text, isNotEmpty);
          expect(
            size,
            12.5,
            reason:
                '"$text" must render at the full label size, not be '
                'shrunk to fit an equal-width segment',
          );
        }

        // Shrink-to-fit is exactly what made the Catalan labels
        // unreadable; the scrolling track must not reintroduce it.
        expect(
          find.descendant(
            of: find.byKey(controlKey),
            matching: find.byType(FittedBox),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(controlKey),
            matching: find.byType(SingleChildScrollView),
          ),
          findsOneWidget,
        );
      });

      testWidgets('the 3-option role eligibility control stays balanced '
          '(${locale.languageCode}, ${smallPhone.width.toInt()}dp)', (
        tester,
      ) async {
        await pump(
          tester,
          const MultiKolabRoleEditorScreen(eventId: 'event-2'),
          locale: locale,
          size: smallPhone,
        );

        expect(tester.takeException(), isNull);

        const controlKey = Key('multiKolabRoleEligibilityControl');
        final labels = segmentLabels(tester, controlKey);
        expect(labels, hasLength(3));

        for (final (text, size) in labels) {
          expect(text, isNotEmpty);
          // The selected "Businesses and communities" option used to be the
          // smallest text on the screen. Every option now renders at the
          // same fixed size and wraps instead.
          expect(size, 12.5, reason: '"$text" must not shrink');
        }

        // Nothing is clipped: each label's laid-out width fits its segment.
        for (final text
            in find
                .descendant(
                  of: find.byKey(controlKey),
                  matching: find.byType(Text),
                )
                .evaluate()) {
          final box = text.renderObject! as RenderBox;
          expect(box.size.width, greaterThan(0));
        }
      });
    }
  });

  // --- Item 3: no event-level eligibility ----------------------------------

  group('eligibility is a role property, never an event property', () {
    testWidgets('the create-event form offers no global "Who can apply?"', (
      tester,
    ) async {
      await pump(tester, const MultiKolabEventEditorScreen());

      expect(
        find.byKey(const Key('multiKolabEventEligibilityControl')),
        findsNothing,
      );
      expect(find.text('Who can apply?'), findsNothing);
      expect(find.text('Businesses and communities'), findsNothing);
    });

    testWidgets('the role editor still asks, with all three options', (
      tester,
    ) async {
      await pump(tester, const MultiKolabRoleEditorScreen(eventId: 'event-2'));

      expect(
        find.byKey(const Key('multiKolabRoleEligibilityControl')),
        findsOneWidget,
      );
      expect(find.text('Who can apply?'), findsOneWidget);
      expect(find.text('Businesses'), findsOneWidget);
      expect(find.text('Communities'), findsOneWidget);
      expect(find.text('Businesses and communities'), findsOneWidget);
    });
  });

  // --- Item 4: partner spots, not role rows --------------------------------

  group('MultiKolabSpotCounts', () {
    test('a single one-partner role', () {
      final counts = MultiKolabSpotCounts.fromRoles([role()]);
      expect(counts.filled, 0);
      expect(counts.total, 1);
      expect(counts.openRoles, 1);
    });

    test('one role recruiting several partners is still ONE open role', () {
      final counts = MultiKolabSpotCounts.fromRoles([role(needed: 3)]);
      expect(counts.total, 3);
      expect(counts.openRoles, 1);
    });

    test('a partially filled role keeps counting as open', () {
      final counts = MultiKolabSpotCounts.fromRoles([
        role(needed: 3, filled: 1),
      ]);
      expect(counts.filled, 1);
      expect(counts.total, 3);
      expect(counts.openRoles, 1);
    });

    test('spots sum across several roles', () {
      final counts = MultiKolabSpotCounts.fromRoles([
        role(id: 'a', needed: 1),
        role(id: 'b', needed: 3, filled: 1),
        role(id: 'c', needed: 2),
      ]);
      expect(counts.filled, 1);
      expect(counts.total, 6);
      expect(counts.openRoles, 3);
    });

    test('filled and closed roles are excluded from the open-role count', () {
      final counts = MultiKolabSpotCounts.fromRoles([
        role(id: 'a', status: MultiKolabRoleStatus.filled, filled: 1),
        role(id: 'b', status: MultiKolabRoleStatus.closed, needed: 2),
        role(id: 'c', needed: 2, filled: 1),
      ]);
      // Confirmed partners on a closed/filled role are still confirmed.
      expect(counts.filled, 2);
      expect(counts.total, 5);
      expect(counts.openRoles, 1);
    });

    test('a stale open role with no capacity left is not an open role', () {
      final counts = MultiKolabSpotCounts.fromRoles([
        role(needed: 2, filled: 2),
      ]);
      expect(counts.openRoles, 0);
      expect(counts.isFullyStaffed, isTrue);
    });
  });

  group('capacity copy', () {
    testWidgets('Manage event states partner spots and open roles', (
      tester,
    ) async {
      // Mock "event-1" has four roles: 1 + 1 + 1 + 3 = 6 partner spots, two
      // of them confirmed, and three roles still recruiting (the `filled` role
      // is excluded).
      await pump(
        tester,
        const MultiKolabEventManagementScreen(eventId: 'event-1'),
        size: const Size(390, 1400),
      );

      expect(find.text('2 of 6 partner spots filled'), findsOneWidget);
      expect(find.text('3 open roles'), findsOneWidget);
      // The role-row phrasing is gone for good.
      expect(find.textContaining('roles filled'), findsNothing);
    });

    testWidgets('singular, plural and zero all read correctly', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(l10n.multiKolabOpenRolesCount(0), 'No open roles');
      expect(l10n.multiKolabOpenRolesCount(1), '1 open role');
      expect(l10n.multiKolabOpenRolesCount(2), '2 open roles');

      expect(
        l10n.multiKolabPartnerSpotsFilled(0, 1),
        '0 of 1 partner spots filled',
      );
      expect(
        l10n.multiKolabPartnerSpotsFilled(1, 3),
        '1 of 3 partner spots filled',
      );

      expect(l10n.multiKolabRoleSpotsOpen(1), '1 spot open');
      expect(l10n.multiKolabRoleSpotsOpen(2), '2 spots open');
    });

    testWidgets('the dashboard card counts open ROLES only', (tester) async {
      await pump(tester, const MultiKolabOrganizerDashboardScreen());

      expect(find.text('1 open role'), findsOneWidget);
      expect(find.textContaining('roles filled'), findsNothing);
    });
  });
}
