import 'dart:convert';

abstract final class JwtDecoder {
  JwtDecoder._();

  /// Decodes the payload segment of a JWT [token] into a Map.
  /// Returns an empty map if the token is malformed.
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      var payload = parts[1];
      // Normalize base64url padding.
      final remainder = payload.length % 4;
      if (remainder != 0) {
        payload += '=' * (4 - remainder);
      }
      final bytes = base64Url.decode(payload);
      final jsonStr = utf8.decode(bytes);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
