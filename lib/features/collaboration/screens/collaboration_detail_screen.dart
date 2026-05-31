import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../gamification/models/challenge.dart';
import '../../opportunity/models/opportunity.dart';
import '../../rewards/widgets/collaboration_reward_nudge.dart';
import '../../../widgets/blurred_identity.dart';
import '../models/collaboration.dart';
import '../providers/collaboration_detail_provider.dart';
import '../widgets/kolab_completion_sheet.dart';
import '../widgets/kolab_review_sheet.dart';
import '../../../widgets/category_icon.dart';

/// Collaboration detail screen shown after a kolabing request is accepted.
/// Both business and community users see this screen with role-aware content.
class CollaborationDetailScreen extends ConsumerWidget {
  const CollaborationDetailScreen({super.key, required this.collaborationId});

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
            return const Center(child: Text('Kolab not found'));
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

    // Subscription-lapse re-gate (docs/ROLES-AND-PERMISSIONS.md §2.8). Only a
    // business viewer with a lapsed subscription on an ongoing collaboration is
    // re-gated; the community counterparty is NEVER blurred. The backend flag
    // is already one-sided, but we AND it with isBusiness as a belt-and-braces
    // guard so a community can never be blurred even if the flag is wrong.
    final mustResubscribe = isBusiness && collaboration.viewerMustResubscribe;

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          backgroundColor: KolabingColors.surface,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: KolabingColors.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'KOLAB',
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
            ),
          ),
          centerTitle: true,
          // 3-dots overflow menu removed: it had an empty handler (dead button).
          // Its only plausible actions already exist inline — Reschedule via the
          // Event Info Card's edit, and Complete via the Complete Kolab CTA —
          // and both are correctly hidden on terminal (completed/cancelled)
          // kolabs, so the menu was fully redundant. Re-add here only if a
          // distinct action (e.g. Cancel) is built.
        ),

        SliverPadding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Lapse re-gate: business with a lapsed subscription sees a
              // "Resubscribe to continue" prompt above the (blurred) details.
              // The community counterparty never reaches this branch.
              if (mustResubscribe) ...[
                const _ResubscribePrompt(),
                const SizedBox(height: KolabingSpacing.md),
              ],

              // The collaboration body. When re-gated we blur it so the
              // business can tell a collaboration exists but cannot read the
              // ongoing details until it resubscribes. We do NOT hard-block or
              // full-screen-overlay (golden rule 5) — the prompt sits above and
              // the content stays on screen, blurred.
              _BlurGate(
                enabled: mustResubscribe,
                child: _CollaborationBody(
                  collaboration: collaboration,
                  collaborationId: collaborationId,
                  partner: partner,
                  isBusiness: isBusiness,
                  interactive: !mustResubscribe,
                ),
              ),

              const SizedBox(height: KolabingSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}

/// The scrollable body of the collaboration detail, extracted so it can be
/// wrapped in a blur when the business is re-gated.
class _CollaborationBody extends ConsumerWidget {
  const _CollaborationBody({
    required this.collaboration,
    required this.collaborationId,
    required this.partner,
    required this.isBusiness,
    required this.interactive,
  });

  final Collaboration collaboration;
  final String collaborationId;
  final CollaborationPartner partner;
  final bool isBusiness;
  final bool interactive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status & Title Header
        _StatusHeader(collaboration: collaboration),
        const SizedBox(height: KolabingSpacing.md),

        // Event Info Card (with edit date/time action when interactive)
        _EventInfoCard(
          collaboration: collaboration,
          collaborationId: collaborationId,
          canEdit: interactive,
        ),
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

        // Today's Kolab info banner — scheduled but not yet active
        if (interactive &&
            collaboration.isToday &&
            collaboration.status == CollaborationStatus.scheduled)
          _TodayScheduledBanner(
            partnerName: isBusiness
                ? collaboration.communityPartner.name
                : collaboration.businessPartner.name,
          ),

