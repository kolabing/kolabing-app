import '../environment.dart';

/// Real-time chat (Laravel Reverb) configuration — NF-16 B4 / Part B.
///
/// Reverb speaks the Pusher protocol over a self-hosted host, so these mirror
/// the **client-facing** `REVERB_*` env vars on the backend (see the Part A
/// ticket in `kolabing-v2`). They MUST match the deployed server exactly.
///
/// Self-gating: the realtime client is a **no-op until [appKey] is filled in**.
/// It ships dormant so there are no reconnect storms before the Reverb daemon
/// exists; once Part A is deployed, drop in `REVERB_APP_KEY` (and confirm host)
/// here and live chat activates with no other code change. Until then the
/// existing poll-on-open keeps threads current.
class RealtimeConfig {
  const RealtimeConfig._();

  /// `REVERB_APP_KEY` (public, client-facing). Empty = realtime disabled.
  static const String appKey = String.fromEnvironment('REVERB_APP_KEY');

  /// `wss` in production (`ws` only for local plaintext).
  static const String scheme = 'wss';

  /// `REVERB_HOST` — the WebSocket subdomain that proxies to the Reverb daemon.
  static const String host = 'ws.kolabing.com';

  /// `REVERB_PORT` (443 behind TLS).
  static const int port = 443;

  /// Laravel broadcasting auth route (Sanctum-guarded). This lives at the app
  /// root, NOT under `/api/v1` — confirm the exact path with Part A.
  static const String authEndpoint = Environment.broadcastAuth;

  /// Wire event name(s) the backend broadcasts `NewChatMessage` under. We bind
  /// to every candidate so the client works whether Part A keeps the class name
  /// or sets `broadcastAs()`. Keep in sync with the backend event.
  static const List<String> messageEventNames = <String>[
    'NewChatMessage',
    'message.sent',
    r'App\Events\NewChatMessage',
  ];

  /// Private channel name for a thread (Pusher `private-` prefix + the Laravel
  /// channel `chat.thread.{id}`).
  static String threadChannel(String threadId) =>
      'private-chat.thread.$threadId';

  /// True once a Reverb app key is provided — gates all realtime work.
  static bool get isConfigured => appKey.isNotEmpty;
}
