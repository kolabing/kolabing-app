import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/challenge.dart';
import '../models/community_challenge.dart';
import '../providers/challenge_library_provider.dart';

/// The leader's checklist: which of Kolabing's challenges this community plays,
/// and how strictly (#150).
///
/// The screen exists because not every community wants the same thing. A social
/// run club wants people meeting each other; another community only cares that
/// people turn up. Until now both got an identical list.
///
/// **An empty checklist is a valid state and does not mean "no challenges"** —
/// it means the community has no opinion, and its events play the whole library.
/// The banner says so, because a screen full of unticked boxes otherwise reads
/// as "nothing is on".
class CommunityChallengesScreen extends ConsumerStatefulWidget {
  const CommunityChallengesScreen({
    super.key,
    required this.communityId,
    this.communityName,
  });

  final String communityId;
  final String? communityName;

  static Future<void> open(
    BuildContext context, {
    required String communityId,
    String? communityName,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => CommunityChallengesScreen(
        communityId: communityId,
        communityName: communityName,
      ),
    ),
  );

  @override
  ConsumerState<CommunityChallengesScreen> createState() =>
      _CommunityChallengesScreenState();
}

class _CommunityChallengesScreenState
    extends ConsumerState<CommunityChallengesScreen> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);

    final ok = await ref
        .read(communityChallengeSetProvider(widget.communityId).notifier)
        .save();

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.communityChallengesSaved
              : l10n.communityChallengesSaveFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final library = ref.watch(challengeLibraryProvider);
    final set = ref.watch(communityChallengeSetProvider(widget.communityId));

    final loaded = set.asData?.value;
    final selections =
        loaded?.selections ?? const <CommunityChallengeSelection>[];
    final byId = {for (final s in selections) s.challengeId: s};

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: Text(
          l10n.communityChallengesTitle,
          style: KolabingTextStyles.titleSmall.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(text: l10n.communityChallengesUnavailable),
        data: (challenges) {
          if (challenges.isEmpty) {
            return _Message(text: l10n.communityChallengesEmptyLibrary);
          }

          // The library and the community's set load independently, so the set
          // can fail while the library succeeds. Rendering the library anyway
          // meant every box unticked, Save enabled — and every tap a silent
          // no-op, because toggle/setOptions/save all bail out when the set is
          // not loaded. That is the bug class #145 was; do not reintroduce it.
          if (set.hasError) {
            return _Message(text: l10n.communityChallengesLoadFailed);
          }
          if (loaded == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _Banner(
                // The server's own answer, not a guess from the list length.
                // They agree today — an empty set IS no curation — but the flag
                // is the contract and the length is an implementation detail.
                curated: loaded.curated || selections.isNotEmpty,
                l10n: l10n,
                communityName: widget.communityName,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(KolabingSpacing.md),
                  itemCount: challenges.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: KolabingSpacing.sm),
                  itemBuilder: (context, index) {
                    final challenge = challenges[index];
                    return _ChallengeTile(
                      challenge: challenge,
                      selection: byId[challenge.id],
                      onToggle: () => ref
                          .read(
                            communityChallengeSetProvider(
                              widget.communityId,
                            ).notifier,
                          )
                          .toggle(challenge.id),
                      onOptions: ({bool? allowRepeat, bool? requiresNew}) => ref
                          .read(
                            communityChallengeSetProvider(
                              widget.communityId,
                            ).notifier,
                          )
                          .setOptions(
                            challenge.id,
                            allowRepeat: allowRepeat,
                            requiresNewPerson: requiresNew,
                          ),
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(KolabingSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: KolabingButton(
                      label: l10n.commonSave,
                      onPressed: _saving ? null : _save,
                      variant: KolabingButtonVariant.primary,
                      isLoading: _saving,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Says which of the two empty states this is.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.curated,
    required this.l10n,
    this.communityName,
  });

  final bool curated;
  final AppLocalizations l10n;
  final String? communityName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            curated ? LucideIcons.listChecks : LucideIcons.info,
            size: 18,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(
              curated
                  ? l10n.communityChallengesCuratedHint
                  : l10n.communityChallengesDefaultHint,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _OptionsChanged = void Function({bool? allowRepeat, bool? requiresNew});

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.selection,
    required this.onToggle,
    required this.onOptions,
  });

  final Challenge challenge;
  final CommunityChallengeSelection? selection;
  final VoidCallback onToggle;
  final _OptionsChanged onOptions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final on = selection != null;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: on ? context.colors.primary : context.colors.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: on,
            onChanged: (_) => onToggle(),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              challenge.name,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: challenge.description == null
                ? null
                : Text(
                    challenge.description!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
          ),
          // The options only exist for a challenge that is on — they are how
          // this community plays it, so they are meaningless when it does not.
          if (on) ...[
            const Divider(height: 1),
            SwitchListTile(
              value: selection!.allowRepeatWithSamePerson,
              onChanged: (v) => onOptions(allowRepeat: v),
              title: Text(
                l10n.communityChallengesAllowRepeat,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
            SwitchListTile(
              value: selection!.requiresNewPerson,
              onChanged: (v) => onOptions(requiresNew: v),
              title: Text(
                l10n.communityChallengesRequiresNewPerson,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: KolabingTextStyles.bodyMedium.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
