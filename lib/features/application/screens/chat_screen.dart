import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/blurred_identity.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/profile_link.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/application.dart';
import '../providers/application_provider.dart';

/// Destination for the chat "View opportunity" action.
///
/// The **opportunity creator** opens the applicant's submission
/// (`ApplicationReviewScreen`) — what the counterparty gave us in the form.
/// The **applicant** opens the offer they applied to, but with `canApply=false`
/// so no "Apply now" CTA appears: the application is already accepted (the chat
/// only exists afterwards) and the offer screen's own `has_applied`/`is_own`
/// flags are unreliable in this payload.
@visibleForTesting
String chatViewOpportunityRoute({
  required bool viewerIsCreator,
  required String applicationId,
  required String opportunityId,
}) => viewerIsCreator
    ? '/application/$applicationId'
    : '/community/explore/offer/$opportunityId?canApply=false';

/// Chat screen for application conversation
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.applicationId, super.key});

  final String applicationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load messages when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).load(widget.applicationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more messages when scrolling near the top
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      final chatState = ref.read(chatMessagesProvider);
      if (chatState.hasMore && !chatState.isLoadingMore) {
        ref.read(chatMessagesProvider.notifier).loadMore();
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _handleSend() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final message = await ref
        .read(chatMessagesProvider.notifier)
        .sendMessage(content);

    if (message != null && mounted) {
      _scrollToBottom();
    } else if (mounted) {
      final chatState = ref.read(chatMessagesProvider);
      if (chatState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatState.error!),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncAppData = ref.watch(chatDataProvider(widget.applicationId));
    final chatState = ref.watch(chatMessagesProvider);

    // Scroll to bottom when messages are first loaded
    if (!_isInitialized &&
        chatState.messages.isNotEmpty &&
        !chatState.isLoading) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animate: false);
      });
    }

    return asyncAppData.when(
      loading: () =>
          _buildScaffold(isLoading: true, body: _buildLoadingState()),
      error: (error, _) {
        if (error is AuthException) {
          return _buildScaffold(body: _buildAuthErrorState());
        }
        return _buildScaffold(body: _buildErrorState(error.toString()));
      },
      data: (application) {
        if (application == null) {
          return _buildScaffold(
            body: _buildErrorState(
              AppLocalizations.of(context).chatApplicationNotFound,
            ),
          );
        }

        // Subscription-lapse re-gate (§2.8): a business whose subscription
        // lapsed loses chat access until it resubscribes. The community
        // counterparty is NEVER blurred, so we AND with isBusiness as a guard.
        final isBusiness = ref.read(authProvider).user?.isBusiness ?? false;
        final mustResubscribe = isBusiness && application.viewerMustResubscribe;

        return _buildScaffold(
          application: application,
          counterpartyName: _counterpartyName(application),
          canOpenCounterpartyProfile: !mustResubscribe,
          body: Column(
            children: [
              _buildApplicationHeader(application),
              if (mustResubscribe) _buildResubscribeBanner(),
              Expanded(
                child: mustResubscribe
                    // Blur the conversation (no full-screen block, golden rule
                    // 5) and prevent interaction while re-gated.
                    ? IgnorePointer(
                        child: BlurredIdentity(
                          enabled: true,
                          sigma: 6,
                          child: _buildMessagesList(chatState),
                        ),
                      )
                    : _buildMessagesList(chatState),
              ),
              // Hide the composer entirely while re-gated.
              if (!mustResubscribe) _buildInputField(chatState.isSending),
            ],
          ),
        );
      },
    );
  }

  /// Compact "Resubscribe to continue" banner shown in chat for a lapsed
  /// business. Routes to the subscription plans screen.
  Widget _buildResubscribeBanner() {
    return Material(
      color: context.colors.softYellow,
      child: InkWell(
        onTap: () => context.push('/business/plans'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.lock, size: 16, color: context.colors.onPrimary),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).chatResubscribeBanner,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).chatResubscribeAction,
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: context.colors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolve the OTHER party's name to show in the chat header (§4: "The other
  /// party's name is shown in chat").
  ///
  /// `application.recipientName` is always the opportunity CREATOR. When the
  /// current user IS the creator (they received the application), the header
  /// must instead show the applicant — otherwise the user sees their own name.
  /// We compare the current user's profile id against the applicant's id.
  String _counterpartyName(Application application) {
    final user = ref.read(authProvider).user;
    final myId = user?.id ?? '';

    // The application carries two profile ids: the applicant (applicantId) and
    // the opportunity creator (recipientId). If our own id matches one, the
    // counterparty is the other. UserModel.id is the viewer's profile id, which
    // mirrors these `profiles.id` values per docs/ROLES-BACKEND-DB-MAP.md §1.
    if (myId.isNotEmpty && application.applicantId == myId) {
      return application.recipientName;
    }
    if (myId.isNotEmpty && application.recipientId == myId) {
      return application.applicantName;
    }
    // Last resort when ids are unavailable: prefer a real (non-"Unknown")
    // applicant name, else the creator name. This preserves prior behaviour for
    // sent-application payloads (which only populate the creator).
    final applicant = application.applicantName;
    if (applicant.isNotEmpty && applicant != 'Unknown') return applicant;
    return application.recipientName;
  }

  /// The counterparty's `profiles.id`, resolved the same way as
  /// [_counterpartyName] so the header's name and the profile it opens can never
  /// be two different people.
  ///
  /// Null when the viewer's own id is unavailable: the fallback in
  /// [_counterpartyName] guesses at a *name*, and guessing at a link would take
  /// you to the wrong profile rather than merely label the header oddly.
  String? _counterpartyId(Application application) {
    final myId = ref.read(authProvider).user?.id ?? '';
    if (myId.isEmpty) return null;
    if (application.applicantId == myId) return application.recipientId;
    if (application.recipientId == myId) return application.applicantId;
    return null;
  }

  Widget _buildScaffold({
    required Widget body,
    Application? application,
    String? counterpartyName,
    bool isLoading = false,
    // §2.8: a lapsed business is re-gated to the free state, and a free business
    // cannot open a community's full profile (§2.5). The header keeps the name —
    // the counterparty is never blurred here — but stops being a door.
    bool canOpenCounterpartyProfile = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = counterpartyName ?? application?.recipientName ?? '';

    return Scaffold(
      backgroundColor: isDark
          ? context.colors.surface
          : context.colors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: isDark
            ? context.colors.darkSurface
            : context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
          color: isDark ? context.colors.textOnDark : context.colors.onSurface,
        ),
        title: application != null
            ? ProfileLink(
                profileId: _counterpartyId(application),
                enabled: canOpenCounterpartyProfile,
                child: Row(
                  children: [
                    _buildAvatar(displayName, isDark: isDark),
                    const SizedBox(width: KolabingSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: KolabingTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? context.colors.textOnDark
                                  : context.colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            application.status.displayName,
                            style: KolabingTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? context.colors.textOnDark.withValues(
                                      alpha: 0.5,
                                    )
                                  : context.colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : isLoading
            ? Text(
                AppLocalizations.of(context).chatLoading,
                style: TextStyle(
                  color: isDark
                      ? context.colors.textOnDark
                      : context.colors.onSurface,
                ),
              )
            : null,
        actions: application != null
            ? [
                IconButton(
                  icon: const Icon(LucideIcons.moreVertical),
                  onPressed: () =>
                      _showOptionsMenu(context, application: application),
                  color: isDark
                      ? context.colors.textOnDark.withValues(alpha: 0.7)
                      : context.colors.onSurfaceVariant,
                ),
              ]
            : null,
      ),
      body: KeyboardAvoidingContent(child: body),
    );
  }

  Widget _buildAvatar(String name, {bool isDark = false}) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: KolabingTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.primary,
        ),
      ),
    ),
  );

  Widget _buildApplicationHeader(Application application) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? context.colors.darkBorder
                : context.colors.darkBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.briefcase, size: 16, color: context.colors.primary),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              application.opportunityTitle,
              style: KolabingTextStyles.captionSecondary.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? context.colors.textOnDark
                    : context.colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.isLoading) {
      return _buildLoadingState();
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return _buildErrorState(chatState.error!);
    }

    if (chatState.messages.isEmpty) {
      return _buildEmptyState();
    }

    final messages = chatState.messages;

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      itemCount: messages.length + (chatState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the top when loading more
        if (chatState.isLoadingMore && index == 0) {
          return _buildLoadingMoreIndicator();
        }

        final adjustedIndex = chatState.isLoadingMore ? index - 1 : index;
        final message = messages[adjustedIndex];
        final showDate =
            adjustedIndex == 0 ||
            !_isSameDay(
              messages[adjustedIndex - 1].timestamp,
              message.timestamp,
            );

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.timestamp),
            _MessageBubble(message: message),
          ],
        );
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateDivider(DateTime date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isYesterday = _isSameDay(date, now.subtract(const Duration(days: 1)));

    String label;
    if (isToday) {
      label = AppLocalizations.of(context).chatDateToday;
    } else if (isYesterday) {
      label = AppLocalizations.of(context).chatDateYesterday;
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    final dividerColor = isDark
        ? context.colors.darkBorder
        : context.colors.darkBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
            child: Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                color: isDark
                    ? context.colors.textOnDark.withValues(alpha: 0.5)
                    : context.colors.textTertiary,
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor)),
        ],
      ),
    );
  }

  Widget _buildInputField(bool isSending) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : context.colors.surface,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? context.colors.surface
                      : context.colors.background,
                  borderRadius: KolabingRadius.borderRadiusRound,
                  border: Border.all(
                    color: isDark
                        ? context.colors.darkBorder
                        : context.colors.darkBorder,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).chatMessageHint,
                    hintStyle: KolabingTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? context.colors.textOnDark.withValues(alpha: 0.5)
                          : context.colors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.md,
                      vertical: KolabingSpacing.sm,
                    ),
                  ),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? context.colors.textOnDark
                        : context.colors.onSurface,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Material(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: isSending ? null : _handleSend,
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: isSending
                      ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colors.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          LucideIcons.send,
                          size: 20,
                          color: context.colors.onPrimary,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? context.colors.darkSurface
          : context.colors.surfaceVariant,
      highlightColor: isDark
          ? context.colors.darkBorder
          : context.colors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        itemCount: 5,
        itemBuilder: (_, index) {
          final isOwn = index % 2 == 0;
          return Align(
            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                color: isDark ? context.colors.darkSurface : Colors.white,
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: context.colors.error),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          KolabingButton(
            label: AppLocalizations.of(context).commonRetry,
            onPressed: () {
              ref.invalidate(chatDataProvider(widget.applicationId));
              ref
                  .read(chatMessagesProvider.notifier)
                  .load(widget.applicationId);
            },
            variant: KolabingButtonVariant.primary,
            size: KolabingButtonSize.compact,
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
          ),
        ],
      ),
    ),
  );

  Widget _buildAuthErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.logIn, size: 48, color: context.colors.error),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).chatSessionExpiredTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? context.colors.textOnDark
                    : context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).chatSessionExpiredBody,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            KolabingButton(
              label: AppLocalizations.of(context).chatSignIn,
              onPressed: () {
                context.go(KolabingRoutes.login);
              },
              variant: KolabingButtonVariant.primary,
              size: KolabingButtonSize.compact,
              icon: const Icon(LucideIcons.logIn, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.messageCircle,
                size: 28,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).chatEmptyTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? context.colors.textOnDark
                    : context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).chatEmptyBody,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, {Application? application}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.eye),
              title: Text(AppLocalizations.of(context).chatViewOpportunity),
              onTap: () {
                Navigator.pop(ctx);
                if (application == null) return;
                // A chat is always between one business and one community
                // (ROLES §2.5: chat exists only after an accepted application),
                // so the viewer is the opportunity CREATOR exactly when their
                // role matches the creator's. Profile-id comparison is
                // unreliable here (user_id vs profile_id live in different id
                // spaces — see community_offer_detail_screen). When the creator
                // role is absent from the payload, fall back to the dominant
                // flow: the business creates the kolab, the community applies.
                final user = ref.read(authProvider).user;
                final creatorType =
                    application.opportunity?.creatorProfile?.userType
                        .toLowerCase() ??
                    '';
                final viewerIsCreator = switch (creatorType) {
                  'business' => user?.isBusiness ?? false,
                  'community' => user?.isCommunity ?? false,
                  _ => user?.isBusiness ?? false,
                };
                context.push(
                  chatViewOpportunityRoute(
                    viewerIsCreator: viewerIsCreator,
                    applicationId: widget.applicationId,
                    opportunityId: application.opportunityId,
                  ),
                  extra: viewerIsCreator ? null : application.opportunity,
                );
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.xCircle, color: context.colors.error),
              title: Text(
                AppLocalizations.of(context).chatCancelApplication,
                style: TextStyle(color: context.colors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showCancelDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatCancelDialogTitle),
        content: Text(l10n.chatCancelDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.chatCancelDialogKeep),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(myApplicationsProvider.notifier)
                  .withdrawApplication(widget.applicationId);
              if (success && mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.chatApplicationWithdrawn),
                    backgroundColor: context.colors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: Text(l10n.chatCancelDialogWithdraw),
          ),
        ],
      ),
    );
  }
}

