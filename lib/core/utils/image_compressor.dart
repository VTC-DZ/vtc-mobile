import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter_image_compress/flutter_image_compress.dart';

abstract final class ImageCompressor {
  static const int _maxWidth = 1280;
  static const int _quality = 70;

  static Future<String> compress(String sourcePath) async {
    final dir = Directory.systemTemp;
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      format: _formatFromPath(sourcePath),
      minWidth: _maxWidth,
      quality: _quality,
      keepExif: false,
    );

    if (result != null && await File(result.path).exists()) {
      return result.path;
    }
    return sourcePath;
  }

  static CompressFormat _formatFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.png' => CompressFormat.png,
      '.webp' => CompressFormat.webp,
      _ => CompressFormat.jpeg,
    };
  }
}
