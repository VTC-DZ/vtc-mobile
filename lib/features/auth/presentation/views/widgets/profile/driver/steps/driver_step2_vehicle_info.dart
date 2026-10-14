import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/widgets/image_source_bottom_sheet.dart';

import '../../../../../../data/models/driver_document.dart';
import '../../../../../../../../shared/widgets/form/profile_field_label_widget.dart';
import '../../../../../cubit/driver_registration_cubit/driver_registration_cubit.dart';
import '../../../../../cubit/driver_registration_cubit/driver_registration_state.dart';
import '../fields/driver_category_dropdown_widget.dart';
import '../fields/driver_color_picker_field_widget.dart';
import '../fields/document_source_sheet.dart';
import '../fields/driver_document_single_card_widget.dart';
import '../../../../../../../../shared/widgets/form/app_date_picker_field_widget.dart';
import '../fields/driver_plate_field_widget.dart';
import '../fields/driver_text_field_widget.dart';
import '../fields/driver_year_dropdown_widget.dart';
import '../../../../../../../../core/constants/validation_patterns.dart';

class DriverStep2VehicleInfo extends StatefulWidget {
  const DriverStep2VehicleInfo({super.key});

  @override
  State<DriverStep2VehicleInfo> createState() => _DriverStep2VehicleInfoState();
}

class _DriverStep2VehicleInfoState extends State<DriverStep2VehicleInfo> {
  late final TextEditingController _modelController = TextEditingController();
  late final TextEditingController _plateController = TextEditingController();

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverRegistrationCubit, DriverRegistrationState>(
      buildWhen: (prev, curr) => prev.vehicleInfo != curr.vehicleInfo,
      builder: (context, state) {
        final cubit = context.read<DriverRegistrationCubit>();
        final vehicle = state.vehicleInfo;
        final isSubmitting = state.status == DriverRegistrationStatus.loading;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Vehicle Category ──────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldVehicleType),
              SizedBox(height: 8.h),
              DriverCategoryDropdownWidget(
                selectedCategory: vehicle.vehicleCategory,
                onChanged: cubit.vehicleCategoryChanged,
                enabled: !isSubmitting,
              ),

              SizedBox(height: 24.h),

              // ── Model ──────────────────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldCarModel),
              SizedBox(height: 8.h),
              DriverTextFieldWidget(
                controller: _modelController,
                hintText: AppStrings.hintCarModel,
                icon: Icons.drive_eta_outlined,
                onChanged: cubit.vehicleModelChanged,
                error: vehicle.vehicleModelError,
                enabled: !isSubmitting,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      ValidationPatterns.vehicleModelInputChars),
                ],
              ),

              SizedBox(height: 24.h),

              // ── Year ───────────────────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldYear),
              SizedBox(height: 8.h),
              DriverYearDropdownWidget(
                selectedYear: vehicle.vehicleYear,
                onChanged: cubit.vehicleYearChanged,
                enabled: !isSubmitting,
              ),

              SizedBox(height: 24.h),

              // ── Color ──────────────────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldColor),
              SizedBox(height: 8.h),
              DriverColorPickerFieldWidget(
                selectedColor: vehicle.vehicleColor.isEmpty
                    ? null
                    : vehicle.vehicleColor,
                onChanged: cubit.vehicleColorChanged,
                enabled: !isSubmitting,
              ),

              SizedBox(height: 24.h),

              // ── Plate Number ───────────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldPlateNumber),
              SizedBox(height: 8.h),
              DriverPlateFieldWidget(
                controller: _plateController,
                onChanged: cubit.plateNumberChanged,
                error: vehicle.plateNumberError,
                enabled: !isSubmitting,
              ),

              SizedBox(height: 24.h),
              // ── Insurance Expiry ───────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldInsuranceExpiry),
              SizedBox(height: 8.h),
              AppDatePickerFieldWidget(
                hintText: AppStrings.hintExpiryDate,
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                selectedDate: vehicle.insuranceExpiry,
                onDateSelected: cubit.insuranceExpiryChanged,
                enabled: !isSubmitting,
                isFutureDate: true,
              ),

              SizedBox(height: 24.h),
              // ── Vehicle Photo ──────────────────────────────────────────────────
              const ProfileFieldLabelWidget(
                  label: AppStrings.fieldVehiclePhoto),
              SizedBox(height: 8.h),
              DriverDocumentSingleCardWidget(
                badgeLabel: AppStrings.docBadgePhoto,
                document: DriverDocument(
                  status: vehicle.vehiclePhotoPath != null
                      ? UploadStatus.uploaded
                      : UploadStatus.idle,
                  filePath: vehicle.vehiclePhotoPath,
                ),
                onTap: () async {
                  final source = await showImageSourceSheet(context);
                  if (source != null) cubit.pickVehiclePhoto(source);
                },
                enabled: !isSubmitting,
              ),

              SizedBox(height: 24.h),

              // ── Insurance Document ─────────────────────────────────────────────
              const ProfileFieldLabelWidget(label: AppStrings.fieldInsurance),
              SizedBox(height: 8.h),
              DriverDocumentSingleCardWidget(
                badgeLabel: AppStrings.docBadgeInsurance,
                document: vehicle.insuranceDocument,
                onTap: () async {
                  final source = await showDocumentSourceSheet(context);
                  if (source != null) cubit.pickInsuranceDocument(source);
                },
                enabled: !isSubmitting,
              ),

              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }
}
