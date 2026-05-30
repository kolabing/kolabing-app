import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../enums/intent_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

/// Step 6 (venue / product flows): Review & Publish.
///
/// Designed to make the user feel "everything is ready":
/// 1. Hero preview card — mirrors how the listing will appear in Explore.
/// 2. Readiness banner — explicit "ready to publish" reassurance.
/// 3. Compact section cards with green checkmarks for filled sections,
///    amber for skipped optional sections, tappable to edit.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final notifier = ref.read(kolabFormProvider.notifier);
    final isVenue = formState.intentType == IntentType.venuePromotion;

    final sections = _sectionsFor(kolab, isVenue, notifier);
    final missingCount = sections.where((s) => s.status == _Status.missing).length;
    final readyToPublish = missingCount == 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.xxl,
      ),
      children: [
        // Hero preview — what communities will see
        _PreviewCard(kolab: kolab, isVenue: isVenue),
        const SizedBox(height: KolabingSpacing.md),

        // Readiness status banner
        _StatusBanner(
          ready: readyToPublish,
          missingCount: missingCount,
        ),
        const SizedBox(height: KolabingSpacing.lg),

        Text(
          'CHECKLIST',
          style: GoogleFonts.rubik(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: KolabingColors.textTertiary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Section checklist cards
        ...sections.map((section) => Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: _SectionCard(section: section),
            )),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section composition
  // ---------------------------------------------------------------------------

  List<_Section> _sectionsFor(
    Kolab kolab,
    bool isVenue,
    KolabFormNotifier notifier,
  ) {
    final sections = <_Section>[];

    // Step 0 — Details
    if (isVenue) {
      // Step 0 only collects campaign copy; venue meta is inherited from the
      // business onboarding profile and is not editable here. Status is based
      // on the user-editable fields only — venue meta is shown for context.
      final copyFilled =
          kolab.title.isNotEmpty && kolab.description.isNotEmpty;
      final hasVenueMeta = (kolab.venueName?.isNotEmpty ?? false) &&
          kolab.venueType != null &&
          (kolab.capacity ?? 0) > 0;

      final summary = copyFilled
          ? hasVenueMeta
              ? '${kolab.venueName} • ${kolab.venueType?.displayName} • ${kolab.capacity} guests'
              : kolab.title
          : 'Add a campaign title and description';
      final secondary = copyFilled && hasVenueMeta
          ? [
              if (kolab.venueAddress?.isNotEmpty ?? false) kolab.venueAddress!,
              if (kolab.preferredCity.isNotEmpty) kolab.preferredCity,
            ].join(', ')
          : null;

      sections.add(_Section(
        icon: LucideIcons.building2,
        title: 'Campaign & Venue',
        status: copyFilled ? _Status.complete : _Status.missing,
        summary: summary,
        secondary: secondary?.isNotEmpty == true ? secondary : null,
        onTap: () => notifier.goToStep(0),
      ));
    } else {
      final fieldsFilled = kolab.title.isNotEmpty &&
          kolab.description.isNotEmpty &&
          (kolab.productName?.isNotEmpty ?? false) &&
          kolab.productType != null &&
          kolab.preferredCity.isNotEmpty;

      sections.add(_Section(
        icon: LucideIcons.package,
        title: 'Product Details',
        status: fieldsFilled ? _Status.complete : _Status.missing,
        summary: fieldsFilled
            ? '${kolab.productName} • ${kolab.productType?.displayName}'
            : 'Tap to fill product details',
        secondary: fieldsFilled ? kolab.preferredCity : null,
        onTap: () => notifier.goToStep(0),
      ));
    }

    // Step 1 — Media
    final photoCount = kolab.media.where((m) => m.type == 'image').length;
    sections.add(_Section(
      icon: LucideIcons.image,
      title: 'Media',
      status: photoCount > 0 ? _Status.complete : _Status.missing,
      summary: photoCount > 0
          ? '$photoCount photo${photoCount == 1 ? '' : 's'} added'
          : 'Add at least 1 photo',
      onTap: () => notifier.goToStep(1),
    ));

    // Step 2 — Offering
    sections.add(_Section(
      icon: LucideIcons.gift,
      title: 'Offering',
      status: kolab.offering.isNotEmpty ? _Status.complete : _Status.missing,
      summary: kolab.offering.isNotEmpty
          ? _formatOffering(kolab.offering)
          : 'Pick what you offer',
      onTap: () => notifier.goToStep(2),
    ));

    // Step 3 — Ideal community (optional)
    final hasIdealCommunity = kolab.seekingCommunities.isNotEmpty ||
        kolab.minCommunitySize != null ||
        kolab.expects.isNotEmpty;
    sections.add(_Section(
      icon: LucideIcons.users,
      title: 'Ideal Community',
      status: hasIdealCommunity ? _Status.complete : _Status.optional,
      summary: hasIdealCommunity
          ? _summarizeIdealCommunity(kolab)
          : 'Optional — leave open to all',
      onTap: () => notifier.goToStep(3),
    ));

    // Step 4 — Past events (optional)
    sections.add(_Section(
      icon: LucideIcons.history,
      title: 'Past Collaborations',
      status: kolab.pastEvents.isNotEmpty ? _Status.complete : _Status.optional,
      summary: kolab.pastEvents.isNotEmpty
          ? '${kolab.pastEvents.length} event${kolab.pastEvents.length == 1 ? '' : 's'} added'
          : 'Optional — adds credibility',
      onTap: () => notifier.goToStep(4),
    ));

    // Step 5 — Availability
    sections.add(_Section(
      icon: LucideIcons.calendar,
      title: 'Availability',
      status: kolab.availabilityMode != null ? _Status.complete : _Status.missing,
      summary: kolab.availabilityMode != null
          ? _summarizeAvailability(kolab)
          : 'Set when you are available',
      onTap: () => notifier.goToStep(5),
    ));

    return sections;
  }

  static String _formatOffering(List<String> items) {
    const labels = <String, String>{
      'venue': 'Venue',
      'food_drink': 'Food & Drink',
      'discount': 'Discount',
      'products': 'Products',
      'social_media': 'Social Media',
      'content_creation': 'Content',
      'sponsorship': 'Sponsorship',
      'other': 'Other',
    };
    final labelled = items.map((i) => labels[i] ?? i).toList();
    if (labelled.length <= 3) return labelled.join(' • ');
    return '${labelled.take(2).join(' • ')} +${labelled.length - 2} more';
  }

  static String _summarizeIdealCommunity(Kolab kolab) {
    final parts = <String>[];
    if (kolab.seekingCommunities.isNotEmpty) {
      final s = kolab.seekingCommunities;
      parts.add(s.length <= 2 ? s.join(' • ') : '${s.take(2).join(' • ')} +${s.length - 2}');
    }
    if (kolab.minCommunitySize != null) {
      parts.add('Min ${kolab.minCommunitySize}+');
    }
    return parts.isEmpty ? 'Open to all' : parts.join(' • ');
  }

  static String _summarizeAvailability(Kolab kolab) {
    final mode = kolab.availabilityMode!.displayName;
    final parts = <String>[mode];
    if (kolab.availabilityStart != null && kolab.availabilityEnd != null) {
      final fmt = DateFormat('MMM d');
      parts.add(
        '${fmt.format(kolab.availabilityStart!)} – ${DateFormat('MMM d, yyyy').format(kolab.availabilityEnd!)}',
      );
    } else if (kolab.availabilityStart != null) {
      parts.add('From ${DateFormat('MMM d, yyyy').format(kolab.availabilityStart!)}');
    }
    if (kolab.selectedTime != null) {
      parts.add(
        '${kolab.selectedTime!.hour.toString().padLeft(2, '0')}:${kolab.selectedTime!.minute.toString().padLeft(2, '0')}',
      );
    }
    return parts.join(' • ');
  }
}

// =============================================================================
// Preview card — mimics how the listing appears in Explore
// =============================================================================

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.kolab, required this.isVenue});

  final Kolab kolab;
  final bool isVenue;

  @override
  Widget build(BuildContext context) {
    final media = kolab.media.where((m) => m.type == 'image').toList();
    final coverUrl = media.isNotEmpty ? media.first.url : null;

    final headline = isVenue
        ? (kolab.venueName?.isNotEmpty ?? false)
            ? kolab.venueName!
            : kolab.title
        : (kolab.productName?.isNotEmpty ?? false)
            ? kolab.productName!
            : kolab.title;

    final subhead = isVenue
        ? [
            kolab.venueType?.displayName,
            if (kolab.capacity != null) '${kolab.capacity} guests',
          ].whereType<String>().join(' • ')
        : kolab.productType?.displayName ?? '';

    return Container(
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _CoverImage(url: coverUrl),
          ),

          Padding(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Eyebrow tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: KolabingColors.softYellow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: KolabingColors.softYellowBorder),
                  ),
                  child: Text(
                    isVenue ? 'VENUE PROMOTION' : 'PRODUCT PROMOTION',
                    style: GoogleFonts.rubik(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: KolabingColors.accentOrangeText,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),

                // Headline
                Text(
                  headline.isNotEmpty ? headline : 'Untitled kolab',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: KolabingColors.onSurface,
                  ),
                ),

                if (subhead.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subhead,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: KolabingColors.onSurfaceVariant,
                    ),
                  ),
                ],

                if (kolab.description.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.sm),
                  Text(
                    kolab.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      height: 1.5,
                      color: KolabingColors.onSurfaceVariant,
                    ),
                  ),
                ],

                if (kolab.preferredCity.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: KolabingColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        kolab.preferredCity,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.onSurfaceVariant,
                        ),
                      ),
                    ],
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

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: KolabingColors.surfaceVariant,
        child: const Center(
          child: Icon(
            LucideIcons.image,
            size: 32,
            color: KolabingColors.textTertiary,
          ),
        ),
      );
    }
    if (url!.startsWith('http')) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.file(
      File(url!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: KolabingColors.surfaceVariant,
        child: const Center(
          child: Icon(
            LucideIcons.imageOff,
            size: 28,
            color: KolabingColors.textTertiary,
          ),
        ),
      );
}

