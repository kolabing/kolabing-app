import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/blurred_identity.dart';
import '../../../widgets/profile_link.dart';
import '../../business/providers/profile_provider.dart';
import '../../onboarding/models/community_type.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../subscription/widgets/subscription_paywall.dart';
import '../models/directory_community.dart';
import '../providers/community_directory_provider.dart';

/// Business Explore's "Communities" tab: every community on Kolabing, paged to
/// the end (ROLES §2.24). For a free business the server has already withheld
/// names and logos; a row then shows a blurred placeholder and opens the
/// paywall. A subscribed business opens the community's profile.
class CommunityDirectoryList extends ConsumerStatefulWidget {
  const CommunityDirectoryList({super.key});

  @override
  ConsumerState<CommunityDirectoryList> createState() =>
      _CommunityDirectoryListState();
}

class _CommunityDirectoryListState
    extends ConsumerState<CommunityDirectoryList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(communityDirectoryProvider.notifier).loadMore();
    }
  }

  Future<void> _subscribe() async {
    final allowed = await SubscriptionPaywall.checkAndShow(context, ref);
    if (!allowed || !mounted) return;
    await ref.read(profileProvider.notifier).refreshSubscription();
    if (!mounted) return;
    // The server unmasks on the next read.
    await ref.read(communityDirectoryProvider.notifier).refresh();
  }

  void _open(DirectoryCommunity community) {
    if (community.identityMasked) {
      _subscribe();
      return;
    }
    ProfileLink.open(context, ref, profileId: community.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(communityDirectoryProvider);
    final typeNames = <String, String>{
      for (final type
          in ref.watch(communityTypesProvider).value ?? const <CommunityType>[])
        type.slug: type.name,
    };

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _Message(
        icon: LucideIcons.alertCircle,
        title: l10n.exploreSomethingWrong,
        body: state.error,
        actionLabel: l10n.exploreTryAgain,
        onAction: () => ref.read(communityDirectoryProvider.notifier).refresh(),
      );
    }
    if (state.isEmpty) {
      return _Message(
        icon: LucideIcons.users,
        title: l10n.communityDirectoryEmpty,
      );
    }

    final anyMasked = state.items.any((c) => c.identityMasked);

    return RefreshIndicator(
      onRefresh: () => ref.read(communityDirectoryProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          KolabingSpacing.xs,
          KolabingSpacing.md,
          120,
        ),
        // Header, rows, then a loader while more pages remain.
        itemCount: state.items.length + 1 + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: KolabingSpacing.xs),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Header(
              total: state.total,
              showLockedBanner: anyMasked,
              onSubscribe: _subscribe,
            );
          }
          final rowIndex = index - 1;
          if (rowIndex >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(KolabingSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final community = state.items[rowIndex];
          return _CommunityRow(
            community: community,
            typeName: typeNames[community.communityType],
            onTap: () => _open(community),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.showLockedBanner,
    required this.onSubscribe,
  });

  final int total;
  final bool showLockedBanner;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.communityDirectoryCount(total),
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        if (showLockedBanner) ...[
          const SizedBox(height: KolabingSpacing.xs),
          Container(
            padding: const EdgeInsets.all(KolabingSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              borderRadius: BorderRadius.circular(KolabingRadius.md),
              border: Border.all(color: context.colors.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.lock, size: 18),
                    const SizedBox(width: KolabingSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.communityDirectoryLockedBanner,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KolabingSpacing.xs),
                // The theme's buttons are full-width; that is why this sits
                // under the text and not beside it.
                ElevatedButton(
                  onPressed: onSubscribe,
                  child: Text(l10n.communityDirectorySubscribe),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.xxs),
      ],
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({
    required this.community,
    required this.onTap,
    this.typeName,
  });

  final DirectoryCommunity community;
  final String? typeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final masked = community.identityMasked;
    final size = community.communitySize;
    final meta = <String>[
      ?typeName ?? community.communityType,
      if (size != null && size > 0) l10n.communityDirectoryPeople(size),
      ?community.cityName,
    ];

    return Semantics(
      button: true,
      label: masked ? l10n.communityDirectoryHiddenName : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KolabingRadius.md),
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(KolabingRadius.md),
            border: Border.all(color: context.colors.hairline),
          ),
          child: Row(
            children: [
              _Avatar(community: community),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: ExcludeSemantics(
                            excluding: masked,
                            child: BlurredIdentity(
                              enabled: masked,
                              sigma: 6,
                              child: Text(
                                // Masked: the server sent no name, so this is a
                                // placeholder shape under the blur, never a name.
                                masked
                                    ? '●●●●●●●●●●'
                                    : (community.displayName ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KolabingTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (community.isVerified) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: l10n.communityDirectoryVerified,
                            child: Icon(
                              LucideIcons.badgeCheck,
                              size: 16,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KolabingTextStyles.captionSecondary.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      l10n.communityDirectoryOpenKolabs(
                        community.publishedKolabsCount,
                      ),
                      style: KolabingTextStyles.captionSecondary.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                masked ? LucideIcons.lock : LucideIcons.chevronRight,
                size: 18,
                color: context.colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.community});

  final DirectoryCommunity community;

  @override
  Widget build(BuildContext context) {
    final url = community.avatarUrl;
    final name = community.displayName ?? '';
    final initial = community.identityMasked || name.isEmpty
        ? '?'
        : name[0].toUpperCase();

    final fallback = Center(
      child: Text(
        initial,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.surfaceContainerLow,
        border: Border.all(color: context.colors.hairline),
      ),
      child: ClipOval(
        child: url != null && !community.identityMasked
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: context.colors.onSurfaceVariant),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: KolabingSpacing.lg),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
