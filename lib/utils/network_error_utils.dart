bool isOfflineNetworkError(String rawMessage) {
  final message = rawMessage.toLowerCase();

  return message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('no address associated with hostname') ||
      message.contains('nodename nor servname provided') ||
      message.contains('temporary failure in name resolution') ||
      message.contains('socketexception') && message.contains('errno = 8') ||
      message.contains('socketexception') && message.contains('errno = 7');
}

String userFriendlyNetworkMessage(String rawMessage) {
  final message = rawMessage.trim();
  final lower = message.toLowerCase();

  if (isOfflineNetworkError(message)) {
    return 'No internet connection. Turn off airplane mode or reconnect, then try again.';
  }

  if (lower.contains('timed out')) {
    return 'Connection timed out. Please try again.';
  }

  if (lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('software caused connection abort')) {
    return 'We could not reach the server. Please try again.';
  }

  if (message.startsWith('Failed to ')) {
    final summary = message.split(':').first.trim();
    return '$summary. Please try again.';
  }

  return 'We could not reach the server. Please try again.';
}
