import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../gamification/models/challenge.dart';
import '../../opportunity/models/opportunity.dart';
import '../../../widgets/blurred_identity.dart';
import '../models/collaboration.dart';
import '../models/collaboration_feedback.dart';
import '../providers/collaboration_detail_provider.dart';
import '../providers/collaboration_feedback_provider.dart';
import '../providers/collaborations_list_provider.dart';
import '../widgets/collaboration_feedback_sheet.dart';

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
    final isBusiness = user?.isBusiness ?? false;
    // Show the OTHER party. Uses the backend `my_role` when available (always
    // correct) so a community viewer is never shown their own side.
    final partner = collaboration.partnerForViewer(
      isBusinessViewer: isBusiness,
    );

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
              color: KolabingColors.textPrimary,
            ),
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
              icon: const Icon(
                LucideIcons.moreVertical,
                color: KolabingColors.textSecondary,
              ),
              onPressed: () {},
            ),
          ],
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
                  // While re-gated, suppress interactive actions (finish, edit,
                  // profile tap) — they would be illegible/blocked anyway.
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

        // Finish action (both parties). Requires feedback before it can
        // complete — see _FinishCollaborationSection. Hidden while
        // re-gated (interactive == false).
        if (interactive &&
            (collaboration.status == CollaborationStatus.scheduled ||
                collaboration.status == CollaborationStatus.inProgress))
          _FinishCollaborationSection(collaborationId: collaborationId),

        // Post-completion: BOTH parties must review. Whoever has not yet left
        // feedback (e.g. the business after the community already completed) is
        // prompted here — the sheet also auto-opens so it is not silently
        // skipped. Hidden once this viewer's feedback row exists.
        if (interactive &&
            collaboration.status == CollaborationStatus.completed &&
            !collaboration.viewerHasSubmittedFeedback)
          _LeaveReviewSection(
            collaborationId: collaborationId,
            variant: isBusiness
                ? FeedbackVariant.business
                : FeedbackVariant.community,
          ),

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
      helpText: 'Reschedule Kolab',
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
            style: GoogleFonts.openSans(color: Colors.white),
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
            style: GoogleFonts.openSans(color: Colors.white),
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
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
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
                          const Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: KolabingColors.textTertiary,
                          ),
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
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textPrimary,
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
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textPrimary,
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
              const Icon(
                LucideIcons.gitBranch,
                size: 16,
                color: KolabingColors.textTertiary,
              ),
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
  const _TimelineStepWidget({required this.step, required this.isLast});

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
                          color: Colors.white,
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
              const Icon(
                LucideIcons.trophy,
                size: 16,
                color: KolabingColors.textTertiary,
              ),
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
                  color: isSelected
                      ? KolabingColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? KolabingColors.primary
                        : KolabingColors.border,
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
                  border: Border.all(color: KolabingColors.border, width: 2),
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
                      borderRadius: BorderRadius.circular(KolabingRadius.md),
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
                style: GoogleFonts.dmSans(
                  fontSize: 12,
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
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your subscription has lapsed, so this ongoing Kolab and its '
            'chat are paused on your side. The community keeps full access. '
            'Resubscribe to pick up where you left off.',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: KolabingColors.textSecondary,
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
                style: GoogleFonts.dmSans(
                  fontSize: 14,
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
              'Failed to load Kolab',
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

// =============================================================================
// D3: Finish Collaboration section
// =============================================================================

class _FinishCollaborationSection extends ConsumerStatefulWidget {
  const _FinishCollaborationSection({required this.collaborationId});

  final String collaborationId;

  @override
  ConsumerState<_FinishCollaborationSection> createState() =>
      _FinishCollaborationSectionState();
}

class _FinishCollaborationSectionState
    extends ConsumerState<_FinishCollaborationSection> {
  bool _isSubmitting = false;

  /// Finishing a collaboration REQUIRES feedback (docs §4). The flow is:
  ///   1. confirm intent,
  ///   2. open the feedback sheet for the caller's role variant — finish is
  ///      BLOCKED until the required questions (star + recommend) are filled,
  ///   3. submit feedback + finish together via the single `/finish` call.
  /// If the user backs out of the sheet, nothing is finished and no feedback is
  /// sent — feedback truly gates the finish action.
  Future<void> _confirmAndFinish() async {
    final isBusiness = ref.read(authProvider).user?.isBusiness ?? false;
    final variant = isBusiness
        ? FeedbackVariant.business
        : FeedbackVariant.community;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Finish Kolab?',
          style: GoogleFonts.rubik(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'To finish, share a quick review of how it went. Both parties will '
          'then see this Kolab in the Completed list.',
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: KolabingColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: KolabingColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Required feedback gate: collect (but don't submit) the draft. Returns
    // null if the user dismissed the sheet — in which case we do NOT finish.
    final draft = await CollaborationFeedbackSheet.collectForFinish(
      context,
      collaborationId: widget.collaborationId,
      variant: variant,
    );
    if (draft == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      // Submit feedback + finish in one call. Falls back to the legacy
      // complete endpoint only if the new finish route isn't deployed yet.
      try {
        await finishCollaborationWithFeedback(widget.collaborationId, draft);
      } on FeedbackEndpointMissingException {
        // Finish route not live yet: complete via the legacy endpoint and
        // submit the feedback separately so the user isn't blocked.
        await markCollaborationCompleted(widget.collaborationId);
        try {
          await submitCollaborationFeedback(widget.collaborationId, draft);
        } on FeedbackEndpointMissingException {
          // Both endpoints pending — completion still succeeded.
        }
      }
      if (!mounted) return;
      // Refresh the detail AND the My Kolabs lists so the collaboration moves
      // from Active to Finished immediately (previously required an app restart).
      ref.invalidate(collaborationDetailProvider(widget.collaborationId));
      ref.invalidate(collaborationsListProvider(CollaborationsFilter.active));
      ref.invalidate(collaborationsListProvider(CollaborationsFilter.finished));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kolab finished. Thanks for the feedback!',
            style: GoogleFonts.openSans(color: Colors.white),
          ),
          backgroundColor: KolabingColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not finish Kolab: $e',
            style: GoogleFonts.openSans(color: Colors.white),
          ),
          backgroundColor: KolabingColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.lg),
    child: SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _confirmAndFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: KolabingColors.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KolabingRadius.md),
          ),
          elevation: 0,
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(LucideIcons.checkCircle, size: 18),
        label: Text(
          _isSubmitting ? 'FINISHING…' : 'FINISH & MARK COMPLETE',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// Post-completion: "Leave review" entry point
// =============================================================================

class _LeaveReviewSection extends ConsumerStatefulWidget {
  const _LeaveReviewSection({
    required this.collaborationId,
    required this.variant,
  });

  final String collaborationId;
  final FeedbackVariant variant;

  @override
  ConsumerState<_LeaveReviewSection> createState() =>
      _LeaveReviewSectionState();
}

class _LeaveReviewSectionState extends ConsumerState<_LeaveReviewSection> {
  bool _autoPrompted = false;

  @override
  void initState() {
    super.initState();
    // Enforce two-sided feedback: when the viewer opens a completed Kolab they
    // have not reviewed, auto-open the feedback sheet once so it is not silently
    // skipped. The persistent CTA below remains until they submit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoPrompted && mounted) {
        _autoPrompted = true;
        _openSheet();
      }
    });
  }

  Future<void> _openSheet() async {
    final submitted = await CollaborationFeedbackSheet.show(
      context,
      collaborationId: widget.collaborationId,
      variant: widget.variant,
    );
    if (submitted && mounted) {
      ref.invalidate(collaborationDetailProvider(widget.collaborationId));
      ref.invalidate(collaborationsListProvider(CollaborationsFilter.active));
      ref.invalidate(collaborationsListProvider(CollaborationsFilter.finished));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = widget.variant.isBusiness;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.lg),
      child: Container(
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
                  LucideIcons.messageSquare,
                  size: 18,
                  color: KolabingColors.onPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your feedback is required',
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isBusiness
                  ? 'The community already wrapped this Kolab. Add your review to '
                        'complete it — it helps other businesses pick the right communities.'
                  : 'Add your review to complete this Kolab — it helps other '
                        'communities pick the right businesses.',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _openSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KolabingRadius.md),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.star, size: 18),
                label: Text(
                  'ADD YOUR FEEDBACK',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
