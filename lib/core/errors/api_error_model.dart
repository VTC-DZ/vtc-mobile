class ApiErrorModel {
  const ApiErrorModel({required this.code, required this.message});

  final String code;
  final String message;

  /// Parses the API error body.
  /// Handles both:
  ///   {"error":{"code":"FORBIDDEN","message":"...","details":null}}
  ///   {"message":"..."}
  static ApiErrorModel? tryParse(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final errorObj = data['error'];
    if (errorObj is Map<String, dynamic>) {
      return ApiErrorModel(
        code: errorObj['code'] as String? ?? '',
        message: errorObj['message'] as String? ?? '',
      );
    }

    final msg = data['message'];
    if (msg is String && msg.isNotEmpty) {
      return ApiErrorModel(code: '', message: msg);
    }

    return null;
  }
}
