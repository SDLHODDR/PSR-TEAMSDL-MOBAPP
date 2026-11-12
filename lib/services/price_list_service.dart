import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/price_list_data.dart';

class PriceListService {
  PriceListService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PriceListData> load() async {
    final data = await _apiClient.priceList();
    try {
      return PriceListData.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The price-list response is invalid.');
    }
  }
}
