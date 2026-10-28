import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/chat/models/chat_message.dart';
import 'package:kolabing_app/features/chat/models/chat_thread.dart';

void main() {
  test('the kolabing_team thread type round-trips and is not a community', () {
    expect(
      ChatThreadType.fromString('kolabing_team'),
      ChatThreadType.kolabingTeam,
    );
    expect(ChatThreadType.kolabingTeam.toApiValue(), 'kolabing_team');
    expect(ChatThreadType.kolabingTeam.isCommunity, isFalse);
  });

  test('a team message has no sender profile and carries the offer card', () {
    final message = ChatMessage.fromJson(<String, dynamic>{
      'id': 'm1',
      'thread_id': 't1',
      'sender_profile': null,
      'sender_type': 'team',
      'sender_name': 'Kolabing team',
      'content': 'We think your club fits this venue.',
      'is_own': false,
      'created_at': '2026-10-28T16:00:00Z',
      'offer': <String, dynamic>{
        'id': 'o1',
        'kind': 'community_apply',
        'status': 'sent',
        'title': 'Host your run club at Cafe Mallorca',
        'venue_name': 'Cafe Mallorca',
        'proposed_date': '2026-11-12',
        'can_respond': true,
      },
    });

    expect(message.isFromTeam, isTrue);
    expect(message.isMine, isFalse);
    expect(message.sender.name, isEmpty);
    expect(message.offer?.id, 'o1');
    expect(message.offer?.canRespond, isTrue);
    expect(message.offer?.proposedDate, DateTime(2026, 11, 12));
  });

  test('an ordinary message is unchanged: not from the team, no offer', () {
    final message = ChatMessage.fromJson(<String, dynamic>{
      'id': 'm2',
      'thread_id': 't2',
      'sender_profile': <String, dynamic>{'id': 'p1', 'display_name': 'Ana'},
      'sender_type': 'profile',
      'content': 'Hi',
      'is_own': true,
      'created_at': '2026-10-28T16:00:00Z',
    });

    expect(message.isFromTeam, isFalse);
    expect(message.offer, isNull);
    expect(message.sender.name, 'Ana');
    expect(message.isMine, isTrue);
  });
}
