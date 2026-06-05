import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/friends/models/friend.dart';
import 'package:kolabing_app/features/friends/providers/friend_providers.dart';
import 'package:kolabing_app/features/friends/services/friend_service.dart';

/// In-memory [FriendService] stand-in. Holds mutable lists so mutations are
/// reflected on the next reload, exactly like the real backend.
class _FakeFriendService implements FriendService {
  _FakeFriendService({
    List<Friend>? friends,
    List<Friend>? incoming,
    List<Friend>? sent,
    List<Friend>? suggested,
  }) : friends = friends ?? <Friend>[],
       incoming = incoming ?? <Friend>[],
       sent = sent ?? <Friend>[],
       suggested = suggested ?? <Friend>[];

  final List<Friend> friends;
  final List<Friend> incoming;
  final List<Friend> sent;
  final List<Friend> suggested;

  final List<String> calls = <String>[];

  @override
  Future<List<Friend>> getFriends() async => List<Friend>.from(friends);

  @override
  Future<FriendRequests> getRequests() async => FriendRequests(
    incoming: List<Friend>.from(incoming),
    sent: List<Friend>.from(sent),
  );

  @override
  Future<List<Friend>> getSuggested() async => List<Friend>.from(suggested);

  @override
  Future<Friend> sendRequest(String profileId) async {
    calls.add('send:$profileId');
    suggested.removeWhere((f) => f.profileId == profileId);
    final friend = Friend(
      friendshipId: 'fr-$profileId',
      profileId: profileId,
      name: 'P $profileId',
      status: FriendshipStatus.pending,
      direction: FriendshipDirection.outgoing,
    );
    sent.add(friend);
    return friend;
  }

  @override
  Future<Friend> acceptRequest(String friendshipId) async {
    calls.add('accept:$friendshipId');
    final idx = incoming.indexWhere((f) => f.friendshipId == friendshipId);
    final accepted = incoming
        .removeAt(idx)
        .copyWith(
          status: FriendshipStatus.accepted,
          direction: FriendshipDirection.mutual,
        );
    friends.add(accepted);
    return accepted;
  }

  @override
  Future<void> declineRequest(String friendshipId) async {
    calls.add('decline:$friendshipId');
    incoming.removeWhere((f) => f.friendshipId == friendshipId);
  }

  @override
  Future<void> unfriend(String profileId) async {
    calls.add('unfriend:$profileId');
    friends.removeWhere((f) => f.profileId == profileId);
    sent.removeWhere((f) => f.profileId == profileId);
  }

  @override
  Future<void> block(String profileId) async {
    calls.add('block:$profileId');
    friends.removeWhere((f) => f.profileId == profileId);
    incoming.removeWhere((f) => f.profileId == profileId);
  }

  @override
  Future<void> unblock(String profileId) async {
    calls.add('unblock:$profileId');
  }
}

Friend _incoming(String id, String profileId) => Friend(
  friendshipId: id,
  profileId: profileId,
  name: 'P $profileId',
  status: FriendshipStatus.pending,
  direction: FriendshipDirection.incoming,
);

Friend _suggested(String profileId, int shared) => Friend(
  profileId: profileId,
  name: 'P $profileId',
  sharedEventCount: shared,
);

/// Build a container wired to [fake] and wait for the notifier's initial load.
Future<ProviderContainer> _ready(_FakeFriendService fake) async {
  final container = ProviderContainer(
    overrides: [friendServiceProvider.overrideWithValue(fake)],
  );
  addTearDown(container.dispose);
  container.read(friendsProvider);
  // Let the microtask-scheduled loadAll() settle.
  await Future<void>.delayed(Duration.zero);
  await container.read(friendsProvider.notifier).loadAll();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initial build loads friends, requests, and suggestions', () async {
    final fake = _FakeFriendService(
      friends: <Friend>[
        const Friend(friendshipId: 'f1', profileId: 'p1', name: 'One'),
      ],
      incoming: <Friend>[_incoming('in1', 'p2')],
      suggested: <Friend>[_suggested('p3', 5)],
    );
    final container = await _ready(fake);

    final state = container.read(friendsProvider);
    expect(state.friends.value, hasLength(1));
    expect(state.requests.value!.incoming, hasLength(1));
    expect(state.suggested.value, hasLength(1));
  });

  test('sendRequest moves a suggestion into the sent bucket', () async {
    final fake = _FakeFriendService(suggested: <Friend>[_suggested('p3', 5)]);
    final container = await _ready(fake);

    await container.read(friendsProvider.notifier).sendRequest('p3');

    expect(fake.calls, contains('send:p3'));
    final state = container.read(friendsProvider);
    expect(state.suggested.value, isEmpty);
    expect(state.requests.value!.sent.single.profileId, 'p3');
    // The relationship for that profile is now "request sent".
    expect(
      container.read(friendRelationshipProvider('p3')),
      FriendRelationship.requestSent,
    );
  });

  test(
    'acceptRequest moves an incoming request into the friends list',
    () async {
      final fake = _FakeFriendService(
        incoming: <Friend>[_incoming('in1', 'p2')],
      );
      final container = await _ready(fake);

      expect(
        container.read(friendRelationshipProvider('p2')),
        FriendRelationship.requestReceived,
      );

      await container.read(friendsProvider.notifier).acceptRequest('in1');

      expect(fake.calls, contains('accept:in1'));
      final state = container.read(friendsProvider);
      expect(state.requests.value!.incoming, isEmpty);
      expect(state.friends.value!.single.profileId, 'p2');
      expect(
        container.read(friendRelationshipProvider('p2')),
        FriendRelationship.friends,
      );
    },
  );

  test('declineRequest removes the incoming request', () async {
    final fake = _FakeFriendService(incoming: <Friend>[_incoming('in1', 'p2')]);
    final container = await _ready(fake);

    await container.read(friendsProvider.notifier).declineRequest('in1');

    expect(fake.calls, contains('decline:in1'));
    final state = container.read(friendsProvider);
    expect(state.requests.value!.incoming, isEmpty);
    expect(
      container.read(friendRelationshipProvider('p2')),
      FriendRelationship.none,
    );
  });

  test(
    'incomingFriendshipIdProvider resolves the row id for a profile',
    () async {
      final fake = _FakeFriendService(
        incoming: <Friend>[_incoming('in1', 'p2')],
      );
      final container = await _ready(fake);

      expect(container.read(incomingFriendshipIdProvider('p2')), 'in1');
      expect(container.read(incomingFriendshipIdProvider('nope')), isNull);
    },
  );
}
