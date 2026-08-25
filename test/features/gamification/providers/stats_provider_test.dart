import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/gamification/models/gamification_stats.dart';
import 'package:kolabing_app/features/gamification/providers/stats_provider.dart';
import 'package:kolabing_app/features/gamification/services/stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'myStatsProvider recomputes when the authenticated attendee changes',
    () async {
      final authNotifier = _MutableAuthNotifier(_attendeeUser('attendee-1'));
      final service = _ScriptedStatsService(
        responses: const <GamificationStats>[
          GamificationStats(
            totalPoints: 10,
            totalChallengesCompleted: 1,
            totalEventsAttended: 1,
            badgesCount: 1,
            rewardsCount: 1,
          ),
          GamificationStats(
            totalPoints: 99,
            totalChallengesCompleted: 5,
            totalEventsAttended: 4,
            badgesCount: 3,
            rewardsCount: 2,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => authNotifier),
          statsServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(myStatsProvider, (_, _) {});
      addTearDown(sub.close);

      final first = await container.read(myStatsProvider.future);
      expect(first.totalPoints, 10);

      authNotifier.signOut();
      await Future<void>.delayed(Duration.zero);

      authNotifier.signIn(_attendeeUser('attendee-2'));
      await Future<void>.delayed(Duration.zero);

      final second = await container.read(myStatsProvider.future);
      expect(second.totalPoints, 99);
      expect(service.callCount, 2);
    },
  );
}

UserModel _attendeeUser(String id) =>
    UserModel(id: id, email: '$id@example.com', userType: UserType.attendee);

class _MutableAuthNotifier extends AuthNotifier {
  _MutableAuthNotifier(this._initialUser);

  final UserModel _initialUser;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: _initialUser,
    token: 'token-${_initialUser.id}',
  );

  void signOut() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void signIn(UserModel user) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: user,
      token: 'token-${user.id}',
    );
  }
}

class _ScriptedStatsService extends StatsService {
  _ScriptedStatsService({required this.responses})
    : super(authService: AuthService());

  final List<GamificationStats> responses;
  int callCount = 0;

  @override
  Future<GamificationStats> getMyStats() async {
    final response =
        responses[callCount < responses.length
            ? callCount
            : responses.length - 1];
    callCount += 1;
    return response;
  }
}
