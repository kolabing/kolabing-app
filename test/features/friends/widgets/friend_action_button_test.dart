import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/friends/models/friend.dart';
import 'package:kolabing_app/features/friends/providers/friend_providers.dart';
import 'package:kolabing_app/features/friends/services/friend_service.dart';
import 'package:kolabing_app/features/friends/widgets/friend_action_button.dart';
import 'package:kolabing_app/l10n/app_localizations.dart';

/// Minimal scripted [FriendService] for driving the button's relationship.
class _StubFriendService implements FriendService {
  _StubFriendService({
    List<Friend> friends = const <Friend>[],
    List<Friend> incoming = const <Friend>[],
    List<Friend> sent = const <Friend>[],
  }) : friends = List<Friend>.from(friends),
       incoming = List<Friend>.from(incoming),
       sent = List<Friend>.from(sent);

  final List<Friend> friends;
  final List<Friend> incoming;
  final List<Friend> sent;

  String? sentRequestTo;

  @override
  Future<List<Friend>> getFriends() async => friends;

  @override
  Future<FriendRequests> getRequests() async =>
      FriendRequests(incoming: incoming, sent: sent);

  @override
  Future<List<Friend>> getSuggested() async => const <Friend>[];

  @override
  Future<Friend> sendRequest(String profileId) async {
    sentRequestTo = profileId;
    final friend = Friend(
      friendshipId: 'fr-$profileId',
      profileId: profileId,
      name: 'P',
      status: FriendshipStatus.pending,
      direction: FriendshipDirection.outgoing,
    );
    sent.add(friend);
    return friend;
  }

  @override
  Future<Friend> acceptRequest(String friendshipId) async =>
      throw UnimplementedError();

  @override
  Future<void> declineRequest(String friendshipId) async {}

  @override
  Future<void> unfriend(String profileId) async {}

  @override
  Future<void> block(String profileId) async {}

  @override
  Future<void> unblock(String profileId) async {}
}

Future<void> _pumpButton(
  WidgetTester tester,
  _StubFriendService stub, {
  required String profileId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [friendServiceProvider.overrideWithValue(stub)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: FriendActionButton(
              profileId: profileId,
              profileName: 'Alex',
            ),
          ),
        ),
      ),
    ),
  );

  // Deterministically drive the notifier's initial load to completion before
  // asserting, then rebuild — the microtask-scheduled loadAll() otherwise may
  // not have resolved its async service calls by the time pumpAndSettle returns.
  final container = ProviderScope.containerOf(
    tester.element(find.byType(FriendActionButton)),
    listen: false,
  );
  // Drive the notifier's load to completion (each loadAll applies one atomic
  // state write, so this is safe even alongside the build()-scheduled load).
  await container.read(friendsProvider.notifier).loadAll();
  await tester.pump();
}

Friend _friend(String profileId) =>
    Friend(friendshipId: 'f', profileId: profileId, name: 'Alex');

Friend _incoming(String profileId) => Friend(
  friendshipId: 'in',
  profileId: profileId,
  name: 'Alex',
  status: FriendshipStatus.pending,
  direction: FriendshipDirection.incoming,
);

Friend _sent(String profileId) => Friend(
  friendshipId: 'out',
  profileId: profileId,
  name: 'Alex',
  status: FriendshipStatus.pending,
  direction: FriendshipDirection.outgoing,
);

void main() {
  testWidgets('shows Add when there is no relationship', (tester) async {
    await _pumpButton(tester, _StubFriendService(), profileId: 'p1');
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('tapping Add sends a request', (tester) async {
    final stub = _StubFriendService();
    await _pumpButton(tester, stub, profileId: 'p1');

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(stub.sentRequestTo, 'p1');
    // After sending, the button reflects the pending state.
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('shows Pending for a sent request', (tester) async {
    await _pumpButton(
      tester,
      _StubFriendService(sent: <Friend>[_sent('p1')]),
      profileId: 'p1',
    );
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('shows Respond for an incoming request', (tester) async {
    await _pumpButton(
      tester,
      _StubFriendService(incoming: <Friend>[_incoming('p1')]),
      profileId: 'p1',
    );
    expect(find.text('Respond'), findsOneWidget);
  });

  testWidgets('Respond menu exposes Accept and Decline', (tester) async {
    await _pumpButton(
      tester,
      _StubFriendService(incoming: <Friend>[_incoming('p1')]),
      profileId: 'p1',
    );

    await tester.tap(find.text('Respond'));
    await tester.pumpAndSettle();

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('shows Friends with an unfriend/block menu', (tester) async {
    await _pumpButton(
      tester,
      _StubFriendService(friends: <Friend>[_friend('p1')]),
      profileId: 'p1',
    );
    expect(find.text('Friends'), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();

    expect(find.text('Unfriend'), findsOneWidget);
    expect(find.text('Block'), findsOneWidget);
  });
}
