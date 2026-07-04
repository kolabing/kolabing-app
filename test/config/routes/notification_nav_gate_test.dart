import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/routes/notification_nav_gate.dart';

void main() {
  group('NotificationNavGate', () {
    test('defers navigation while not ready (cold start on splash)', () {
      final navigated = <String>[];
      final gate = NotificationNavGate(onNavigate: navigated.add);

      gate.navigate('/collaboration/123');

      // Nothing navigates yet — splash is still up and would wipe it.
      expect(navigated, isEmpty);
      expect(gate.isReady, isFalse);
      expect(gate.pendingRoute, '/collaboration/123');
    });

    test('replays the pending route once ready (after splash routes)', () {
      final navigated = <String>[];
      final gate = NotificationNavGate(onNavigate: navigated.add);

      gate.navigate('/collaboration/123');
      gate.markReady();

      expect(navigated, ['/collaboration/123']);
      expect(gate.pendingRoute, isNull);
    });

    test('navigates immediately once ready (background/foreground taps)', () {
      final navigated = <String>[];
      final gate = NotificationNavGate(onNavigate: navigated.add);

      gate.markReady();
      gate.navigate('/application/456');

      expect(navigated, ['/application/456']);
    });

    test('markReady with no pending route is a no-op', () {
      final navigated = <String>[];
      final gate = NotificationNavGate(onNavigate: navigated.add);

      gate.markReady();

      expect(navigated, isEmpty);
    });

    test(
      'keeps only the most recent route when several arrive during cold start',
      () {
        final navigated = <String>[];
        final gate = NotificationNavGate(onNavigate: navigated.add);

        gate.navigate('/collaboration/1');
        gate.navigate('/application/2');
        gate.markReady();

        expect(navigated, ['/application/2']);
      },
    );

    test('markReady is idempotent and does not re-replay', () {
      final navigated = <String>[];
      final gate = NotificationNavGate(onNavigate: navigated.add);

      gate.navigate('/collaboration/123');
      gate.markReady();
      gate.markReady();

      expect(navigated, ['/collaboration/123']);
    });
  });
}
