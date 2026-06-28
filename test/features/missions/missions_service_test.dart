import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kolabing_app/features/auth/services/auth_service.dart';
import 'package:kolabing_app/features/missions/services/missions_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'auth_token': 'token-123',
    });
  });

  test('throws MissionException when data.missions is missing on a 200', () async {
    final client = MockClient((request) async {
      return http.Response('{"success": true, "data": {"oops": []}}', 200);
    });

    final service = MissionsService(
      authService: AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      ),
      httpClient: client,
    );

    expect(() => service.getMyMissions(), throwsA(isA<MissionException>()));
  });

  test('returns an empty list when data.missions is genuinely empty on a 200', () async {
    final client = MockClient((request) async {
      return http.Response('{"success": true, "data": {"missions": []}}', 200);
    });

    final service = MissionsService(
      authService: AuthService(
        secureStorage: const FlutterSecureStorage(),
        httpClient: client,
      ),
      httpClient: client,
    );

    final missions = await service.getMyMissions();

    expect(missions, isEmpty);
  });
}
