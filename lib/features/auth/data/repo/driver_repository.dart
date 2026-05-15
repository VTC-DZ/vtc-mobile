// lib/features/auth/data/repo/driver_repository.dart

import 'package:dio/dio.dart';
import 'package:khfif_drif/core/session/auth_session.dart';

import '../../../../core/constants/driver_api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/image_compressor.dart';

final class DriverRepository {
  const DriverRepository();

  Future<KycSubmitResult> submitKyc({
    required Map<String, dynamic> reqFields,
    required List<String> nationalIdPaths,
    required List<String> driverLicensePaths,
    required String grayCardPath,
    required String insurancePath,
    required List<String> carPicturePaths,
  }) async {
    final formData = FormData();

    reqFields.forEach((key, value) {
      if (value != null) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    for (final path in nationalIdPaths) {
      final compressed = await ImageCompressor.compress(path);
      formData.files.add(
          MapEntry('nationalId', await MultipartFile.fromFile(compressed)));
    }
    for (final path in driverLicensePaths) {
      final compressed = await ImageCompressor.compress(path);
      formData.files.add(
          MapEntry('driverLicense', await MultipartFile.fromFile(compressed)));
    }
    final compressedGrayCard = await ImageCompressor.compress(grayCardPath);
    formData.files.add(
        MapEntry('grayCard', await MultipartFile.fromFile(compressedGrayCard)));
    final compressedInsurance = await ImageCompressor.compress(insurancePath);
    formData.files.add(MapEntry(
        'insurance', await MultipartFile.fromFile(compressedInsurance)));
    for (final path in carPicturePaths) {
      final compressed = await ImageCompressor.compress(path);
      formData.files.add(
          MapEntry('carPictures', await MultipartFile.fromFile(compressed)));
    }

    final response = await DioClient.postMultipart(
      path: DriverApiConstants.kycSubmit,
      formData: formData,
    );

    final data = response.data as Map<String, dynamic>;

    await AuthSession.setWaitingKycStatus(true);

    return KycSubmitResult(
      submissionId: data['submissionId'] as String? ?? '',
      status: data['status'] as String? ?? '',
    );
  }

  Future<KycStatusResult> getKycStatus() async {
    final response = await DioClient.get(
      path: DriverApiConstants.kycStatus,
    );

    final data = response.data as Map<String, dynamic>;
    final submission = data['submission'] as Map<String, dynamic>?;
    return KycStatusResult(
      kycStatus: data['kycStatus'] as String? ?? '',
      submissionId: submission?['id'] as String?,
      submissionStatus: submission?['status'] as String?,
      resubmissionNote: submission?['resubmissionNote'] as String?,
    );
  }
}

final class KycSubmitResult {
  const KycSubmitResult({required this.submissionId, required this.status});
  final String submissionId;
  final String status;
}

final class KycStatusResult {
  const KycStatusResult({
    required this.kycStatus,
    this.submissionId,
    this.submissionStatus,
    this.resubmissionNote,
  });

  final String kycStatus;
  final String? submissionId;
  final String? submissionStatus;
  final String? resubmissionNote;
}
