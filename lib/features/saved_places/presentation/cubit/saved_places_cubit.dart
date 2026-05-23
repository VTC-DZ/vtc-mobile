import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/address_model.dart';
import '../../data/address_repository.dart';
import 'saved_places_state.dart';

final class SavedPlacesCubit extends Cubit<SavedPlacesState> {
  SavedPlacesCubit(this._repository) : super(const SavedPlacesState());

  final AddressRepository _repository;

  Future<void> getAddresses() async {
    emit(state.copyWith(
      getAddressesStatus: GetAddressesStatus.loading,
      errorMessage: '',
    ));
    try {
      final addresses = await _repository.getAddresses();
      emit(state.copyWith(
        getAddressesStatus: GetAddressesStatus.success,
        addresses: addresses,
      ));
    } catch (e) {
      emit(state.copyWith(
        getAddressesStatus: GetAddressesStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> addAddress(AddressModel address) async {
    emit(state.copyWith(
      createAddressStatus: CreateAddressStatus.loading,
      errorMessage: '',
    ));
    try {
      final created = await _repository.addAddress(address);
      emit(state.copyWith(
        createAddressStatus: CreateAddressStatus.success,
        addresses: [...state.addresses, created],
      ));
    } catch (e) {
      emit(state.copyWith(
        createAddressStatus: CreateAddressStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    emit(state.copyWith(
      updateAddressStatus: UpdateAddressStatus.loading,
      errorMessage: '',
    ));
    try {
      final updated = await _repository.updateAddress(id, data);
      emit(state.copyWith(
        updateAddressStatus: UpdateAddressStatus.success,
        addresses: state.addresses
            .map((a) => a.id == id ? updated : a)
            .toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        updateAddressStatus: UpdateAddressStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteAddress(String id) async {
    emit(state.copyWith(
      deleteAddressStatus: DeleteAddressStatus.loading,
      errorMessage: '',
    ));
    try {
      await _repository.deleteAddress(id);
      emit(state.copyWith(
        deleteAddressStatus: DeleteAddressStatus.success,
        addresses: state.addresses.where((a) => a.id != id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        deleteAddressStatus: DeleteAddressStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
