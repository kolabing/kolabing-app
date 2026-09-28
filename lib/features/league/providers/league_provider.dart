import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/league_models.dart';
import '../services/league_service.dart';

/// Provider for [LeagueService].
final leagueServiceProvider = Provider<LeagueService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LeagueService(authService: authService);
});

/// True only for a signed-in community (organiser) profile. The league and
/// levels are organiser-only in v1; every other role gets `null` below and
/// never calls the endpoints.
final _isOrganiserProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.isAuthenticated && auth.user?.userType == UserType.community;
});

/// The signed-in community's city league position this month.
///
/// `null` = hide the surface (not an organiser, or endpoint not live yet).
/// Refresh with `ref.invalidate(communityRankProvider)`.
final communityRankProvider = FutureProvider<CommunityRank?>((ref) async {
  if (!ref.watch(_isOrganiserProvider)) return null;
  return ref.watch(leagueServiceProvider).getCommunityRank();
});

/// The full current table for a city (keyed by [LeagueCity.key]).
final leagueTableProvider = FutureProvider.family<LeagueTable?, String>((
  ref,
  city,
) async {
  if (!ref.watch(_isOrganiserProvider)) return null;
  return ref.watch(leagueServiceProvider).getCurrentLeague(city);
});

/// The signed-in organiser's level, criteria and perks.
///
/// `null` = hide the surface (not an organiser, or endpoint not live yet).
final organiserLevelProvider = FutureProvider<OrganiserLevel?>((ref) async {
  if (!ref.watch(_isOrganiserProvider)) return null;
  return ref.watch(leagueServiceProvider).getOrganiserLevel();
});
