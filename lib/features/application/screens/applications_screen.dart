import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolab_card_shell.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../../widgets/verified_tick.dart';
import '../models/application.dart';
import '../providers/application_provider.dart';

/// Applications list screen showing both sent and received applications
/// via a tabbed interface.
class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key, this.embedded = false});

  /// When true, renders only the filter chips + list (no Scaffold, AppBar or
  /// page header) so it can be embedded as the "Requests" tab inside
  /// [MyKolabsHubScreen].
  final bool embedded;

  @override
  ConsumerState<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tabHeader = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: context.colors.primary,
          indicatorWeight: 3,
          labelColor: isDark
              ? context.colors.textOnDark
              : context.colors.onSurface,
          unselectedLabelColor: isDark
              ? context.colors.textOnDark.withValues(alpha: 0.5)
              : context.colors.textTertiary,
          labelStyle: KolabingTextStyles.button.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: KolabingTextStyles.button.copyWith(fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: AppLocalizations.of(context).applicationsTabSent),
            Tab(text: AppLocalizations.of(context).applicationsTabReceived),
          ],
        ),
        Divider(
          height: 1,
          color: isDark ? context.colors.darkBorder : context.colors.darkBorder,
        ),
      ],
    );

    final tabView = TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: Sent applications
        _SentApplicationsTab(),
        // Tab 2: Received applications
        _ReceivedApplicationsTab(),
      ],
    );

    // Embedded as the "Requests" tab of MyKolabsHubScreen: drop the Scaffold and
    // the 'APPLICATIONS' AppBar, but keep the SENT/RECEIVED sub-tabs as-is.
    if (widget.embedded) {
      return Column(children: [tabHeader, Expanded(child: tabView)]);
    }

    return Scaffold(
      backgroundColor:
          isDark ? context.colors.surface : context.colors.background,
      appBar: AppBar(
        backgroundColor:
            isDark ? context.colors.darkSurface : context.colors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context).applicationsTitle,
          style: KolabingTextStyles.pageTitleSmall.copyWith(
            color: isDark ? context.colors.textOnDark : context.colors.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: tabHeader,
        ),
      ),
      body: tabView,
    );
  }
}

// =============================================================================
// Sent Applications Tab
// =============================================================================

class _SentApplicationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myApplicationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () => ref.read(myApplicationsProvider.notifier).refresh(),
      color: context.colors.primary,
      child: _buildBody(context, state, isDark: isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ApplicationsState state, {
    required bool isDark,
  }) {
    if (state.isLoading) {
      return _buildLoadingState(context, isDark);
    }

    if (state.error != null) {
      return _buildErrorState(context, state.error!, isDark);
    }

    // Requests shows only items still awaiting a decision. Accepted
    // applications graduate to a collaboration and surface in the Active tab,
    // so they are excluded here (see MyKolabsHubScreen).
    final requests = state.applications
        .where((a) => a.status != ApplicationStatus.accepted)
        .toList();

    if (requests.isEmpty) {
      return _buildSentEmptyState(context, isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        final application = requests[index];
        return _ApplicationCard(
          application: application,
          isReceived: false,
          isDark: isDark,
          onTap: () => context.push('/application/${application.id}/chat'),
        );
      },
    );
  }

  Widget _buildSentEmptyState(BuildContext context, bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.send,
                  size: 36,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                AppLocalizations.of(context).applicationsSentEmptyTitle,
                style: KolabingTextStyles.titleMedium.copyWith(color: isDark
                      ? context.colors.textOnDark
                      : context.colors.onSurface),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).applicationsSentEmptyBody,
                style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// Received Applications Tab
// =============================================================================

class _ReceivedApplicationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receivedApplicationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(receivedApplicationsProvider.notifier).refresh(),
      color: context.colors.primary,
      child: _buildBody(context, state, isDark),
    );
  }

  Widget _buildBody(BuildContext context, ApplicationsState state, bool isDark) {
    if (state.isLoading) {
      return _buildLoadingState(context, isDark);
    }

    if (state.error != null) {
      return _buildErrorState(context, state.error!, isDark);
    }

    // Requests shows only items still awaiting a decision. Accepted
    // applications graduate to a collaboration and surface in the Active tab.
    final requests = state.applications
        .where((a) => a.status != ApplicationStatus.accepted)
        .toList();

    if (requests.isEmpty) {
      return _buildReceivedEmptyState(context, isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        final application = requests[index];
        return _ApplicationCard(
          application: application,
          isReceived: true,
          isDark: isDark,
          onTap: () {
            // Pending → review screen, accepted → chat
            if (application.status.isPending) {
              context.push('/application/${application.id}');
            } else {
              context.push('/application/${application.id}/chat');
            }
          },
        );
      },
    );
  }

  Widget _buildReceivedEmptyState(BuildContext context, bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.inbox,
                  size: 36,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                AppLocalizations.of(context).applicationsReceivedEmptyTitle,
                style: KolabingTextStyles.titleMedium.copyWith(color: isDark
                      ? context.colors.textOnDark
                      : context.colors.onSurface),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).applicationsReceivedEmptyBody,
                style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// Shared helpers
// =============================================================================

Widget _buildLoadingState(BuildContext context, bool isDark) => Shimmer.fromColors(
      baseColor:
          isDark ? context.colors.darkSurface : context.colors.surfaceVariant,
      highlightColor:
          isDark ? context.colors.darkBorder : context.colors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: KolabingSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? context.colors.darkSurface : context.colors.surface,
            borderRadius: KolabingRadius.borderRadiusMd,
          ),
        ),
      ),
    );

Widget _buildErrorState(BuildContext context, String error, bool isDark) => Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: context.colors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).applicationsErrorTitle,
              style: KolabingTextStyles.titleMedium.copyWith(color: isDark
                    ? context.colors.textOnDark
                    : context.colors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

// =============================================================================
// Application Card Widget
// =============================================================================

/// Application card widget supporting both sent and received display modes.
///
/// When [isReceived] is true, the card shows applicant info (From: name)
/// instead of recipient info (To: name).
class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
    this.isReceived = false,
    this.isDark = false,
  });

  final Application application;
  final VoidCallback onTap;
  final bool isReceived;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final imageUrl = application.opportunity?.offerPhoto;
    final initials = application.opportunityTitle.isNotEmpty
        ? application.opportunityTitle[0].toUpperCase()
        : 'K';

    return KolabCardShell(
      imageUrl: imageUrl,
      initials: initials,
      onTap: onTap,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KolabStatusBadge(status: application.status.name),
          const SizedBox(height: 6),
          Text(
            application.opportunityTitle,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Flexible(
                child: Text(
                  isReceived
                      ? AppLocalizations.of(context)
                          .applicationCardFrom(application.applicantName)
                      : AppLocalizations.of(context)
                          .applicationCardTo(application.recipientName),
                  style: KolabingTextStyles.captionSecondary.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isReceived &&
                  (application.applicantProfile?.isVerified ?? false)) ...[
                const SizedBox(width: KolabingSpacing.xxs),
                const VerifiedTick(isVerified: true, size: 14),
              ],
            ],
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            application.message,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Row(
            children: [
              Icon(LucideIcons.clock, size: 12, color: context.colors.textTertiary),
              const SizedBox(width: 4),
              Text(
                application.createdAtDisplay,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: context.colors.textTertiary,
                ),
              ),
              const Spacer(),
              if (application.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${application.unreadCount}',
                    style: KolabingTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textOnDark,
                    ),
                  ),
                )
              else
                Icon(LucideIcons.chevronRight, size: 18, color: context.colors.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}
