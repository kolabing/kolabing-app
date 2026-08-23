import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../../gamification/models/event_checkin.dart';
import '../models/community.dart';
import '../providers/community_follow_provider.dart';
import 'community_application_sheet.dart';

/// "You came — do you want to belong?" (#148)
///
/// Turning up is the one moment worth asking. Before this, checking in did a lot
/// — points, badges, tiers, missions — and then said nothing, while the person
/// stood in the room of a community they were not a member of.
///
/// It only asks, and only once per event. Nothing depends on the answer: the
/// check-in already succeeded before the question appears, so ignoring it costs
/// nothing. Membership is never automatic — it is the choosing that makes it
/// mean something.
class MembershipPrompt {
  const MembershipPrompt._();

  static const String _dismissedKey = 'membership_prompt_dismissed_events';

  /// Offers membership if this check-in is one worth offering it for.
  ///
  /// Safe to call after every check-in through either door; it decides for
  /// itself whether there is anything to ask.
  static Future<void> maybeOffer(
    BuildContext context,
    WidgetRef ref,
    EventCheckin checkin,
  ) async {
    if (!checkin.canOfferMembership) return;
    if (await _wasDismissed(checkin.eventId)) return;
    if (!context.mounted) return;

    final wants = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PromptSheet(communityName: checkin.communityName!),
    );

    if (wants != true) {
      // Someone who said no while walking into a run must not be asked again.
      await _remember(checkin.eventId);
      return;
    }
    if (!context.mounted) return;

    // The existing flow, verbatim: it already resolves the leader's questions
    // first, joins directly when there are none, and shows the form when there
    // are. This adds a trigger, not a second way to become a member.
    final outcome = await CommunityApplicationSheet.run(
      context,
      ref,
      community: Community(
        id: checkin.communityId!,
        ownerProfileId: '',
        name: checkin.communityName!,
        slug: '',
        type: CommunityType.other,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (outcome == MembershipOutcome.joined) {
      // Joining now also follows (#146) — pick that up so no screen offers a
      // Follow button for something they already belong to.
      await ref.read(communityFollowsProvider.notifier).reload();
    }

    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final message = switch (outcome) {
      MembershipOutcome.joined => l10n.communityApplicationJoinedSnack,
      MembershipOutcome.pending => l10n.communityApplicationSentSnack,
      MembershipOutcome.failed => l10n.communityApplicationFailed,
      MembershipOutcome.dismissed => null,
    };

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Dismissals are per event and stored on the device: only the client knows
  /// someone already said no, which is why the API returns facts rather than a
  /// `should_prompt` flag.
  static Future<bool> _wasDismissed(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_dismissedKey) ?? const []).contains(eventId);
    } on Object {
      // Unreadable storage must not block the prompt; asking twice is a smaller
      // failure than never asking.
      return false;
    }
  }

  static Future<void> _remember(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_dismissedKey) ?? const <String>[];
      if (current.contains(eventId)) return;
      // Bounded: this list only exists to stop one question repeating, so it
      // does not need to remember every event forever.
      final next = [...current, eventId];
      await prefs.setStringList(
        _dismissedKey,
        next.length > 50 ? next.sublist(next.length - 50) : next,
      );
    } on Object {
      // Nothing to do — worst case the question comes back once.
    }
  }
}

class _PromptSheet extends StatelessWidget {
  const _PromptSheet({required this.communityName});

  final String communityName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: KolabingSpacing.lg,
        right: KolabingSpacing.lg,
        top: KolabingSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + KolabingSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.userPlus,
                size: 30,
                color: context.colors.charcoal,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            l10n.membershipPromptTitle(communityName),
            textAlign: TextAlign.center,
            style: KolabingTextStyles.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.membershipPromptBody,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          KolabingButton(
            label: l10n.communityBecomeMember,
            onPressed: () => Navigator.of(context).pop(true),
            variant: KolabingButtonVariant.primary,
          ),
          const SizedBox(height: KolabingSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.membershipPromptNotNow),
          ),
        ],
      ),
    );
  }
}
