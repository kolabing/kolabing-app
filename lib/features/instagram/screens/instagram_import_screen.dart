import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/instagram_models.dart';
import '../providers/instagram_providers.dart';
import '../widgets/instagram_professional_helper_sheet.dart';

/// Pick Instagram photos and videos and import them into the profile gallery.
///
/// Grid of the connected account's media (newest first, as Instagram returns
/// it), multi-select, video and carousel badges, infinite scroll by cursor,
/// pull to refresh (asks the backend to sync first). Items already imported
/// are marked and cannot be picked twice.
class InstagramImportScreen extends ConsumerStatefulWidget {
  const InstagramImportScreen({super.key});

  @override
  ConsumerState<InstagramImportScreen> createState() =>
      _InstagramImportScreenState();
}

class _InstagramImportScreenState extends ConsumerState<InstagramImportScreen> {
  final ScrollController _scroll = ScrollController();

  /// Start fetching the next page this far from the bottom.
  static const double _loadMoreThreshold = 600;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    Future.microtask(
      () => ref.read(instagramPickerProvider.notifier).loadFirstPage(),
    );
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.maxScrollExtent - position.pixels < _loadMoreThreshold) {
      unawaited(ref.read(instagramPickerProvider.notifier).loadMore());
    }
  }

  void _toggle(String id) {
    final result = ref.read(instagramPickerProvider.notifier).toggle(id);
    if (result == InstagramToggleResult.limitReached) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              l10n.instagramSelectionLimit(InstagramPickerState.maxSelection),
            ),
          ),
        );
    }
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref
          .read(instagramPickerProvider.notifier)
          .importSelected();
      if (!mounted) return;
      await _showResult(result);
      if (mounted) unawaited(Navigator.of(context).maybePop());
    } on Exception catch (e) {
      debugPrint('Instagram import failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.instagramImportFailed)));
    }
  }

  Future<void> _showResult(InstagramImportResult result) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: context.colors.surface,
        builder: (sheetContext) {
          final l10n = AppLocalizations.of(sheetContext);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                KolabingSpacing.lg,
                0,
                KolabingSpacing.lg,
                KolabingSpacing.lg,
              ),
              child: Column(
                key: const Key('instagram-import-result'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    LucideIcons.checkCircle2,
                    size: 40,
                    color: sheetContext.colors.success,
                  ),
                  const SizedBox(height: KolabingSpacing.sm),
                  Text(
                    l10n.instagramImportResultTitle,
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.titleLarge.copyWith(
                      color: sheetContext.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xs),
                  Text(
                    l10n.instagramImportResultBody(result.importedCount),
                    textAlign: TextAlign.center,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: sheetContext.colors.onSurfaceVariant,
                    ),
                  ),
                  if (result.skipped > 0) ...[
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      l10n.instagramImportResultSkipped(result.skipped),
                      textAlign: TextAlign.center,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: sheetContext.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: KolabingSpacing.lg),
                  KolabingButton(
                    key: const Key('instagram-import-done'),
                    label: l10n.instagramImportDone,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    size: KolabingButtonSize.compact,
                  ),
                ],
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(instagramPickerProvider);

    // A page shorter than the screen never scrolls, so ask for the next one
    // after layout instead of waiting for a scroll event that cannot happen.
    if (state.hasMore && !state.isLoadingMore && state.loadMoreError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeLoadMore();
      });
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: Text(l10n.instagramImportTitle)),
      body: _buildBody(context, state),
      bottomNavigationBar: state.items.isEmpty
          ? null
          : _ImportBar(state: state, onImport: _import),
    );
  }

  Widget _buildBody(BuildContext context, InstagramPickerState state) {
    final l10n = AppLocalizations.of(context);

    if (!state.hasLoaded && state.error == null) {
      return const Center(
        key: Key('instagram-import-loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (state.items.isEmpty && state.errorIsPersonalAccount) {
      return _Message(
        key: const Key('instagram-import-personal'),
        icon: LucideIcons.instagram,
        text: l10n.instagramPersonalTitle,
        actionLabel: l10n.instagramPersonalAccountLink,
        onAction: () => InstagramProfessionalHelperSheet.show(context),
      );
    }
    if (state.items.isEmpty && state.error != null) {
      return _Message(
        key: const Key('instagram-import-error'),
        icon: LucideIcons.refreshCw,
        text: l10n.instagramImportLoadError,
        actionLabel: l10n.instagramRetry,
        onAction: () =>
            ref.read(instagramPickerProvider.notifier).loadFirstPage(),
      );
    }

    final notifier = ref.read(instagramPickerProvider.notifier);
    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: state.items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: KolabingSpacing.xxl),
                _Message(
                  key: const Key('instagram-import-empty'),
                  icon: LucideIcons.instagram,
                  text: l10n.instagramImportEmpty,
                ),
              ],
            )
          : CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(KolabingSpacing.xxs),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: KolabingSpacing.xxs,
                          crossAxisSpacing: KolabingSpacing.xxs,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final media = state.items[index];
                      final order = state.selected.toList().indexOf(media.id);
                      return InstagramMediaTile(
                        media: media,
                        selectionIndex: order < 0 ? null : order + 1,
                        onTap: () => _toggle(media.id),
                      );
                    }, childCount: state.items.length),
                  ),
                ),
                SliverToBoxAdapter(child: _buildFooter(context, state)),
              ],
            ),
    );
  }

  Widget _buildFooter(BuildContext context, InstagramPickerState state) {
    if (state.isLoadingMore) {
      return const Padding(
        key: Key('instagram-import-loading-more'),
        padding: EdgeInsets.all(KolabingSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        child: Center(
          child: TextButton(
            key: const Key('instagram-import-load-more-retry'),
            onPressed: () =>
                ref.read(instagramPickerProvider.notifier).loadMore(),
            child: Text(AppLocalizations.of(context).instagramRetry),
          ),
        ),
      );
    }
    return const SizedBox(height: KolabingSpacing.md);
  }
}

