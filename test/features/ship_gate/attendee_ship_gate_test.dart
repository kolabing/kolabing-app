import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/config/constants/feature_flags.dart';
import 'package:kolabing_app/config/routes/routes.dart';
import 'package:kolabing_app/features/auth/screens/user_type_selection_screen.dart';
import 'package:kolabing_app/features/auth/widgets/selection_card.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/widgets/coming_soon_view.dart';

/// Ship gate: the attendee / member layer is hidden behind
/// [FeatureFlags.attendeeEnabled] (default false). These tests assert the gated
/// behaviour holds while the flag is off. The flag is a compile-time const, so
/// flipping it back to `true` is a one-line change that restores normal
/// routing — see the comment at the end of this file.
void main() {
  group('FeatureFlags.attendeeEnabled', () {
    test('ships OFF — only Business + Community are enabled', () {
      expect(FeatureFlags.attendeeEnabled, isFalse);
    });
  });

  group('ComingSoonView', () {
    testWidgets('renders the localized coming-soon headline + message', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ComingSoonView(),
        ),
      );
      await tester.pump();

      expect(find.text('Coming soon'), findsOneWidget);
      expect(
        find.text('This experience is on the way. Check back soon.'),
        findsOneWidget,
      );
    });
  });

  group('isAttendeeGatedLocation', () {
    test('matches every gated attendee / member surface', () {
      const gated = <String>[
        '/auth/register/attendee',
        '/onboarding/attendee/step1',
        '/onboarding/attendee/step4',
        '/attendee',
        '/attendee/profile',
        '/communities/discover',
        '/community/abc123/profile',
        '/rewards',
        '/attendee/events/42/qr',
        '/attendee/events/42/checkins',
        '/attendee/events/42/challenges',
        '/attendee/events/42/challenges/create',
      ];
      for (final path in gated) {
        expect(isAttendeeGatedLocation(path), isTrue, reason: path);
      }
    });

    test('does NOT match business / community PARTNER routes', () {
      const allowed = <String>[
        '/business',
        '/community',
        '/community/offers',
        '/community/opportunities/new',
        '/community/wallet',
        '/community/wallet/withdraw',
        '/community/referrals',
        '/profile/abc123',
        '/event/42',
        '/chats',
      ];
      for (final path in allowed) {
        expect(isAttendeeGatedLocation(path), isFalse, reason: path);
      }
    });
  });

  group('Route guard (deep-link safety)', () {
    testWidgets('/attendee resolves to ComingSoonView while the flag is off', (
      tester,
    ) async {
      kolabingRouter.go(KolabingRoutes.attendeeDashboard);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: kolabingRouter,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ComingSoonView), findsOneWidget);
    });

    testWidgets('/rewards resolves to ComingSoonView while the flag is off', (
      tester,
    ) async {
      kolabingRouter.go(KolabingRoutes.rewards);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: kolabingRouter,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ComingSoonView), findsOneWidget);
    });
  });

  group('User type selection', () {
    testWidgets(
      'attendee card is disabled with a COMING SOON badge; business + '
      'community cards stay enabled',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: UserTypeSelectionScreen(),
            ),
          ),
        );
        await tester.pump();

        final cards = tester
            .widgetList<SelectionCard>(find.byType(SelectionCard))
            .toList();
        expect(cards.length, 3);

        final business = cards.firstWhere(
          (c) => c.userType == SelectionUserType.business,
        );
        final community = cards.firstWhere(
          (c) => c.userType == SelectionUserType.community,
        );
        final attendee = cards.firstWhere(
          (c) => c.userType == SelectionUserType.attendee,
        );

        expect(business.isEnabled, isTrue);
        expect(community.isEnabled, isTrue);
        expect(attendee.isEnabled, isFalse);
        expect(attendee.badgeLabel, 'COMING SOON');

        // Badge is rendered.
        expect(find.text('COMING SOON'), findsOneWidget);
      },
    );
  });

  // SMOKE NOTE — flipping FeatureFlags.attendeeEnabled back to `true`:
  //   * resolveAuthDestination() falls through to the attendee onboarding /
  //     dashboard branch (no early login return),
  //   * the GoRouter global redirect skips the whole ship-gate block, so
  //     /attendee, /rewards, /communities/discover, etc. build their real
  //     screens again,
  //   * the attendee SelectionCard renders enabled with no badge,
  //   * the Community nav tab restores CommunityDetailScreen.
  // No other change is required; the flag is the single switch. The asserts in
  // this file (which expect the OFF behaviour) are the canary if it changes.
}
