import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../opportunity/models/opportunity.dart';

class OpportunityPublishSuccessDialog extends StatelessWidget {
  const OpportunityPublishSuccessDialog({
    required this.isDraft,
    required this.onViewOpportunities,
    super.key,
    this.opportunity,
    this.onShare,
  });

  final bool isDraft;
  final Opportunity? opportunity;
  final VoidCallback? onShare;
  final VoidCallback onViewOpportunities;

  @override
  Widget build(BuildContext context) {
    final canShare =
        !isDraft && onShare != null && (opportunity?.id?.isNotEmpty ?? false);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: KolabingRadius.borderRadiusLg,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: KolabingColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle,
              size: 48,
              color: KolabingColors.success,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            isDraft ? 'Draft Saved!' : 'Opportunity Published!',
            style: GoogleFonts.rubik(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: KolabingColors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            isDraft
                ? 'Your opportunity has been saved as a draft. You can edit and publish it later.'
                : 'Your opportunity is now live. Businesses can start applying!',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        if (canShare)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onShare,
              child: const Text('SHARE'),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onViewOpportunities,
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
            ),
            child: Text(
              'VIEW MY OPPORTUNITIES',
              style: GoogleFonts.dmSans(
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
