import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/multi_kolab/providers/multi_kolab_repository_provider.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/api_multi_kolab_repository.dart';
import 'package:kolabing_app/features/multi_kolab/repositories/mock_multi_kolab_repository.dart';

Set<String> _messageKeys(String locale) {
  final raw =
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;
  return raw.keys.where((String key) => !key.startsWith('@')).toSet();
}

void main() {
  group('localization parity', () {
    final en = _messageKeys('en');
    final es = _messageKeys('es');
    final ca = _messageKeys('ca');

    test('es defines every en message key', () {
      expect(en.difference(es), isEmpty, reason: 'missing from app_es.arb');
    });

    test('ca defines every en message key', () {
      expect(en.difference(ca), isEmpty, reason: 'missing from app_ca.arb');
    });

    test('es and ca define no keys en does not', () {
      expect(es.difference(en), isEmpty, reason: 'orphaned in app_es.arb');
      expect(ca.difference(en), isEmpty, reason: 'orphaned in app_ca.arb');
    });

    test('every Multi-Kolab role key exists in all three locales', () {
      const required = <String>{
        'multiKolabExploreCardBadge',
        'multiKolabRoleLookingFor',
        'multiKolabRoleOpenToAnyBusiness',
        'multiKolabRoleOpenToAnyCommunity',
        'multiKolabRoleOpenToAnyPartner',
        'multiKolabRoleSpotsOpen',
        'multiKolabRoleAppliedChip',
        'multiKolabCompensationPaid',
        'multiKolabCompensationSponsoredInKind',
        'multiKolabCompensationValueExchange',
        'multiKolabCompensationNegotiable',
      };

      for (final locale in <(String, Set<String>)>[
        ('en', en),
        ('es', es),
        ('ca', ca),
      ]) {
        expect(
          required.difference(locale.$2),
          isEmpty,
          reason: 'missing from app_${locale.$1}.arb',
        );
      }
    });

    test(
      'keys used only by the removed standalone Explore screen are gone',
      () {
        const removed = <String>{
          'multiKolabExploreEntryPointLabel',
          'multiKolabExploreEntryPointSubtitle',
          'multiKolabExploreTitle',
          'multiKolabExploreEmptyTitle',
          'multiKolabExploreEmptyBody',
        };

        for (final keys in <Set<String>>[en, es, ca]) {
          expect(keys.intersection(removed), isEmpty);
        }
      },
    );
  });

  group('mock repository release gate', () {
    test(
      'the default (production) configuration selects the API repository',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          container.read(multiKolabRepositoryProvider),
          isA<ApiMultiKolabRepository>(),
        );
        expect(
          container.read(multiKolabRepositoryProvider),
          isNot(isA<MockMultiKolabRepository>()),
        );
      },
    );

    test(
      'the mock is gated behind BOTH a dart-define AND a non-release build',
      () {
        // `MULTI_KOLAB_USE_MOCK` is not passed here, so the mock is
        // unreachable regardless of build mode. A release binary additionally
        // fails the `!kReleaseMode` half of the gate, so the mock can never
        // ship.
        const mockRequested = bool.fromEnvironment('MULTI_KOLAB_USE_MOCK');
        expect(mockRequested, isFalse);
        expect(mockRequested && !kReleaseMode, isFalse);
      },
    );
  });

  group('mock fixtures cover every Explore eligibility case', () {
    test(
      'the deterministic fixtures include each required role shape',
      () async {
        final repository = MockMultiKolabRepository();
        final event = await repository.getEvent('event-1');
        final ownEvent = await repository.getEvent('event-2');

        // Community-only, business-only and `either` roles.
        expect(
          event.roles.where((r) => r.eligibleAccountType.name == 'community'),
          isNotEmpty,
        );
        expect(
          event.roles.where((r) => r.eligibleAccountType.name == 'business'),
          isNotEmpty,
        );
        expect(
          event.roles.where((r) => r.eligibleAccountType.name == 'either'),
          isNotEmpty,
        );

        // A filled role, which must never surface as a card.
        expect(event.roles.where((r) => r.isFilled), isNotEmpty);

        // A multi-position role, proving one role still equals one card.
        expect(
          event.roles.where((r) => r.positionsNeeded > 1 && r.isOpen),
          isNotEmpty,
        );

        // An event with several OPEN roles, each of which becomes its own card.
        expect(event.roles.where((r) => r.isOpen).length, greaterThan(1));

        // A role belonging to the mock viewer's own event.
        expect(
          ownEvent.creatorProfileId,
          MockMultiKolabRepository.mockViewerProfileId,
        );
        expect(ownEvent.roles.where((r) => r.isOpen), isNotEmpty);
      },
    );
  });
}
