import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/community/screens/my_opportunities_screen.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';
import 'package:kolabing_app/features/opportunity/providers/opportunity_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  testWidgets('share fallback shows snackbar when sharing is unavailable', (
    tester,
  ) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-42',
      title: 'Sunset Rooftop Collab',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    var copiedText = '';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOpportunitiesProvider.overrideWith(
            () => _FakeMyOpportunitiesNotifier(
              OpportunityListState(opportunities: [opportunity], total: 1),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MyOpportunitiesScreen(
            share: (_, {sharePositionOrigin}) async => ShareResult.unavailable,
            copyText: (text) async {
              copiedText = text;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Share is an icon button (GlassIconButton) with a "Share" tooltip.
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();

    expect(copiedText, contains('/c/opp-42'));
    expect(
      find.text('Sharing is unavailable. Link copied instead.'),
      findsOneWidget,
    );
  });

  testWidgets('share fallback shows snackbar when share sheet cannot open', (
    tester,
  ) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-42',
      title: 'Sunset Rooftop Collab',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    var copiedText = '';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOpportunitiesProvider.overrideWith(
            () => _FakeMyOpportunitiesNotifier(
              OpportunityListState(opportunities: [opportunity], total: 1),
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MyOpportunitiesScreen(
            share: (_, {sharePositionOrigin}) async {
              throw Exception('share failed');
            },
            copyText: (text) async {
              copiedText = text;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Share is an icon button (GlassIconButton) with a "Share" tooltip.
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();

    expect(copiedText, isEmpty);
    expect(find.text('Could not open the share sheet.'), findsOneWidget);
  });

  testWidgets('subscription gating opens paywall and refreshes after upgrade', (
    tester,
  ) async {
    final notifier = _FakeMyOpportunitiesNotifier(const OpportunityListState());
    final profileNotifier = _FakeProfileNotifier(
      const ProfileState(isLoading: false, isInitialized: true),
    );
    var paywallShown = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOpportunitiesProvider.overrideWith(() => notifier),
          profileProvider.overrideWith(() => profileNotifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MyOpportunitiesScreen(
            showSubscriptionPaywall: (_) async {
              paywallShown++;
              return true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    notifier.triggerSubscriptionRequirement();
    await tester.pumpAndSettle();

    expect(paywallShown, 1);
    expect(notifier.clearSubscriptionCalls, 1);
    expect(notifier.refreshCalls, 1);
    expect(profileNotifier.refreshSubscriptionCalls, 1);
  });

  testWidgets('create new opportunity is free for communities (no paywall)', (
    tester,
  ) async {
    var paywallShown = 0;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MyOpportunitiesScreen(
            showSubscriptionPaywall: (_) async {
              paywallShown++;
              return false;
            },
          ),
        ),
        GoRoute(
          path: '/kolab/new',
          builder: (context, state) =>
              const Scaffold(body: Text('kolab-new-flow')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOpportunitiesProvider.overrideWith(
            () => _FakeMyOpportunitiesNotifier(const OpportunityListState()),
          ),
          profileProvider.overrideWith(
            () => _FakeProfileNotifier(
              const ProfileState(
                profile: UserModel(
                  id: 'community-1',
                  email: 'community@example.com',
                  userType: UserType.community,
                  hasActiveSubscription: false,
                  communityProfile: CommunityProfile(
                    id: 'profile-1',
                    name: 'Move Club',
                  ),
                ),
                isLoading: false,
                isInitialized: true,
              ),
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Communities are NEVER paywalled (ROLES §1): tapping create goes straight
    // to the unified kolab flow with no paywall.
    expect(paywallShown, 0);
    expect(find.text('kolab-new-flow'), findsOneWidget);
  });

  testWidgets('published opportunity View navigates to opportunity detail', (
    tester,
  ) async {
    final opportunity = Opportunity.empty().copyWith(
      id: 'opp-42',
      title: 'Sunset Rooftop Collab',
      preferredCity: 'Barcelona',
      status: OpportunityStatus.published,
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MyOpportunitiesScreen(),
        ),
        GoRoute(
          path: '/opportunity/:id',
          builder: (context, state) =>
              Scaffold(body: Text('detail:${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myOpportunitiesProvider.overrideWith(
            () => _FakeMyOpportunitiesNotifier(
              OpportunityListState(opportunities: [opportunity], total: 1),
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The View pill renders its label uppercased (GlassButton).
    expect(find.text('VIEW'), findsOneWidget);

    await tester.tap(find.text('VIEW'));
    await tester.pumpAndSettle();

    expect(find.text('detail:opp-42'), findsOneWidget);
  });
}

class _FakeMyOpportunitiesNotifier extends MyOpportunitiesNotifier {
  _FakeMyOpportunitiesNotifier(this._initialState);

  final OpportunityListState _initialState;
  int refreshCalls = 0;
  int clearSubscriptionCalls = 0;

  @override
  OpportunityListState build() => _initialState;

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }

  @override
  Future<void> loadMore() async {}

  @override
  void clearSubscriptionRequirement() {
    clearSubscriptionCalls++;
    state = state.copyWith(requiresSubscription: false);
  }

  void triggerSubscriptionRequirement() {
    state = state.copyWith(requiresSubscription: true);
  }
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;
  int refreshSubscriptionCalls = 0;

  @override
  ProfileState build() => _initialState;

  @override
  Future<void> refreshSubscription() async {
    refreshSubscriptionCalls++;
  }
}
