import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
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
import '../../../widgets/verified_tick.dart';

/// Collaboration detail screen shown after a kolabing request is accepted.
/// Both business and community users see this screen with role-aware content.
class CollaborationDetailScreen extends ConsumerWidget {
  const CollaborationDetailScreen({super.key, required this.collaborationId});

  final String collaborationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCollab = ref.watch(collaborationDetailProvider(collaborationId));

    return Scaffold(
      backgroundColor: context.colors.background,
      body: asyncCollab.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          onRetry: () =>
              ref.invalidate(collaborationDetailProvider(collaborationId)),
        ),
        data: (collaboration) {
          if (collaboration == null) {
            return Center(
              child: Text(AppLocalizations.of(context).collaborationDetailNotFound),
            );
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
          backgroundColor: context.colors.surface,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: Icon(
              LucideIcons.arrowLeft,
              color: context.colors.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'KOLAB',
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
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
        context.colors.pendingBg,
        context.colors.pendingText,
      ),
      CollaborationStatus.inProgress => (
        context.colors.activeBg,
        context.colors.activeText,
      ),
      CollaborationStatus.pendingConfirmation => (
        context.colors.pendingBg,
        context.colors.pendingText,
      ),
      CollaborationStatus.completed => (
        context.colors.completedBg,
        context.colors.completedText,
      ),
      CollaborationStatus.cancelled => (
        context.colors.errorBg,
        context.colors.errorText,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${collaboration.businessPartner.name} x ${collaboration.communityPartner.name}',
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                    if (collaboration.communityPartner.isVerified) ...[
                      const SizedBox(width: KolabingSpacing.xs),
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: VerifiedTick(isVerified: true, size: 18),
                      ),
                    ],
                  ],
                ),
                if (collaboration.opportunity?.title != null) ...[
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    collaboration.opportunity!.title,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: collaboration.scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: l10n.collaborationDetailRescheduleHelp,
    );
    if (pickedDate == null || !mounted) return;

