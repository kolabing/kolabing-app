import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/api.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../auth/services/auth_service.dart';

/// Lightweight post-completion review sheet.
///
/// Collects: star rating (required), short text (optional), would-Kolab-again (optional).
/// Submits to POST /collaborations/{id}/review.
/// Awards +10 XP server-side on first submission.
///
/// Usage:
///   final submitted = await KolabReviewSheet.show(context, collaborationId: id);
class KolabReviewSheet extends StatefulWidget {
  const KolabReviewSheet({
    required this.collaborationId,
    required this.partnerName,
    super.key,
  });

  final String collaborationId;
  final String partnerName;

  /// Shows the sheet and returns true if the review was submitted.
  static Future<bool> show(
    BuildContext context, {
    required String collaborationId,
    required String partnerName,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KolabReviewSheet(
        collaborationId: collaborationId,
        partnerName: partnerName,
      ),
    );
    return result == true;
  }

  @override
  State<KolabReviewSheet> createState() => _KolabReviewSheetState();
}

class _KolabReviewSheetState extends State<KolabReviewSheet> {
  int? _rating;
  bool? _wouldCollabAgain;
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _rating != null && !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null || token.isEmpty) throw Exception('Session expired.');

      final body = _bodyController.text.trim();
      final payload = <String, dynamic>{
        'rating': _rating,
        if (body.isNotEmpty) 'body': body,
        if (_wouldCollabAgain != null)
          'would_collaborate_again': _wouldCollabAgain,
      };

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/collaborations/${widget.collaborationId}/review',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      if (response.statusCode == 401) {
        await authService.refreshSession();
        // Re-attempt once after refresh
        final retryToken = await authService.getToken();
        final retry = await http.post(
          Uri.parse(
            '${ApiConfig.baseUrl}/collaborations/${widget.collaborationId}/review',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $retryToken',
          },
          body: jsonEncode(payload),
        );
        if (retry.statusCode == 200 || retry.statusCode == 201) {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      }

      throw Exception('Something went wrong. Please try again.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(KolabingRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        KolabingSpacing.lg,
        KolabingSpacing.lg,
        KolabingSpacing.lg,
        KolabingSpacing.lg + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.darkBorder,
                borderRadius: KolabingRadius.borderRadiusRound,
              ),
            ),
          ),

          // Title
          Text(
            l10n.kolabReviewSheetTitle,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.kolabReviewSheetSubtitle(widget.partnerName),
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Star rating
          _StarRating(
            value: _rating,
            onChanged: (v) => setState(() => _rating = v),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Optional text
          TextField(
            controller: _bodyController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: l10n.kolabReviewSheetCommentHint,
              hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.textTertiary,
              ),
              filled: true,
              fillColor: context.colors.background,
              border: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: BorderSide(color: context.colors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: KolabingRadius.borderRadiusMd,
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 1.5,
                ),
              ),
              counterStyle: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Would collaborate again
          _WouldCollabRow(
            value: _wouldCollabAgain,
            onChanged: (v) => setState(() => _wouldCollabAgain = v),
          ),

          if (_error != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              _error!,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: KolabingSpacing.lg),

          // Submit CTA
          KolabingButton(
            label: l10n.kolabReviewSheetSubmitXp,
            onPressed: _canSubmit ? _submit : null,
            variant: KolabingButtonVariant.primary,
            isLoading: _isSubmitting,
            isDisabled: !_canSubmit,
          ),

          const SizedBox(height: KolabingSpacing.xs),

          // Skip
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.kolabReviewSheetSkip,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Star Rating
// =============================================================================

class _StarRating extends StatelessWidget {
  const _StarRating({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = value != null && star <= value!;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              filled ? LucideIcons.star : LucideIcons.star,
              size: 36,
              color: filled
                  ? context.colors.primary
                  : context.colors.darkBorder,
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Would Collaborate Again toggle
// =============================================================================

class _WouldCollabRow extends StatelessWidget {
  const _WouldCollabRow({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          l10n.kolabReviewSheetWouldAgain,
          style: KolabingTextStyles.bodyMedium.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const Spacer(),
        _ToggleChip(
          label: l10n.kolabReviewSheetYes,
          selected: value == true,
          onTap: () => onChanged(value == true ? null : true),
        ),
        const SizedBox(width: KolabingSpacing.xs),
        _ToggleChip(
          label: l10n.kolabReviewSheetNo,
          selected: value == false,
          onTap: () => onChanged(value == false ? null : false),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary
              : context.colors.background,
          borderRadius: KolabingRadius.borderRadiusRound,
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: KolabingTextStyles.labelSmall.copyWith(
            color: selected
                ? context.colors.onPrimary
                : context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
