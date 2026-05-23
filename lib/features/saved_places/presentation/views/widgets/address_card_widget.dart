import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../saved_places/data/address_model.dart';
import '../../../../saved_places/presentation/cubit/saved_places_cubit.dart';
import 'address_type_icon_widget.dart';

class AddressCardWidget extends StatelessWidget {
  const AddressCardWidget({super.key, required this.address});

  final AddressModel address;

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Address',
      message: 'Are you sure you want to delete "${address.label}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      if (context.mounted) {
        context.read<SavedPlacesCubit>().deleteAddress(address.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          AddressTypeIconWidget(type: address.type),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  address.address,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20.w),
            onPressed: () =>
                context.push(RouteNames.addressEdit, extra: address),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 20.w),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }
}