/// One grid cell: preview, video / carousel badge, selection or imported mark.
class InstagramMediaTile extends StatelessWidget {
  const InstagramMediaTile({
    required this.media,
    required this.onTap,
    this.selectionIndex,
    super.key,
  });

  final InstagramMedia media;
  final VoidCallback onTap;

  /// 1-based position in the selection, or null when not selected.
  final int? selectionIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = media.previewUrl;
    final selected = selectionIndex != null;

    return Semantics(
      selected: selected,
      button: !media.imported,
      child: GestureDetector(
        key: Key('instagram-media-${media.id}'),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: KolabingRadius.borderRadiusXs,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: context.colors.surfaceContainer),
              if (preview != null)
                Image.network(
                  preview,
                  fit: BoxFit.cover,
                  cacheWidth: 360,
                  errorBuilder: (_, _, _) => Icon(
                    LucideIcons.image,
                    color: context.colors.textTertiary,
                  ),
                ),
              if (media.imported)
                ColoredBox(color: context.colors.overlayDark50),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.primary, width: 3),
                  ),
                ),
              // Type badge (top right)
              if (media.isVideo || media.isCarousel)
                Positioned(
                  top: KolabingSpacing.xxs,
                  right: KolabingSpacing.xxs,
                  child: Tooltip(
                    message: media.isVideo
                        ? l10n.instagramVideoBadge
                        : l10n.instagramCarouselBadge,
                    child: Icon(
                      media.isVideo ? LucideIcons.play : LucideIcons.layers,
                      key: Key(
                        media.isVideo
                            ? 'instagram-badge-video'
                            : 'instagram-badge-carousel',
                      ),
                      size: 18,
                      color: context.colors.textOnDark,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              // Selection counter (top left)
              if (selected)
                Positioned(
                  top: KolabingSpacing.xxs,
                  left: KolabingSpacing.xxs,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$selectionIndex',
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: context.colors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (media.imported)
                Center(
                  child: Container(
                    key: const Key('instagram-badge-imported'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: KolabingSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 12,
                          color: context.colors.onSurface,
                        ),
                        const SizedBox(width: KolabingSpacing.xxxs),
                        Text(
                          l10n.instagramImportedBadge,
                          style: KolabingTextStyles.labelSmall.copyWith(
                            color: context.colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportBar extends StatelessWidget {
  const _ImportBar({required this.state, required this.onImport});

  final InstagramPickerState state;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = state.selected.length;

    return Material(
      color: context.colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            KolabingSpacing.sm,
            KolabingSpacing.md,
            KolabingSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isImporting) ...[
                const LinearProgressIndicator(
                  key: Key('instagram-import-progress'),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  l10n.instagramImporting(count),
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ] else
                Text(
                  l10n.instagramSelectedCount(count),
                  key: const Key('instagram-selected-count'),
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: KolabingSpacing.xs),
              KolabingButton(
                key: const Key('instagram-import-submit'),
                label: l10n.instagramImportToGallery,
                onPressed: state.canImport ? onImport : null,
                isDisabled: !state.canImport,
                isLoading: state.isImporting,
                size: KolabingButtonSize.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: context.colors.textTertiary),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            text,
            textAlign: TextAlign.center,
            style: KolabingTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: KolabingSpacing.md),
            KolabingButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: KolabingButtonVariant.secondary,
              size: KolabingButtonSize.small,
              width: 160,
            ),
          ],
        ],
      ),
    ),
  );
}
