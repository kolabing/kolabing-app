import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_thread.dart';
import '../providers/chat_providers.dart';
import '../services/chat_service.dart';
import '../services/pending_team_link.dart';
import 'chat_thread_screen.dart';

/// Opens a "Kolabing team" thread from a link or a push tap (SERR-1344).
///
/// - [offerId]: a tapped offer link (`/o/{offerId}`). The backend resolves the
///   offer to its thread. Signed out, the route is parked
///   ([PendingTeamLink]) and the person goes to sign in; after sign-in they come
///   back here, so they land on the card.
/// - [threadId]: the push for a team message, whose thread id the push carries.
///   (Before this, the tap opened the chats list and left the finding to the
///   person.)
///
/// Either way it ends on [ChatThreadScreen], which is where the offer card and
/// its Accept / Not now live. If the thread cannot be found, a short message
/// and a way to the chats list.
class TeamLinkScreen extends ConsumerStatefulWidget {
  const TeamLinkScreen({this.offerId, this.threadId, super.key})
    : assert(offerId != null || threadId != null);

  final String? offerId;
  final String? threadId;

  @override
  ConsumerState<TeamLinkScreen> createState() => _TeamLinkScreenState();
}

class _TeamLinkScreenState extends ConsumerState<TeamLinkScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (!ref.read(authProvider).isAuthenticated) {
      if (widget.offerId != null) {
        await PendingTeamLink.save('/team-offer/${widget.offerId}');
      }
      if (!mounted) return;
      context.go(KolabingRoutes.welcome);
      return;
    }

    try {
      final svc = ref.read(chatServiceProvider);
      final threadId =
          widget.threadId ?? (await svc.getTeamOffer(widget.offerId!)).threadId;
      final threads = await svc.getThreads();
      final ChatThread? thread = threads
          .where((t) => t.id == threadId)
          .cast<ChatThread?>()
          .firstWhere((_) => true, orElse: () => null);

      if (!mounted) return;
      if (thread == null) {
        setState(() => _failed = true);
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ChatThreadScreen(thread: thread),
        ),
      );
    } on ChatException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: _failed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.teamLinkNotFound,
                      key: const ValueKey('team-link-error'),
                      textAlign: TextAlign.center,
                      style: KolabingTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: KolabingSpacing.md),
                    FilledButton(
                      key: const ValueKey('team-link-open-chats'),
                      onPressed: () => context.go(KolabingRoutes.chats),
                      child: Text(l10n.teamLinkOpenChats),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
