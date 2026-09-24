import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../core/utils/uuid.dart';
import '../../../../../saved_places/data/address_model.dart';
import '../../../data/models/place_models.dart';
import '../../../data/places_repository.dart';
import 'location_picker_state.dart';

class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit(this._places) : super(const LocationPickerState());

  final PlacesRepository _places;

  /// Groups the keystrokes of one search session; cleared once a result is
  /// resolved or the search is cleared.
  String? _sessionToken;

  /// Incremented per search so a slow earlier response can't overwrite a
  /// newer one.
  int _searchSeq = 0;

  Future<void> init({LatLng? initial}) async {
    // When an initial position is provided (e.g. editing a saved place),
    // open centered on it with the pin already dropped and address resolved.
    if (initial != null) {
      emit(state.copyWith(
        mapCenter: initial,
        selectedPosition: initial,
        isGeocoding: true,
        clearError: true,
      ));
      await _reverseGeocode(initial);
      return;
    }

    final position = await _fetchPosition();
    // Only center the camera — no pin, no geocoding until user taps.
    if (position != null) {
      emit(state.copyWith(mapCenter: position));
    }
    // If position is null, silently fall back to the default Algeria center.
  }

  /// Recenters the camera on the device's current GPS position.
  /// Keeps any existing pin/selection intact.
  ///
  /// Returns `true` on success, `false` (with an [errorMessage] emitted) when
  /// the position can't be resolved. The view uses the return value to decide
  /// whether to move the camera or show an error toast.
  Future<bool> goToMyLocation() async {
    emit(state.copyWith(isLocating: true, clearError: true));
    final position = await _fetchPosition();
    if (position != null) {
      emit(state.copyWith(mapCenter: position, isLocating: false));
      return true;
    }
    emit(state.copyWith(
      isLocating: false,
      errorMessage: 'Could not get your location. Check GPS/permissions.',
    ));
    return false;
  }

  /// Resolves GPS permissions and returns the current position, or null on any
  /// failure (service disabled, permission denied, timeout, …).
  Future<LatLng?> _fetchPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  void onMapTap(LatLng position) {
    emit(state.copyWith(
      selectedPosition: position,
      pickedAddress: '',
      isGeocoding: true,
      clearError: true,
    ));
    _reverseGeocode(position);
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final place = await _places.reverseGeocode(position);
      if (isClosed || state.selectedPosition != position) return;
      emit(state.copyWith(pickedAddress: place.label, isGeocoding: false));
    } catch (_) {
      if (isClosed || state.selectedPosition != position) return;
      emit(state.copyWith(
        isGeocoding: false,
        pickedAddress:
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      ));
    }
  }

  Future<void> search(String query) async {
    final q = query.trim();
    final seq = ++_searchSeq;
    // The API rejects queries shorter than 2 characters.
    if (q.length < 2) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }
    emit(state.copyWith(isSearching: true, searchResults: [], clearError: true));
    try {
      final results = await _places.search(
        q,
        sessionToken: _sessionToken ??= uuidV4(),
        bias: state.mapCenter,
      );
      if (isClosed || seq != _searchSeq) return;
      emit(state.copyWith(searchResults: results, isSearching: false));
    } catch (_) {
      if (isClosed || seq != _searchSeq) return;
      emit(state.copyWith(searchResults: [], isSearching: false));
    }
  }

  /// Search results carry no coordinates, so the place is resolved first.
  ///
  /// Returns `false` (with an [errorMessage] emitted) when it can't be
  /// resolved; the view shows the error toast.
  Future<bool> selectResult(PlaceSummary place) async {
    _searchSeq++; // Drop any in-flight search response.
    // Any previous pin stays put on failure, so its address is restored too.
    final previousAddress = state.pickedAddress;
    emit(state.copyWith(
      pickedAddress: place.label,
      isGeocoding: true,
      searchResults: [],
      isSearching: false,
      clearError: true,
    ));
    try {
      final detail = await _places.resolve(place.placeId);
      _sessionToken = null;
      if (isClosed) return false;
      final position = LatLng(detail.lat, detail.lng);
      // Move camera AND drop pin at the resolved place.
      emit(state.copyWith(
        mapCenter: position,
        selectedPosition: position,
        pickedAddress: detail.label,
        isGeocoding: false,
      ));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(
        isGeocoding: false,
        pickedAddress: previousAddress,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  void clearSearch() {
    _searchSeq++;
    _sessionToken = null;
    emit(state.copyWith(searchResults: [], isSearching: false));
  }

  void selectSavedAddress(AddressModel address) {
    final position = LatLng(address.latitude, address.longitude);
    // Move camera AND drop pin at the saved address, using its stored address text directly.
    emit(state.copyWith(
      mapCenter: position,
      selectedPosition: position,
      pickedAddress: address.address,
      searchResults: [],
      isSearching: false,
    ));
  }
}
