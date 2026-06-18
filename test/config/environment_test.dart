import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/environment.dart';

void main() {
  group('Environment.resolveFlavor', () {
    test('prod flavor resolves to prod', () {
      expect(Environment.resolveFlavor('prod'), AppEnvironment.prod);
    });
    test('dev flavor resolves to dev', () {
      expect(Environment.resolveFlavor('dev'), AppEnvironment.dev);
    });
    test('null (no flavor) defaults to dev', () {
      expect(Environment.resolveFlavor(null), AppEnvironment.dev);
    });
    test('unknown flavor defaults to dev', () {
      expect(Environment.resolveFlavor('staging'), AppEnvironment.dev);
    });
    test('prod uses kolabing.com REST base', () {
      expect(
        Environment.apiBaseUrlFor(AppEnvironment.prod),
        'https://kolabing.com/api/v1',
      );
    });
    test('dev uses the laravel.cloud REST base', () {
      expect(
        Environment.apiBaseUrlFor(AppEnvironment.dev),
        'https://kolabing-v2-development-uhzrzd.laravel.cloud/api/v1',
      );
    });
    test('const apiBaseUrl stays in sync with apiBaseUrlFor(current)', () {
      expect(
        Environment.apiBaseUrl,
        Environment.apiBaseUrlFor(Environment.current),
      );
    });
  });
}
