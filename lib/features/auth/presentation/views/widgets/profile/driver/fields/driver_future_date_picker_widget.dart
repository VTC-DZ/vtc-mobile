import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../core/theme/app_text_styles.dart';

class DriverFutureDatePickerWidget extends StatelessWidget {
  const DriverFutureDatePickerWidget({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    required this.enabled,
  });

  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool enabled;

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedDate != null;

    return GestureDetector(
      onTap: enabled ? () => _openPicker(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.borderDefault(context),
            width: 1.5.w,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 20.w,
                color: AppColors.textSecondary(context),
              ),
              SizedBox(width: 12.w),
              Text(
                hasValue ? _formatDate(selectedDate!) : label,
                style: hasValue
                    ? AppTextStyles.inputText(context)
                    : AppTextStyles.inputHint(context),
              ),
              const Spacer(),
              Icon(
                Icons.calendar_month_outlined,
                size: 18.w,
                color: AppColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
