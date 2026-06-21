import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/environment.dart';

void main() {
  group('Environment.resolveEnv', () {
    test('APP_ENV=prod resolves to prod (even in debug)', () {
      expect(
        Environment.resolveEnv('prod', isRelease: false),
        AppEnvironment.prod,
      );
    });
    test('APP_ENV=dev resolves to dev (even in release)', () {
      expect(
        Environment.resolveEnv('dev', isRelease: true),
        AppEnvironment.dev,
      );
    });
    test('no define + release defaults to prod (safe release)', () {
      expect(Environment.resolveEnv('', isRelease: true), AppEnvironment.prod);
    });
    test('no define + debug defaults to dev', () {
      expect(Environment.resolveEnv('', isRelease: false), AppEnvironment.dev);
    });
    test('unknown define + debug defaults to dev', () {
      expect(
        Environment.resolveEnv('staging', isRelease: false),
        AppEnvironment.dev,
      );
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
