import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/friend.dart';
import '../providers/friend_providers.dart';
import '../widgets/friend_action_button.dart';
import '../widgets/friend_tile.dart';
import '../widgets/suggested_friends_section.dart';
import 'friend_requests_screen.dart';

/// Friends home: a two-tab surface — the accepted friends list (with a search
/// field and the co-attendance suggestions) and the requests inbox.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          title: Text(l10n.friendsTitle),
          bottom: TabBar(
            labelColor: KolabingColors.onSurface,
            unselectedLabelColor: KolabingColors.onSurfaceVariant,
            indicatorColor: KolabingColors.primaryDark,
            tabs: [
              Tab(text: l10n.friendsTabFriends),
              Tab(text: l10n.friendsTabRequests),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_FriendsListTab(), FriendRequestsScreen()],
        ),
      ),
    );
  }
}

class _FriendsListTab extends ConsumerStatefulWidget {
  const _FriendsListTab();

  @override
  ConsumerState<_FriendsListTab> createState() => _FriendsListTabState();
}

class _FriendsListTabState extends ConsumerState<_FriendsListTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Friend> _filter(List<Friend> friends) {
    if (_query.isEmpty) {
      return friends;
    }
    final q = _query.toLowerCase();
    return friends.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(friendsProvider).friends;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            KolabingSpacing.md,
            KolabingSpacing.md,
            0,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: l10n.friendsSearchHint,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: KolabingColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: KolabingColors.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: KolabingColors.outlineVariant,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorBody(
              message: e.toString(),
              onRetry: () => ref.read(friendsProvider.notifier).reloadFriends(),
            ),
            data: (friends) {
              final filtered = _filter(friends);
              return RefreshIndicator(
                onRefresh: () => ref.read(friendsProvider.notifier).loadAll(),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: KolabingSpacing.xl),
                  children: [
                    if (_query.isEmpty) const SuggestedFriendsSection(),
                    if (friends.isEmpty)
                      _EmptyFriends(
                        title: l10n.friendsEmptyTitle,
                        body: l10n.friendsEmptyBody,
                      )
                    else if (filtered.isEmpty)
                      _EmptyFriends(title: l10n.friendsSearchEmpty)
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          KolabingSpacing.md,
                          KolabingSpacing.md,
                          KolabingSpacing.md,
                          0,
                        ),
                        child: Column(
                          children: filtered
                              .map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: KolabingSpacing.xs,
                                  ),
                                  child: FriendTile(
                                    friend: f,
                                    onTap: () =>
                                        context.push('/profile/${f.profileId}'),
                                    trailing: FriendActionButton(
                                      profileId: f.profileId,
                                      profileName: f.name,
                                      compact: true,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.xl,
      vertical: KolabingSpacing.xxl,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          LucideIcons.users,
          size: 32,
          color: KolabingColors.onSurfaceVariant,
        ),
        const SizedBox(height: KolabingSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
