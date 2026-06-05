import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../opportunity/models/opportunity.dart';

/// Celebratory bottom sheet shown after a successful application submission.
///
/// Replaces the previous toast/snackbar approach with a focused success screen
/// that confirms the action, sets expectations ("we'll notify you"), and offers
/// two clear next steps: view applications or keep exploring.
class ApplySuccessSheet extends StatefulWidget {
  const ApplySuccessSheet({
    required this.opportunity,
    required this.onViewApplications,
    super.key,
  });

  final Opportunity opportunity;
  final VoidCallback onViewApplications;

  static Future<void> show(
    BuildContext context, {
    required Opportunity opportunity,
    required VoidCallback onViewApplications,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ApplySuccessSheet(
          opportunity: opportunity,
          onViewApplications: onViewApplications,
        ),
      );

  @override
  State<ApplySuccessSheet> createState() => _ApplySuccessSheetState();
}

class _ApplySuccessSheetState extends State<ApplySuccessSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _ringScale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _ringScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );
    _checkScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final creatorName =
        widget.opportunity.creatorProfile?.displayName ?? 'the host';

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        KolabingSpacing.lg,
        KolabingSpacing.sm,
        KolabingSpacing.lg,
        KolabingSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 6, bottom: KolabingSpacing.lg),
              decoration: BoxDecoration(
                color: context.colors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Hero check
          _Hero(
            ringScale: _ringScale,
            checkScale: _checkScale,
            reduceMotion: reduceMotion,
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Headline
          FadeTransition(
            opacity: reduceMotion ? const AlwaysStoppedAnimation(1) : _fade,
            child: Column(
              children: [
                Text(
                  'Application sent!',
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: context.colors.onSurface, height: 1.2),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  'Your application is on its way to $creatorName.',
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, color: context.colors.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Info card — sets expectations
          FadeTransition(
            opacity: reduceMotion ? const AlwaysStoppedAnimation(1) : _fade,
            child: Container(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.08),
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  const _InfoRow(
                    icon: LucideIcons.bell,
                    title: "We'll notify you",
                    body:
                        "You'll get a push notification the moment they review your application.",
                  ),
                  const SizedBox(height: KolabingSpacing.sm),
                  Container(
                    height: 1,
                    color: context.colors.primary.withValues(alpha: 0.18),
                  ),
                  const SizedBox(height: KolabingSpacing.sm),
                  const _InfoRow(
                    icon: LucideIcons.fileText,
                    title: 'Track in My Applications',
                    body:
                        'See status updates, message the host, and manage all your applications in one place.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Primary CTA — go to applications
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onViewApplications();
              },
              icon: const Icon(LucideIcons.fileText, size: 18),
              label: Text(
                'VIEW MY APPLICATIONS',
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.xs),

          // Secondary CTA — keep browsing
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'Keep exploring',
                style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.ringScale,
    required this.checkScale,
    required this.reduceMotion,
  });

  final Animation<double> ringScale;
  final Animation<double> checkScale;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final ring = reduceMotion ? const AlwaysStoppedAnimation(1.0) : ringScale;
    final check = reduceMotion ? const AlwaysStoppedAnimation(1.0) : checkScale;

    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft halo
          ScaleTransition(
            scale: ring,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.success.withValues(alpha: 0.12),
              ),
            ),
          ),
          // Inner solid disk
          ScaleTransition(
            scale: ring,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.success,
              ),
            ),
          ),
          // Animated check mark
          ScaleTransition(
            scale: check,
            child: const Icon(
              LucideIcons.check,
              size: 38,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.25),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: context.colors.onSurface),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface, height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      );
}
