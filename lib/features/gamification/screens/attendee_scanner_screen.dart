import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/permission_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../event/providers/event_provider.dart';
import '../models/event_checkin.dart';
import '../models/qr_payload.dart';
import '../../community/widgets/membership_prompt.dart';
import '../providers/active_event_session_provider.dart';
import '../providers/checkin_provider.dart';
import '../services/checkin_service.dart';
import '../widgets/peer_challenge_sheet.dart';
import '../widgets/qr_scan_frame.dart';
import '../widgets/scan_outcome_sheet.dart';
import 'challenge_together_screen.dart';

/// The one scanner a member ever needs.
///
/// It reads all three Kolabing codes and routes each to its step of the loop:
///
/// - an **event code** checks you in and opens the active-event session;
/// - a **member's profile code** pairs you up and lists that event's challenges;
/// - a **verification code** confirms a challenge someone else played.
///
/// Members do not have to know which is which — that classification is
/// [QrPayload.parse]'s job, which is why there is one scanner and not three.
class AttendeeScannerScreen extends ConsumerStatefulWidget {
  const AttendeeScannerScreen({super.key, this.eventId, this.eventName});

  /// The event the scanner was opened from, when it was opened from one.
  ///
  /// This is the recovery path for a duplicate check-in: `POST /checkin`
  /// answers 409 without saying which event, so without this the member ends up
  /// checked in server-side with no local session — and the only thing the app
  /// can suggest is rescanning the code that 409s.
  final String? eventId;
  final String? eventName;

  static Future<void> open(
    BuildContext context, {
    String? eventId,
    String? eventName,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            AttendeeScannerScreen(eventId: eventId, eventName: eventName),
      ),
    );
  }

  @override
  ConsumerState<AttendeeScannerScreen> createState() =>
      _AttendeeScannerScreenState();
}

class _AttendeeScannerScreenState extends ConsumerState<AttendeeScannerScreen> {
  /// Ignore a repeat of the same code for this long. The old scanner latched a
  /// `_hasScanned` flag forever, so one bad scan meant closing and reopening
  /// the screen; a window lets a retry just work.
  static const Duration _repeatWindow = Duration(seconds: 3);

  late final MobileScannerController _controller;

  bool _busy = false;
  bool _torchOn = false;
  String? _lastValue;
  DateTime? _lastAt;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Scan dispatch
  // ---------------------------------------------------------------------------

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final now = DateTime.now();
    if (raw == _lastValue &&
        _lastAt != null &&
        now.difference(_lastAt!) < _repeatWindow) {
      return;
    }
    _lastValue = raw;
    _lastAt = now;

    final payload = QrPayload.parse(raw);

    if (payload is QrUnknown) {
      // Not ours: nudge and keep the camera live rather than tearing down.
      HapticFeedback.lightImpact();
      _snack(AppLocalizations.of(context).scannerUnknownCode);
      return;
    }

    setState(() => _busy = true);
    await _controller.stop();
    await HapticFeedback.mediumImpact();

