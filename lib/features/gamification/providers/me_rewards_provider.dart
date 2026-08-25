import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/me_rewards_overview.dart';
import '../services/me_rewards_service.dart';

/// DI for [MeRewardsService].
final meRewardsServiceProvider = Provider<MeRewardsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return MeRewardsService(authService: authService);
});

/// Personal rewards overview (`GET /me/rewards-overview`). A Notifier so a
/// redeem can `reload()` to refresh balances. A null value = endpoint not
/// deployed yet (self-gated → coming-soon/empty state).
class MeRewardsOverviewNotifier
    extends Notifier<AsyncValue<MeRewardsOverview?>> {
  @override
  AsyncValue<MeRewardsOverview?> build() {
    Future.microtask(reload);
    return const AsyncLoading();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(meRewardsServiceProvider).getOverview(),
    );
  }
}

final meRewardsOverviewProvider =
    NotifierProvider<MeRewardsOverviewNotifier, AsyncValue<MeRewardsOverview?>>(
      MeRewardsOverviewNotifier.new,
    );