        // Complete Kolab CTA — only when active (inProgress)
        if (interactive && collaboration.status.canBeCompleted)
          _CompleteKolabSection(
            collaborationId: collaborationId,
            partnerName: isBusiness
                ? collaboration.communityPartner.name
                : collaboration.businessPartner.name,
            isToday: collaboration.isToday,
          ),

        // Post-completion: leave review CTA
        if (interactive &&
            collaboration.status == CollaborationStatus.completed)
          _PostCompletionReviewSection(
            collaborationId: collaborationId,
            partnerName: isBusiness
                ? collaboration.communityPartner.name
                : collaboration.businessPartner.name,
            hasReviewed: collaboration.hasReviewed,
          ),

        // Post-completion: community users see a reward nudge (+1 point earned,
        // prompt to post a review for another point).
        if (interactive &&
            collaboration.status == CollaborationStatus.completed &&
            !isBusiness)
          const Padding(
            padding: EdgeInsets.only(bottom: KolabingSpacing.md),
            child: CollaborationRewardNudge(),
          ),

        // Gamification: Challenges Setup
        _ChallengesSection(collaborationId: collaborationId),
        const SizedBox(height: KolabingSpacing.lg),

        // QR Code Section
        _QRCodeSection(
          collaborationId: collaborationId,
          eventId: collaboration.eventId,
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
        KolabingColors.pendingText,
      ),
      CollaborationStatus.inProgress => (
        KolabingColors.activeBg,
        KolabingColors.activeText,
      ),
      CollaborationStatus.pendingConfirmation => (
        const Color(0xFFFFF3CD),
        const Color(0xFF856404),
      ),
      CollaborationStatus.completed => (
        KolabingColors.completedBg,
        KolabingColors.completedText,
      ),
      CollaborationStatus.cancelled => (
        KolabingColors.errorBg,
        KolabingColors.errorText,
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
                    style: KolabingTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                Text(
                  '${collaboration.businessPartner.name} x ${collaboration.communityPartner.name}',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onSurface,
                  ),
                ),
                if (collaboration.opportunity?.title != null) ...[
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    collaboration.opportunity!.title,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.onSurfaceVariant,
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

class _EventInfoCard extends ConsumerStatefulWidget {
  const _EventInfoCard({
    required this.collaboration,
    required this.collaborationId,
    required this.canEdit,
  });
  final Collaboration collaboration;
  final String collaborationId;

  /// §4: either party can edit the scheduled date/time. False when re-gated or
  /// when the collaboration is in a terminal state.
  final bool canEdit;

  @override
  ConsumerState<_EventInfoCard> createState() => _EventInfoCardState();
}

class _EventInfoCardState extends ConsumerState<_EventInfoCard> {
  bool _isSaving = false;

  /// Pick a new date (and optional time range) and PATCH it to the backend.
  /// Both parties may reschedule a non-terminal collaboration.
  Future<void> _editSchedule() async {
    final collaboration = widget.collaboration;
    final messenger = ScaffoldMessenger.of(context);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: collaboration.scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Reschedule kolab',
    );
    if (pickedDate == null || !mounted) return;

    // Optional time refinement. We keep the existing free-text time as a hint
    // and let the user pick a start time; the backend stores `scheduled_time`
    // as a string so we format a single time. (A full range editor can be
    // added later; this satisfies "edit the date or time".)
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Start time (optional)',
    );
    if (!mounted) return;

    final timeString = pickedTime != null
        ? pickedTime.format(context)
        : collaboration.scheduledTime;

    setState(() => _isSaving = true);
    try {
      await updateCollaborationSchedule(
        widget.collaborationId,
        scheduledDate: pickedDate,
        scheduledTime: timeString,
      );
      if (!mounted) return;
      ref.invalidate(collaborationDetailProvider(widget.collaborationId));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Schedule updated.',
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textOnDark),
          ),
          backgroundColor: KolabingColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not update schedule: $e',
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textOnDark),
          ),
          backgroundColor: KolabingColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collaboration = widget.collaboration;
    final canEditNow =
        widget.canEdit && collaboration.status.isActive && !_isSaving;

    return _SectionCard(
      icon: LucideIcons.calendar,
      title: 'EVENT DETAILS',
      trailing: canEditNow
          ? _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: _editSchedule,
                    style: TextButton.styleFrom(
                      foregroundColor: KolabingColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: Text(
                      'EDIT',
                      style: KolabingTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
          : null,
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
            label: 'Community Reach',
            value: collaboration.communityDeliverables.communityReach
                ? 'Included'
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
        // "View business/creator profile" opens the public profile route
        // `/profile/:id`, whose `:id` MUST be a `profiles.id` (the route binds
        // to a Profile -> PublicProfileResource). `partner.id` is sourced from
        // the collaboration's `business_partner`/`community_partner` object,
        // which carries the partner's `profiles.id` (mirrors the backend's
        // ProfileSummaryResource `id`), NOT a business/community-profile id.
        // Guard against an empty id so we never push `/profile/` (which would
        // 404 and look like the link is broken).
        onTap: partner.id.isEmpty
            ? null
            : () => context.push('/profile/${partner.id}'),
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
                              style: KolabingTextStyles.bodyLarge.copyWith(
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
                          style: KolabingTextStyles.bodyLarge.copyWith(
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
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.onSurface,
                      ),
                    ),
                    if (partner.category != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          CategoryIcon(name: partner.category!, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            partner.category!,
                            style: KolabingTextStyles.captionSecondary.copyWith(
                              color: KolabingColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (partner.city != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: KolabingColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            partner.city!,
                            style: KolabingTextStyles.bodySmall.copyWith(
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
  const _OffersSection({required this.businessOffer, required this.isBusiness});

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
      items.add(
        _CheckItem(
          'Discount: ${businessOffer.discount.percentage ?? 0}%',
          true,
        ),
      );
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
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
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
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
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
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
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
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
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
          style: KolabingTextStyles.captionSecondary.copyWith(
            color: KolabingColors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: KolabingTextStyles.captionSecondary.copyWith(
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
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
              const Icon(
                LucideIcons.gitBranch,
                size: 16,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'PROCESS',
                style: KolabingTextStyles.eyebrow.copyWith(
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
  const _TimelineStepWidget({required this.step, required this.isLast});

  final TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (dotColor, lineColor, textColor) = switch (step.status) {
      TimelineStepStatus.completed => (
        KolabingColors.success,
        KolabingColors.success.withValues(alpha: 0.3),
        KolabingColors.onSurface,
      ),
      TimelineStepStatus.current => (
        KolabingColors.primary,
        KolabingColors.darkBorder,
        KolabingColors.onSurface,
      ),
      TimelineStepStatus.upcoming => (
        KolabingColors.darkBorder,
        KolabingColors.darkBorder,
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
                            color: KolabingColors.primary.withValues(
                              alpha: 0.3,
                            ),
                            width: 3,
                          )
                        : null,
                  ),
                  child: step.status == TimelineStepStatus.completed
                      ? const Icon(
                          LucideIcons.check,
                          size: 7,
                          color: KolabingColors.textOnDark,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : KolabingSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontWeight: step.status == TimelineStepStatus.current
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: step.status == TimelineStepStatus.upcoming
                          ? KolabingColors.textTertiary
                          : KolabingColors.onSurfaceVariant,
                    ),
                  ),
                  if (step.date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(step.date!),
                      style: KolabingTextStyles.labelSmall.copyWith(
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}

// =============================================================================
// Challenges Section (Gamification Setup)
// =============================================================================

class _ChallengesSection extends ConsumerWidget {
  const _ChallengesSection({required this.collaborationId});

  final String collaborationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(challengeSelectionProvider);
    // Real system-challenge catalogue from the backend (GET /challenges/system).
    // The `challenges` field (collaboration.challenges) is currently always []
    // from the API, so we source the selectable pool from this provider.
    final availableAsync = ref.watch(availableChallengesProvider);
    final challenges = availableAsync.asData?.value ?? const <Challenge>[];
    final isLoadingChallenges = availableAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: KolabingSpacing.xxs),
          child: Row(
            children: [
              const Icon(
                LucideIcons.trophy,
                size: 16,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'GAMIFICATION SETUP',
                style: KolabingTextStyles.eyebrow.copyWith(
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '${selectedIds.length} selected',
                style: KolabingTextStyles.bodySmall.copyWith(
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
              const Icon(
                LucideIcons.info,
                size: 14,
                color: KolabingColors.onPrimary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  'Select challenges for attendees to complete during the event. '
                  'These will be available in the attendee app.',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: KolabingColors.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Challenge list
        if (isLoadingChallenges)
          const Padding(
            padding: EdgeInsets.all(KolabingSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(
                color: KolabingColors.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (challenges.isEmpty)
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
                    style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textOnDark),
                  ),
                  backgroundColor: KolabingColors.onSurfaceVariant,
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
              style: KolabingTextStyles.button.copyWith(
                fontSize: 13,
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
        border: Border.all(color: KolabingColors.darkBorder),
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
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'Add challenges to make the event more engaging for attendees',
            style: KolabingTextStyles.captionSecondary.copyWith(
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
                  : KolabingColors.darkBorder,
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
                  color: isSelected
                      ? KolabingColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? KolabingColors.primary
                        : KolabingColors.darkBorder,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        LucideIcons.check,
                        size: 14,
                        color: KolabingColors.onPrimary,
                      )
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
                            style: KolabingTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: KolabingColors.onSurface,
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
                            style: KolabingTextStyles.labelSmall.copyWith(
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
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: KolabingColors.onSurfaceVariant,
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
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: KolabingColors.primary,
                    ),
                  ),
                  Text(
                    'pts',
                    style: KolabingTextStyles.labelSmall.copyWith(
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
  const _QRCodeSection({required this.collaborationId, required this.eventId});

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
              const Icon(
                LucideIcons.qrCode,
                size: 16,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'QR CODE CHECK-IN',
                style: KolabingTextStyles.eyebrow.copyWith(
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
            border: Border.all(color: KolabingColors.darkBorder),
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
                  border: Border.all(color: KolabingColors.darkBorder, width: 2),
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
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                    Text(
                      'Generated on event day',
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: KolabingColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KolabingSpacing.md),

              Text(
                'Attendees scan this QR code at your event to check in and start completing challenges.',
                style: KolabingTextStyles.captionSecondary.copyWith(
                  color: KolabingColors.onSurfaceVariant,
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
                            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textOnDark),
                          ),
                          backgroundColor: KolabingColors.onSurfaceVariant,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KolabingRadius.md),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.qrCode, size: 18),
                  label: Text(
                    'VIEW QR CODE',
                    style: KolabingTextStyles.button.copyWith(
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
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// Optional widget pinned to the right of the section title (e.g. an Edit
  /// button on the event card).
  final Widget? trailing;

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
                style: KolabingTextStyles.eyebrow.copyWith(
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
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
          style: KolabingTextStyles.captionSecondary.copyWith(
            color: KolabingColors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: KolabingTextStyles.captionSecondary.copyWith(
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
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
// Subscription-lapse re-gate (§2.8)
// =============================================================================

/// Wraps the collaboration body and blurs it when [enabled]. Reuses the shared
/// [BlurredIdentity] widget (client-side Gaussian blur). When blurred we also
/// wrap in IgnorePointer so the unreadable content can't be tapped — without a
/// full-screen overlay (golden rule 5: blur, don't hard-block).
class _BlurGate extends StatelessWidget {
  const _BlurGate({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return IgnorePointer(
      // Slightly stronger blur than the Explore identity blur so multi-line
      // body text is not legible.
      child: BlurredIdentity(enabled: true, sigma: 6, child: child),
    );
  }
}

/// "Resubscribe to continue" prompt shown to a business whose subscription
/// lapsed on an ongoing collaboration (§2.8). Routes to the subscription flow.
class _ResubscribePrompt extends StatelessWidget {
  const _ResubscribePrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.softYellow,
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        border: Border.all(color: KolabingColors.softYellowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.lock,
                size: 18,
                color: KolabingColors.onPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resubscribe to continue',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your subscription has lapsed, so this ongoing kolab and its '
            'chat are paused on your side. The community keeps full access. '
            'Resubscribe to pick up where you left off.',
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: KolabingColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => context.push(KolabingRoutes.businessPlans),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KolabingRadius.md),
                ),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.creditCard, size: 18),
              label: Text(
                'RESUBSCRIBE',
                style: KolabingTextStyles.button.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              'Failed to load kolab',
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: KolabingColors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: KolabingTextStyles.labelLarge.copyWith(
                  color: KolabingColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Today's Kolab banner — scheduled but not yet active
// =============================================================================

class _TodayScheduledBanner extends StatelessWidget {
  const _TodayScheduledBanner({required this.partnerName});
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.primary.withOpacity(0.12),
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.primaryDark.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Kolab!",
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Your Kolab with $partnerName is today. Once it's active you'll be able to mark it complete.",
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: KolabingColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Complete Kolab section — first party CTA (status: inProgress only)
// =============================================================================

class _CompleteKolabSection extends ConsumerWidget {
  const _CompleteKolabSection({
    required this.collaborationId,
    required this.partnerName,
    required this.isToday,
  });

  final String collaborationId;
  final String partnerName;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isToday
            ? KolabingColors.primary.withOpacity(0.12)
            : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: isToday
              ? KolabingColors.primaryDark.withOpacity(0.4)
              : KolabingColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(isToday ? '🎉' : '✅', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                isToday ? "Complete today's Kolab!" : 'Kolab completed?',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? 'Did your Kolab with $partnerName happen? Mark it done.'
                : 'Did the Kolab with $partnerName happen? Mark it done.',
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final result = await KolabCompletionSheet.show(
                context,
                collaborationId: collaborationId,
                partnerName: partnerName,
              );
              if (result != null) {
                ref.invalidate(collaborationDetailProvider(collaborationId));
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: KolabingColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                isToday ? "Mark it done ✨" : "Yes, it happened ✨",
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Post-completion review section
// =============================================================================

class _PostCompletionReviewSection extends ConsumerWidget {
  const _PostCompletionReviewSection({
    required this.collaborationId,
    required this.partnerName,
    required this.hasReviewed,
  });

  final String collaborationId;
  final String partnerName;
  final bool hasReviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: hasReviewed ? KolabingColors.activeBg : KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: hasReviewed ? KolabingColors.activeBg : KolabingColors.darkBorder,
        ),
      ),
      child: hasReviewed ? _buildReviewed() : _buildUnreviewed(context, ref),
    );
  }

  Widget _buildReviewed() => Row(
    children: [
      const Icon(
        Icons.check_circle_rounded,
        color: KolabingColors.activeText,
        size: 18,
      ),
      const SizedBox(width: 8),
      Text(
        'Review submitted ✓',
        style: KolabingTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: KolabingColors.activeText,
        ),
      ),
    ],
  );

  Widget _buildUnreviewed(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Leave a review',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: KolabingColors.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.primary.withValues(alpha: 0.15),
              borderRadius: KolabingRadius.borderRadiusRound,
            ),
            child: Text(
              '+10 XP',
              style: KolabingTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: KolabingColors.onSurface,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Help $partnerName build trust on Kolabing.',
        style: KolabingTextStyles.captionSecondary.copyWith(
          color: KolabingColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: () async {
            final submitted = await KolabReviewSheet.show(
              context,
              collaborationId: collaborationId,
              partnerName: partnerName,
            );
            if (submitted) {
              ref.invalidate(collaborationDetailProvider(collaborationId));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
            elevation: 0,
          ),
          child: Text(
            'Leave review +10 XP ✨',
            style: KolabingTextStyles.button,
          ),
        ),
      ),
    ],
  );
}
