import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/community.dart';
import '../models/community_join_question.dart';
import '../providers/community_follow_provider.dart';
import '../providers/community_providers.dart';
import '../services/community_service.dart';

/// How an attempt to become a member ended.
enum MembershipOutcome {
  /// Membership granted straight away — the community asked nothing, or asked
  /// questions but admits automatically.
  joined,

  /// The application is with the leader.
  pending,

  /// Nothing happened.
  dismissed,

  failed,
}

/// "Become a member" (#138).
///
/// Following is one tap; this is the deliberate step. What it does depends
/// entirely on what the leader chose:
///
///  - **asks nothing** → joins immediately, no form shown at all. This is the
///    default and the common case;
///  - **asks questions** → the form, then the leader decides (or the community
///    admits automatically if it is open).
///
/// So the sheet resolves the questions *before* deciding whether to render
/// anything, and a member of a community that asks nothing never sees a form.
class CommunityApplicationSheet extends ConsumerStatefulWidget {
  const CommunityApplicationSheet({
    super.key,
    required this.community,
    required this.questions,
  });

  final Community community;

  /// The questions to ask, resolved by [run] BEFORE this is built.
  ///
  /// Passed in rather than re-read from the provider inside `build`. Reading it
  /// there meant loading and error both rendered as "asks nothing" — a title, no
  /// fields, and an enabled Submit — and submitting in that window posted
  /// `{"answers": []}`, which is exactly the payload that opts into the
  /// backend's required-answer enforcement and comes back 422.
  final List<CommunityJoinQuestion> questions;

  /// Runs the whole flow and resolves with what happened. Shows a form only if
  /// the community actually asks something.
  static Future<MembershipOutcome> run(
    BuildContext context,
    WidgetRef ref, {
    required Community community,
  }) async {
    List<CommunityJoinQuestion> questions;
    try {
      questions = await ref.read(
        communityJoinQuestionsProvider(community.id).future,
      );
    } on Object {
      // Could not ask what the questions are; fall through to the direct path
      // rather than blocking the member.
      questions = const [];
    }

    if (!context.mounted) return MembershipOutcome.dismissed;

    if (questions.isEmpty) {
      return _joinDirectly(context, ref, community);
    }

    final outcome = await showModalBottomSheet<MembershipOutcome>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CommunityApplicationSheet(community: community, questions: questions),
    );
    return outcome ?? MembershipOutcome.dismissed;
  }

  /// No questions: join through the plain path, falling back to a request when
  /// the community needs a decision.
  static Future<MembershipOutcome> _joinDirectly(
    BuildContext context,
    WidgetRef ref,
    Community community,
  ) async {
    final service = ref.read(communityServiceProvider);
    try {
      await service.joinCommunity(community.id);
      return MembershipOutcome.joined;
    } on CommunityException catch (e) {
      // invite_only → the leader decides. needsApplication should not happen
      // here (we just read an empty question set) but a leader could have added
      // one in between, so handle it the same way.
      if (e.isInviteOnly || e.needsApplication) {
        try {
          await service.requestToJoin(community.id);
          return MembershipOutcome.pending;
        } on Object {
          return MembershipOutcome.failed;
        }
      }
      return MembershipOutcome.failed;
    } on Object {
      return MembershipOutcome.failed;
    }
  }

  @override
  ConsumerState<CommunityApplicationSheet> createState() =>
      _CommunityApplicationSheetState();
}

class _CommunityApplicationSheetState
    extends ConsumerState<CommunityApplicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String questionId) =>
      _controllers.putIfAbsent(questionId, TextEditingController.new);

  Future<void> _submit(List<CommunityJoinQuestion> questions) async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final answers = questions
        .map(
          (q) => CommunityJoinAnswer(
            questionId: q.id,
            answer: _controllerFor(q.id).text.trim(),
          ),
        )
        .where((a) => a.answer.isNotEmpty)
        .toList(growable: false);

    try {
      await ref
          .read(communityServiceProvider)
          .requestToJoin(widget.community.id, answers: answers);

      if (!mounted) return;
      // An open community admits on submit, an invite-only one does not. The
      // reload tells us which happened rather than us guessing.
      await ref
          .read(communityByIdProvider(widget.community.id).notifier)
          .reload();
      if (!mounted) return;

      final fresh = ref.read(communityByIdProvider(widget.community.id));
      final joined = fresh.asData?.value.isMember ?? false;

      Navigator.of(
        context,
      ).pop(joined ? MembershipOutcome.joined : MembershipOutcome.pending);
    } on Object {
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pop(MembershipOutcome.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final questions = widget.questions;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: KolabingSpacing.lg,
        right: KolabingSpacing.lg,
        top: KolabingSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + KolabingSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                l10n.communityApplicationTitle,
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                l10n.communityApplicationIntro(widget.community.name),
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              for (final question in questions) ...[
                _QuestionField(
                  question: question,
                  controller: _controllerFor(question.id),
                ),
                const SizedBox(height: KolabingSpacing.md),
              ],
              const SizedBox(height: KolabingSpacing.xs),
              KolabingButton(
                label: l10n.communityApplicationSubmit,
                onPressed: _submitting ? null : () => _submit(questions),
                variant: KolabingButtonVariant.primary,
                isLoading: _submitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({required this.question, required this.controller});

  final CommunityJoinQuestion question;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                question.prompt,
                style: KolabingTextStyles.labelLarge.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ),
            if (!question.required)
              Text(
                l10n.communityApplicationOptional,
                style: KolabingTextStyles.labelSmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.xs),
        TextFormField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 2000,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(counterText: ''),
          validator: (value) {
            if (!question.required) return null;
            return (value ?? '').trim().isEmpty
                ? l10n.communityApplicationRequiredError
                : null;
          },
        ),
      ],
    );
  }
}
