import '../core/api/api_client.dart';
import '../models/asp_campaign_data.dart';

class AspCampaignService {
  AspCampaignService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AspCampaignOrder>> loadOrders() async {
    final data = await _apiClient.aspCampaignOrders();
    return _maps(data['orders'])
        .map(AspCampaignOrder.fromJson)
        .toList(growable: false);
  }

  Future<AspCampaignOptions> loadOptions() async {
    final data = await _apiClient.aspCampaignOptions();
    return AspCampaignOptions.fromJson(data);
  }

  Future<void> save({
    required int customerId,
    required int orderToId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _apiClient.saveAspCampaignOrder({
      'customer_id': customerId,
      'order_to_id': orderToId,
      'items': items,
    });
  }

  List<Map<String, dynamic>> _maps(dynamic value) => value is! List
      ? const []
      : value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
}
