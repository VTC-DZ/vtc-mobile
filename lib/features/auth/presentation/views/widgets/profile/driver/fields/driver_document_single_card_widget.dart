// lib/features/auth/presentation/views/widgets/profile/driver/fields/driver_document_single_card_widget.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../data/models/driver_document.dart';

/// Upload card for single-sided documents (e.g. Vehicle Registration).
/// Shares the same left-badge + centred-content layout as the flip card faces.
class DriverDocumentSingleCardWidget extends StatelessWidget {
  const DriverDocumentSingleCardWidget({
    super.key,
    required this.label,
    required this.badgeLabel,
    required this.document,
    required this.onTap,
    this.enabled = true,
  });

  /// Full document label, e.g. "Vehicle Registration".
  final String label;

  /// Short rotated badge text shown in the left strip, e.g. "REG".
  final String badgeLabel;

  final DriverDocument document;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final status = document.status;
    final isUploaded = status == UploadStatus.uploaded;
    final isUploading = status == UploadStatus.uploading;
    final isError = status == UploadStatus.error;

    final borderColor = isUploaded
        ? AppColors.primary.withValues(alpha: 0.5)
        : isError
            ? AppColors.error
            : AppColors.borderDefault(context);

    return GestureDetector(
      onTap: enabled && !isUploading ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 130.h,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Image preview when uploaded ─────────────────────────────
              if (isUploaded && document.filePath != null)
                Row(
                  children: [
                    SizedBox(width: 36.w), // leave badge strip uncovered
                    Expanded(
                      child: Image.file(
                        File(document.filePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),

              // ── Scrim over image ─────────────────────────────────────────
              if (isUploaded && document.filePath != null)
                Positioned(
                  left: 36.w,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),

              // ── Main row (badge + content) ────────────────────────────────
              Row(
                children: [
                  // Left badge strip
                  Container(
                    width: 36.w,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isError
                          ? AppColors.error.withValues(alpha: 0.06)
                          : AppColors.borderDefault(context)
                              .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(13.r),
                        bottomLeft: Radius.circular(13.r),
                      ),
                    ),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          badgeLabel,
                          style: AppTextStyles.labelSmall(context).copyWith(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isError
                                ? AppColors.error
                                : AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: _Content(
                        status: status,
                        document: document,
                        hasImage: isUploaded && document.filePath != null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.status,
    required this.document,
    required this.hasImage,
  });

  final UploadStatus status;
  final DriverDocument document;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case UploadStatus.idle:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_rounded,
                size: 26.w, color: AppColors.textSecondary(context)),
            SizedBox(height: 6.h),
            Text('Tap to upload', style: AppTextStyles.labelSmall(context)),
          ],
        );

      case UploadStatus.uploading:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28.w,
              height: 28.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            SizedBox(height: 8.h),
            Text('Uploading…',
                style: AppTextStyles.labelSmall(context)
                    .copyWith(color: AppColors.primary)),
          ],
        );

      case UploadStatus.uploaded:
        final textColor =
            hasImage ? Colors.white.withValues(alpha: 0.85) : null;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 26.w,
                color: hasImage
                    ? Colors.white70
                    : AppColors.textSecondary(context)),
            SizedBox(height: 6.h),
            Text(
              'Uploaded',
              style: AppTextStyles.labelSmall(context).copyWith(
                color: textColor ?? AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                'Tap to change',
                style: AppTextStyles.labelSmall(context).copyWith(
                  fontSize: 10.sp,
                  color: textColor?.withValues(alpha: 0.7) ??
                      AppColors.textSecondary(context).withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );

      case UploadStatus.error:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 26.w, color: AppColors.error),
            SizedBox(height: 6.h),
            Text('Failed — retry',
                style: AppTextStyles.labelSmall(context)
                    .copyWith(color: AppColors.error)),
          ],
        );
    }
  }
}
