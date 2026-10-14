import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter_image_compress/flutter_image_compress.dart';

abstract final class ImageCompressor {
  static const int _maxWidth = 1280;
  static const int _quality = 70;

  /// Re-encodes the photo at [sourcePath] smaller and without EXIF data, and
  /// returns the new file's path, or [sourcePath] if that fails. A PNG stays
  /// PNG; anything else (JPEG, HEIC, WebP…) becomes a `.jpg`, so uploads are
  /// always a type the backend accepts and the file name matches its bytes.
  static Future<String> compress(String sourcePath) async {
    final isPng = p.extension(sourcePath).toLowerCase() == '.png';
    final targetPath = '${Directory.systemTemp.path}/compressed_'
        '${DateTime.now().millisecondsSinceEpoch}${isPng ? '.png' : '.jpg'}';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      format: isPng ? CompressFormat.png : CompressFormat.jpeg,
      minWidth: _maxWidth,
      quality: _quality,
      keepExif: false,
    );

    if (result != null && await File(result.path).exists()) {
      return result.path;
    }
    return sourcePath;
  }
}
