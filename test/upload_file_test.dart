import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/utils/upload_file.dart';

void main() {
  test('recognises a PDF by its extension, in any case', () {
    expect(isPdfPath('/docs/licence.pdf'), isTrue);
    expect(isPdfPath('/docs/LICENCE.PDF'), isTrue);
    expect(isPdfPath('/docs/licence.jpg'), isFalse);
  });

  test('accepts only the file types the backend stores', () {
    for (final path in ['a.jpg', 'a.JPEG', 'a.png', 'a.pdf']) {
      expect(hasUploadFileExtension(path), isTrue, reason: path);
    }
    for (final path in ['a.heic', 'a.webp', 'a.docx', 'no-extension']) {
      expect(hasUploadFileExtension(path), isFalse, reason: path);
    }
  });

  test('declares the content type the backend checks', () {
    expect(uploadContentType('a.pdf').mimeType, 'application/pdf');
    expect(uploadContentType('a.PNG').mimeType, 'image/png');
    expect(uploadContentType('a.jpg').mimeType, 'image/jpeg');
  });

  test('falls back to JPEG for any other photo', () {
    expect(uploadContentType('IMG_0001.heic').mimeType, 'image/jpeg');
  });
}
