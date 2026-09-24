abstract final class PlacesApiConstants {
  PlacesApiConstants._();

  static const String _base = '/api/passenger/places';

  static const String search = '$_base/search';
  static const String reverseGeocode = '$_base/reverse-geocode';
  static String resolve(String placeId) => '$_base/$placeId';
}
