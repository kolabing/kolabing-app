import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/application.dart';
import '../providers/application_provider.dart';

/// Applications list screen showing both sent and received applications
/// via a tabbed interface.
class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

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

    return Scaffold(
      backgroundColor:
          isDark ? KolabingColors.darkBackground : KolabingColors.background,
      appBar: AppBar(
        backgroundColor:
            isDark ? KolabingColors.darkSurface : KolabingColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'APPLICATIONS',
          style: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color:
                isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: KolabingColors.primary,
                indicatorWeight: 3,
                labelColor: isDark
                    ? KolabingColors.textOnDark
                    : KolabingColors.textPrimary,
                unselectedLabelColor: isDark
                    ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                    : KolabingColors.textTertiary,
                labelStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'SENT'),
                  Tab(text: 'RECEIVED'),
                ],
              ),
              Divider(
                height: 1,
                color:
                    isDark ? KolabingColors.darkBorder : KolabingColors.border,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Sent applications
          _SentApplicationsTab(),
          // Tab 2: Received applications
          _ReceivedApplicationsTab(),
        ],
      ),
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
      color: KolabingColors.primary,
      child: _buildBody(context, state, isDark: isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ApplicationsState state, {
    required bool isDark,
  }) {
    if (state.isLoading) {
      return _buildLoadingState(isDark);
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, isDark);
    }

    if (state.isEmpty) {
      return _buildSentEmptyState(isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: state.applications.length,
      separatorBuilder: (_, _) => const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        final application = state.applications[index];
        return _ApplicationCard(
          application: application,
          isReceived: false,
          isDark: isDark,
          onTap: () => context.push('/application/${application.id}/chat'),
        );
      },
    );
  }

  Widget _buildSentEmptyState(bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: KolabingColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.send,
                  size: 36,
                  color: KolabingColors.primary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                'No Applications Yet',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'Start exploring opportunities and apply to collaborate with businesses and communities.',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                ),
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
      color: KolabingColors.primary,
      child: _buildBody(context, state, isDark),
    );
  }

  Widget _buildBody(BuildContext context, ApplicationsState state, bool isDark) {
    if (state.isLoading) {
      return _buildLoadingState(isDark);
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, isDark);
    }

    if (state.isEmpty) {
      return _buildReceivedEmptyState(isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: state.applications.length,
      separatorBuilder: (_, _) => const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        final application = state.applications[index];
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

  Widget _buildReceivedEmptyState(bool isDark) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: KolabingColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.inbox,
                  size: 36,
                  color: KolabingColors.primary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                'No Received Applications',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                "When someone applies to your opportunities, they'll appear here.",
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.textSecondary,
                ),
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

Widget _buildLoadingState(bool isDark) => Shimmer.fromColors(
      baseColor:
          isDark ? KolabingColors.darkSurface : KolabingColors.surfaceVariant,
      highlightColor:
          isDark ? KolabingColors.darkBorder : KolabingColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: KolabingSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? KolabingColors.darkSurface : Colors.white,
            borderRadius: KolabingRadius.borderRadiusMd,
          ),
        ),
      ),
    );

Widget _buildErrorState(String error, bool isDark) => Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              'Something went wrong',
              style: GoogleFonts.rubik(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? KolabingColors.textOnDark
                    : KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
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
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: KolabingRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _buildAvatar(),
            const SizedBox(width: KolabingSpacing.sm),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          application.opportunityTitle,
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? KolabingColors.textOnDark
                                : KolabingColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),

                  // Name label: "From:" for received, "To:" for sent
                  Text(
                    isReceived
                        ? 'From: ${application.applicantName}'
                        : 'To: ${application.recipientName}',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xs),

                  // Message preview
                  Text(
                    application.message,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: KolabingColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: KolabingSpacing.xs),

                  // Footer
                  Row(
                    children: [
                      // Created time
                      const Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: KolabingColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        application.createdAtDisplay,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: KolabingColors.textTertiary,
                        ),
                      ),

                      const Spacer(),

                      // Unread indicator
                      if (application.unreadCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: KolabingColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${application.unreadCount}',
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: KolabingColors.textTertiary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildAvatar() {
    final String? avatarUrl;
    final String name;

    if (isReceived) {
      avatarUrl = application.applicantAvatar;
      name = application.applicantName;
    } else {
      avatarUrl = application.recipientAvatar;
      name = application.recipientName;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: KolabingColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _avatarPlaceholder(name),
              ),
            )
          : _avatarPlaceholder(name),
    );
  }

  Widget _avatarPlaceholder(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: KolabingColors.primary,
          ),
        ),
      );

  Widget _buildStatusBadge() {
    final (bgColor, textColor, label) = switch (application.status) {
      ApplicationStatus.pending => (
          KolabingColors.pendingBg,
          KolabingColors.pendingText,
          'Pending',
        ),
      ApplicationStatus.accepted => (
          KolabingColors.activeBg,
          KolabingColors.activeText,
          'Accepted',
        ),
      ApplicationStatus.declined => (
          KolabingColors.errorBg,
          KolabingColors.error,
          'Declined',
        ),
      ApplicationStatus.withdrawn => (
          KolabingColors.surfaceVariant,
          KolabingColors.textTertiary,
          'Withdrawn',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
