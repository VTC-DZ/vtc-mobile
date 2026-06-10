import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/models/ride_models.dart';
import '../cubit/location_picker_cubit.dart';
import '../cubit/location_picker_state.dart';

class LocationPickerView extends StatefulWidget {
  const LocationPickerView({super.key, this.label = 'Location'});

  final String label;

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<LocationPickerCubit>().init();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      context.read<LocationPickerCubit>().search(query);
    });
  }

  void _confirm(LocationPickerState state) {
    final pos = state.selectedPosition!;
    context.pop(CoordinatePoint(
      address: state.pickedAddress.isNotEmpty
          ? state.pickedAddress
          : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
      lat: pos.latitude,
      lng: pos.longitude,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationPickerCubit, LocationPickerState>(
      // Only move the camera when init() or selectResult() changes mapCenter.
      listenWhen: (prev, curr) => prev.mapCenter != curr.mapCenter,
      listener: (context, state) {
        _mapController.move(state.mapCenter, _mapController.camera.zoom);
      },
      child: Scaffold(
        body: BlocBuilder<LocationPickerCubit, LocationPickerState>(
          builder: (context, state) {
            final cubit = context.read<LocationPickerCubit>();

            return Stack(
              children: [
                // ── Map ────────────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: state.mapCenter,
                    initialZoom: 15,
                    onTap: (tapPosition, latLng) => cubit.onMapTap(latLng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.khfif.drif',
                    ),
                    // Pin marker at the tapped position
                    if (state.selectedPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: state.selectedPosition!,
                            width: 44.w,
                            height: 44.w,
                            alignment: Alignment.topCenter,
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 44.w,
                              color: AppColors.primary,
                              shadows: [
                                Shadow(
                                  color: AppColors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Geocoding indicator ────────────────────────────────────
                if (state.isGeocoding)
                  const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),

                // ── Top overlay (back + search) ────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12.h,
                  left: 16.w,
                  right: 16.w,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _MapButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => context.pop(),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _SearchBar(
                              controller: _searchCtrl,
                              focusNode: _searchFocus,
                              hint: 'Search for a location…',
                              isLoading: state.isSearching,
                              onChanged: _onSearchChanged,
                              onClear: () {
                                _searchCtrl.clear();
                                cubit.clearSearch();
                                _searchFocus.unfocus();
                              },
                            ),
                          ),
                        ],
                      ),

                      // Search results dropdown
                      if (state.searchResults.isNotEmpty)
                        _SearchResultsList(
                          results: state.searchResults,
                          onSelect: (place) {
                            _searchCtrl.text = place.displayName;
                            cubit.selectResult(place);
                            _searchFocus.unfocus();
                          },
                        ),
                    ],
                  ),
                ),

                // ── Bottom confirm card ────────────────────────────────────
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 16.h,
                  left: 16.w,
                  right: 16.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.12),
                          blurRadius: 20.r,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16.w,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              widget.label,
                              style: AppTextStyles.labelSmall(context).copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          state.pickedAddress.isNotEmpty
                              ? state.pickedAddress
                              : 'Tap on the map to select a location',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 14.h),
                        PrimaryButton(
                          label: 'Confirm Location',
                          isEnabled: state.selectedPosition != null &&
                              !state.isGeocoding,
                          onPressed: () => _confirm(state),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Small icon button on map overlay ────────────────────────────────────────

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background(context),
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Icon(icon, size: 20.w, color: AppColors.text(context)),
        ),
      ),
    );
  }
}

// ── Search bar widget ────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.isLoading,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background(context),
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      child: SizedBox(
        height: 44.w,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: AppTextStyles.bodyMedium(context)
              .copyWith(color: AppColors.text(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium(context),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18.w,
              color: AppColors.textSecondary(context),
            ),
            suffixIcon: isLoading
                ? Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 16.w,
                            color: AppColors.textSecondary(context)),
                        onPressed: onClear,
                      )
                    : null,
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
          ),
        ),
      ),
    );
  }
}

// ── Search results list ──────────────────────────────────────────────────────

class _SearchResultsList extends StatelessWidget {
  const _SearchResultsList({
    required this.results,
    required this.onSelect,
  });

  final List<NominatimPlace> results;
  final void Function(NominatimPlace) onSelect;

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
                        horizontal: 14.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16.w,
                          color: AppColors.textSecondary(context),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            place.displayName,
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.text(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
