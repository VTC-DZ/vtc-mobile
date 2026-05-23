import 'package:equatable/equatable.dart';

import '../../data/address_model.dart';

enum GetAddressesStatus { initial, loading, success, failure }
enum CreateAddressStatus { initial, loading, success, failure }
enum UpdateAddressStatus { initial, loading, success, failure }
enum DeleteAddressStatus { initial, loading, success, failure }

final class SavedPlacesState extends Equatable {
  const SavedPlacesState({
    this.getAddressesStatus = GetAddressesStatus.initial,
    this.createAddressStatus = CreateAddressStatus.initial,
    this.updateAddressStatus = UpdateAddressStatus.initial,
    this.deleteAddressStatus = DeleteAddressStatus.initial,
    this.addresses = const [],
    this.errorMessage = '',
  });

  final GetAddressesStatus getAddressesStatus;
  final CreateAddressStatus createAddressStatus;
  final UpdateAddressStatus updateAddressStatus;
  final DeleteAddressStatus deleteAddressStatus;
  final List<AddressModel> addresses;
  final String errorMessage;

  bool get isLoading => getAddressesStatus == GetAddressesStatus.loading;
  bool get isEmpty =>
      getAddressesStatus == GetAddressesStatus.success && addresses.isEmpty;

  SavedPlacesState copyWith({
    GetAddressesStatus? getAddressesStatus,
    CreateAddressStatus? createAddressStatus,
    UpdateAddressStatus? updateAddressStatus,
    DeleteAddressStatus? deleteAddressStatus,
    List<AddressModel>? addresses,
    String? errorMessage,
  }) {
    return SavedPlacesState(
      getAddressesStatus: getAddressesStatus ?? this.getAddressesStatus,
      createAddressStatus: createAddressStatus ?? this.createAddressStatus,
      updateAddressStatus: updateAddressStatus ?? this.updateAddressStatus,
      deleteAddressStatus: deleteAddressStatus ?? this.deleteAddressStatus,
      addresses: addresses ?? this.addresses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        getAddressesStatus,
        createAddressStatus,
        updateAddressStatus,
        deleteAddressStatus,
        addresses,
        errorMessage,
      ];
}
