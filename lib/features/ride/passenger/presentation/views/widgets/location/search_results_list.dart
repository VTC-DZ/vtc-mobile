import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/place_models.dart';

class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.results,
    required this.onSelect,
  });

  final List<PlaceSummary> results;
  final void Function(PlaceSummary) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 6.h),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: results.map((place) {
            final isLast = place == results.last;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onSelect(place),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16.w,
                          color: AppColors.textSecondary(context),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                place.displayName,
                                style:
                                    AppTextStyles.bodySmall(context).copyWith(
                                  color: AppColors.text(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (place.formattedAddress.isNotEmpty &&
                                  place.formattedAddress != place.displayName)
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h),
                                  child: Text(
                                    place.formattedAddress,
                                    style: AppTextStyles.bodySmall(context)
                                        .copyWith(
                                      color: AppColors.textSecondary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 40.w,
                    color: AppColors.borderDefault(context),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
