import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/chat/models/chat_thread.dart';

void main() {
  test('parses the Batch 2 management fields + event summary', () {
    final thread = ChatThread.fromJson(<String, dynamic>{
      'id': 'thread-1',
      'type': 'event',
      'name': 'Sat Run',
      'event_id': 'event-7',
      'event': {'id': 'event-7', 'name': 'Saturday Run', 'date': '2026-06-14'},
      'is_open': true,
      'can_manage': true,
      'is_member': true,
      'is_participant': false,
      'unread_count': 0,
      'participant_summary': const <dynamic>[],
      'created_at': '2026-06-01T10:00:00Z',
    });

    expect(thread.isOpen, isTrue);
    expect(thread.canManage, isTrue);
    expect(thread.isMember, isTrue);
    expect(thread.isParticipant, isFalse);
    expect(thread.event?.id, 'event-7');
    expect(thread.event?.name, 'Saturday Run');
    expect(thread.isDeletable, isTrue); // event chats are deletable
    expect(thread.isRenamable, isFalse); // only custom chats rename
    expect(thread.canJoin, isTrue); // open + not yet a participant
  });

  test('defaults the new flags to false when absent', () {
    final thread = ChatThread.fromJson(<String, dynamic>{
      'id': 'thread-2',
      'type': 'community_custom',
      'created_at': '2026-06-01T10:00:00Z',
    });

    expect(thread.isOpen, isFalse);
    expect(thread.canManage, isFalse);
    expect(thread.isParticipant, isFalse);
    expect(thread.canJoin, isFalse);
    expect(thread.isRenamable, isTrue);
    expect(thread.isDeletable, isTrue);
    expect(thread.event, isNull);
  });

  test('participant carries a profile id for the ban action', () {
    final thread = ChatThread.fromJson(<String, dynamic>{
      'id': 'thread-3',
      'type': 'collaboration',
      'participant_summary': [
        {'name': 'Maria', 'profile_id': 'p1'},
        {'name': 'Run Club', 'id': 'p2'},
      ],
      'created_at': '2026-06-01T10:00:00Z',
    });

    expect(thread.participants.first.profileId, 'p1');
    expect(thread.participants.last.profileId, 'p2');
  });

  test('parses the last_message preview (#8)', () {
    final withPreview = ChatThread.fromJson(<String, dynamic>{
      'id': 't1',
      'type': 'community_custom',
      'created_at': '2026-06-01T10:00:00Z',
      'last_message_at': '2026-06-02T09:00:00Z',
      'last_message': <String, dynamic>{
        'content': 'See you at 6!',
        'created_at': '2026-06-02T09:00:00Z',
      },
    });
    expect(withPreview.lastMessagePreview, 'See you at 6!');
    expect(withPreview.hasMessages, isTrue);
  });

  test('last_message preview is null when the backend omits it (#8 fallback)', () {
    final noPreview = ChatThread.fromJson(<String, dynamic>{
      'id': 't2',
      'type': 'community_custom',
      'created_at': '2026-06-01T10:00:00Z',
      'last_message_at': '2026-06-02T09:00:00Z',
    });
    // Older backend: has a timestamp but no preview → list shows "Tap to open".
    expect(noPreview.lastMessagePreview, isNull);
    expect(noPreview.hasMessages, isTrue);
  });
}
