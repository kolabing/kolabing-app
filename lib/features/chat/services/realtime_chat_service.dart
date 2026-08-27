import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import '../../../config/constants/realtime.dart';
import '../models/chat_message.dart';

/// Handle for a live thread subscription. Cancel it in the screen's `dispose()`
/// to stop listening, unsubscribe the channel, and (when it's the last one)
/// tear down the shared client.
class RealtimeThreadSubscription {
  RealtimeThreadSubscription._(this._onCancel);

  final Future<void> Function() _onCancel;
  bool _cancelled = false;

  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    await _onCancel();
  }
}

/// Real-time chat over Laravel Reverb (Pusher protocol) — NF-16 B4 / Part B.
///
/// One WebSocket client app-wide, lazily created on the first subscribe and
/// torn down when the last thread unsubscribes. **Fail-safe**: every entry
/// point is guarded and a no-op when realtime is unconfigured (see
/// [RealtimeConfig.isConfigured]) or auth is missing, so chat keeps working via
/// the existing poll-on-open. Never throws into a caller.
class RealtimeChatService {
  RealtimeChatService._();

  static final RealtimeChatService instance = RealtimeChatService._();

  PusherChannelsClient? _client;
  StreamSubscription<void>? _connectionSub;

  /// Channels we want subscribed, kept so we can re-subscribe on every
  /// (re)connection — the recommended Reverb resubscribe pattern.
  final Map<String, PrivateChannel> _channels = <String, PrivateChannel>{};

  /// Whether realtime is switched on (a Reverb app key is configured).
  bool get isEnabled => RealtimeConfig.isConfigured;

  /// Subscribe to a thread's private channel and call [onMessage] for each
  /// inbound message. Returns `null` (and the screen falls back to polling) if
  /// realtime is off, the token is missing, or setup fails.
  Future<RealtimeThreadSubscription?> subscribeToThread(
    String threadId, {
    required String? token,
    required void Function(ChatMessage message) onMessage,
  }) async {
    if (!isEnabled || token == null || token.isEmpty) return null;

    try {
      final client = _ensureClient();
      final channelName = RealtimeConfig.threadChannel(threadId);

      final channel = client.privateChannel(
        channelName,
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
              authorizationEndpoint: Uri.parse(RealtimeConfig.authEndpoint),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            ),
      );

      final eventSubs = <StreamSubscription<ChannelReadEvent>>[
        for (final eventName in RealtimeConfig.messageEventNames)
          channel.bind(eventName).listen((event) {
            final message = _tryParseMessage(event);
            if (message != null) onMessage(message);
          }),
      ];

      _channels[channelName] = channel;
      // Covers the already-connected case (a 2nd thread opened later); the
      // onConnectionEstablished listener covers (re)connects. Idempotent.
      channel.subscribeIfNotUnsubscribed();

      return RealtimeThreadSubscription._(() async {
        for (final sub in eventSubs) {
          await sub.cancel();
        }
        try {
          channel.unsubscribe();
        } on Object catch (_) {
          /* best-effort */
        }
        _channels.remove(channelName);
        if (_channels.isEmpty) {
          await _teardownClient();
        }
      });
    } on Object catch (e) {
      debugPrint('[Realtime] subscribeToThread failed: $e');
      return null;
    }
  }

  PusherChannelsClient _ensureClient() {
    final existing = _client;
    if (existing != null) return existing;

    final client = PusherChannelsClient.websocket(
      options: const PusherChannelsOptions.fromHost(
        scheme: RealtimeConfig.scheme,
        host: RealtimeConfig.host,
        key: RealtimeConfig.appKey,
        port: RealtimeConfig.port,
      ),
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('[Realtime] connection error: $exception');
        refresh();
      },
    );

    // Re-subscribe every tracked channel on connect AND reconnect.
    _connectionSub = client.onConnectionEstablished.listen((_) {
      for (final channel in _channels.values) {
        channel.subscribeIfNotUnsubscribed();
      }
    });

    _client = client;
    unawaited(client.connect());
    return client;
  }

  Future<void> _teardownClient() async {
    await _connectionSub?.cancel();
    _connectionSub = null;
    try {
      _client?.dispose();
    } on Object catch (_) {
      /* best-effort */
    }
    _client = null;
  }

  ChatMessage? _tryParseMessage(ChannelReadEvent event) {
    try {
      final data = event.tryGetDataAsMap();
      if (data == null) return null;
      // Broadcast payload is either the message resource directly or wrapped
      // under a `message` key (Laravel `broadcastWith`).
      final raw = data['message'] is Map<String, dynamic>
          ? data['message'] as Map<String, dynamic>
          : data;
      return ChatMessage.fromJson(raw);
    } on Object catch (e) {
      debugPrint('[Realtime] message parse failed: $e');
      return null;
    }
  }
}
