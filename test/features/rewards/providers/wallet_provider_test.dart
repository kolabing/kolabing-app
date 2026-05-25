import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';
import 'package:kolabing_app/features/rewards/models/reward_badge.dart';
import 'package:kolabing_app/features/rewards/models/wallet_model.dart';
import 'package:kolabing_app/features/rewards/providers/wallet_provider.dart';
import 'package:kolabing_app/features/rewards/services/rewards_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'wallet provider ignores stale load completion from a previous session',
    () async {
      final authNotifier = _MutableAuthNotifier(_communityUser('community-1'));
      final service = _ScriptedRewardsService(
        walletResponses: <Object>[
          Completer<XpModel>(),
          const XpModel(totalXp: 250),
        ],
        badgeResponses: <Object>[
          Completer<List<RewardBadge>>(),
          const <RewardBadge>[
            RewardBadge(
              slug: RewardBadgeSlug.communityEarner,
              isUnlocked: true,
            ),
          ],
        ],
        referralResponses: <Object>[
          Completer<({String code, String link, int totalConversions})>(),
          (
            code: 'new-code',
            link: 'https://kolabing.com/ref/new',
            totalConversions: 2,
          ),
        ],
      );

      final firstWalletLoad =
          service.walletResponses.first as Completer<XpModel>;
      final firstBadgeLoad =
          service.badgeResponses.first as Completer<List<RewardBadge>>;
      final firstReferralLoad =
          service.referralResponses.first
              as Completer<({String code, String link, int totalConversions})>;

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => authNotifier),
          rewardsServiceProvider.overrideWith((ref) => service),
        ],
      );
      addTearDown(container.dispose);

      container.read(authProvider);
      container.read(walletProvider);
      await Future<void>.delayed(Duration.zero);

      authNotifier.signOut();
      await Future<void>.delayed(Duration.zero);

      authNotifier.signIn(_communityUser('community-2'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      firstWalletLoad.complete(const XpModel(totalXp: 10));
      firstBadgeLoad.complete(const <RewardBadge>[
        RewardBadge(slug: RewardBadgeSlug.firstKolab, isUnlocked: true),
      ]);
      firstReferralLoad.complete((
        code: 'old-code',
        link: 'https://kolabing.com/ref/old',
        totalConversions: 1,
      ));
      await Future<void>.delayed(Duration.zero);

      final state = container.read(walletProvider);
      expect(state.wallet?.totalXp, 250);
      expect(state.referralCode, 'new-code');
      expect(state.referralConversions, 2);
      expect(state.badges.map((badge) => badge.slug), <RewardBadgeSlug>[
        RewardBadgeSlug.communityEarner,
      ]);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    },
  );
}

UserModel _communityUser(String id) => UserModel(
  id: id,
  email: '$id@example.com',
  userType: UserType.community,
  communityProfile: CommunityProfile(id: 'profile-$id', name: 'User $id'),
);

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

class _ScriptedRewardsService extends RewardsService {
  _ScriptedRewardsService({
    required this.walletResponses,
    required this.badgeResponses,
    required this.referralResponses,
  });

  final List<Object> walletResponses;
  final List<Object> badgeResponses;
  final List<Object> referralResponses;

  int _walletIndex = 0;
  int _badgeIndex = 0;
  int _referralIndex = 0;

  @override
  Future<XpModel> getWallet() => _resolve<XpModel>(
    walletResponses[_nextIndex(_walletIndex++, walletResponses.length)],
  );

  @override
  Future<List<RewardBadge>> getBadges() => _resolve<List<RewardBadge>>(
    badgeResponses[_nextIndex(_badgeIndex++, badgeResponses.length)],
  );

  @override
  Future<({String code, String link, int totalConversions})> getReferralCode() {
    return _resolve<({String code, String link, int totalConversions})>(
      referralResponses[_nextIndex(_referralIndex++, referralResponses.length)],
    );
  }

  int _nextIndex(int requestedIndex, int length) {
    if (length == 0) {
      throw StateError('Scripted rewards service received no responses.');
    }
    return requestedIndex < length ? requestedIndex : length - 1;
  }

  Future<T> _resolve<T>(Object value) async {
    if (value is Completer<T>) {
      return value.future;
    }
    if (value is T) {
      return value as T;
    }
    throw StateError('Unexpected scripted rewards value: $value');
  }
}