/// Message bubble widget with avatar and read receipts
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwn = message.isOwn;
    final senderProfile = message.senderProfile;

    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Row(
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show avatar for received messages
          if (!isOwn) ...[
            _buildAvatar(context, senderProfile),
            const SizedBox(width: KolabingSpacing.xs),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isOwn
                    ? context.colors.primary
                    : isDark
                    ? context.colors.darkSurface
                    : context.colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isOwn ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isOwn ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: isOwn
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Show sender name for received messages
                  if (!isOwn) ...[
                    Text(
                      senderProfile.name,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Message content
                  Text(
                    message.content,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: isOwn
                          ? context.colors.onPrimary
                          : isDark
                          ? context.colors.textOnDark
                          : context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Time and read receipts row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeDisplay,
                        style: KolabingTextStyles.labelSmall.copyWith(
                          color: isOwn
                              ? context.colors.onPrimary.withValues(alpha: 0.7)
                              : isDark
                              ? context.colors.textOnDark.withValues(alpha: 0.5)
                              : context.colors.textTertiary,
                        ),
                      ),
                      // Read receipts for own messages
                      if (isOwn) ...[
                        const SizedBox(width: 4),
                        _buildReadReceipt(context),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Spacer for own messages (to account for missing avatar)
          if (isOwn) const SizedBox(width: KolabingSpacing.xs + 28),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, SenderProfile profile) {
    if (profile.profilePhoto != null && profile.profilePhoto!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profile.profilePhoto!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(context, profile),
        ),
      );
    }
    return _buildFallbackAvatar(context, profile);
  }

  Widget _buildFallbackAvatar(BuildContext context, SenderProfile profile) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          profile.initial,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }

  /// Build read receipt indicator
  /// Single check (checkmark) = sent
  /// Double check (checkmarks) = read
  Widget _buildReadReceipt(BuildContext context) {
    final isRead = message.isRead;
    final iconColor = context.colors.onPrimary.withValues(alpha: 0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.check, size: 12, color: iconColor),
        if (isRead)
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Icon(LucideIcons.check, size: 12, color: iconColor),
          ),
      ],
    );
  }
}