    switch (payload) {
      case QrCheckinToken(:final token):
        await _checkIn(token);
      case QrPeerProfile(:final profileRef):
        await _pair(profileRef);
      case QrVerifyCompletion():
        // Retired in #140 — a challenge is agreed with one scan and confirmed
        // on the partner's own device, so nothing shows a verify QR any more.
        // Still parsed so an old screenshot of one reads as "not ours" rather
        // than as a check-in token.
        _snack(AppLocalizations.of(context).scannerUnknownCode);
        await _resume();
      case QrUnknown():
        break; // handled above
    }
  }

  /// Re-arms the camera so the member can scan the next code without leaving.
  Future<void> _resume() async {
    if (!mounted) return;
    setState(() => _busy = false);
    await _controller.start();
  }

  // ---------------------------------------------------------------------------
  // Step 1 — check in
  // ---------------------------------------------------------------------------

  Future<void> _checkIn(String token) async {
    final l10n = AppLocalizations.of(context);
    final ok = await ref.read(checkinProvider.notifier).checkIn(token);
    if (!mounted) return;

    final state = ref.read(checkinProvider);

    if (!ok) {
      await _showCheckinFailure(state, l10n);
      return;
    }

    final checkin = state.checkin;
    if (checkin != null) {
      await ref.read(activeEventSessionProvider.notifier).start(checkin);

      // Turning up is the moment worth asking whether they want to belong
      // (#148). After the session opens, so a "not now" leaves them able to
      // play regardless.
      if (mounted) {
        await MembershipPrompt.maybeOffer(context, ref, checkin);
      }
    }
    if (!mounted) return;

    final eventName = checkin?.eventName ?? widget.eventName;
    final action = await ScanOutcomeSheet.show(
      context,
      tone: ScanOutcomeTone.success,
      title: l10n.qrScannerSuccessTitle,
      body: eventName == null
          ? l10n.checkinNextStep
          : '${l10n.checkinSuccessBody(eventName)}\n\n${l10n.checkinNextStep}',
      xpEarned: checkin?.pointsEarned,
      // The natural next move is pairing up, so that is the primary action.
      primaryLabel: l10n.checkinScanPeer,
      secondaryLabel: l10n.commonDone,
    );
    await _afterOutcome(action);
  }

  Future<void> _showCheckinFailure(
    CheckinState state,
    AppLocalizations l10n,
  ) async {
    final failure = state.failure;

    // `alreadyCheckedIn` is not a failure the member caused — they are where
    // they wanted to be. It also has to leave them with a usable session, or
    // pairing sends them back to rescan the very code that just 409'd.
    if (failure == CheckinFailure.alreadyCheckedIn) {
      await _recoverSession(state.checkin);
      if (!mounted) return;

      final action = await ScanOutcomeSheet.show(
        context,
        tone: ScanOutcomeTone.info,
        title: l10n.checkinAlreadyTitle,
        body: '${l10n.scannerAlreadyCheckedIn}\n\n${l10n.checkinNextStep}',
        primaryLabel: l10n.checkinScanPeer,
        secondaryLabel: l10n.commonDone,
      );
      await _afterOutcome(action);
      return;
    }

    final action = await ScanOutcomeSheet.show(
      context,
      tone: ScanOutcomeTone.failure,
      title: l10n.qrScannerErrorTitle,
      body: switch (failure) {
        CheckinFailure.invalidToken => l10n.checkinInvalidToken,
        CheckinFailure.notAcceptingCheckins => l10n.checkinNotAccepting,
        _ => l10n.commonErrorGeneric,
      },
      primaryLabel: l10n.commonTryAgain,
    );
    await _afterOutcome(action);
  }

  /// Opens a session after a duplicate check-in.
  ///
  /// A 409 means the server has us checked in but will not say to what — the
  /// response body is `{success, message}` with no `data` (verified against the
  /// dev API). Without recovering the event here, the member is checked in
  /// server-side yet cannot pair up, and the only thing the app can suggest is
  /// rescanning the code that just 409'd.
  ///
  /// Three sources, best first:
  ///  1. the check-in on the 409 body, if a future backend starts sending one;
  ///  2. the event this scanner was opened from (the event-hub path);
  ///  3. `GET /events?attendee=me&time=upcoming` — events the viewer has a
  ///     check-in or live signup for. Used only when it names exactly one, so a
  ///     guess is never presented as fact.
  Future<void> _recoverSession(EventCheckin? fromResponse) async {
    final notifier = ref.read(activeEventSessionProvider.notifier);

    if (fromResponse != null) {
      await notifier.start(fromResponse);
      return;
    }

    final eventId = widget.eventId;
    if (eventId != null && eventId.isNotEmpty) {
      await notifier.startForEvent(
        eventId: eventId,
        eventName: widget.eventName,
      );
      return;
    }

    try {
      final result = await ref
          .read(eventServiceProvider)
          .getEvents(mine: true, time: 'upcoming', limit: 5);

      if (result.events.length == 1) {
        final only = result.events.first;
        await notifier.startForEvent(eventId: only.id, eventName: only.name);
      }
      // More than one live event, or none: do not guess. The member still gets
      // the "you're already checked in" sheet, and pairing will ask them to
      // scan the event code.
    } on Object catch (e) {
      debugPrint('scanner: could not recover the active event: $e');
    }
  }

  /// Closes the scanner when the member chose the "done" action; otherwise
  /// hands the camera back.
  ///
  /// Navigation happens here rather than inside a sheet callback: popping the
  /// scanner from a callback left this method's `await` to resume and restart a
  /// camera controller that `dispose()` was already tearing down.
  Future<void> _afterOutcome(ScanOutcomeAction action) async {
    if (!mounted) return;
    if (action == ScanOutcomeAction.secondary) {
      Navigator.of(context).maybePop();
      return;
    }
    await _resume();
  }

  // ---------------------------------------------------------------------------
  // Step 2 — pair up and pick a challenge
  // ---------------------------------------------------------------------------

  Future<void> _pair(String profileRef) async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authProvider).user;

    if (profileRef == user?.id || profileRef == user?.handle) {
      _snack(l10n.scannerOwnCode);
      await _resume();
      return;
    }

    final result = await PeerChallengeSheet.show(
      context,
      peerProfileRef: profileRef,
    );
    if (!mounted) return;

    if (result.outcome == PeerSheetOutcome.challengeStarted &&
        result.completionId != null) {
      // No second QR: the other phone finds out on its own and opens this same
      // screen. One scan between two people, and the app holds the moment
      // instead of the paperwork (#140).
      await ChallengeTogetherScreen.open(
        context,
        completionId: result.completionId!,
        role: TogetherRole.starter,
        challengeName: result.challengeName,
        challengeDescription: result.challengeDescription,
        otherName: result.verifierName,
        points: result.points,
      );
    }

    // Both the "scan the event code instead" and the dismissed cases simply
    // hand the camera back.
    await _resume();
  }

  // ---------------------------------------------------------------------------
  // Step 4 — confirm someone else's challenge
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stored = ref.watch(activeEventSessionProvider);
    final session = stored == null || stored.isExpired ? null : stored;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.qrScannerTitle,
          style: KolabingTextStyles.titleSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.scannerTorchTooltip,
            icon: Icon(
              _torchOn ? LucideIcons.zapOff : LucideIcons.zap,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (session?.eventName != null)
              _ActiveEventBanner(eventName: session!.eventName!),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(KolabingSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) =>
                            _CameraUnavailable(error: error),
                      ),
                      QrScanFrame(active: _busy),
                      if (_busy)
                        const ColoredBox(
                          color: Colors.black54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KolabingSpacing.lg,
                0,
                KolabingSpacing.lg,
                KolabingSpacing.lg,
              ),
              child: Column(
                children: [
                  Text(
                    l10n.qrScannerInstructionTitle,
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xs),
                  Text(
                    l10n.qrScannerInstructionSubtitle,
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reminds the member which event they are checked in to — the context that
/// decides which challenges the next peer scan will offer.
class _ActiveEventBanner extends StatelessWidget {
  const _ActiveEventBanner({required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: KolabingSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.mapPin, size: 14, color: context.colors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l10n.peerPairedAtEvent(eventName),
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.labelSmall.copyWith(
                color: context.colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the camera preview when the camera cannot start — most often
/// a denied permission, where the only useful action is the system settings.
class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.cameraOff, color: Colors.white54, size: 40),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.scannerCameraBlocked,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton(
              onPressed: PermissionService.instance.openSettings,
              child: Text(l10n.permissionDeniedDialogOpenSettings),
            ),
          ],
        ),
      ),
    );
  }
}
