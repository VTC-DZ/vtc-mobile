abstract final class AddressApiConstants {
  AddressApiConstants._();

  static const String _base = '/api/passenger/addresses';

  static const String list = _base;
  static const String add = _base;
  static String update(String id) => '$_base/$id';
  static String delete(String id) => '$_base/$id';
}
