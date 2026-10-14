import 'package:flutter/material.dart';

import '../../../../../../../../shared/widgets/bottomsheets/app_option_sheet.dart';
import '../../../../../../../../shared/widgets/app_text_field.dart';
import '../../../../../../../ride/shared/models/shared_ride_models.dart';
import '../../../../../../../../core/constants/app_strings.dart';

class DriverCategoryDropdownWidget extends StatefulWidget {
  const DriverCategoryDropdownWidget({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.enabled,
  });

  final VehicleCategory? selectedCategory;
  final ValueChanged<VehicleCategory> onChanged;
  final bool enabled;

  @override
  State<DriverCategoryDropdownWidget> createState() =>
      _DriverCategoryDropdownWidgetState();
}

class _DriverCategoryDropdownWidgetState
    extends State<DriverCategoryDropdownWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _getText());
  }

  @override
  void didUpdateWidget(covariant DriverCategoryDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _controller.text = _getText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getText() => widget.selectedCategory?.label ?? '';

  void _openSheet() async {
    final selected = await showAppOptionSheet<VehicleCategory>(
      context: context,
      title: AppStrings.selectVehicleType,
      options: [
        for (final category in VehicleCategory.values)
          AppSheetOption(
            icon: category.icon,
            label: category.label,
            value: category,
          ),
      ],
    );
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      readOnly: true,
      onTap: widget.enabled ? _openSheet : null,
      enabled: widget.enabled,
      hintText: AppStrings.selectType,
      prefixIcon: const Icon(Icons.directions_car_outlined),
      suffixIcon: const Icon(Icons.expand_more_rounded),
    );
  }
}
