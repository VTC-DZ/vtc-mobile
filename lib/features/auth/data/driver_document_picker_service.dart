import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/upload_file.dart';
import 'models/document_pick_result.dart';
import 'models/document_source.dart';

/// Picks KYC documents — photos with `image_picker`, images or PDFs with
/// `file_picker` — and enforces the size limit.
///
/// Not `final`, so tests can extend it with a fake.
class DriverDocumentPickerService {
  DriverDocumentPickerService() : _imagePicker = ImagePicker();

  DriverDocumentPickerService.withPicker(this._imagePicker);

  final ImagePicker _imagePicker;

  Future<String?> pickVehiclePhoto(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  Future<DocumentPickResult> pickDocument(DocumentSource source) async {
    try {
      final picked = source == DocumentSource.file
          ? await _pickFile()
          : await _pickImage(source);
      if (picked == null) return const DocumentPickCancelled();

      // Photos are re-encoded before upload; a file goes up as it is.
      if (source == DocumentSource.file &&
          !hasUploadFileExtension(picked.path)) {
        return const DocumentPickFailure(
            errorMessage: AppStrings.fileTypeNotAllowed);
      }
      final fileSize = await File(picked.path).length();
      if (fileSize > AppConstants.maxDocumentSizeBytes) {
        return const DocumentPickFailure(errorMessage: AppStrings.fileTooLarge);
      }

      return DocumentPickSuccess(path: picked.path, name: picked.name);
    } catch (_) {
      return const DocumentPickFailure(
          errorMessage: AppStrings.documentPickFailed);
    }
  }

  Future<({String path, String name})?> _pickImage(
      DocumentSource source) async {
    final file = await _imagePicker.pickImage(
      source: source == DocumentSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    return file == null ? null : (path: file.path, name: file.name);
  }

  Future<({String path, String name})?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: uploadFileExtensions,
    );
    final file = result?.files.singleOrNull;
    final path = file?.path;
    return path == null ? null : (path: path, name: file!.name);
  }
}