    // Optional time refinement. We keep the existing free-text time as a hint
    // and let the user pick a start time; the backend stores `scheduled_time`
    // as a string so we format a single time. (A full range editor can be
    // added later; this satisfies "edit the date or time".)
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: l10n.collaborationDetailStartTimeHelp,
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
            l10n.collaborationDetailScheduleUpdated,
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.textOnDark),
          ),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.collaborationDetailScheduleUpdateError(e.toString()),
            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.textOnDark),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final collaboration = widget.collaboration;
    final canEditNow =
        widget.canEdit && collaboration.status.isActive && !_isSaving;

    return _SectionCard(
      icon: LucideIcons.calendar,
      title: l10n.collaborationDetailEventDetails,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    label: Text(
                      l10n.collaborationDetailEdit,
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
            label: l10n.collaborationDetailDateLabel,
            value: collaboration.formattedDate,
          ),
          if (collaboration.scheduledTime != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _InfoRow(
              icon: LucideIcons.clock,
              label: l10n.collaborationDetailTimeLabel,
              value: collaboration.scheduledTime!,
            ),
          ],
          if (collaboration.businessOffer.venue) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _InfoRow(
              icon: LucideIcons.mapPin,
              label: l10n.collaborationDetailVenueLabel,
              value: l10n.collaborationDetailVenueValue(
                collaboration.businessPartner.name,
              ),
            ),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          _InfoRow(
            icon: LucideIcons.users,
            label: l10n.collaborationDetailCommunityReachLabel,
            value: collaboration.communityDeliverables.communityReach
                ? l10n.collaborationDetailReachIncluded
                : l10n.collaborationDetailReachNotSpecified,
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
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      icon: LucideIcons.users2,
      title: partner.isBusiness
          ? l10n.collaborationDetailBusinessPartner
          : l10n.collaborationDetailCommunityPartner,
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
                  color: context.colors.primary.withValues(alpha: 0.12),
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
                                color: context.colors.primary,
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
                            color: context.colors.primary,
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
                        color: context.colors.onSurface,
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
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (partner.city != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: context.colors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            partner.city!,
                            style: KolabingTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: context.colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
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

// =============================================================================
// Offers Section (What Business provides)
// =============================================================================

class _OffersSection extends StatelessWidget {
  const _OffersSection({required this.businessOffer, required this.isBusiness});

  final BusinessOffer businessOffer;
  final bool isBusiness;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_CheckItem>[];

    if (businessOffer.venue) {
      items.add(_CheckItem(l10n.collaborationDetailOfferVenue, true));
    }
    if (businessOffer.foodDrink) {
      items.add(_CheckItem(l10n.collaborationDetailOfferFoodDrink, true));
    }
    if (businessOffer.socialMediaExposure) {
      items.add(_CheckItem(l10n.collaborationDetailOfferSocialMedia, true));
    }
    if (businessOffer.contentCreation) {
      items.add(_CheckItem(l10n.collaborationDetailOfferContentCreation, true));
    }
    if (businessOffer.discount.enabled) {
      items.add(
        _CheckItem(
          l10n.collaborationDetailOfferDiscount(
            businessOffer.discount.percentage ?? 0,
          ),
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
      title: isBusiness
          ? l10n.collaborationDetailOffersTitleBusiness
          : l10n.collaborationDetailOffersTitleCommunity,
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
                      color: context.colors.success,
                    ),
                    const SizedBox(width: KolabingSpacing.xs),
                    Expanded(
                      child: Text(
                        item.label,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurface,
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
    final l10n = AppLocalizations.of(context);
    final items = <_CheckItem>[];

    if (deliverables.socialMediaContent) {
      items.add(_CheckItem(l10n.collaborationDetailDeliverableSocialContent, true));
    }
    if (deliverables.eventActivation) {
      items.add(_CheckItem(l10n.collaborationDetailDeliverableEventActivation, true));
    }
    if (deliverables.productPlacement) {
      items.add(_CheckItem(l10n.collaborationDetailDeliverableProductPlacement, true));
    }
    if (deliverables.communityReach) {
      items.add(_CheckItem(l10n.collaborationDetailDeliverableCommunityReach, true));
    }
    if (deliverables.reviewFeedback) {
      items.add(_CheckItem(l10n.collaborationDetailDeliverableReviewFeedback, true));
    }
    if (deliverables.other != null && deliverables.other!.isNotEmpty) {
      items.add(_CheckItem(deliverables.other!, true));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      icon: LucideIcons.megaphone,
      title: isBusiness
          ? l10n.collaborationDetailDeliverablesTitleBusiness
          : l10n.collaborationDetailDeliverablesTitleCommunity,
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
                      color: context.colors.info,
                    ),
                    const SizedBox(width: KolabingSpacing.xs),
                    Expanded(
                      child: Text(
                        item.label,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurface,
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

    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      icon: LucideIcons.contact,
      title: l10n.collaborationDetailContactTitle,
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
              label: l10n.collaborationDetailContactEmail,
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
        Icon(icon, size: 16, color: context.colors.textTertiary),
        const SizedBox(width: KolabingSpacing.xs),
        Text(
          '$label: ',
          style: KolabingTextStyles.captionSecondary.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: KolabingTextStyles.captionSecondary.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: KolabingSpacing.xxs),
          child: Row(
            children: [
              Icon(
                LucideIcons.gitBranch,
                size: 16,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                l10n.collaborationDetailProcessTitle,
                style: KolabingTextStyles.eyebrow.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textTertiary,
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
        context.colors.success,
        context.colors.success.withValues(alpha: 0.3),
        context.colors.onSurface,
      ),
      TimelineStepStatus.current => (
        context.colors.primary,
        context.colors.darkBorder,
        context.colors.onSurface,
      ),
      TimelineStepStatus.upcoming => (
        context.colors.darkBorder,
        context.colors.darkBorder,
        context.colors.textTertiary,
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
                            color: context.colors.primary.withValues(
                              alpha: 0.3,
                            ),
                            width: 3,
                          )
                        : null,
                  ),
                  child: step.status == TimelineStepStatus.completed
                      ? Icon(
                          LucideIcons.check,
                          size: 7,
                          color: context.colors.textOnDark,
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
                          ? context.colors.textTertiary
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                  if (step.date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(step.date!),
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: context.colors.textTertiary,
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: KolabingSpacing.xxs),
          child: Row(
            children: [
              Icon(
                LucideIcons.trophy,
                size: 16,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                l10n.collaborationDetailGamificationTitle,
                style: KolabingTextStyles.eyebrow.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                l10n.collaborationDetailSelectedCount(selectedIds.length),
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  color: context.colors.textTertiary,
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
            color: context.colors.softYellow,
            borderRadius: KolabingRadius.borderRadiusSm,
            border: Border.all(color: context.colors.softYellowBorder),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 14,
                color: context.colors.onPrimary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  l10n.collaborationDetailGamificationDescription,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: context.colors.onSurface,
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
          Padding(
            padding: EdgeInsets.all(KolabingSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(
                color: context.colors.primary,
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
                    l10n.collaborationDetailCustomChallengeSoon,
                    style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.textOnDark),
                  ),
                  backgroundColor: context.colors.onSurfaceVariant,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(
              l10n.collaborationDetailAddCustomChallenge,
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
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.trophy,
            size: 32,
            color: context.colors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            AppLocalizations.of(context).collaborationDetailNoChallengesTitle,
            style: KolabingTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            AppLocalizations.of(context).collaborationDetailNoChallengesBody,
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: context.colors.textTertiary,
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
        context.colors.activeText,
        context.colors.activeBg,
      ),
      ChallengeDifficulty.medium => (
        context.colors.pendingText,
        context.colors.pendingBg,
      ),
      ChallengeDifficulty.hard => (
        context.colors.errorText,
        context.colors.errorBg,
      ),
    };

    return Material(
      color: isSelected
          ? context.colors.primary.withValues(alpha: 0.06)
          : context.colors.surface,
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
                  ? context.colors.primary
                  : context.colors.darkBorder,
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
                      ? context.colors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? context.colors.primary
                        : context.colors.darkBorder,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        LucideIcons.check,
                        size: 14,
                        color: context.colors.onPrimary,
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
                              color: context.colors.onSurface,
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
                          color: context.colors.onSurfaceVariant,
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
                      color: context.colors.primary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).collaborationDetailPoints,
                    style: KolabingTextStyles.labelSmall.copyWith(
                      fontSize: 10,
                      color: context.colors.textTertiary,
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: KolabingSpacing.xxs),
          child: Row(
            children: [
              Icon(
                LucideIcons.qrCode,
                size: 16,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                l10n.collaborationDetailQrTitle,
                style: KolabingTextStyles.eyebrow.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textTertiary,
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
            color: context.colors.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            border: Border.all(color: context.colors.darkBorder),
          ),
          child: Column(
            children: [
              // QR placeholder
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(color: context.colors.darkBorder, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.qrCode,
                      size: 64,
                      color: context.colors.textTertiary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: KolabingSpacing.sm),
                    Text(
                      l10n.collaborationDetailQrPlaceholder,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.colors.textTertiary,
                      ),
                    ),
                    Text(
                      l10n.collaborationDetailQrGeneratedOnDay,
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: KolabingSpacing.md),

              Text(
                l10n.collaborationDetailQrDescription,
                style: KolabingTextStyles.captionSecondary.copyWith(
                  color: context.colors.onSurfaceVariant,
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
                            l10n.collaborationDetailQrUnavailable,
                            style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.textOnDark),
                          ),
                          backgroundColor: context.colors.onSurfaceVariant,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.qrCode, size: 18),
                  label: Text(
                    l10n.collaborationDetailViewQr,
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
        color: context.colors.surface,
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
              Icon(icon, size: 16, color: context.colors.textTertiary),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                title,
                style: KolabingTextStyles.eyebrow.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textTertiary,
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
        Icon(icon, size: 16, color: context.colors.textTertiary),
        const SizedBox(width: KolabingSpacing.xs),
        Text(
          '$label: ',
          style: KolabingTextStyles.captionSecondary.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: KolabingTextStyles.captionSecondary.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.softYellow,
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        border: Border.all(color: context.colors.softYellowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.lock,
                size: 18,
                color: context.colors.onPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.collaborationDetailResubscribeTitle,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.collaborationDetailResubscribeBody,
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: context.colors.onSurfaceVariant,
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
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.creditCard, size: 18),
              label: Text(
                l10n.collaborationDetailResubscribeCta,
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
    return Center(
      child: CircularProgressIndicator(color: context.colors.primary),
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
    final l10n = AppLocalizations.of(context);
    return Center(
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
              l10n.collaborationDetailLoadError,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            TextButton(
              onPressed: onRetry,
              child: Text(
                l10n.commonRetry,
                style: KolabingTextStyles.labelLarge.copyWith(
                  color: context.colors.primary,
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
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primary.withOpacity(0.12),
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.primaryDark.withOpacity(0.4)),
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
                  l10n.collaborationDetailTodayBannerTitle,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.collaborationDetailTodayBannerBody(partnerName),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
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
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isToday
            ? context.colors.primary.withOpacity(0.12)
            : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: isToday
              ? context.colors.primaryDark.withOpacity(0.4)
              : context.colors.darkBorder,
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
                isToday
                    ? l10n.collaborationDetailCompleteTitleToday
                    : l10n.collaborationDetailCompleteTitle,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? l10n.collaborationDetailCompleteBodyToday(partnerName)
                : l10n.collaborationDetailCompleteBody(partnerName),
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: context.colors.onSurfaceVariant,
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
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(KolabingRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                isToday
                    ? l10n.collaborationDetailMarkDone
                    : l10n.collaborationDetailItHappened,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
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
        color: hasReviewed ? context.colors.activeBg : context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: hasReviewed ? context.colors.activeBg : context.colors.darkBorder,
        ),
      ),
      child: hasReviewed
          ? _buildReviewed(context)
          : _buildUnreviewed(context, ref),
    );
  }

  Widget _buildReviewed(BuildContext context) => Row(
    children: [
      Icon(
        Icons.check_circle_rounded,
        color: context.colors.activeText,
        size: 18,
      ),
      const SizedBox(width: 8),
      Text(
        AppLocalizations.of(context).collaborationDetailReviewSubmitted,
        style: KolabingTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.activeText,
        ),
      ),
    ],
  );

  Widget _buildUnreviewed(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.collaborationDetailLeaveReview,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.15),
              borderRadius: KolabingRadius.borderRadiusRound,
            ),
            child: Text(
              l10n.collaborationDetailXpBadge,
              style: KolabingTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        l10n.collaborationDetailReviewHelp(partnerName),
        style: KolabingTextStyles.captionSecondary.copyWith(
          color: context.colors.onSurfaceVariant,
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
            elevation: 0,
          ),
          child: Text(
            l10n.collaborationDetailLeaveReviewCta,
            style: KolabingTextStyles.button,
          ),
        ),
      ),
    ],
    );
  }
}
