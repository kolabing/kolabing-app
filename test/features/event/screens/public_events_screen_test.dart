import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/l10n/app_localizations.dart';
import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/event/models/event.dart';
import 'package:kolabing_app/features/event/models/public_event.dart';
import 'package:kolabing_app/features/event/providers/event_provider.dart';
import 'package:kolabing_app/features/event/screens/public_events_screen.dart';
import 'package:kolabing_app/features/event/services/event_service.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester, EventService service) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _AuthedNotifier(_attendee())),
          eventServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PublicEventsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders public-event cards with PUBLIC badge and RSVP', (
    tester,
  ) async {
    final service = _ScriptedEventService(
      page: _pageOf(<String>['event-1', 'event-2']),
    );

    await pumpScreen(tester, service);

    expect(find.text('Rooftop event-1'), findsOneWidget);
    expect(find.text('Rooftop event-2'), findsOneWidget);
    // PUBLIC badge appears once per card.
    expect(find.text('PUBLIC'), findsNWidgets(2));
    expect(find.text('RSVP'), findsNWidgets(2));
  });

  testWidgets('tapping RSVP on a public event flips the card to Going', (
    tester,
  ) async {
    final service = _ScriptedEventService(page: _pageOf(<String>['event-1']));

    await pumpScreen(tester, service);

    await tester.tap(find.text('RSVP'));
    await tester.pumpAndSettle();

    expect(service.signupCalls, <String>['event-1']);
    expect(find.text('Going'), findsOneWidget);
    expect(find.text('RSVP'), findsNothing);
  });

  testWidgets(
    'members-only 403 opens the "Join community to RSVP" gate instead of an error',
    (tester) async {
      final service = _ScriptedEventService(
        page: _pageOf(<String>['event-1']),
        signupError: const MembersOnlyRsvpException(
          communityId: 'community-7',
          communityName: 'Iron Club',
        ),
      );

      await pumpScreen(tester, service);

      await tester.tap(find.text('RSVP'));
      await tester.pumpAndSettle();

      // The gate sheet shows the join CTA + the community name in the body.
      expect(find.text('Members-only event'), findsOneWidget);
      expect(find.text('Join community to RSVP'), findsOneWidget);
      expect(find.textContaining('Iron Club'), findsOneWidget);
      // Card did NOT flip to going.
      expect(find.text('Going'), findsNothing);
    },
  );
}

UserModel _attendee() => const UserModel(
  id: 'attendee-1',
  email: 'a@example.com',
  userType: UserType.attendee,
);

PublicEvent _event(String id) => PublicEvent(
  id: id,
  name: 'Rooftop $id',
  date: DateTime.parse('2026-07-01T18:00:00Z'),
  visibility: EventVisibility.public,
  goingCount: 4,
  community: PublicEventCommunity(id: 'c-$id', name: 'Community $id'),
);

PublicEventsPage _pageOf(List<String> ids) => PublicEventsPage(
  events: ids.map(_event).toList(),
  currentPage: 1,
  totalPages: 1,
  totalCount: ids.length,
  perPage: 15,
);

Event _signedUpEvent(String id) => Event(
  id: id,
  name: 'Rooftop $id',
  partner: const EventPartner(name: 'Org', type: PartnerType.community),
  date: DateTime.parse('2026-07-01'),
  attendeeCount: 5,
  photos: const <EventPhoto>[],
  createdAt: DateTime.parse('2026-06-01T10:00:00Z'),
  visibility: EventVisibility.public,
  mySignupStatus: 'going',
);

class _AuthedNotifier extends AuthNotifier {
  _AuthedNotifier(this._user);

  final UserModel _user;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: _user,
    token: 'token-${_user.id}',
  );
}

class _ScriptedEventService extends EventService {
  _ScriptedEventService({required this.page, this.signupError})
    : super(authService: AuthService());

  final PublicEventsPage page;
  final Object? signupError;
  final List<String> signupCalls = <String>[];

  @override
  Future<PublicEventsPage> getDiscovery({
    int page = 1,
    int perPage = 15,
  }) async => this.page;

  @override
  Future<Event> signup(String eventId) async {
    signupCalls.add(eventId);
    if (signupError != null) throw signupError!;
    return _signedUpEvent(eventId);
  }
}
