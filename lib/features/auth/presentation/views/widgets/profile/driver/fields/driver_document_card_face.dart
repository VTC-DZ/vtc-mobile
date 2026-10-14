import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../data/models/driver_document.dart';

/// One document card: a rotated [badgeLabel] strip on the left and the
/// document's state on the right (the photo itself once one is picked, or the
/// file name for a PDF).
///
/// Fills its parent; [DriverDocumentSingleCardWidget] and both sides of
/// [DriverDocumentFlipCardWidget] give it the height.
class DriverDocumentCardFace extends StatelessWidget {
  const DriverDocumentCardFace({
    super.key,
    required this.badgeLabel,
    required this.document,
    required this.onTap,
    required this.enabled,
  });

  /// Short text in the left strip, e.g. "REG" or "FRONT".
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
    final hasImage = isUploaded && document.filePath != null && !document.isPdf;

    final borderColor = isUploaded
        ? AppColors.primary.withValues(alpha: 0.5)
        : isError
            ? AppColors.error
            : AppColors.borderDefault(context);

    return GestureDetector(
      onTap: enabled && !isUploading ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
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
              // ── Image preview once picked ───────────────────────────────
              if (hasImage)
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
              if (hasImage)
                Positioned(
                  left: 36.w,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),

              // ── Badge strip + content ────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isError
                          ? AppColors.error.withValues(alpha: 0.06)
                          : AppColors.text(context).withValues(alpha: 0.06),
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
                  Expanded(
                    child: _StatusContent(document: document, hasImage: hasImage),
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

class _StatusContent extends StatelessWidget {
  const _StatusContent({required this.document, required this.hasImage});

  final DriverDocument document;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    switch (document.status) {
      case UploadStatus.idle:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_rounded,
                size: 26.w, color: AppColors.textSecondary(context)),
            SizedBox(height: 6.h),
            Text(AppStrings.docTapToUpload,
                style: AppTextStyles.labelSmall(context)),
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
            Text(AppStrings.docUploading,
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
            Icon(
                document.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.insert_drive_file_outlined,
                size: 26.w,
                color: hasImage
                    ? Colors.white70
                    : AppColors.textSecondary(context)),
            SizedBox(height: 6.h),
            Text(
              AppStrings.docUploaded,
              style: AppTextStyles.labelSmall(context).copyWith(
                color: textColor ?? AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (document.isPdf && document.fileName != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  document.fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    fontSize: 10.sp,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                AppStrings.docTapToChange,
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                document.errorMessage.isNotEmpty
                    ? document.errorMessage
                    : AppStrings.docFailedRetry,
                style: AppTextStyles.labelSmall(context)
                    .copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
    }
  }
}
