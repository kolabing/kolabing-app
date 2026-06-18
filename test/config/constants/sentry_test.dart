import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/constants/sentry.dart';

void main() {
  group('SentryConfig', () {
    test('ships a default DSN and is enabled by default', () {
      expect(SentryConfig.dsn, isNotEmpty);
      expect(SentryConfig.isEnabled, isTrue);
    });

    test('default DSN targets the kolabing-mobile project', () {
      expect(SentryConfig.dsn, contains('ingest.de.sentry.io'));
      expect(SentryConfig.dsn, endsWith('/4511585430339664'));
    });

    test('environment resolves to a non-empty tag', () {
      expect(SentryConfig.environment, isNotEmpty);
    });

    test('traces sample rate stays within 0.0–1.0', () {
      final rate = SentryConfig.tracesSampleRate;
      expect(rate, inInclusiveRange(0.0, 1.0));
    });
  });
}
