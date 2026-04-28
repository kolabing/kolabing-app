import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/auth_response.dart';
import '../../auth/services/auth_service.dart';
import '../enums/intent_type.dart';
import '../models/kolab.dart';
import '../services/kolab_service.dart';

@immutable
class MyKolabsState {
  const MyKolabsState({
    this.kolabs = const [],
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.requiresSubscription = false,
    this.error,
  });

  final List<Kolab> kolabs;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool requiresSubscription;
  final String? error;

  bool get hasMore => false;
  bool get isEmpty => kolabs.isEmpty && !isLoading;

  MyKolabsState copyWith({
    List<Kolab>? kolabs,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? requiresSubscription,
    String? error,
    bool clearError = false,
  }) => MyKolabsState(
    kolabs: kolabs ?? this.kolabs,
    total: total ?? this.total,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    requiresSubscription: requiresSubscription ?? this.requiresSubscription,
    error: clearError ? null : (error ?? this.error),
  );
}

class MyKolabsStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setStatus(String? status) {
    state = status;
  }
}

final myKolabsStatusProvider =
    NotifierProvider<MyKolabsStatusNotifier, String?>(
      MyKolabsStatusNotifier.new,
    );

class MyKolabsNotifier extends Notifier<MyKolabsState> {
  late KolabService _service;

  @override
  MyKolabsState build() {
    _service = ref.read(kolabServiceProvider);
    final status = ref.watch(myKolabsStatusProvider);
    Future.microtask(() => _load(status));
    return const MyKolabsState(isLoading: true);
  }

  Future<void> _load(String? status) async {
    state = state.copyWith(
      isLoading: true,
      requiresSubscription: false,
      clearError: true,
    );

    try {
      final kolabs = await _service.getMyKolabs(status: status);
      state = MyKolabsState(kolabs: kolabs, total: kolabs.length);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.error.message);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on Exception catch (e) {
      debugPrint('Load my kolabs error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load your kolabs',
      );
    }
  }

  Future<void> refresh() async {
    await _load(ref.read(myKolabsStatusProvider));
  }

  Future<void> loadMore() async {}

  Future<bool> publish(String id) async {
    final kolab = await _resolveKolab(id);
    if (kolab == null) {
      state = state.copyWith(error: 'Kolab not found');
      return false;
    }

    try {
      final updated = await _service.publish(id, kolab);
      _replaceInList(id, updated);
      await refresh();
      return true;
    } on ApiException catch (e) {
      if (e.error.requiresSubscription || e.error.statusCode == 402) {
        state = state.copyWith(
          requiresSubscription: true,
          error: e.error.message,
        );
        return false;
      }
      state = state.copyWith(error: e.error.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Publish kolab error: $e');
      state = state.copyWith(error: 'Failed to publish kolab');
      return false;
    }
  }

  Future<bool> close(String id) async {
    final kolab = await _resolveKolab(id);
    if (kolab == null) {
      state = state.copyWith(error: 'Kolab not found');
      return false;
    }

    try {
      final updated = await _service.close(id, kolab);
      _replaceInList(id, updated);
      await refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.error.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Close kolab error: $e');
      state = state.copyWith(error: 'Failed to close kolab');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _service.delete(id);
      final updated = state.kolabs.where((kolab) => kolab.id != id).toList();
      state = state.copyWith(kolabs: updated, total: updated.length);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.error.message);
      return false;
    } on Exception catch (e) {
      debugPrint('Delete kolab error: $e');
      state = state.copyWith(error: 'Failed to delete kolab');
      return false;
    }
  }

  void clearSubscriptionRequirement() {
    state = state.copyWith(requiresSubscription: false);
  }

  Future<Kolab?> _resolveKolab(String id) async {
    final index = state.kolabs.indexWhere((kolab) => kolab.id == id);
    if (index >= 0) {
      return state.kolabs[index];
    }

    try {
      return await _service.getDetail(id);
    } on Exception {
      return null;
    }
  }

  void _replaceInList(String id, Kolab updated) {
    final list = state.kolabs.map((kolab) {
      if (kolab.id == id) {
        return updated;
      }
      return kolab;
    }).toList();

    state = state.copyWith(
      kolabs: list,
      total: list.length,
      requiresSubscription: false,
      clearError: true,
    );
  }
}

final myKolabsProvider = NotifierProvider<MyKolabsNotifier, MyKolabsState>(
  MyKolabsNotifier.new,
);

extension KolabStatusActions on Kolab {
  bool get canEdit => status == 'draft' || status == 'published';
  bool get canPublish => status == 'draft';
  bool get canClose => status == 'published';
  bool get canDelete => status == 'draft';

  String get statusLabel => switch (status) {
    'published' => 'Published',
    'closed' => 'Closed',
    'completed' => 'Completed',
    _ => 'Draft',
  };

  String get typeLabel => switch (intentType) {
    IntentType.communitySeeking => 'Community',
    IntentType.venuePromotion => 'Venue',
    IntentType.productPromotion => 'Product',
  };
}
