import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/instagram/models/instagram_models.dart';
import 'package:kolabing_app/features/instagram/providers/instagram_providers.dart';
import 'package:kolabing_app/features/instagram/services/instagram_service.dart';
import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';

import 'fake_instagram_service.dart';

void main() {
  late FakeInstagramService service;
  late CountingGalleryNotifier gallery;
  late ProviderContainer container;

  setUp(() {
    service = FakeInstagramService(
      pages: {
        null: InstagramMediaPage(
          items: [
            media('1'),
            media('2', type: InstagramMediaType.video),
            media('3', imported: true),
          ],
          nextCursor: 'p2',
        ),
        'p2': InstagramMediaPage(
          items: [
            media('3'), // overlap with page 1: must not duplicate
            media('4', type: InstagramMediaType.carouselAlbum),
          ],
        ),
      },
      importResult: const InstagramImportResult(importedCount: 2),
    );
    gallery = CountingGalleryNotifier();
    // Listening keeps the autoDispose picker alive for the whole test.
    container = ProviderContainer(
      overrides: [
        instagramServiceProvider.overrideWithValue(service),
        galleryProvider.overrideWith(() => gallery),
      ],
    )..listen(instagramPickerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  InstagramPickerNotifier notifier() =>
      container.read(instagramPickerProvider.notifier);
  InstagramPickerState state() => container.read(instagramPickerProvider);

  test(
    'first page, then the next page by cursor, without duplicates',
    () async {
      await notifier().loadFirstPage();
      expect(state().hasLoaded, isTrue);
      expect(state().items.map((m) => m.id), ['1', '2', '3']);
      expect(state().hasMore, isTrue);

      await notifier().loadMore();
      expect(service.mediaCursors, [null, 'p2']);
      expect(state().items.map((m) => m.id), ['1', '2', '3', '4']);
      expect(state().hasMore, isFalse);

      // No cursor left: loadMore is a no-op.
      await notifier().loadMore();
      expect(service.mediaCursors, hasLength(2));
    },
  );

  test('a failing first page surfaces an error; a failing next page keeps '
      'the grid', () async {
    service.mediaError = const InstagramException('boom');
    await notifier().loadFirstPage();
    expect(state().error, 'boom');
    expect(state().items, isEmpty);

    service.mediaError = null;
    await notifier().loadFirstPage();
    expect(state().error, isNull);

    service.mediaError = const InstagramException('page 2 down');
    await notifier().loadMore();
    expect(state().items, hasLength(3));
    expect(state().loadMoreError, 'page 2 down');
  });

  test('selection: toggle, imported items are not selectable', () async {
    await notifier().loadFirstPage();

    expect(notifier().toggle('1'), InstagramToggleResult.selected);
    expect(notifier().toggle('2'), InstagramToggleResult.selected);
    expect(state().selected, {'1', '2'});
    expect(notifier().toggle('1'), InstagramToggleResult.deselected);
    expect(state().selected, {'2'});

    expect(notifier().toggle('3'), InstagramToggleResult.notSelectable);
    expect(notifier().toggle('missing'), InstagramToggleResult.notSelectable);
    expect(state().selected, {'2'});
  });

  test('selection stops at the gallery size', () async {
    service.pages = {
      null: InstagramMediaPage(
        items: [for (var i = 0; i < 12; i++) media('m$i')],
      ),
    };
    await notifier().loadFirstPage();
    for (var i = 0; i < InstagramPickerState.maxSelection; i++) {
      expect(notifier().toggle('m$i'), InstagramToggleResult.selected);
    }
    expect(notifier().toggle('m11'), InstagramToggleResult.limitReached);
    expect(state().selected, hasLength(InstagramPickerState.maxSelection));
  });

  test('import sends the selection, marks items imported, reloads the '
      'gallery', () async {
    await notifier().loadFirstPage();
    notifier()
      ..toggle('2')
      ..toggle('1');

    final result = await notifier().importSelected();

    expect(service.importedIds.single, ['2', '1']);
    expect(result.importedCount, 2);
    expect(state().selected, isEmpty);
    expect(state().isImporting, isFalse);
    expect(state().items.where((m) => m.imported).map((m) => m.id).toSet(), {
      '1',
      '2',
      '3',
    });
    expect(gallery.loads, 1);
  });

  test('a failed import keeps the selection for a retry', () async {
    await notifier().loadFirstPage();
    notifier().toggle('1');
    service.importError = const InstagramException('too big');

    await expectLater(
      notifier().importSelected(),
      throwsA(isA<InstagramException>()),
    );
    expect(state().selected, {'1'});
    expect(state().isImporting, isFalse);
    expect(gallery.loads, 0);
  });

  test('import with nothing selected does not call the API', () async {
    await notifier().loadFirstPage();
    final result = await notifier().importSelected();
    expect(result.importedCount, 0);
    expect(service.importedIds, isEmpty);
  });

  test('refresh syncs first, then reloads page 1', () async {
    await notifier().refresh();
    expect(service.syncCalls, 1);
    expect(service.mediaCursors, [null]);
  });
}
