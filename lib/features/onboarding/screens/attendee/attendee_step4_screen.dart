import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/utils/auth_navigation.dart';
import '../../../community/models/community.dart';
import '../../../community/providers/community_providers.dart';
import '../../providers/attendee_onboarding_provider.dart';
import 'attendee_onboarding_scaffold.dart';

/// Attendee onboarding step 4 — "Join". The community discover feed, ranked so
/// interest-matched communities (per the `matched` server hint, with a
/// client-side `typeSlug ∈ interests` fallback) appear first. The user toggles
/// open communities to auto-join, then "Finish" submits `PUT /onboarding/attendee`.
class AttendeeStep4Screen extends ConsumerStatefulWidget {
  const AttendeeStep4Screen({super.key});

  @override
  ConsumerState<AttendeeStep4Screen> createState() =>
      _AttendeeStep4ScreenState();
}

class _AttendeeStep4ScreenState extends ConsumerState<AttendeeStep4Screen> {
  bool _submitting = false;

  /// Rank interest-matched communities first; preserve backend order within
  /// each bucket (featured-first already applied server-side).
  List<Community> _rank(List<Community> communities, Set<String> interests) {
    bool isMatch(Community c) =>
        c.matched ||
        (c.typeSlug != null && interests.contains(c.typeSlug!.toLowerCase()));
    final matched = communities.where(isMatch).toList();
    final rest = communities.where((c) => !isMatch(c)).toList();
    return [...matched, ...rest];
  }

  Future<void> _finish() async {
    setState(() => _submitting = true);
    final result = await ref.read(attendeeOnboardingProvider.notifier).submit();
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ref.read(attendeeOnboardingProvider.notifier).reset();
      await _goHome();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.displayError),
        backgroundColor: KolabingColors.error,
      ),
    );
  }

  Future<void> _skipToHome() async {
    // Submit name/handle (+ whatever is set) even on skip so the handle is
    // claimed; ignore community selection. Reuses the same submit path.
    setState(() => _submitting = true);
    final result = await ref.read(attendeeOnboardingProvider.notifier).submit();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) {
      ref.read(attendeeOnboardingProvider.notifier).reset();
    }
    await _goHome();
  }

  Future<void> _goHome() async {
    final route = await gateDestinationOnPermissions(
      KolabingRoutes.attendeeDashboard,
    );
    if (!mounted) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(attendeeOnboardingProvider);
    final async = ref.watch(discoverCommunitiesProvider(null));
    final interests = data.interests.map((s) => s.toLowerCase()).toSet();

    return AttendeeOnboardingScaffold(
      step: 4,
      title: l10n.attendeeOnboardingStep4Title,
      subtitle: l10n.attendeeOnboardingStep4Subtitle,
      primaryLabel: l10n.attendeeOnboardingFinish,
      busy: _submitting,
      onBack: _submitting ? null : () => context.pop(),
      onSkip: _submitting ? null : _skipToHome,
      onPrimary: _finish,
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: KolabingColors.primary),
          ),
        ),
        error: (_, _) => _EmptyJoin(
          title: l10n.discoverCommunitiesError,
          action: TextButton(
            onPressed: () => ref.invalidate(discoverCommunitiesProvider(null)),
            child: Text(l10n.commonRetry),
          ),
        ),
        data: (communities) {
          if (communities.isEmpty) {
            return _EmptyJoin(title: l10n.discoverCommunitiesEmptyTitle);
          }
          final ranked = _rank(communities, interests);
          return Column(
            children: [
              for (final c in ranked) ...[
                _JoinCard(
                  community: c,
                  selected: data.communityIds.contains(c.id),
                  highlighted:
                      c.matched ||
                      (c.typeSlug != null &&
                          interests.contains(c.typeSlug!.toLowerCase())),
                  onToggle: c.joinPolicy.allowsSelfJoin
                      ? () => ref
                            .read(attendeeOnboardingProvider.notifier)
                            .toggleCommunity(c.id)
                      : null,
                ),
                const SizedBox(height: KolabingSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.community,
    required this.selected,
    required this.highlighted,
    required this.onToggle,
  });

  final Community community;
  final bool selected;
  final bool highlighted;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inviteOnly = onToggle == null;
    return InkWell(
      borderRadius: BorderRadius.circular(KolabingRadius.lg),
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KolabingRadius.lg),
          border: Border.all(
            color: selected
                ? KolabingColors.primary
                : KolabingColors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
              backgroundImage: community.avatarUrl != null
                  ? NetworkImage(community.avatarUrl!)
                  : null,
              child: community.avatarUrl == null
                  ? const Icon(
                      LucideIcons.users,
                      color: KolabingColors.onSurface,
                    )
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (highlighted) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.check,
                          size: 13,
                          color: KolabingColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.attendeeOnboardingForYou,
                          style: KolabingTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: KolabingColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (inviteOnly)
              const Icon(
                LucideIcons.lock,
                size: 18,
                color: KolabingColors.textTertiary,
              )
            else
              Icon(
                selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                size: 22,
                color: selected
                    ? KolabingColors.primary
                    : KolabingColors.outlineVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyJoin extends StatelessWidget {
  const _EmptyJoin({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
    child: Center(
      child: Column(
        children: [
          const Icon(
            LucideIcons.compass,
            size: 40,
            color: KolabingColors.textTertiary,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            action!,
          ],
        ],
      ),
    ),
  );
}
