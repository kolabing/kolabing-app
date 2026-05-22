import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/kolab/enums/intent_type.dart';
import 'package:kolabing_app/features/kolab/models/kolab.dart';
import 'package:kolabing_app/features/kolab/providers/kolab_form_provider.dart';
import 'package:kolabing_app/features/kolab/screens/community/photo_screen.dart';
import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';

void main() {
  testWidgets('photo screen shows uploaded photo state when media exists', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(kolabFormProvider.notifier).selectIntent(
          IntentType.communitySeeking,
        );
    container.read(kolabFormProvider.notifier).addMedia(
          const KolabMedia(
            url: 'https://example.com/community-photo.jpg',
            type: 'photo',
            sortOrder: 0,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PhotoScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Uploaded photo selected'), findsOneWidget);
    expect(find.text('Replace photo'), findsOneWidget);
    expect(find.text('Upload a photo'), findsNothing);
  });

  testWidgets('photo screen shows library selection when reusable photos exist', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        galleryProvider.overrideWith(
          () => _FakeGalleryNotifier(
            GalleryState(
              photos: [
                GalleryPhoto.fromUrl(
                  id: 'photo-1',
                  rawUrl: '/storage/gallery/community-photo.jpg',
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(kolabFormProvider.notifier).selectIntent(
          IntentType.communitySeeking,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PhotoScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Choose from library'), findsOneWidget);
  });
}

class _FakeGalleryNotifier extends GalleryNotifier {
  _FakeGalleryNotifier(this._state);

  final GalleryState _state;

  @override
  GalleryState build() => _state;

  @override
  Future<void> loadGallery() async {}
}
