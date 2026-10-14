import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

/// The file types the backend stores for uploads — KYC documents
/// (`vtc.storage.allowed-mime-types`) and top-up receipts — by extension.
const List<String> uploadFileExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

/// Whether [path] has one of the [uploadFileExtensions].
bool hasUploadFileExtension(String path) => uploadFileExtensions
    .contains(p.extension(path).toLowerCase().replaceFirst('.', ''));

/// Whether [path] is a PDF, judged by its extension.
bool isPdfPath(String path) => p.extension(path).toLowerCase() == '.pdf';

/// The content type an upload declares. The backend checks each part's
/// declared type against its allow-list and doesn't look at the bytes, so it
/// is set explicitly rather than guessed from the file name. `ImageCompressor`
/// turns every photo that isn't a PNG into a `.jpg`.
MediaType uploadContentType(String path) =>
    switch (p.extension(path).toLowerCase()) {
      '.pdf' => MediaType('application', 'pdf'),
      '.png' => MediaType('image', 'png'),
      _ => MediaType('image', 'jpeg'),
    };
