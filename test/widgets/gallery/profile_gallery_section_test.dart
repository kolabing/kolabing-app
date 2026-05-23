import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/auth/models/user_model.dart';
import 'package:kolabing_app/features/business/providers/profile_provider.dart';
import 'package:kolabing_app/features/profile/providers/gallery_provider.dart';
import 'package:kolabing_app/widgets/gallery/profile_gallery_section.dart';

void main() {
  testWidgets(
    'uses business primary venue photos when gallery endpoint is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            galleryProvider.overrideWith(
              () => _FakeGalleryNotifier(const GalleryState()),
            ),
            profileProvider.overrideWith(
              () => _FakeProfileNotifier(_businessProfileStateWithVenuePhotos),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileGallerySection()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2/10'), findsOneWidget);
      expect(find.text('Showcase your venue'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is NetworkImage,
        ),
        findsNWidgets(2),
      );
    },
  );

  testWidgets('shows business-specific empty state copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryProvider.overrideWith(
            () => _FakeGalleryNotifier(const GalleryState()),
          ),
          profileProvider.overrideWith(
            () => _FakeProfileNotifier(_businessProfileStateWithoutPhotos),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileGallerySection())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Showcase your venue'), findsOneWidget);
    expect(find.text('Showcase your community'), findsNothing);
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

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._state);

  final ProfileState _state;

  @override
  ProfileState build() => _state;

  @override
  Future<void> loadProfile() async {}
}

const ProfileState _businessProfileStateWithVenuePhotos = ProfileState(
  profile: UserModel(
    id: 'business-1',
    email: 'venue@example.com',
    userType: UserType.business,
    businessProfile: BusinessProfile(
      id: 'bp-1',
      name: 'Venue Works',
      primaryVenue: PrimaryVenueProfile(
        name: 'Venue Works',
        formattedAddress: 'Carrer 1',
        city: 'Barcelona',
        photos: <String>[
          '/storage/gallery/venue-1.jpg',
          'storage/gallery/venue-2.jpg',
        ],
      ),
    ),
  ),
  isLoading: false,
  isInitialized: true,
);

const ProfileState _businessProfileStateWithoutPhotos = ProfileState(
  profile: UserModel(
    id: 'business-2',
    email: 'venue-empty@example.com',
    userType: UserType.business,
    businessProfile: BusinessProfile(
      id: 'bp-2',
      name: 'Venue Empty',
      primaryVenue: PrimaryVenueProfile(
        name: 'Venue Empty',
        formattedAddress: 'Carrer 2',
        city: 'Barcelona',
      ),
    ),
  ),
  isLoading: false,
  isInitialized: true,
);
