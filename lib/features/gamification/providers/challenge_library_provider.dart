import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/community_challenge.dart';
import 'challenge_provider.dart';

/// The challenge library a leader picks from (#150).
///
/// `autoDispose` because it is read when the curation screen opens and is a
/// catalogue, not state.
final challengeLibraryProvider = FutureProvider.autoDispose<List<Challenge>>((
  ref,
) async {
  final response = await ref.read(challengeServiceProvider).getLibrary();
  return response.challenges;
});

/// What one community has chosen, editable.
///
/// Held as a notifier rather than a `FutureProvider` because the screen is a
/// checklist: every tap changes it locally and only **Save** sends it, so the
/// unsaved state has to live somewhere.
class CommunityChallengeSetNotifier
    extends Notifier<AsyncValue<CommunityChallengeSet>> {
  CommunityChallengeSetNotifier(this.communityId);

  final String communityId;

  @override
  AsyncValue<CommunityChallengeSet> build() {
    Future.microtask(load);
    return const AsyncValue.loading();
  }

  Future<void> load() async {
    try {
      state = AsyncValue.data(
        await ref
            .read(challengeServiceProvider)
            .getCommunityChallenges(communityId),
      );
    } on Object catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggles a challenge locally. Nothing is sent until [save].
  void toggle(String challengeId) {
    final current = state.asData?.value;
    if (current == null) return;

    final without = current.selections
        .where((s) => s.challengeId != challengeId)
        .toList();

    final selections = without.length == current.selections.length
        ? [
            ...current.selections,
            CommunityChallengeSelection(challengeId: challengeId),
          ]
        : without;

    state = AsyncValue.data(
      CommunityChallengeSet(curated: current.curated, selections: selections),
    );
  }

  /// Updates one challenge's options locally.
  void setOptions(
    String challengeId, {
    bool? allowRepeat,
    bool? requiresNewPerson,
  }) {
    final current = state.asData?.value;
    if (current == null) return;

    state = AsyncValue.data(
      CommunityChallengeSet(
        curated: current.curated,
        selections: current.selections
            .map(
              (s) => s.challengeId == challengeId
                  ? s.copyWith(
                      allowRepeatWithSamePerson: allowRepeat,
                      requiresNewPerson: requiresNewPerson,
                    )
                  : s,
            )
            .toList(growable: false),
      ),
    );
  }

  /// Sends the checklist. An empty one is a real choice — it turns curation off
  /// and hands the community back the whole library — so it is not blocked.
  Future<bool> save() async {
    final current = state.asData?.value;
    if (current == null) return false;

    try {
      state = AsyncValue.data(
        await ref
            .read(challengeServiceProvider)
            .syncCommunityChallenges(communityId, current.selections),
      );
      return true;
    } on Object catch (e) {
      debugPrint('communityChallenges: save failed: $e');
      return false;
    }
  }
}

final communityChallengeSetProvider =
    NotifierProvider.family<
      CommunityChallengeSetNotifier,
      AsyncValue<CommunityChallengeSet>,
      String
    >(CommunityChallengeSetNotifier.new);