// =============================================================================
// Status banner
// =============================================================================

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.ready, required this.missingCount});

  final bool ready;
  final int missingCount;

  @override
  Widget build(BuildContext context) {
    final bg = ready
        ? KolabingColors.success.withValues(alpha: 0.16)
        : KolabingColors.warning.withValues(alpha: 0.16);
    final border = ready
        ? KolabingColors.success.withValues(alpha: 0.4)
        : KolabingColors.warning.withValues(alpha: 0.4);
    final iconColor =
        ready ? const Color(0xFF1A8C46) : KolabingColors.accentOrangeText;
    final icon = ready ? LucideIcons.checkCircle : LucideIcons.alertCircle;
    final title = ready
        ? 'Ready to publish'
        : 'Almost ready — $missingCount step${missingCount == 1 ? '' : 's'} left';
    final subtitle = ready
        ? 'Your listing will appear in Explore for matching communities.'
        : 'Tap any incomplete card below to finish.';

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
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
// Section card
// =============================================================================

enum _Status { complete, missing, optional }

class _Section {
  const _Section({
    required this.icon,
    required this.title,
    required this.status,
    required this.summary,
    required this.onTap,
    this.secondary,
  });

  final IconData icon;
  final String title;
  final _Status status;
  final String summary;
  final String? secondary;
  final VoidCallback onTap;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg, IconData icon}) badge = switch (section.status) {
      _Status.complete => (
          bg: KolabingColors.success.withValues(alpha: 0.18),
          fg: const Color(0xFF1A8C46),
          icon: LucideIcons.check,
        ),
      _Status.missing => (
          bg: KolabingColors.error.withValues(alpha: 0.14),
          fg: KolabingColors.error,
          icon: LucideIcons.alertCircle,
        ),
      _Status.optional => (
          bg: KolabingColors.surfaceVariant,
          fg: KolabingColors.textTertiary,
          icon: LucideIcons.minus,
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: section.onTap,
        borderRadius: KolabingRadius.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(
              color: section.status == _Status.missing
                  ? KolabingColors.error.withValues(alpha: 0.3)
                  : KolabingColors.darkBorder,
            ),
          ),
          child: Row(
            children: [
              // Status badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badge.bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(badge.icon, color: badge.fg, size: 18),
              ),
              const SizedBox(width: KolabingSpacing.sm),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          section.icon,
                          size: 14,
                          color: KolabingColors.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          section.title,
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      section.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: section.status == _Status.missing
                            ? KolabingColors.error
                            : KolabingColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    if (section.secondary != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        section.secondary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: KolabingSpacing.xs),
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
