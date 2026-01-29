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

/// Applications list screen showing user's sent applications
class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Applications',
          style: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myApplicationsProvider.notifier).refresh(),
        color: KolabingColors.primary,
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ApplicationsState state) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    if (state.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: state.applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: KolabingSpacing.sm),
      itemBuilder: (context, index) {
        final application = state.applications[index];
        return _ApplicationCard(
          application: application,
          onTap: () => context.push('/application/${application.id}/chat'),
        );
      },
    );
  }

  Widget _buildLoadingState() => Shimmer.fromColors(
        baseColor: KolabingColors.surfaceVariant,
        highlightColor: KolabingColors.surface,
        child: ListView.separated(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: KolabingSpacing.sm),
          itemBuilder: (_, __) => Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
          ),
        ),
      );

  Widget _buildErrorState(String error) => Center(
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
                  color: KolabingColors.textPrimary,
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

  Widget _buildEmptyState() => Center(
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
                  color: KolabingColors.textPrimary,
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

/// Application card widget
class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onTap,
  });

  final Application application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KolabingRadius.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusMd,
          boxShadow: [
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
                            color: KolabingColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),

                  // Recipient name
                  Text(
                    'To: ${application.recipientName}',
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
                      Icon(
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
  }

  Widget _buildAvatar() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: application.recipientAvatar != null
            ? ClipOval(
                child: Image.network(
                  application.recipientAvatar!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                ),
              )
            : _avatarPlaceholder(),
      );

  Widget _avatarPlaceholder() => Center(
        child: Text(
          application.recipientName.isNotEmpty
              ? application.recipientName[0].toUpperCase()
              : '?',
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
