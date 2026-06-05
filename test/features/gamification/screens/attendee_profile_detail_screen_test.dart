import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/models/attendee_profile_detail.dart';
import 'package:kolabing_app/features/gamification/providers/attendee_profile_provider.dart';
import 'package:kolabing_app/features/gamification/screens/attendee_profile_detail_screen.dart';
import 'package:kolabing_app/features/gamification/services/attendee_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(
    WidgetTester tester, {
    required AttendeeProfileDetail profile,
    required String currentUserId,
    String? profileId,
  }) async {
    // Tall surface so the lazy ListView builds every section (header, badges,
    // communities, events) without needing to scroll.
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(currentUserId)),
          attendeeProfileServiceProvider.overrideWith(
            (ref) => _FakeService(profile),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AttendeeProfileDetailScreen(profileId: profileId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('self view renders name, points, badges and communities', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      currentUserId: 'me',
      profileId: 'me',
      profile: _detail(
        name: 'Ada Lovelace',
        points: 150,
        badgeSlugs: const <String>['first-event'],
        communityName: 'Runners',
        tierName: 'Gold',
        friendsCount: null,
      ),
    );

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('150 points'), findsOneWidget);
    expect(find.text('Runners'), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
    // Self view shows the "See all" action for the events list.
    expect(find.text('See all'), findsOneWidget);
    // No friends count -> no Add friend affordance.
    expect(find.text('Add friend'), findsNothing);
  });

  testWidgets(
    'public view with friends_count shows the Add friend placeholder and hides See all',
    (tester) async {
      await pumpScreen(
        tester,
        currentUserId: 'me',
        profileId: 'someone-else',
        profile: _detail(
          name: 'Grace Hopper',
          points: 20,
          badgeSlugs: const <String>[],
          communityName: 'Coders',
          tierName: null,
          friendsCount: 4,
        ),
      );

      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('4 friends'), findsOneWidget);
      expect(find.text('Add friend'), findsOneWidget);
      // Full events list is self-only, so no See all on a public profile.
      expect(find.text('See all'), findsNothing);
    },
  );
}

AttendeeProfileDetail _detail({
  required String name,
  required int points,
  required List<String> badgeSlugs,
  required String communityName,
  required String? tierName,
  required int? friendsCount,
}) {
  return AttendeeProfileDetail(
    identity: AttendeeIdentity(id: 'p', name: name),
    gamification: AttendeeGamification(
      points: points,
      badgeCount: badgeSlugs.length,
      badges: badgeSlugs.map((slug) => AttendeeBadge(slug: slug)).toList(),
    ),
    communities: <AttendeeCommunity>[
      AttendeeCommunity(id: 'c', name: communityName, tierName: tierName),
    ],
    eventsAttended: AttendeeEventsAttended(
      total: 1,
      recent: <AttendedEvent>[
        AttendedEvent(eventId: 'e1', eventName: 'Sample Event'),
      ],
    ),
    friendsCount: friendsCount,
  );
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._userId);

  final String _userId;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: UserModel(
      id: _userId,
      email: '$_userId@example.com',
      userType: UserType.attendee,
    ),
    token: 'token-$_userId',
  );
}

class _FakeService extends AttendeeProfileService {
  _FakeService(this._profile) : super(authService: AuthService());

  final AttendeeProfileDetail _profile;

  @override
  Future<AttendeeProfileDetail> getAttendeeProfile(String profileId) async =>
      _profile;
}
