import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/auth/providers/auth_provider.dart';

void main() {
  group('UserTerms parsing (from GET /auth/me)', () {
    test('parses the terms block and flags re-consent', () {
      final user = UserModel.fromJson(<String, dynamic>{
        'id': 1,
        'email': 'a@b.com',
        'user_type': 'community',
        'terms': <String, dynamic>{
          'current_version': '2026-07-12',
          'accepted_version': '2026-01-01',
          'accepted_at': '2026-01-01T10:00:00+00:00',
          'needs_acceptance': true,
        },
      });

      expect(user.terms, isNotNull);
      expect(user.terms!.currentVersion, '2026-07-12');
      expect(user.terms!.acceptedVersion, '2026-01-01');
      expect(user.terms!.acceptedAt, isNotNull);
      expect(user.terms!.needsAcceptance, isTrue);
      expect(user.needsTermsAcceptance, isTrue);
    });

    test(
      'missing terms block → needsTermsAcceptance is false (older payloads)',
      () {
        final user = UserModel.fromJson(<String, dynamic>{
          'id': 2,
          'email': 'c@d.com',
          'user_type': 'business',
        });

        expect(user.terms, isNull);
        expect(user.needsTermsAcceptance, isFalse);
      },
    );

    test('accepted the current version → no re-consent needed', () {
      final user = UserModel.fromJson(<String, dynamic>{
        'id': 3,
        'email': 'e@f.com',
        'user_type': 'attendee',
        'terms': <String, dynamic>{
          'current_version': '2026-07-12',
          'accepted_version': '2026-07-12',
          'needs_acceptance': false,
        },
      });

      expect(user.needsTermsAcceptance, isFalse);
    });
  });

  group('AuthState.needsTermsConsent gate', () {
    UserModel userNeeding(bool needs) => UserModel(
      id: '1',
      email: 'a@b.com',
      userType: UserType.community,
      terms: UserTerms(currentVersion: '2026-07-12', needsAcceptance: needs),
    );

    test('true when authenticated AND the user needs acceptance', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: userNeeding(true),
      );
      expect(state.needsTermsConsent, isTrue);
    });

    test('false when the user does not need acceptance', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: userNeeding(false),
      );
      expect(state.needsTermsConsent, isFalse);
    });

    test('false when not authenticated, even if terms are outdated', () {
      final state = AuthState(
        status: AuthStatus.unauthenticated,
        user: userNeeding(true),
      );
      expect(state.needsTermsConsent, isFalse);
    });
  });
}
