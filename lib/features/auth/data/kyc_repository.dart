import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/driver_api_constants.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/session/auth_session.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/upload_file.dart';
import '../../profile/shared/data/models/kyc_status.dart';
import 'models/kyc_status_result.dart';
import 'models/kyc_submission.dart';

/// Driver KYC: submitting the application and reading its review status.
///
/// Not `final`, so tests can extend it with a fake.
class KycRepository {
  const KycRepository();

  /// Uploads the whole application in one multipart request. Every photo is
  /// recompressed first (see [ImageCompressor]); a PDF goes up as picked.
  /// [onProgress] gets the share of the request sent so far, from 0 to 1.
  Future<KycSubmitResult> submitKyc(
    KycSubmission submission, {
    void Function(double fraction)? onProgress,
  }) async {
    final formData = FormData()..fields.addAll(submission.toFields().entries);
    await _addFiles(formData, 'nationalId', submission.nationalIdPaths);
    await _addFiles(formData, 'driverLicense', submission.driverLicensePaths);
    await _addFiles(formData, 'grayCard', [submission.grayCardPath]);
    await _addFiles(formData, 'insurance', [submission.insurancePath]);
    await _addFiles(formData, 'carPictures', submission.carPicturePaths);

    final result = await _send(formData, onProgress);

    await AuthSession.setWaitingKycStatus(true);
    // The server creates the driver profile with the first application.
    await AuthSession.setHasDriverProfile(true);
    // Onboarding is over once an application exists — otherwise the app would
    // reopen on the mode selection screen forever.
    await AuthSession.setIsNewUser(false);

    return result;
  }

  /// Reads the review status. An approval also clears
  /// [AuthSession.waitingKycStatus]: the driver is no longer waiting on review.
  Future<KycStatusResult> getKycStatus() async {
    final response = await DioClient.get(path: DriverApiConstants.kycStatus);
    final result =
        KycStatusResult.fromJson(response.data as Map<String, dynamic>);
    if (result.kycStatus == KycStatus.approved) {
      await AuthSession.setWaitingKycStatus(false);
    }
    return result;
  }

  /// Posts the application. A `409 submission_already_pending` means one is
  /// already waiting for review — say, an earlier tap whose answer never
  /// arrived. A 409 means this view is stale, not that the submit failed, so
  /// it ends like a success.
  static Future<KycSubmitResult> _send(
    FormData formData,
    void Function(double fraction)? onProgress,
  ) async {
    try {
      final response = await DioClient.postMultipart(
        path: DriverApiConstants.kycSubmit,
        formData: formData,
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) onProgress(sent / total);
              },
      );
      return KycSubmitResult.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (!e.isConflict ||
          !e.hasCode(KycErrorCodes.submissionAlreadyPending)) {
        rethrow;
      }
      return const KycSubmitResult(submissionId: '', status: 'SUBMITTED');
    }
  }

  /// Attaches each of [paths] under the multipart [field], in order (the
  /// server keeps the front of a two-sided document first). Photos are
  /// compressed; a PDF is sent as it is.
  static Future<void> _addFiles(
    FormData formData,
    String field,
    List<String> paths,
  ) async {
    for (final path in paths) {
      final upload =
          isPdfPath(path) ? path : await ImageCompressor.compress(path);
      formData.files.add(MapEntry(
        field,
        await MultipartFile.fromFile(
          upload,
          filename: p.basename(upload),
          contentType: uploadContentType(upload),
        ),
      ));
    }
  }
}
