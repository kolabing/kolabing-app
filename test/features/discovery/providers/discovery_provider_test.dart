import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/features/discovery/models/discovery_filters.dart';
import 'package:kolabing_app/features/discovery/models/discovery_item.dart';
import 'package:kolabing_app/features/discovery/models/explore_feed_item.dart';
import 'package:kolabing_app/features/discovery/providers/discovery_provider.dart';
import 'package:kolabing_app/features/discovery/services/discovery_service.dart';
import 'package:kolabing_app/features/opportunity/models/opportunity.dart';

import '../../../support/auth_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'discovery provider loads, refreshes, appends, and switches feed',
    () async {
      final service = _FakeDiscoveryService();
      final container = ProviderContainer(
        overrides: [discoveryServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);
      authenticateContainer(container);

      expect(container.read(discoveryListProvider).isLoading, isTrue);

      final initial = await _waitForLoadedState(
        container,
        expectedCallCount: 1,
      );
      expect(initial.items.map((item) => item.feedKey).toList(), <String>[
        'offer:recommended-1',
      ]);
      expect(service.calls.single.filters.feed, DiscoveryFeed.recommended);

      container.read(discoveryFiltersProvider.notifier).setCity('Madrid');
      final filtered = await _waitForLoadedState(
        container,
        expectedCallCount: 2,
      );
      expect(filtered.items.map((item) => item.feedKey).toList(), <String>[
        'offer:madrid-1',
      ]);
      expect(service.calls.last.filters.city, 'Madrid');

      await container.read(discoveryListProvider.notifier).loadMore();
      final appended = await _waitForLoadedState(
        container,
        expectedCallCount: 3,
      );
      expect(appended.items.map((item) => item.feedKey).toList(), <String>[
        'offer:madrid-1',
        'offer:madrid-2',
      ]);

      container
          .read(discoveryFiltersProvider.notifier)
          .setFeed(DiscoveryFeed.all);
      final allFeed = await _waitForLoadedState(
        container,
        expectedCallCount: 4,
      );
      expect(service.calls.last.filters.feed, DiscoveryFeed.all);
      expect(allFeed.items.map((item) => item.feedKey).toList(), <String>[
        'offer:all-1',
      ]);
    },
  );
}

class _FakeDiscoveryService extends DiscoveryService {
  final List<_DiscoveryCall> calls = <_DiscoveryCall>[];

  @override
  Future<PaginatedResponse<ExploreFeedItem>> getOpportunities({
    DiscoveryFilters filters = const DiscoveryFilters(),
    int page = 1,
    int perPage = 15,
  }) async {
    calls.add(_DiscoveryCall(filters: filters, page: page, perPage: perPage));

    if (filters.feed == DiscoveryFeed.all) {
      return PaginatedResponse<ExploreFeedItem>(
        data: <ExploreFeedItem>[_item('all-1')],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      );
    }

    if (filters.city == 'Madrid' && page == 1) {
      return PaginatedResponse<ExploreFeedItem>(
        data: <ExploreFeedItem>[_item('madrid-1')],
        currentPage: 1,
        lastPage: 2,
        total: 2,
      );
    }

    if (filters.city == 'Madrid' && page == 2) {
      return PaginatedResponse<ExploreFeedItem>(
        data: <ExploreFeedItem>[_item('madrid-2')],
        currentPage: 2,
        lastPage: 2,
        total: 2,
      );
    }

    return PaginatedResponse<ExploreFeedItem>(
      data: <ExploreFeedItem>[_item('recommended-1')],
      currentPage: 1,
      lastPage: 1,
      total: 1,
    );
  }

  ExploreFeedItem _item(String id) => ExploreOfferItem(
    DiscoveryItem(
      id: id,
      creatorType: 'business',
      intentType: 'venue_promotion',
      title: id,
      description: '$id description',
      preferredCity: 'Madrid',
      availability: DiscoveryAvailability(
        mode: 'one_time',
        start: DateTime(2026, 5, 20),
        end: DateTime(2026, 5, 20),
      ),
      creatorProfile: const DiscoveryCreatorProfile(
        id: 'creator-1',
        displayName: 'Casa Sol',
      ),
      businessOffer: const BusinessOfferSummary(
        offerTypes: <String>['venue'],
        venueType: 'rooftop',
      ),
      match: const DiscoveryMatch(
        feed: 'recommended',
        score: 90,
        reasons: <String>['city_match'],
      ),
    ),
  );
}

class _DiscoveryCall {
  const _DiscoveryCall({
    required this.filters,
    required this.page,
    required this.perPage,
  });

  final DiscoveryFilters filters;
  final int page;
  final int perPage;
}

Future<DiscoveryListState> _waitForLoadedState(
  ProviderContainer container, {
  required int expectedCallCount,
}) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    final state = container.read(discoveryListProvider);
    final service =
        container.read(discoveryServiceProvider) as _FakeDiscoveryService;

    if (!state.isLoading &&
        !state.isLoadingMore &&
        service.calls.length >= expectedCallCount) {
      return state;
    }

    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  return container.read(discoveryListProvider);
}
