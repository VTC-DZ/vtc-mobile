// lib/features/auth/presentation/views/widgets/profile/driver/fields/driver_date_picker_field_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/constants/app_constants.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../../shared/widgets/app_text_field.dart';

/// A tappable field that opens a beautifully themed date picker,
/// using AppTextField for exact design consistency.
class DriverDatePickerFieldWidget extends StatefulWidget {
  const DriverDatePickerFieldWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.enabled,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool enabled;

  @override
  State<DriverDatePickerFieldWidget> createState() =>
      _DriverDatePickerFieldWidgetState();
}

class _DriverDatePickerFieldWidgetState
    extends State<DriverDatePickerFieldWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getText());
  }

  @override
  void didUpdateWidget(covariant DriverDatePickerFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _controller.text = _getText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getText() {
    if (widget.selectedDate == null) return '';
    return _formatDate(widget.selectedDate!);
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _openPicker() async {
    final maxDate = DateTime(
      DateTime.now().year - AppConstants.driverMinAgeYears,
      DateTime.now().month,
      DateTime.now().day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? maxDate,
      firstDate: DateTime(1940),
      lastDate: maxDate,
      builder: (context, child) {
        final isDark = AppColors.isDark(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.text(context), // Minimal primary
                    onPrimary: AppColors.background(context),
                    surface: AppColors.surface(context),
                    onSurface: AppColors.text(context),
                  )
                : ColorScheme.light(
                    primary: AppColors.text(context), // Minimal primary
                    onPrimary: AppColors.background(context),
                    surface: AppColors.surface(context),
                    onSurface: AppColors.text(context),
                  ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppColors.surface(context),
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppColors.surface(context),
              headerForegroundColor: AppColors.text(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              dayStyle: AppTextStyles.bodyMedium(context)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.text(context),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) widget.onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      readOnly: true,
      onTap: widget.enabled ? _openPicker : null,
      enabled: widget.enabled,
      hintText: 'DD/MM/YYYY',
      prefixIcon: const Icon(Icons.cake_outlined),
      suffixIcon: const Icon(Icons.calendar_month_outlined),
    );
  }
}
