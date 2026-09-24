import 'package:flutter_test/flutter_test.dart';
import 'package:khfif_drif/core/utils/uuid.dart';
import 'package:khfif_drif/features/ride/passenger/data/models/place_models.dart';

/// Fixtures mirror the `PlaceSummary` / `PlaceDetailResponse` schemas in
/// `swagger/passenger.json`.
void main() {
  group('PlaceSummary.fromJson', () {
    test('maps a full payload field by field', () {
      final place = PlaceSummary.fromJson(const {
        'placeId': 'place-1',
        'displayName': 'Grande Poste',
        'formattedAddress': 'Boulevard Larbi Ben M\'hidi, Alger',
      });

      expect(place.placeId, 'place-1');
      expect(place.displayName, 'Grande Poste');
      expect(place.formattedAddress, 'Boulevard Larbi Ben M\'hidi, Alger');
      expect(place.label, 'Boulevard Larbi Ben M\'hidi, Alger');
    });

    test('label falls back to displayName when formattedAddress is missing',
        () {
      final place = PlaceSummary.fromJson(const {
        'placeId': 'place-1',
        'displayName': 'Grande Poste',
      });

      expect(place.formattedAddress, '');
      expect(place.label, 'Grande Poste');
    });
  });

  group('PlaceDetail.fromJson', () {
    test('maps a full payload field by field', () {
      final place = PlaceDetail.fromJson(const {
        'placeId': 'place-1',
        'displayName': 'Grande Poste',
        'formattedAddress': 'Boulevard Larbi Ben M\'hidi, Alger',
        'coordinates': {'lat': 36.7753, 'lng': 3.0602},
      });

      expect(place.placeId, 'place-1');
      expect(place.displayName, 'Grande Poste');
      expect(place.label, 'Boulevard Larbi Ben M\'hidi, Alger');
      expect(place.lat, 36.7753);
      expect(place.lng, 3.0602);
    });

    test('accepts integer coordinates', () {
      final place = PlaceDetail.fromJson(const {
        'placeId': 'place-1',
        'displayName': 'Somewhere',
        'coordinates': {'lat': 36, 'lng': 3},
      });

      expect(place.lat, 36.0);
      expect(place.lng, 3.0);
      expect(place.label, 'Somewhere');
    });

    test('defaults coordinates to 0 when missing', () {
      final place = PlaceDetail.fromJson(const {'placeId': 'place-1'});

      expect(place.lat, 0);
      expect(place.lng, 0);
      expect(place.displayName, '');
    });
  });

  group('uuidV4', () {
    test('produces RFC 4122 v4 UUIDs', () {
      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      for (var i = 0; i < 100; i++) {
        expect(uuidV4(), matches(pattern));
      }
    });

    test('is not repeated across calls', () {
      expect(uuidV4(), isNot(uuidV4()));
    });
  });
}
