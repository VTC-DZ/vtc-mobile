import 'package:equatable/equatable.dart';

import '../../../../core/utils/upload_file.dart';

enum UploadStatus { idle, uploading, uploaded, error }

enum DriverDocumentType {
  nationalIdFront,
  nationalIdBack,
  licenseFront,
  licenseBack,
  vehicleRegistration,
}

/// A document picked on this device — a photo or a PDF; nothing is uploaded
/// until the application is submitted.
final class DriverDocument extends Equatable {
  const DriverDocument({
    this.filePath,
    this.fileName,
    this.status = UploadStatus.idle,
    this.errorMessage = '',
  });

  final String? filePath;
  final String? fileName;
  final UploadStatus status;
  final String errorMessage;

  bool get isUploaded => status == UploadStatus.uploaded;

  bool get isPdf => filePath != null && isPdfPath(filePath!);

  DriverDocument copyWith({
    String? filePath,
    String? fileName,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return DriverDocument(
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [filePath, fileName, status, errorMessage];
}
