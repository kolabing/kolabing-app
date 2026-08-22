import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/checkin_provider.dart';
import '../services/checkin_service.dart';

/// Screen displaying QR code for event check-in (organizer view)
class EventQRCodeScreen extends ConsumerWidget {
  const EventQRCodeScreen({super.key, required this.eventId, this.eventName});

  final String eventId;
  final String? eventName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrTokenAsync = ref.watch(qrTokenProvider(eventId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? context.colors.surface : context.colors.background;
    final textColor = isDark
        ? context.colors.textOnDark
        : context.colors.onSurface;
    final surfaceColor = isDark
        ? context.colors.darkSurface
        : context.colors.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppLocalizations.of(context).eventQrTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: textColor),
            onPressed: qrTokenAsync.isLoading
                ? null
                : () => ref.invalidate(qrTokenProvider(eventId)),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Event name
              if (eventName != null) ...[
                Text(
                  eventName!,
                  style: KolabingTextStyles.bodyLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KolabingSpacing.md),
              ],

              // QR Code container
              Container(
                padding: const EdgeInsets.all(KolabingSpacing.lg),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? context.colors.darkBorder
                        : context.colors.darkBorder,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: qrTokenAsync.when(
                  data: (token) => _buildQRCode(context, ref, token),
                  loading: () => _buildLoadingState(context),
                  error: (error, _) => _buildErrorState(context, ref, error),
                ),
              ),

              const SizedBox(height: KolabingSpacing.xl),

              // Instructions
              Container(
                padding: const EdgeInsets.all(KolabingSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 20,
                      color: context.colors.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).eventQrInstructions,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? context.colors.textOnDark
                              : context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // NOTE: a "View check-ins" button used to sit here, pushing a
              // hardcoded /attendee/events/{id}/checkins path. That route was
              // never registered and the screen never existed, so it led to the
              // router's error page — invisible while this screen itself was
              // unreachable. The leader already has the roster on the event hub
              // (`_AttendeesSection`); a dedicated check-ins screen is tracked
              // separately (`eventCheckinsProvider` is ready for it).
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.colors.primary),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).eventQrGenerating,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Localized copy for a token-generation failure.
  ///
  /// Never `error.toString()`: that renders the exception's type name and its
  /// untranslated backend message straight into the UI.
  String _errorMessage(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is CheckinException &&
        error.kind == CheckinFailure.unauthorized) {
      return l10n.eventQrNotAuthorized;
    }
    return l10n.commonErrorGeneric;
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: context.colors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).eventQrErrorTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              _errorMessage(context, error),
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton.icon(
              onPressed: () => ref.invalidate(qrTokenProvider(eventId)),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(AppLocalizations.of(context).commonTryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode(BuildContext context, WidgetRef ref, String token) {
    return Column(
      children: [
        // QR Code
        Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: token,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: KolabingSpacing.md),

        // Copy token button
        TextButton.icon(
          onPressed: () => _copyToken(context, token),
          icon: const Icon(LucideIcons.copy, size: 16),
          label: Text(AppLocalizations.of(context).eventQrCopyToken),
        ),
      ],
    );
  }

  void _copyToken(BuildContext context, String token) {
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).eventQrTokenCopied),
        backgroundColor: context.colors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.md),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
