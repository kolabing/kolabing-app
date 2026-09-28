import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/gallery_provider.dart';
import '../models/instagram_models.dart';
import '../models/instagram_return_link.dart';
import '../services/instagram_service.dart';

/// Provider for [InstagramService].
final instagramServiceProvider = Provider<InstagramService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return InstagramService(authService: authService);
});

/// Opens the Instagram authorize URL outside the app.
///
/// The system browser, not a WebView: Meta's login refuses embedded WebViews,
/// and the browser already holds the person's Instagram session. This is the
/// same `url_launcher` + `kolabing://` return pattern as the Stripe checkout
/// (`subscription_paywall.dart`), so no new package is needed.
typedef InstagramUrlLauncher = Future<bool> Function(Uri url);

final instagramUrlLauncherProvider = Provider<InstagramUrlLauncher>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);

/// The return-link channel (overridable in tests).
final instagramReturnBusProvider = Provider<InstagramReturnBus>(
  (ref) => InstagramReturnBus.instance,
);

/// True for a signed-in business or community: the two roles with a profile
/// gallery. Attendees never call the endpoints.
final _hasGalleryRoleProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  final type = auth.user?.userType;
  return auth.isAuthenticated &&
      (type == UserType.business || type == UserType.community);
});

/// Connection status. `null` = hide the Instagram card (wrong role, or the
/// endpoint is not deployed yet). A status with `enabled: false` is hidden
/// too. Refresh with `ref.invalidate(instagramStatusProvider)`.
final instagramStatusProvider = FutureProvider<InstagramStatus?>((ref) async {
  if (!ref.watch(_hasGalleryRoleProvider)) return null;
  return ref.watch(instagramServiceProvider).getStatus();
});

// =============================================================================
// Media picker
// =============================================================================

@immutable
class InstagramPickerState {
  const InstagramPickerState({
    this.items = const [],
    this.nextCursor,
    this.hasLoaded = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isImporting = false,
    this.error,
    this.loadMoreError,
    this.selected = const <String>{},
  });

  final List<InstagramMedia> items;
  final String? nextCursor;

  /// The first page has come back at least once.
  final bool hasLoaded;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isImporting;

  /// First-page failure (full-screen error with Retry).
  final String? error;

  /// Next-page failure (inline Retry at the bottom of the grid).
  final String? loadMoreError;

  /// Selected media ids, in tap order.
  final Set<String> selected;

  bool get hasMore => nextCursor != null;
  bool get canImport => selected.isNotEmpty && !isImporting;

  /// One import fills at most a whole gallery; the backend still has the
  /// final say (it reports what it skipped).
  static const int maxSelection = GalleryState.maxPhotos;

  InstagramPickerState copyWith({
    List<InstagramMedia>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasLoaded,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isImporting,
    String? error,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    Set<String>? selected,
  }) => InstagramPickerState(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    hasLoaded: hasLoaded ?? this.hasLoaded,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isImporting: isImporting ?? this.isImporting,
    error: clearError ? null : (error ?? this.error),
    loadMoreError: clearLoadMoreError
        ? null
        : (loadMoreError ?? this.loadMoreError),
    selected: selected ?? this.selected,
  );
}

/// Outcome of [InstagramPickerNotifier.toggle].
enum InstagramToggleResult { selected, deselected, limitReached, notSelectable }

class InstagramPickerNotifier extends Notifier<InstagramPickerState> {
  InstagramService get _service => ref.read(instagramServiceProvider);

  @override
  InstagramPickerState build() => const InstagramPickerState();

  /// Load (or reload) the first page. Keeps the selection that still exists.
  Future<void> loadFirstPage() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearLoadMoreError: true,
    );
    try {
      final page = await _service.getMedia();
      final ids = page.items.map((m) => m.id).toSet();
      state = state.copyWith(
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        hasLoaded: true,
        isLoading: false,
        selected: state.selected.where(ids.contains).toSet(),
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Infinite scroll: fetch the page after [InstagramPickerState.nextCursor].
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.isLoadingMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);
    try {
      final page = await _service.getMedia(cursor: cursor);
      final known = state.items.map((m) => m.id).toSet();
      state = state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((m) => !known.contains(m.id)),
        ],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        isLoadingMore: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoadingMore: false, loadMoreError: e.toString());
    }
  }

  /// Pull to refresh: ask the backend to pull the latest media, then reload.
  /// A failing sync is not fatal; the cached list is still worth showing.
  Future<void> refresh() async {
    try {
      await _service.sync();
    } on Exception catch (e) {
      debugPrint('Instagram sync failed: $e');
    }
    await loadFirstPage();
  }

  InstagramToggleResult toggle(String id) {
    final media = state.items.where((m) => m.id == id).firstOrNull;
    if (media == null || media.imported || state.isImporting) {
      return InstagramToggleResult.notSelectable;
    }
    final next = {...state.selected};
    if (next.remove(id)) {
      state = state.copyWith(selected: next);
      return InstagramToggleResult.deselected;
    }
    if (next.length >= InstagramPickerState.maxSelection) {
      return InstagramToggleResult.limitReached;
    }
    next.add(id);
    state = state.copyWith(selected: next);
    return InstagramToggleResult.selected;
  }

  void clearSelection() => state = state.copyWith(selected: <String>{});

  /// Import the selection into the profile gallery. On success the imported
  /// items are marked, the selection clears and the gallery reloads. Throws
  /// [InstagramException] (or another [Exception]) on failure, keeping the
  /// selection so the person can retry.
  Future<InstagramImportResult> importSelected() async {
    final ids = state.selected.toList();
    if (ids.isEmpty || state.isImporting) {
      return const InstagramImportResult(importedCount: 0);
    }
    state = state.copyWith(isImporting: true);
    try {
      final result = await _service.importMedia(ids);
      final done = ids.toSet();
      state = state.copyWith(
        isImporting: false,
        selected: <String>{},
        items: [
          for (final m in state.items)
            done.contains(m.id) ? m.copyWith(imported: true) : m,
        ],
      );
      await ref.read(galleryProvider.notifier).loadGallery();
      return result;
    } on Exception {
      state = state.copyWith(isImporting: false);
      rethrow;
    }
  }
}

final instagramPickerProvider =
    NotifierProvider.autoDispose<InstagramPickerNotifier, InstagramPickerState>(
      InstagramPickerNotifier.new,
    );
