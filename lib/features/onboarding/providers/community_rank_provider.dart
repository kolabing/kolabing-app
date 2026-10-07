import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/community_rank.dart';
import '../services/community_rank_service.dart';

final communityRankServiceProvider = Provider<CommunityRankService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CommunityRankService(authService: authService);
});

/// The signed-in organiser's city-league standing (`GET /me/community-rank`).
/// `autoDispose` — this is a one-shot read for the onboarding live-preview
/// screen, not a value worth keeping warm in the background.
final myCommunityRankProvider = FutureProvider.autoDispose<CommunityRank>((
  ref,
) async {
  final service = ref.watch(communityRankServiceProvider);
  return service.getMyCommunityRank();
});
