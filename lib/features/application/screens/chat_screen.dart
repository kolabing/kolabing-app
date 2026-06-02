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
import '../../../widgets/keyboard_avoiding_content.dart';
import '../../../widgets/blurred_identity.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/application.dart';
import '../providers/application_provider.dart';

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
            backgroundColor: KolabingColors.error,
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
                AppLocalizations.of(context).chatApplicationNotFound),
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
      color: KolabingColors.softYellow,
      child: InkWell(
        onTap: () => context.push('/business/plans'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.lock,
                size: 16,
                color: KolabingColors.onPrimary,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).chatResubscribeBanner,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).chatResubscribeAction,
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: KolabingColors.onPrimary,
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

  Widget _buildScaffold({
    required Widget body,
    Application? application,
    String? counterpartyName,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = counterpartyName ?? application?.recipientName ?? '';

    return Scaffold(
      backgroundColor: isDark
          ? KolabingColors.surface
          : KolabingColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: isDark
            ? KolabingColors.darkSurface
            : KolabingColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
          color: isDark
              ? KolabingColors.textOnDark
              : KolabingColors.onSurface,
        ),
        title: application != null
            ? Row(
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
                                ? KolabingColors.textOnDark
                                : KolabingColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          application.status.displayName,
                          style: KolabingTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: isDark
                                ? KolabingColors.textOnDark.withValues(
                                    alpha: 0.5,
                                  )
                                : KolabingColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : isLoading
            ? Text(
                AppLocalizations.of(context).chatLoading,
                style: TextStyle(
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.onSurface,
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
                      ? KolabingColors.textOnDark.withValues(alpha: 0.7)
                      : KolabingColors.onSurfaceVariant,
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
      color: KolabingColors.primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: KolabingTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: KolabingColors.primary,
        ),
      ),
    ),
  );

  Widget _buildApplicationHeader(Application application) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: KolabingColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: isDark ? KolabingColors.darkBorder : KolabingColors.darkBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.briefcase,
            size: 16,
            color: KolabingColors.primary,
          ),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              application.opportunityTitle,
              style: KolabingTextStyles.captionSecondary.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? KolabingColors.textOnDark
                    : KolabingColors.onSurface,
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: KolabingColors.primary,
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
        ? KolabingColors.darkBorder
        : KolabingColors.darkBorder;

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
                    ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                    : KolabingColors.textTertiary,
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
        color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
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
                      ? KolabingColors.surface
                      : KolabingColors.background,
                  borderRadius: KolabingRadius.borderRadiusRound,
                  border: Border.all(
                    color: isDark
                        ? KolabingColors.darkBorder
                        : KolabingColors.darkBorder,
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
                          ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                          : KolabingColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.md,
                      vertical: KolabingSpacing.sm,
                    ),
                  ),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? KolabingColors.textOnDark
                        : KolabingColors.onSurface,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Material(
              color: KolabingColors.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: isSending ? null : _handleSend,
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: isSending
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: KolabingColors.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(
                          LucideIcons.send,
                          size: 20,
                          color: KolabingColors.onPrimary,
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
          ? KolabingColors.darkSurface
          : KolabingColors.surfaceVariant,
      highlightColor: isDark
          ? KolabingColors.darkBorder
          : KolabingColors.surface,
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
                color: isDark ? KolabingColors.darkSurface : Colors.white,
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
          const Icon(
            LucideIcons.alertCircle,
            size: 48,
            color: KolabingColors.error,
          ),
          const SizedBox(height: KolabingSpacing.md),
          Text(
            error,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(chatDataProvider(widget.applicationId));
              ref
                  .read(chatMessagesProvider.notifier)
                  .load(widget.applicationId);
            },
            icon: const Icon(LucideIcons.rotateCcw, size: 16),
            label: Text(AppLocalizations.of(context).commonRetry),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
            ),
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
            const Icon(
              LucideIcons.logIn,
              size: 48,
              color: KolabingColors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).chatSessionExpiredTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? KolabingColors.textOnDark
                    : KolabingColors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).chatSessionExpiredBody,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                context.go(KolabingRoutes.login);
              },
              icon: const Icon(LucideIcons.logIn, size: 16),
              label: Text(AppLocalizations.of(context).chatSignIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
              ),
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
                color: KolabingColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.messageCircle,
                size: 28,
                color: KolabingColors.primary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).chatEmptyTitle,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? KolabingColors.textOnDark
                    : KolabingColors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).chatEmptyBody,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.onSurfaceVariant,
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
                if (application != null) {
                  final authState = ref.read(authProvider);
                  final isBusiness = authState.user?.isBusiness ?? false;
                  final routePrefix = isBusiness
                      ? '/business/explore/offer'
                      : '/community/explore/offer';
                  context.push(
                    '$routePrefix/${application.opportunityId}',
                    extra: application.opportunity,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.xCircle,
                color: KolabingColors.error,
              ),
              title: Text(
                AppLocalizations.of(context).chatCancelApplication,
                style: const TextStyle(color: KolabingColors.error),
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
        content: Text(
          l10n.chatCancelDialogBody,
        ),
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
                    backgroundColor: KolabingColors.success,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
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
            _buildAvatar(senderProfile),
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
                    ? KolabingColors.primary
                    : isDark
                    ? KolabingColors.darkSurface
                    : KolabingColors.surface,
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
                        color: KolabingColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Message content
                  Text(
                    message.content,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: isOwn
                          ? KolabingColors.onPrimary
                          : isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.onSurface,
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
                              ? KolabingColors.onPrimary.withValues(alpha: 0.7)
                              : isDark
                              ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                              : KolabingColors.textTertiary,
                        ),
                      ),
                      // Read receipts for own messages
                      if (isOwn) ...[
                        const SizedBox(width: 4),
                        _buildReadReceipt(),
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

  Widget _buildAvatar(SenderProfile profile) {
    if (profile.profilePhoto != null && profile.profilePhoto!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profile.profilePhoto!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(profile),
        ),
      );
    }
    return _buildFallbackAvatar(profile);
  }

  Widget _buildFallbackAvatar(SenderProfile profile) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: KolabingColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          profile.initial,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: KolabingColors.primary,
          ),
        ),
      ),
    );
  }

  /// Build read receipt indicator
  /// Single check (checkmark) = sent
  /// Double check (checkmarks) = read
  Widget _buildReadReceipt() {
    final isRead = message.isRead;
    final iconColor = KolabingColors.onPrimary.withValues(alpha: 0.7);

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
