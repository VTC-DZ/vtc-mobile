// lib/features/auth/presentation/views/widgets/profile/driver/fields/driver_document_flip_card_widget.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../data/models/driver_document.dart';

/// Flip-card widget for two-sided documents (e.g. National ID, Driver's License).
///
/// Front and back sides share the same card area — tapping the chip or
/// uploading the front auto-flips to the back.
class DriverDocumentFlipCardWidget extends StatefulWidget {
  const DriverDocumentFlipCardWidget({
    super.key,
    required this.label,
    required this.frontDocument,
    required this.backDocument,
    required this.onFrontTap,
    required this.onBackTap,
    required this.icon,
    this.enabled = true,
  });

  final String label;
  final DriverDocument frontDocument;
  final DriverDocument backDocument;
  final VoidCallback onFrontTap;
  final VoidCallback onBackTap;
  final IconData icon;
  final bool enabled;

  @override
  State<DriverDocumentFlipCardWidget> createState() =>
      _DriverDocumentFlipCardWidgetState();
}

class _DriverDocumentFlipCardWidgetState
    extends State<DriverDocumentFlipCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(DriverDocumentFlipCardWidget old) {
    super.didUpdateWidget(old);
    // Auto-flip to back once front is uploaded
    if (!_showBack &&
        old.frontDocument.status != UploadStatus.uploaded &&
        widget.frontDocument.status == UploadStatus.uploaded) {
      _flip();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showBack) {
      setState(() => _showBack = false);
      _ctrl.reverse();
    } else {
      setState(() => _showBack = true);
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          label: widget.label,
          icon: widget.icon,
          showBack: _showBack,
          enabled: widget.enabled,
          onFlip: _flip,
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 130.h,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final angle = _anim.value * math.pi;
              final frontVisible = angle <= math.pi / 2;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: frontVisible
                    ? _CardFace(
                        isFront: true,
                        document: widget.frontDocument,
                        onTap: widget.onFrontTap,
                        enabled: widget.enabled,
                      )
                    : Transform(
                        transform: Matrix4.rotationY(math.pi),
                        alignment: Alignment.center,
                        child: _CardFace(
                          isFront: false,
                          document: widget.backDocument,
                          onTap: widget.onBackTap,
                          enabled: widget.enabled,
                        ),
                      ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        _Dots(
          showBack: _showBack,
          front: widget.frontDocument,
          back: widget.backDocument,
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.label,
    required this.icon,
    required this.showBack,
    required this.enabled,
    required this.onFlip,
  });

  final String label;
  final IconData icon;
  final bool showBack;
  final bool enabled;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: AppColors.primary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.labelMedium(context)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        GestureDetector(
          onTap: enabled ? onFlip : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: showBack
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface(context),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: showBack
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.borderDefault(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flip_rounded,
                  size: 12.w,
                  color: showBack
                      ? AppColors.primary
                      : AppColors.textSecondary(context),
                ),
                SizedBox(width: 4.w),
                Text(
                  showBack ? 'Back' : 'Front',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: showBack
                        ? AppColors.primary
                        : AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.isFront,
    required this.document,
    required this.onTap,
    required this.enabled,
  });

  final bool isFront;
  final DriverDocument document;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final status = document.status;
    final isUploaded = status == UploadStatus.uploaded;
    final isUploading = status == UploadStatus.uploading;
    final isError = status == UploadStatus.error;
    final hasImage = isUploaded && document.filePath != null;

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
              // ── Image preview when uploaded ─────────────────────────────
              if (hasImage)
                Row(
                  children: [
                    SizedBox(width: 36.w), // leave badge strip uncovered
                    Expanded(
                      child: Image.file(
                        File(document.filePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
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

              // ── Main row ─────────────────────────────────────────────────
              Row(
                children: [
                  // Side badge
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
                          isFront ? 'FRONT' : 'BACK',
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
                    child: _StatusContent(
                        status: status,
                        document: document,
                        hasImage: hasImage),
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
  const _StatusContent({
    required this.status,
    required this.document,
    this.hasImage = false,
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
            Text('Uploaded',
                style: AppTextStyles.labelSmall(context).copyWith(
                  color: textColor ?? AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                )),
            SizedBox(height: 2.h),
            Text('Tap to change',
                style: AppTextStyles.labelSmall(context).copyWith(
                  fontSize: 10.sp,
                  color: textColor?.withValues(alpha: 0.7) ??
                      AppColors.textSecondary(context).withValues(alpha: 0.7),
                )),
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



class _Dots extends StatelessWidget {
  const _Dots(
      {required this.showBack, required this.front, required this.back});

  final bool showBack;
  final DriverDocument front;
  final DriverDocument back;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(context, active: !showBack, doc: front),
        SizedBox(width: 6.w),
        _dot(context, active: showBack, doc: back),
      ],
    );
  }

  Widget _dot(BuildContext context,
      {required bool active, required DriverDocument doc}) {
    final Color color = doc.status == UploadStatus.uploaded
        ? AppColors.primary
        : doc.status == UploadStatus.error
            ? AppColors.error
            : active
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.borderDefault(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 18.w : 6.w,
      height: 5.h,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(3.r)),
    );
  }
}
