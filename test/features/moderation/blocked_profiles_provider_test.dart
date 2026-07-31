import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/moderation/providers/blocked_profiles_provider.dart';
import 'package:kolabing_app/features/moderation/services/moderation_service.dart';

/// A fake [ModerationService] that records calls and can be made to fail,
/// so we can assert the provider's optimistic-update + revert behaviour.
class _FakeModerationService implements ModerationService {
  _FakeModerationService({this.seed = const [], this.failNext = false});

  final List<String> seed;
  bool failNext;
  final List<String> blockedCalls = <String>[];
  final List<String> unblockedCalls = <String>[];

  @override
  Future<List<String>> blockedProfileIds() async => seed;

  @override
  Future<void> block(String profileId) async {
    if (failNext) {
      failNext = false;
      throw const ModerationException('boom');
    }
    blockedCalls.add(profileId);
  }

  @override
  Future<void> unblock(String profileId) async {
    if (failNext) {
      failNext = false;
      throw const ModerationException('boom');
    }
    unblockedCalls.add(profileId);
  }

  @override
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    String? reportedProfileId,
    String? note,
  }) async {}
}

ProviderContainer _containerWith(_FakeModerationService service) {
  final container = ProviderContainer(
    overrides: [moderationServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads blocked ids from the service on first watch', () async {
    final service = _FakeModerationService(seed: const ['p1', 'p2']);
    final container = _containerWith(service);

    // First read is the synchronous empty set…
    expect(container.read(blockedProfilesProvider), isEmpty);
    // …then the microtask load merges the backend ids in.
    await Future<void>.delayed(Duration.zero);
    expect(container.read(blockedProfilesProvider), {'p1', 'p2'});
  });

  test('block adds optimistically and persists via the service', () async {
    final service = _FakeModerationService();
    final container = _containerWith(service);
    final notifier = container.read(blockedProfilesProvider.notifier);

    final future = notifier.block('abc');
    // Optimistic: the id is present before the backend call resolves.
    expect(container.read(blockedProfilesProvider), contains('abc'));
    await future;
    expect(service.blockedCalls, ['abc']);
    expect(container.read(blockedProfilesProvider), contains('abc'));
  });

  test('block reverts the optimistic add when the service fails', () async {
    final service = _FakeModerationService(failNext: true);
    final container = _containerWith(service);
    final notifier = container.read(blockedProfilesProvider.notifier);

    await expectLater(
      notifier.block('abc'),
      throwsA(isA<ModerationException>()),
    );
    // Reverted: the id is gone again.
    expect(container.read(blockedProfilesProvider), isNot(contains('abc')));
  });

  test('unblock removes optimistically and persists', () async {
    final service = _FakeModerationService(seed: const ['abc']);
    final container = _containerWith(service);
    // Touch the provider to trigger build() (which schedules the load), then
    // let the initial load populate the set.
    container.read(blockedProfilesProvider);
    await Future<void>.delayed(Duration.zero);
    final notifier = container.read(blockedProfilesProvider.notifier);
    expect(container.read(blockedProfilesProvider), contains('abc'));

    final future = notifier.unblock('abc');
    expect(container.read(blockedProfilesProvider), isNot(contains('abc')));
    await future;
    expect(service.unblockedCalls, ['abc']);
  });

  test('unblock reverts when the service fails', () async {
    final service = _FakeModerationService(seed: const ['abc'], failNext: true);
    final container = _containerWith(service);
    container.read(blockedProfilesProvider);
    await Future<void>.delayed(Duration.zero);
    final notifier = container.read(blockedProfilesProvider.notifier);

    await expectLater(
      notifier.unblock('abc'),
      throwsA(isA<ModerationException>()),
    );
    // Reverted: the id is back.
    expect(container.read(blockedProfilesProvider), contains('abc'));
  });
}
