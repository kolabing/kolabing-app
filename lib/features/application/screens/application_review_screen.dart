import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../auth/models/auth_response.dart';
import '../../opportunity/models/opportunity.dart';
import '../models/application.dart';
import '../providers/application_provider.dart';
import '../../../widgets/category_icon.dart';

/// Application review screen — shown when tapping a received application.
/// Displays the applicant's profile like a "CV card" with their message,
/// availability, and Accept / Decline actions.
/// After accepting, navigates to the chat screen.
class ApplicationReviewScreen extends ConsumerStatefulWidget {
  const ApplicationReviewScreen({
    super.key,
    required this.applicationId,
  });

  final String applicationId;

  @override
  ConsumerState<ApplicationReviewScreen> createState() =>
      _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState
    extends ConsumerState<ApplicationReviewScreen> {
  bool _isAccepting = false;
  bool _isDeclining = false;

  @override
  Widget build(BuildContext context) {
    final asyncApplication =
        ref.watch(applicationDetailProvider(widget.applicationId));

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: KolabingColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'APPLICATION',
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: KolabingColors.onSurface,
          ),
        ),
      ),
      body: asyncApplication.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KolabingColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertCircle,
                    size: 48, color: KolabingColors.error),
                const SizedBox(height: KolabingSpacing.md),
                Text(
                  'Failed to load application',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onSurface,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),
                TextButton(
                  onPressed: () => ref.invalidate(
                      applicationDetailProvider(widget.applicationId)),
                  child: Text('Retry',
                      style: KolabingTextStyles.labelLarge.copyWith(
                          color: KolabingColors.primary)),
                ),
              ],
            ),
          ),
        ),
        data: (application) {
          if (application == null) {
            return const Center(child: Text('Application not found'));
          }
          return _buildContent(application);
        },
      ),
    );
  }

  Widget _buildContent(Application application) {
    final profile = application.applicantProfile;
    final opportunity = application.opportunity;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Opportunity header
                _buildOpportunityHeader(opportunity),
                const SizedBox(height: KolabingSpacing.md),

                // Applicant CV card
                _buildApplicantCard(profile, application),
                const SizedBox(height: KolabingSpacing.md),

                // Application message
                _buildSection(
                  icon: LucideIcons.messageSquare,
                  title: 'Message',
                  child: Text(
                    application.message.isNotEmpty
                        ? application.message
                        : 'No message provided',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: application.message.isNotEmpty
                          ? KolabingColors.onSurface
                          : KolabingColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.md),

                // Availability
                _buildSection(
                  icon: LucideIcons.calendar,
                  title: 'Availability',
                  child: Text(
                    application.availability.isNotEmpty
                        ? application.availability
                        : 'Not specified',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: application.availability.isNotEmpty
                          ? KolabingColors.onSurface
                          : KolabingColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.md),

                // Applied date
                _buildSection(
                  icon: LucideIcons.clock,
                  title: 'Applied',
                  child: Text(
                    application.createdAtDisplay,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.onSurfaceVariant,
                    ),
                  ),
                ),

                // Status info if already decided
                if (application.status.isFinal) ...[
                  const SizedBox(height: KolabingSpacing.md),
                  _buildStatusInfo(application),
                ],

                const SizedBox(height: KolabingSpacing.xl),
              ],
            ),
          ),
        ),

        // Bottom action bar
        _buildActionBar(application),
      ],
    );
  }

  Widget _buildOpportunityHeader(Opportunity? opportunity) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.softYellow,
        borderRadius: KolabingRadius.borderRadiusSm,
        border: Border.all(color: KolabingColors.softYellowBorder),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.briefcase, size: 18, color: KolabingColors.onPrimary),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              opportunity?.title ?? 'Unknown Opportunity',
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: KolabingColors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(
      ApplicantProfile? profile, Application application) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: KolabingColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: profile?.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      profile!.avatarUrl!,
                      fit: BoxFit.cover,
                      width: 72,
                      height: 72,
                      errorBuilder: (_, _, _) => _avatarFallback(profile),
                    ),
                  )
                : _avatarFallback(profile),
          ),
          const SizedBox(height: KolabingSpacing.sm),

          // Name
          Text(
            profile?.displayName ?? application.applicantName,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: KolabingColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          // Category
          if (profile?.category != null && profile!.category!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: KolabingColors.accentOrange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryIcon(name: profile.category!, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    profile.category!,
                    style: KolabingTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.accentOrangeText,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // City
          if (profile?.city != null && profile!.city!.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.mapPin,
                    size: 14, color: KolabingColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  profile.city!,
                  style: KolabingTextStyles.captionSecondary.copyWith(
                    color: KolabingColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // View profile link
          const SizedBox(height: KolabingSpacing.sm),
          GestureDetector(
            onTap: () {
              final profileId = profile?.id ?? application.applicantId;
              if (profileId.isNotEmpty) {
                context.push('/profile/$profileId');
              }
            },
            child: Text(
              'View Full Profile',
              style: KolabingTextStyles.captionSecondary.copyWith(
                fontWeight: FontWeight.w600,
                color: KolabingColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: KolabingColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(ApplicantProfile? profile) {
    final initial = profile?.initial ?? '?';
    return Center(
      child: Text(
        initial,
        style: KolabingTextStyles.bodyLarge.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: KolabingColors.primary,
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
            ],
          ),
          const SizedBox(height: KolabingSpacing.xs),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusInfo(Application application) {
    final (icon, color, label, description) = switch (application.status) {
      ApplicationStatus.accepted => (
          LucideIcons.checkCircle,
          KolabingColors.success,
          'Accepted',
          'This application has been accepted. You can chat with the applicant.',
        ),
      ApplicationStatus.declined => (
          LucideIcons.xCircle,
          KolabingColors.error,
          'Declined',
          application.declineReason != null
              ? 'Declined: ${application.declineReason}'
              : 'This application has been declined.',
        ),
      ApplicationStatus.withdrawn => (
          LucideIcons.minusCircle,
          KolabingColors.textTertiary,
          'Withdrawn',
          'The applicant has withdrawn their application.',
        ),
      _ => (
          LucideIcons.clock,
          KolabingColors.pendingText,
          'Pending',
          '',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: KolabingTextStyles.captionSecondary.copyWith(
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

  Widget _buildActionBar(Application application) {
    // If already decided, show a "Go to Chat" button
    if (application.status.isAccepted) {
      return _buildBottomBar(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () =>
                context.push('/application/${application.id}/chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(LucideIcons.messageCircle, size: 18),
            label: Text(
              'OPEN CHAT',
              style: KolabingTextStyles.button.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    }

    // If declined or withdrawn, show info only
    if (application.status.isFinal) {
      return const SizedBox.shrink();
    }

    // Pending — show Accept / Decline buttons
    return _buildBottomBar(
      child: Row(
        children: [
          // Decline button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed:
                    _isDeclining || _isAccepting
                        ? null
                        : () => _showDeclineDialog(application),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KolabingColors.error,
                  side: const BorderSide(color: KolabingColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isDeclining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: KolabingColors.error),
                      )
                    : const Icon(LucideIcons.x, size: 18),
                label: Text(
                  'DECLINE',
                  style: KolabingTextStyles.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Accept button
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _isAccepting || _isDeclining
                        ? null
                        : () => _handleAccept(application),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isAccepting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: KolabingColors.onPrimary),
                      )
                    : const Icon(LucideIcons.check, size: 18),
                label: Text(
                  'ACCEPT',
                  style: KolabingTextStyles.button.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.sm,
        KolabingSpacing.md,
        MediaQuery.of(context).padding.bottom + KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }

  void _handleAccept(Application application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AcceptFormSheet(
        application: application,
        onAccepted: () {
          // Refresh and navigate to chat
          ref.invalidate(applicationDetailProvider(application.id));
          ref.read(receivedApplicationsProvider.notifier).refresh();
          context.pushReplacement('/application/${application.id}/chat');
        },
        ref: ref,
      ),
    );
  }

  Future<void> _showDeclineDialog(Application application) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Decline Application',
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to decline this application from ${application.applicantName}?',
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: KolabingColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: KolabingColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: KolabingColors.borderFocus),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: KolabingTextStyles.labelLarge.copyWith(color: KolabingColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              'Decline',
              style: KolabingTextStyles.button,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeclining = true);

    final reason =
        reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null;

    try {
      await ref
          .read(receivedApplicationsProvider.notifier)
          .declineApplication(application.id, reason: reason);

      reasonController.dispose();

      if (!mounted) return;
      setState(() => _isDeclining = false);

      ref.invalidate(applicationDetailProvider(application.id));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Application declined',
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textOnDark),
          ),
          backgroundColor: KolabingColors.onSurfaceVariant,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      reasonController.dispose();

      if (!mounted) return;
      setState(() => _isDeclining = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _parseError(e),
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textOnDark),
          ),
          backgroundColor: KolabingColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _parseError(dynamic e) {
    if (e is ApiException) {
      return e.error.allErrorMessages;
    }
    final s = e.toString();
    if (s.contains('NetworkException:')) {
      return s.replaceAll('NetworkException: ', '');
    }
    return 'Something went wrong. Please try again.';
  }
}

// =============================================================================
// Accept Form Bottom Sheet
// =============================================================================

class _AcceptFormSheet extends StatefulWidget {
  const _AcceptFormSheet({
    required this.application,
    required this.onAccepted,
    required this.ref,
  });

  final Application application;
  final VoidCallback onAccepted;
  final WidgetRef ref;

  @override
  State<_AcceptFormSheet> createState() => _AcceptFormSheetState();
}

class _AcceptFormSheetState extends State<_AcceptFormSheet> {
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  String? _error;

  /// Build available dates from the opportunity's availability range,
  /// constrained by the publisher's mode (C12). One-time → single date,
  /// recurring → only matching weekdays, flexible → full range.
  /// Only future dates (after today) as required by API.
  List<DateTime> get _availableDates {
    final opportunity = widget.application.opportunity;
    if (opportunity == null) return [];

    final start = DateUtils.dateOnly(opportunity.availabilityStart);
    final end = DateUtils.dateOnly(opportunity.availabilityEnd);
    final tomorrow =
        DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    final effectiveStart = start.isBefore(tomorrow) ? tomorrow : start;

    if (effectiveStart.isAfter(end)) return [];

    final modeName = opportunity.availabilityMode.toApiValue();

    // One-time: publisher locked a single date. Offer only that date.
    if (modeName == 'one_time') {
      return start.isBefore(tomorrow) ? const [] : [start];
    }

    // Recurring: publisher picked specific weekdays. Filter the daily walk.
    final filterByWeekday = modeName == 'recurring' &&
        opportunity.recurringDays.isNotEmpty;

    final dates = <DateTime>[];
    var current = effectiveStart;
    while (!current.isAfter(end)) {
      if (!filterByWeekday || opportunity.recurringDays.contains(current.weekday)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  // C13: Contact-methods exchange was dropped from the accept flow. The
  // in-app chat (routed in `_handleAccept.onAccepted`) is the canonical
  // post-accept communication channel.
  bool get _isValid => _selectedDate != null;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final dates = _availableDates;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          KolabingSpacing.lg,
          KolabingSpacing.sm,
          KolabingSpacing.lg,
          bottomPadding + KolabingSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KolabingColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),

              // Title
              Text(
                'Accept Application',
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xxs),
              Text(
                "Pick a collaboration date — you'll continue the conversation in chat after accepting.",
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),

              // Date picker section
              Text(
                'SCHEDULED DATE',
                style: KolabingTextStyles.eyebrow.copyWith(
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),

              if (dates.isEmpty)
                Container(
                  padding: const EdgeInsets.all(KolabingSpacing.md),
                  decoration: BoxDecoration(
                    color: KolabingColors.surfaceVariant,
                    borderRadius: KolabingRadius.borderRadiusSm,
                  ),
                  child: Text(
                    'No available future dates in the opportunity range.',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dates.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: KolabingSpacing.xs),
                    itemBuilder: (_, index) {
                      final date = dates[index];
                      final isSelected = _selectedDate != null &&
                          DateUtils.isSameDay(_selectedDate!, date);
                      return _buildDateTile(date, isSelected);
                    },
                  ),
                ),
              const SizedBox(height: KolabingSpacing.lg),

              // C13: Contact-methods inputs removed. After accept we route
              // straight to the in-app chat.

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(KolabingSpacing.sm),
                  decoration: BoxDecoration(
                    color: KolabingColors.errorBg,
                    borderRadius: KolabingRadius.borderRadiusSm,
                  ),
                  child: Text(
                    _error!,
                    style: KolabingTextStyles.captionSecondary.copyWith(
                      color: KolabingColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.sm),
              ],

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isValid && !_isSubmitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: KolabingColors.onPrimary),
                        )
                      : const Icon(LucideIcons.check, size: 18),
                  label: Text(
                    'CONFIRM ACCEPT',
                    style: KolabingTextStyles.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(DateTime date, bool isSelected) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? KolabingColors.primary
              : KolabingColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(color: KolabingColors.darkBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayNames[date.weekday - 1],
              style: KolabingTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? KolabingColors.onPrimary
                    : KolabingColors.textTertiary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? KolabingColors.onPrimary
                    : KolabingColors.onSurface,
              ),
            ),
            Text(
              monthNames[date.month - 1],
              style: KolabingTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? KolabingColors.onPrimary
                    : KolabingColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_isValid) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final dateStr =
        '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    // C13: contact_methods exchange dropped. Send empty map — backend either
    // already accepts empty, or the next backend pass will drop the
    // requirement entirely. After accept the user lands in chat.
    const contactMethods = <String, String>{};

    try {
      await widget.ref
          .read(receivedApplicationsProvider.notifier)
          .acceptApplication(
            widget.application.id,
            scheduledDate: dateStr,
            contactMethods: contactMethods,
          );

      if (!mounted) return;

      Navigator.of(context).pop(); // Close bottom sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Application accepted! Collaboration created.',
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.textOnDark),
          ),
          backgroundColor: KolabingColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onAccepted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        if (e is ApiException) {
          _error = e.error.allErrorMessages;
        } else {
          _error = 'Failed to accept application. Please try again.';
        }
      });
    }
  }
}
