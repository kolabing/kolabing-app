import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../gamification/models/challenge.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/collaboration.dart';
import '../providers/collaboration_detail_provider.dart';

/// Collaboration detail screen shown after a kolabing request is accepted.
/// Both business and community users see this screen with role-aware content.
class CollaborationDetailScreen extends ConsumerWidget {
  const CollaborationDetailScreen({
    super.key,
    required this.collaborationId,
  });

  final String collaborationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCollab = ref.watch(collaborationDetailProvider(collaborationId));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: asyncCollab.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          onRetry: () =>
              ref.invalidate(collaborationDetailProvider(collaborationId)),
        ),
        data: (collaboration) {
          if (collaboration == null) {
            return const Center(child: Text('Collaboration not found'));
          }
          return _CollaborationContent(
            collaboration: collaboration,
            collaborationId: collaborationId,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Main Content
// =============================================================================

class _CollaborationContent extends ConsumerWidget {
  const _CollaborationContent({
    required this.collaboration,
    required this.collaborationId,
  });

  final Collaboration collaboration;
  final String collaborationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isBusiness = user?.isBusiness ?? true;
    final partner = collaboration.partnerFor(isBusiness: isBusiness);

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft,
                color: KolabingColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'COLLABORATION',
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.moreVertical,
                  color: KolabingColors.textSecondary),
              onPressed: () {},
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status & Title Header
              _StatusHeader(collaboration: collaboration),
              const SizedBox(height: KolabingSpacing.md),

              // Event Info Card
              _EventInfoCard(collaboration: collaboration),
              const SizedBox(height: KolabingSpacing.md),

              // Partner Info Card
              _PartnerInfoCard(partner: partner),
              const SizedBox(height: KolabingSpacing.md),

              // What's Offered (Business side)
              _OffersSection(
                businessOffer: collaboration.businessOffer,
                isBusiness: isBusiness,
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Expected Deliverables (Community side)
              _DeliverablesSection(
                deliverables: collaboration.communityDeliverables,
                isBusiness: isBusiness,
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Contact Methods
              _ContactSection(contact: collaboration.contactMethods),
              const SizedBox(height: KolabingSpacing.lg),

              // Process Timeline
              _TimelineSection(steps: collaboration.timeline),
              const SizedBox(height: KolabingSpacing.lg),

              // Gamification: Challenges Setup
              _ChallengesSection(
                collaborationId: collaborationId,
                challenges: collaboration.challenges ?? [],
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // QR Code Section
              _QRCodeSection(
                collaborationId: collaborationId,
                eventId: collaboration.eventId,
              ),

              const SizedBox(height: KolabingSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Status Header
// =============================================================================

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.collaboration});
  final Collaboration collaboration;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (collaboration.status) {
      CollaborationStatus.scheduled => (
          KolabingColors.pendingBg,
          KolabingColors.pendingText
        ),
      CollaborationStatus.inProgress => (
          KolabingColors.activeBg,
          KolabingColors.activeText
        ),
      CollaborationStatus.completed => (
          KolabingColors.completedBg,
          KolabingColors.completedText
        ),
      CollaborationStatus.cancelled => (
          KolabingColors.errorBg,
          KolabingColors.errorText
        ),
    };

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(KolabingRadius.round),
                  ),
                  child: Text(
                    collaboration.status.label.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                Text(
                  '${collaboration.businessPartner.name} x ${collaboration.communityPartner.name}',
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                if (collaboration.opportunity?.title != null) ...[
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    collaboration.opportunity!.title,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: KolabingColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Event Info Card
// =============================================================================

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({required this.collaboration});
  final Collaboration collaboration;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: LucideIcons.calendar,
      title: 'EVENT DETAILS',
      child: Column(
        children: [
          _InfoRow(
            icon: LucideIcons.calendarDays,
            label: 'Date',
            value: collaboration.formattedDate,
          ),
          if (collaboration.scheduledTime != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _InfoRow(
              icon: LucideIcons.clock,
              label: 'Time',
              value: collaboration.scheduledTime!,
            ),
          ],
          if (collaboration.businessOffer.venue) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _InfoRow(
              icon: LucideIcons.mapPin,
              label: 'Venue',
              value: '${collaboration.businessPartner.name} (Business venue)',
            ),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          _InfoRow(
            icon: LucideIcons.users,
            label: 'Expected Attendees',
            value: collaboration.communityDeliverables.attendeeCount != null
                ? '~${collaboration.communityDeliverables.attendeeCount}'
                : 'Not specified',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Partner Info Card
// =============================================================================

class _PartnerInfoCard extends StatelessWidget {
  const _PartnerInfoCard({required this.partner});
  final CollaborationPartner partner;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: LucideIcons.users2,
      title: partner.isBusiness ? 'BUSINESS PARTNER' : 'COMMUNITY PARTNER',
      child: InkWell(
        onTap: () => context.push('/profile/${partner.id}'),
        borderRadius: KolabingRadius.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: KolabingColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: partner.profilePhoto != null
                    ? ClipOval(
                        child: Image.network(
                          partner.profilePhoto!,
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              partner.initial,
                              style: GoogleFonts.rubik(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: KolabingColors.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          partner.initial,
                          style: GoogleFonts.rubik(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                    ),
                    if (partner.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        partner.category!,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: KolabingColors.textSecondary,
                        ),
                      ),
                    ],
                    if (partner.city != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin,
                              size: 12, color: KolabingColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(
                            partner.city!,
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: KolabingColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: KolabingColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Offers Section (What Business provides)
// =============================================================================

class _OffersSection extends StatelessWidget {
  const _OffersSection({
    required this.businessOffer,
    required this.isBusiness,
  });

  final BusinessOffer businessOffer;
  final bool isBusiness;

  @override
  Widget build(BuildContext context) {
    final items = <_CheckItem>[];

    if (businessOffer.venue) {
      items.add(const _CheckItem('Venue provided', true));
    }
    if (businessOffer.foodDrink) {
      items.add(const _CheckItem('Food & Drink included', true));
    }
    if (businessOffer.socialMediaExposure) {
      items.add(const _CheckItem('Social media exposure', true));
    }
    if (businessOffer.contentCreation) {
      items.add(const _CheckItem('Content creation support', true));
    }
    if (businessOffer.discount.enabled) {
      items.add(_CheckItem(
        'Discount: ${businessOffer.discount.percentage ?? 0}%',
        true,
      ));
    }
    for (final product in businessOffer.products) {
      items.add(_CheckItem(product, true));
    }
    if (businessOffer.other != null && businessOffer.other!.isNotEmpty) {
      items.add(_CheckItem(businessOffer.other!, true));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      icon: LucideIcons.gift,
      title: isBusiness ? "WHAT YOU'RE OFFERING" : "WHAT'S OFFERED",
      child: Column(
        children: items
            .map((item) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: KolabingSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 16,
                        color: KolabingColors.success,
                      ),
                      const SizedBox(width: KolabingSpacing.xs),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: KolabingColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// =============================================================================
// Deliverables Section (What Community provides)
// =============================================================================

class _DeliverablesSection extends StatelessWidget {
  const _DeliverablesSection({
    required this.deliverables,
    required this.isBusiness,
  });

  final CommunityDeliverables deliverables;
  final bool isBusiness;

  @override
  Widget build(BuildContext context) {
    final items = <_CheckItem>[];

    if (deliverables.socialMediaContent) {
      items.add(const _CheckItem('Social Media Content', true));
    }
    if (deliverables.eventActivation) {
      items.add(const _CheckItem('Event Activation', true));
    }
    if (deliverables.productPlacement) {
      items.add(const _CheckItem('Product Placement', true));
    }
    if (deliverables.communityReach) {
      items.add(const _CheckItem('Community Reach', true));
    }
    if (deliverables.reviewFeedback) {
      items.add(const _CheckItem('Review & Feedback', true));
    }
    if (deliverables.other != null && deliverables.other!.isNotEmpty) {
      items.add(_CheckItem(deliverables.other!, true));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      icon: LucideIcons.megaphone,
      title: isBusiness ? 'EXPECTED DELIVERABLES' : "WHAT YOU'LL DELIVER",
      child: Column(
        children: items
            .map((item) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: KolabingSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.checkCircle2,
                        size: 16,
                        color: KolabingColors.info,
                      ),
                      const SizedBox(width: KolabingSpacing.xs),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: KolabingColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// =============================================================================
// Contact Section
// =============================================================================

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.contact});
  final ContactMethods contact;

  @override
  Widget build(BuildContext context) {
    if (!contact.hasAny) return const SizedBox.shrink();

    return _SectionCard(
      icon: LucideIcons.contact,
      title: 'CONTACT',
      child: Column(
        children: [
          if (contact.whatsapp != null && contact.whatsapp!.isNotEmpty)
            _ContactRow(
              icon: LucideIcons.messageSquare,
              label: 'WhatsApp',
              value: contact.whatsapp!,
            ),
          if (contact.email != null && contact.email!.isNotEmpty) ...[
            if (contact.whatsapp != null && contact.whatsapp!.isNotEmpty)
              const SizedBox(height: KolabingSpacing.xs),
            _ContactRow(
              icon: LucideIcons.mail,
              label: 'Email',
              value: contact.email!,
            ),
          ],
          if (contact.instagram != null && contact.instagram!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ContactRow(
              icon: LucideIcons.atSign,
              label: 'Instagram',
              value: contact.instagram!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KolabingColors.textTertiary),
        const SizedBox(width: KolabingSpacing.xs),
        Text(
          '$label: ',
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: KolabingColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Process Timeline
// =============================================================================

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.steps});
  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: KolabingSpacing.xxs),
          child: Row(
            children: [
              const Icon(LucideIcons.gitBranch,
                  size: 16, color: KolabingColors.textTertiary),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'PROCESS',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return _TimelineStepWidget(step: step, isLast: isLast);
        }),
      ],
    );
  }
}

class _TimelineStepWidget extends StatelessWidget {
  const _TimelineStepWidget({
    required this.step,
    required this.isLast,
  });

  final TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (dotColor, lineColor, textColor) = switch (step.status) {
      TimelineStepStatus.completed => (
          KolabingColors.success,
          KolabingColors.success.withValues(alpha: 0.3),
          KolabingColors.textPrimary,
        ),
      TimelineStepStatus.current => (
          KolabingColors.primary,
          KolabingColors.border,
          KolabingColors.textPrimary,
        ),
      TimelineStepStatus.upcoming => (
          KolabingColors.border,
          KolabingColors.border,
          KolabingColors.textTertiary,
        ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: step.status == TimelineStepStatus.current ? 14 : 10,
                  height: step.status == TimelineStepStatus.current ? 14 : 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: step.status == TimelineStepStatus.current
                        ? Border.all(
                            color: KolabingColors.primary.withValues(alpha: 0.3),
                            width: 3,
                          )
                        : null,
                  ),
                  child: step.status == TimelineStepStatus.completed
                      ? const Icon(LucideIcons.check,
                          size: 7, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : KolabingSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: step.status == TimelineStepStatus.current
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: step.status == TimelineStepStatus.upcoming
                          ? KolabingColors.textTertiary
                          : KolabingColors.textSecondary,
                    ),
                  ),
                  if (step.date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(step.date!),
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}

// =============================================================================
// Challenges Section (Gamification Setup)
// =============================================================================

class _ChallengesSection extends ConsumerWidget {
  const _ChallengesSection({
    required this.collaborationId,
    required this.challenges,
  });

  final String collaborationId;
  final List<Challenge> challenges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(challengeSelectionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: KolabingSpacing.xxs),
          child: Row(
            children: [
              const Icon(LucideIcons.trophy,
                  size: 16, color: KolabingColors.textTertiary),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'GAMIFICATION SETUP',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${selectedIds.length} selected',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),

        // Description
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            color: KolabingColors.softYellow,
            borderRadius: KolabingRadius.borderRadiusSm,
            border: Border.all(color: KolabingColors.softYellowBorder),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info,
                  size: 14, color: KolabingColors.onPrimary),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  'Select challenges for attendees to complete during the event. '
                  'These will be available in the attendee app.',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: KolabingColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Challenge list
        if (challenges.isEmpty)
          _EmptyChallenges()
        else
          ...challenges.map((challenge) {
            final isSelected = selectedIds.contains(challenge.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
              child: _ChallengeCard(
                challenge: challenge,
                isSelected: isSelected,
                onToggle: () => ref
                    .read(challengeSelectionProvider.notifier)
                    .toggle(challenge.id),
              ),
            );
          }),

        const SizedBox(height: KolabingSpacing.sm),

        // Add custom challenge button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              // Will navigate to create challenge screen when API is ready
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Custom challenge creation coming soon',
                    style: GoogleFonts.openSans(color: Colors.white),
                  ),
                  backgroundColor: KolabingColors.textSecondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: KolabingColors.primary,
              side: BorderSide(
                color: KolabingColors.primary.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KolabingRadius.md),
              ),
            ),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(
              'ADD CUSTOM CHALLENGE',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChallenges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.trophy,
            size: 32,
            color: KolabingColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            'No challenges yet',
            style: GoogleFonts.rubik(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Add challenges to make the event more engaging for attendees',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.isSelected,
    required this.onToggle,
  });

  final Challenge challenge;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final (diffColor, diffBgColor) = switch (challenge.difficulty) {
      ChallengeDifficulty.easy => (
          const Color(0xFF155724),
          const Color(0xFFD4EDDA),
        ),
      ChallengeDifficulty.medium => (
          const Color(0xFF856404),
          const Color(0xFFFFF3CD),
        ),
      ChallengeDifficulty.hard => (
          const Color(0xFF721C24),
          const Color(0xFFF8D7DA),
        ),
    };

    return Material(
      color: isSelected
          ? KolabingColors.primary.withValues(alpha: 0.06)
          : KolabingColors.surface,
      borderRadius: KolabingRadius.borderRadiusMd,
      child: InkWell(
        onTap: onToggle,
        borderRadius: KolabingRadius.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(
              color: isSelected
                  ? KolabingColors.primary
                  : KolabingColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      isSelected ? KolabingColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? KolabingColors.primary
                        : KolabingColors.border,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(LucideIcons.check,
                        size: 14, color: KolabingColors.onPrimary)
                    : null,
              ),
              const SizedBox(width: KolabingSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.name,
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: KolabingColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: KolabingSpacing.xs),
                        // Difficulty badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: diffBgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            challenge.difficulty.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: diffColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (challenge.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        challenge.description!,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: KolabingColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Points
              const SizedBox(width: KolabingSpacing.xs),
              Column(
                children: [
                  Text(
                    '${challenge.points}',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.primary,
                    ),
                  ),
                  Text(
                    'pts',
                    style: GoogleFonts.openSans(
                      fontSize: 10,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// QR Code Section
// =============================================================================

class _QRCodeSection extends StatelessWidget {
  const _QRCodeSection({
    required this.collaborationId,
    required this.eventId,
  });

  final String collaborationId;
  final String? eventId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: KolabingSpacing.xxs),
          child: Row(
            children: [
              const Icon(LucideIcons.qrCode,
                  size: 16, color: KolabingColors.textTertiary),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'QR CODE CHECK-IN',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          decoration: BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            border: Border.all(color: KolabingColors.border),
          ),
          child: Column(
            children: [
              // QR placeholder
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: KolabingColors.background,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(
                    color: KolabingColors.border,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.qrCode,
                      size: 64,
                      color: KolabingColors.textTertiary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Text(
                      'QR Code',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                    Text(
                      'Generated on event day',
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KolabingSpacing.md),

              Text(
                'Attendees scan this QR code at your event to check in and start completing challenges.',
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  color: KolabingColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: KolabingSpacing.md),

              // Generate QR button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (eventId != null) {
                      context.push(
                        '/attendee/events/$eventId/qr?name=Collaboration%20Event',
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'QR code will be available when the event is created',
                            style: GoogleFonts.openSans(color: Colors.white),
                          ),
                          backgroundColor: KolabingColors.textSecondary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(KolabingRadius.md),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.qrCode, size: 18),
                  label: Text(
                    'VIEW QR CODE',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Shared Widgets
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: KolabingColors.textTertiary),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KolabingColors.textTertiary),
        const SizedBox(width: KolabingSpacing.xs),
        Text(
          '$label: ',
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: KolabingColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckItem {
  const _CheckItem(this.label, this.checked);
  final String label;
  final bool checked;
}

// =============================================================================
// Loading State
// =============================================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: KolabingColors.primary),
    );
  }
}

// =============================================================================
// Error State
// =============================================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: KolabingColors.error),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              'Failed to load collaboration',
              style: GoogleFonts.rubik(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: GoogleFonts.dmSans(
                  color: KolabingColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
