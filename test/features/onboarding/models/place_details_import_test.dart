import 'package:flutter_test/flutter_test.dart';

import 'package:kolabing_app/features/onboarding/models/place_details_import.dart';

void main() {
  test('normalizes relative preview urls for imported Google photos', () {
    final payload = <String, dynamic>{
      'data': <String, dynamic>{
        'name': 'Sol Studio Rooftop',
        'categories': ['cafe'],
        'primary_venue': <String, dynamic>{
          'name': 'Sol Studio Rooftop',
          'place_id': 'google-place-id',
          'formatted_address': 'Carrer de Mallorca 1, Barcelona',
          'city': 'Barcelona',
          'photos': <Map<String, dynamic>>[
            <String, dynamic>{
              'resource_name': 'places/google-place-id/photos/photo-1',
              'preview_url':
                  '/api/v1/places/photo?name=places%2Fgoogle-place-id%2Fphotos%2Fphoto-1',
            },
          ],
        },
      },
    };

    final result = PlaceDetailsImport.fromJson(payload);

    expect(
      result.primaryVenue.photos.single.previewUrl,
      'https://kolabing.com/api/v1/places/photo?name=places%2Fgoogle-place-id%2Fphotos%2Fphoto-1',
    );
  });

  test('keeps absolute preview urls unchanged for imported Google photos', () {
    final payload = <String, dynamic>{
      'data': <String, dynamic>{
        'name': 'Sol Studio Rooftop',
        'categories': ['cafe'],
        'primary_venue': <String, dynamic>{
          'name': 'Sol Studio Rooftop',
          'place_id': 'google-place-id',
          'formatted_address': 'Carrer de Mallorca 1, Barcelona',
          'city': 'Barcelona',
          'photos': <Map<String, dynamic>>[
            <String, dynamic>{
              'resource_name': 'places/google-place-id/photos/photo-1',
              'preview_url':
                  'https://kolabing.com/api/v1/places/photo?name=places%2Fgoogle-place-id%2Fphotos%2Fphoto-1',
            },
          ],
        },
      },
    };

    final result = PlaceDetailsImport.fromJson(payload);

    expect(
      result.primaryVenue.photos.single.previewUrl,
      'https://kolabing.com/api/v1/places/photo?name=places%2Fgoogle-place-id%2Fphotos%2Fphoto-1',
    );
  });
}
