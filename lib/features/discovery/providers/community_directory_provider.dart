import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../models/directory_community.dart';
import '../services/discovery_service.dart';
import 'discovery_provider.dart';

@immutable
class CommunityDirectoryState {
  const CommunityDirectoryState({
    this.items = const <DirectoryCommunity>[],
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<DirectoryCommunity> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => items.isEmpty && !isLoading && error == null;
}

/// The business community directory (ROLES §2.24). Auto-disposed, so it is
/// fetched fresh each time the tab opens and never outlives a session.
class CommunityDirectoryNotifier extends Notifier<CommunityDirectoryState> {
  late DiscoveryService _service;
  int _generation = 0;

  @override
  CommunityDirectoryState build() {
    _service = ref.read(discoveryServiceProvider);
    Future<void>.microtask(refresh);
    return const CommunityDirectoryState(isLoading: true);
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = const CommunityDirectoryState(isLoading: true);
    try {
      final result = await _service.getCommunityDirectory();
      if (generation != _generation) return;
      state = CommunityDirectoryState(
        items: result.data,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      );
    } on Exception catch (e) {
      if (generation != _generation) return;
      state = CommunityDirectoryState(error: _message(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _generation;
    final current = state;
    state = CommunityDirectoryState(
      items: current.items,
      currentPage: current.currentPage,
      lastPage: current.lastPage,
      total: current.total,
      isLoadingMore: true,
    );
    try {
      final result = await _service.getCommunityDirectory(
        page: current.currentPage + 1,
      );
      if (generation != _generation) return;
      state = CommunityDirectoryState(
        items: <DirectoryCommunity>[...current.items, ...result.data],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
      );
    } on Exception {
      if (generation != _generation) return;
      // Keep what is on screen; the next scroll to the bottom tries again.
      state = current;
    }
  }

  static String _message(Exception e) => switch (e) {
    ApiException(:final error) => error.message,
    AuthException(:final message) => message,
    NetworkException(:final message) => message,
    _ => e.toString(),
  };
}

final communityDirectoryProvider =
    NotifierProvider.autoDispose<
      CommunityDirectoryNotifier,
      CommunityDirectoryState
    >(CommunityDirectoryNotifier.new);
