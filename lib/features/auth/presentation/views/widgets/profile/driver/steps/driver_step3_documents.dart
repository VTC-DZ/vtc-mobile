import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../data/models/driver_document.dart';
import '../../../../../cubit/driver_registration_cubit/driver_registration_cubit.dart';
import '../../../../../cubit/driver_registration_cubit/driver_registration_state.dart';
import '../fields/driver_document_flip_card_widget.dart';
import '../fields/document_source_sheet.dart';
import '../fields/driver_document_single_card_widget.dart';
import '../../../../../../../../shared/widgets/form/app_date_picker_field_widget.dart';
import '../fields/driver_text_field_widget.dart';
import '../../../../../../../../shared/widgets/form/profile_field_label_widget.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/validation_patterns.dart';

class DriverStep3Documents extends StatefulWidget {
  const DriverStep3Documents({super.key});

  @override
  State<DriverStep3Documents> createState() => _DriverStep3DocumentsState();
}

class _DriverStep3DocumentsState extends State<DriverStep3Documents> {
  final _licenseNumberController = TextEditingController();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverRegistrationCubit, DriverRegistrationState>(
      buildWhen: (prev, curr) =>
          prev.documents != curr.documents || prev.status != curr.status,
      builder: (context, state) {
        final cubit = context.read<DriverRegistrationCubit>();
        final docs = state.documents;
        final isSubmitting = state.status == DriverRegistrationStatus.loading;

        Future<void> pick(DriverDocumentType type) async {
          final source = await showDocumentSourceSheet(context);
          if (source != null) cubit.pickDocument(type, source);
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Info hint ───────────────────────────────────────────────────
              _InfoHint(),
              SizedBox(height: 24.h),

              // ── License Details ─────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldLicenseNumber),
              SizedBox(height: 8.h),
              DriverTextFieldWidget(
                controller: _licenseNumberController,
                hintText: AppStrings.hintLicenseNumber,
                icon: Icons.credit_card_outlined,
                onChanged: cubit.licenseNumberChanged,
                error: docs.licenseNumberError,
                enabled: !isSubmitting,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      ValidationPatterns.licenseNumberInputChars),
                ],
              ),

              SizedBox(height: 20.h),

              const ProfileFieldLabelWidget(label: AppStrings.fieldLicenseExpiry),
              SizedBox(height: 8.h),
              AppDatePickerFieldWidget(
                hintText: AppStrings.hintExpiryDate,
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                selectedDate: docs.licenseExpiry,
                onDateSelected: cubit.licenseExpiryChanged,
                enabled: !isSubmitting,
                isFutureDate: true,
              ),

              SizedBox(height: 20.h),

              // ── License Photos ──────────────────────────────────────────────
              DriverDocumentFlipCardWidget(
                label: AppStrings.fieldLicensePhotos,
                frontDocument: docs.licenseFront,
                backDocument: docs.licenseBack,
                onFrontTap: () => pick(DriverDocumentType.licenseFront),
                onBackTap: () => pick(DriverDocumentType.licenseBack),
                icon: Icons.credit_card_outlined,
                enabled: !isSubmitting,
              ),

              SizedBox(height: 20.h),

              // ── National ID ─────────────────────────────────────────────────
              DriverDocumentFlipCardWidget(
                label: AppStrings.fieldNationalId,
                frontDocument: docs.nationalIdFront,
                backDocument: docs.nationalIdBack,
                onFrontTap: () => pick(DriverDocumentType.nationalIdFront),
                onBackTap: () => pick(DriverDocumentType.nationalIdBack),
                icon: Icons.badge_outlined,
                enabled: !isSubmitting,
              ),

              SizedBox(height: 20.h),

              // ── Vehicle Registration ────────────────────────────────────────
              const _SectionLabel(text: AppStrings.docVehicleRegistration),
              SizedBox(height: 8.h),
              DriverDocumentSingleCardWidget(
                badgeLabel: AppStrings.docBadgeRegistration,
                document: docs.vehicleRegistration,
                onTap: () => pick(DriverDocumentType.vehicleRegistration),
                enabled: !isSubmitting,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _InfoHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 15.w),
          SizedBox(width: 8.w),
          Text(
            AppStrings.documentRequirements,
            style: AppTextStyles.labelSmall(context)
                .copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelMedium(context)
          .copyWith(fontWeight: FontWeight.w600),
    );
  }
}
