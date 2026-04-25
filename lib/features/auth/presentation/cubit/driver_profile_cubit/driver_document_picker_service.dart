import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../data/models/driver_document.dart';
import 'document_pick_result.dart';

final class DriverDocumentPickerService {
  DriverDocumentPickerService() : _imagePicker = ImagePicker();

  DriverDocumentPickerService.withPicker(this._imagePicker);

  final ImagePicker _imagePicker;

  Future<String?> pickVehiclePhoto() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  Future<DocumentPickResult> pickDocument(DriverDocumentType type) async {
    try {
      final (path, name) = await _selectFile(type);

      if (path == null) return const DocumentPickCancelled();

      final fileSize = await File(path).length();
      if (fileSize > AppConstants.maxDocumentSizeBytes) {
        return const DocumentPickFailure(errorMessage: AppStrings.fileTooLarge);
      }

      await Future<void>.delayed(const Duration(milliseconds: 800));

      return DocumentPickSuccess(path: path, name: name ?? path.split('/').last);
    } catch (_) {
      return const DocumentPickFailure(errorMessage: 'Upload failed. Tap to retry.');
    }
  }

  Future<(String?, String?)> _selectFile(DriverDocumentType type) async {
    if (type == DriverDocumentType.vehicleRegistration) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        return (result.files.first.path, result.files.first.name);
      }
      return (null, null);
    } else {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return (file?.path, file?.name);
    }
  }
}
