import '../../../../core/constants/address_api_constants.dart';
import '../../../../core/network/dio_client.dart';
import 'address_model.dart';

final class AddressRepository {
  const AddressRepository();

  Future<List<AddressModel>> getAddresses() async {
    final response = await DioClient.get(path: AddressApiConstants.list);
    final list = response.data['addresses'] as List<dynamic>;
    return list
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    final response = await DioClient.post(
      path: AddressApiConstants.add,
      data: address.toJson(),
    );
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AddressModel> updateAddress(String id, Map<String, dynamic> data) async {
    final response = await DioClient.put(
      path: AddressApiConstants.update(id),
      data: data,
    );
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await DioClient.delete(path: AddressApiConstants.delete(id));
  }
}
