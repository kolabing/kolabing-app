import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/community/models/community_join_question.dart';
import 'package:kolabing_app/features/community/services/community_service.dart';

CommunityService _service(
  http.Response Function(http.BaseRequest) respond, {
  List<http.BaseRequest>? seen,
}) {
  final client = MockClient((request) async {
    seen?.add(request);
    return respond(request);
  });
  return CommunityService(
    authService: AuthService(
      secureStorage: const FlutterSecureStorage(),
      httpClient: client,
    ),
    httpClient: client,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  group('follow / unfollow', () {
    test('follow posts to the follow route', () async {
      final seen = <http.BaseRequest>[];
      final service = _service(
        (_) =>
            http.Response('{"success":true,"data":{"is_following":true}}', 201),
        seen: seen,
      );

      await service.followCommunity('c-1');

      expect(seen.single.method, 'POST');
      expect(seen.single.url.path, endsWith('/communities/c-1/follow'));
    });

    test('unfollow deletes the same route', () async {
      final seen = <http.BaseRequest>[];
      final service = _service(
        (_) => http.Response(
          '{"success":true,"data":{"is_following":false}}',
          200,
        ),
        seen: seen,
      );

      await service.unfollowCommunity('c-1');

      expect(seen.single.method, 'DELETE');
      expect(seen.single.url.path, endsWith('/communities/c-1/follow'));
    });

    /// The app must be shippable before the backend deploys, so a missing route
    /// is a typed, ignorable failure rather than a crash.
    test('a missing route self-gates as request_unavailable', () async {
      final service = _service((_) => http.Response('', 404));

      await expectLater(
        service.followCommunity('c-1'),
        throwsA(
          isA<CommunityException>().having(
            (e) => e.code,
            'code',
            'request_unavailable',
          ),
        ),
      );
    });

    test('my follows returns the community ids', () async {
      final service = _service(
        (_) => http.Response(
          '{"success":true,"data":[{"community":{"id":"c-1","name":"A"}},'
          '{"community":{"id":"c-2","name":"B"}}]}',
          200,
        ),
      );

      expect(await service.myFollowedCommunityIds(), ['c-1', 'c-2']);
    });
  });

  group('join questions', () {
    test('reads the question set', () async {
      final service = _service(
        (_) => http.Response(
          '{"success":true,"data":{"questions":['
          '{"id":"q1","prompt":"Why join?","position":1,"required":true},'
          '{"id":"q2","prompt":"How far?","position":2,"required":false}'
          ']}}',
          200,
        ),
      );

      final questions = await service.joinQuestions('c-1');

      expect(questions.map((q) => q.prompt), ['Why join?', 'How far?']);
      expect(questions.first.required, isTrue);
      expect(questions.last.required, isFalse);
    });

    /// An empty set is the normal answer: it means membership is not gated by an
    /// application, and "Become a member" should go straight through.
    test('an empty set is not an error', () async {
      final service = _service(
        (_) => http.Response('{"success":true,"data":{"questions":[]}}', 200),
      );

      expect(await service.joinQuestions('c-1'), isEmpty);
    });

    test(
      'a question missing its prompt is dropped rather than rendered blank',
      () async {
        final service = _service(
          (_) => http.Response(
            '{"success":true,"data":{"questions":[{"id":"q1","prompt":""}]}}',
            200,
          ),
        );

        expect(await service.joinQuestions('c-1'), isEmpty);
      },
    );

    test('required defaults to true when the field is absent', () {
      final q = CommunityJoinQuestion.fromJson({'id': 'q', 'prompt': 'p'});

      expect(q.required, isTrue);
    });
  });

  group('requestToJoin', () {
    /// The important one. The backend enforces required answers ONLY when the
    /// `answers` key is present, precisely so builds that predate the questions
    /// flow keep working. Sending an empty array would opt this client into that
    /// enforcement for nothing.
    test('sends no body at all when no answers were collected', () async {
      final seen = <http.BaseRequest>[];
      final service = _service(
        (_) => http.Response('{"success":true,"data":{}}', 201),
        seen: seen,
      );

      await service.requestToJoin('c-1');

      final body = (seen.single as http.Request).body;
      expect(body, isEmpty, reason: 'no answers key means no enforcement');
    });

    test('sends the answers when they were collected', () async {
      final seen = <http.BaseRequest>[];
      final service = _service(
        (_) => http.Response('{"success":true,"data":{}}', 201),
        seen: seen,
      );

      await service.requestToJoin(
        'c-1',
        answers: const [
          CommunityJoinAnswer(questionId: 'q1', answer: 'Because I run.'),
        ],
      );

      final body =
          jsonDecode((seen.single as http.Request).body)
              as Map<String, dynamic>;
      expect(body, {
        'answers': [
          {'question_id': 'q1', 'answer': 'Because I run.'},
        ],
      });
    });

    test('an empty answers list is still sent as a key', () async {
      final seen = <http.BaseRequest>[];
      final service = _service(
        (_) => http.Response('{"success":true,"data":{}}', 201),
        seen: seen,
      );

      await service.requestToJoin('c-1', answers: const []);

      final body =
          jsonDecode((seen.single as http.Request).body)
              as Map<String, dynamic>;
      expect(body, {'answers': <dynamic>[]});
    });
  });

  group('the application gate', () {
    /// A leader who added questions turns one-tap join off; the app has to read
    /// that as "run the application", not as a failure.
    test(
      'join surfaces join_requires_application as needsApplication',
      () async {
        final service = _service(
          (_) => http.Response(
            '{"success":false,"error":"join_requires_application",'
            '"message":"This community asks a few questions before you join."}',
            409,
          ),
        );

        await expectLater(
          service.joinCommunity('c-1'),
          throwsA(
            isA<CommunityException>()
                .having((e) => e.needsApplication, 'needsApplication', isTrue)
                .having((e) => e.isInviteOnly, 'isInviteOnly', isFalse),
          ),
        );
      },
    );
  });
}
