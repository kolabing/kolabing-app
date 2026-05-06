import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/providers/my_kolabs_provider.dart';
import 'package:kolabing_app/features/kolab/services/kolab_service.dart';

void main() {
  group('MyKolabsNotifier pagination', () {
    test('initial load stores pagination metadata and hasMore', () async {
      final service = _FakeKolabService()
        ..setResponse(
          status: null,
          page: 1,
          response: PaginatedKolabResponse(
            data: <Kolab>[
              _kolab(id: '1', title: 'First'),
              _kolab(id: '2', title: 'Second'),
            ],
            currentPage: 1,
            lastPage: 3,
            total: 5,
          ),
        );

      final container = ProviderContainer(
        overrides: [kolabServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);

      final state = await _waitForLoadedState(container);

      expect(state.kolabs.map((kolab) => kolab.id), <String?>['1', '2']);
      expect(state.currentPage, 1);
      expect(state.lastPage, 3);
      expect(state.total, 5);
      expect(state.hasMore, isTrue);
    });

    test(
      'loadMore appends the next page using the active status filter',
      () async {
        final service = _FakeKolabService()
          ..setResponse(
            status: 'draft',
            page: 1,
            response: PaginatedKolabResponse(
              data: <Kolab>[
                _kolab(id: '1', title: 'Draft One'),
                _kolab(id: '2', title: 'Draft Two'),
              ],
              currentPage: 1,
              lastPage: 2,
              total: 3,
            ),
          )
          ..setResponse(
            status: 'draft',
            page: 2,
            response: PaginatedKolabResponse(
              data: <Kolab>[_kolab(id: '3', title: 'Draft Three')],
              currentPage: 2,
              lastPage: 2,
              total: 3,
            ),
          );

        final container = ProviderContainer(
          overrides: [kolabServiceProvider.overrideWith((ref) => service)],
        );
        addTearDown(container.dispose);

        container.read(myKolabsStatusProvider.notifier).setStatus('draft');
        await _waitForLoadedState(container);

        await container.read(myKolabsProvider.notifier).loadMore();
        final state = await _waitForCondition(
          container,
          (MyKolabsState value) =>
              !value.isLoadingMore && value.currentPage == 2,
        );

        expect(service.requests, <_MyKolabsRequest>[
          const _MyKolabsRequest(status: 'draft', page: 1, perPage: 15),
          const _MyKolabsRequest(status: 'draft', page: 2, perPage: 15),
        ]);
        expect(state.kolabs.map((kolab) => kolab.id), <String?>['1', '2', '3']);
        expect(state.total, 3);
        expect(state.hasMore, isFalse);
      },
    );

    test(
      'refresh replaces paginated data and resets back to page one',
      () async {
        final service = _FakeKolabService()
          ..setResponse(
            status: 'published',
            page: 1,
            response: PaginatedKolabResponse(
              data: <Kolab>[_kolab(id: '1', title: 'Old First')],
              currentPage: 1,
              lastPage: 2,
              total: 2,
            ),
          )
          ..setResponse(
            status: 'published',
            page: 2,
            response: PaginatedKolabResponse(
              data: <Kolab>[_kolab(id: '2', title: 'Old Second')],
              currentPage: 2,
              lastPage: 2,
              total: 2,
            ),
          );

        final container = ProviderContainer(
          overrides: [kolabServiceProvider.overrideWith((ref) => service)],
        );
        addTearDown(container.dispose);

        container.read(myKolabsStatusProvider.notifier).setStatus('published');
        await _waitForLoadedState(container);
        await container.read(myKolabsProvider.notifier).loadMore();
        await _waitForCondition(
          container,
          (MyKolabsState value) =>
              !value.isLoadingMore && value.currentPage == 2,
        );

        service.setResponse(
          status: 'published',
          page: 1,
          response: PaginatedKolabResponse(
            data: <Kolab>[_kolab(id: '10', title: 'Fresh First Page')],
            currentPage: 1,
            lastPage: 1,
            total: 1,
          ),
        );

        await container.read(myKolabsProvider.notifier).refresh();
        final state = await _waitForCondition(
          container,
          (MyKolabsState value) =>
              !value.isLoading &&
              value.currentPage == 1 &&
              value.kolabs.length == 1 &&
              value.kolabs.single.id == '10',
        );

        expect(state.kolabs.map((kolab) => kolab.id), <String?>['10']);
        expect(state.lastPage, 1);
        expect(state.total, 1);
        expect(state.hasMore, isFalse);
      },
    );

    test('stale loadMore result is ignored after a refresh starts', () async {
      final stalePageTwo = Completer<PaginatedKolabResponse>();
      final refreshedPageOne = Completer<PaginatedKolabResponse>();

      final service = _FakeKolabService()
        ..setResponse(
          status: null,
          page: 1,
          response: PaginatedKolabResponse(
            data: <Kolab>[_kolab(id: '1', title: 'Initial First Page')],
            currentPage: 1,
            lastPage: 2,
            total: 2,
          ),
        )
        ..setDeferredResponse(
          status: null,
          page: 2,
          future: stalePageTwo.future,
        )
        ..setDeferredResponse(
          status: null,
          page: 1,
          future: refreshedPageOne.future,
        );

      final container = ProviderContainer(
        overrides: [kolabServiceProvider.overrideWith((ref) => service)],
      );
      addTearDown(container.dispose);

      await _waitForLoadedState(container);

      final loadMoreFuture = container
          .read(myKolabsProvider.notifier)
          .loadMore();
      await _waitForCondition(
        container,
        (MyKolabsState value) => value.isLoadingMore,
      );

      final refreshFuture = container.read(myKolabsProvider.notifier).refresh();
      await _waitForCondition(
        container,
        (MyKolabsState value) => value.isLoading,
      );

      refreshedPageOne.complete(
        PaginatedKolabResponse(
          data: <Kolab>[_kolab(id: '10', title: 'Refreshed First Page')],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      await refreshFuture;
      await _waitForCondition(
        container,
        (MyKolabsState value) =>
            !value.isLoading &&
            value.currentPage == 1 &&
            value.kolabs.length == 1 &&
            value.kolabs.single.id == '10',
      );

      stalePageTwo.complete(
        PaginatedKolabResponse(
          data: <Kolab>[_kolab(id: '99', title: 'Stale Page Two')],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );
      await loadMoreFuture;

      final state = container.read(myKolabsProvider);
      expect(state.kolabs.map((kolab) => kolab.id), <String?>['10']);
      expect(state.currentPage, 1);
      expect(state.lastPage, 1);
      expect(state.total, 1);
    });

    test(
      'delete refreshes page one and recomputes pagination metadata',
      () async {
        final service = _FakeKolabService()
          ..setResponse(
            status: null,
            page: 1,
            response: PaginatedKolabResponse(
              data: <Kolab>[
                _kolab(id: '1', title: 'First'),
                _kolab(id: '2', title: 'Second'),
              ],
              currentPage: 1,
              lastPage: 2,
              total: 3,
            ),
          )
          ..setResponse(
            status: null,
            page: 1,
            response: PaginatedKolabResponse(
              data: <Kolab>[
                _kolab(id: '2', title: 'Second'),
                _kolab(id: '3', title: 'Third'),
              ],
              currentPage: 1,
              lastPage: 1,
              total: 2,
            ),
          );

        final container = ProviderContainer(
          overrides: [kolabServiceProvider.overrideWith((ref) => service)],
        );
        addTearDown(container.dispose);

        await _waitForLoadedState(container);

        final deleted = await container
            .read(myKolabsProvider.notifier)
            .delete('1');
        final state = await _waitForCondition(
          container,
          (MyKolabsState value) =>
              !value.isLoading &&
              value.currentPage == 1 &&
              value.lastPage == 1 &&
              value.total == 2 &&
              value.kolabs.length == 2,
        );

        expect(deleted, isTrue);
        expect(service.deletedIds, <String>['1']);
        expect(service.requests, <_MyKolabsRequest>[
          const _MyKolabsRequest(status: null, page: 1, perPage: 15),
          const _MyKolabsRequest(status: null, page: 1, perPage: 15),
        ]);
        expect(state.kolabs.map((kolab) => kolab.id), <String?>['2', '3']);
        expect(state.hasMore, isFalse);
      },
    );
  });
}

Future<MyKolabsState> _waitForLoadedState(ProviderContainer container) {
  return _waitForCondition(
    container,
    (MyKolabsState state) => !state.isLoading,
  );
}

Future<MyKolabsState> _waitForCondition(
  ProviderContainer container,
  bool Function(MyKolabsState state) predicate,
) {
  final current = container.read(myKolabsProvider);
  if (predicate(current)) {
    return Future<MyKolabsState>.value(current);
  }

  final completer = Completer<MyKolabsState>();
  final subscription = container.listen<MyKolabsState>(myKolabsProvider, (
    MyKolabsState? previous,
    MyKolabsState next,
  ) {
    if (!completer.isCompleted && predicate(next)) {
      completer.complete(next);
    }
  });

  completer.future.whenComplete(subscription.close);

  return completer.future.timeout(const Duration(seconds: 2));
}

Kolab _kolab({required String id, required String title}) => Kolab(
  id: id,
  intentType: IntentType.communitySeeking,
  title: title,
  description: '$title description',
  preferredCity: 'Madrid',
);

class _FakeKolabService extends KolabService {
  final Map<_MyKolabsRequest, List<Future<PaginatedKolabResponse>>> _responses =
      <_MyKolabsRequest, List<Future<PaginatedKolabResponse>>>{};

  final List<_MyKolabsRequest> requests = <_MyKolabsRequest>[];
  final List<String> deletedIds = <String>[];

  void setResponse({
    required String? status,
    required int page,
    required PaginatedKolabResponse response,
    int perPage = 15,
  }) {
    final request = _MyKolabsRequest(
      status: status,
      page: page,
      perPage: perPage,
    );
    (_responses[request] ??= <Future<PaginatedKolabResponse>>[]).add(
      Future<PaginatedKolabResponse>.value(response),
    );
  }

  void setDeferredResponse({
    required String? status,
    required int page,
    required Future<PaginatedKolabResponse> future,
    int perPage = 15,
  }) {
    final request = _MyKolabsRequest(
      status: status,
      page: page,
      perPage: perPage,
    );
    (_responses[request] ??= <Future<PaginatedKolabResponse>>[]).add(future);
  }

  @override
  Future<PaginatedKolabResponse> getMyKolabs({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final request = _MyKolabsRequest(
      status: status,
      page: page,
      perPage: perPage,
    );
    requests.add(request);

    final responses = _responses[request];
    if (responses == null || responses.isEmpty) {
      throw StateError('Missing fake response for $request');
    }
    return responses.removeAt(0);
  }

  @override
  Future<void> delete(String id) async {
    deletedIds.add(id);
  }
}

class _MyKolabsRequest {
  const _MyKolabsRequest({
    required this.status,
    required this.page,
    required this.perPage,
  });

  final String? status;
  final int page;
  final int perPage;

  @override
  bool operator ==(Object other) {
    return other is _MyKolabsRequest &&
        other.status == status &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode => Object.hash(status, page, perPage);

  @override
  String toString() =>
      '_MyKolabsRequest(status: $status, page: $page, perPage: $perPage)';
}
