import '../core/api/api_client.dart';

class DayPlanService {
  DayPlanService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> load(String date) => _apiClient.dayPlan(date);

  Future<Map<String, dynamic>> loadOptions(String date) =>
      _apiClient.dayPlanOptions(date);

  Future<Map<String, dynamic>> loadRouteCustomers(
    int dayPlanId,
    int routeId,
  ) =>
      _apiClient.dayPlanRouteCustomers(dayPlanId, routeId);

  Future<Map<String, dynamic>> loadUnlistedCustomers(int dayPlanId) =>
      _apiClient.dayPlanUnlistedCustomers(dayPlanId);

  Future<Map<String, dynamic>> loadCustomerActivity({
    required int dayPlanId,
    required String activity,
    int? customerId,
    int? unlistedCustomerId,
    String? orderType,
  }) =>
      _apiClient.dayPlanCustomerActivity(
        dayPlanId: dayPlanId,
        activity: activity,
        customerId: customerId,
        unlistedCustomerId: unlistedCustomerId,
        orderType: orderType,
      );

  Future<void> deleteListedCustomer({
    required int dayPlanId,
    required int customerId,
  }) async {
    await _apiClient.deleteDayPlanCustomer(dayPlanId, customerId);
  }

  Future<void> saveCustomerActivity({
    required int dayPlanId,
    required String activity,
    required List<Map<String, dynamic>> products,
    int? customerId,
    int? unlistedCustomerId,
    int? routeId,
    List<int> workWithIds = const [],
    String? orderType,
    String remarks = '',
    String orderTo = '',
  }) async {
    await _apiClient.saveDayPlanCustomerActivity({
      'day_plan_id': dayPlanId,
      'activity': activity,
      'products': products,
      if (activity == 'detailing') 'work_with_ids': workWithIds,
      if (customerId != null) 'customer_id': customerId,
      if (routeId != null) 'route_id': routeId,
      if (unlistedCustomerId != null)
        'unlisted_customer_id': unlistedCustomerId,
      if (orderType != null && orderType.isNotEmpty) 'order_type': orderType,
      if (activity == 'pob') 'remarks': remarks,
      if (activity == 'pob' && customerId != null) 'order_to': orderTo,
    });
  }

  Future<Map<String, dynamic>> saveDraft({
    required String date,
    required String remarks,
    int? startTownId,
  }) =>
      _apiClient.saveDayPlanDraft({
        'date': date,
        'remarks': remarks,
        if (startTownId != null) 'start_town_id': startTownId,
      });

  Future<void> addListedCustomers({
    required int dayPlanId,
    required int routeId,
    required List<int> customerIds,
  }) async {
    await _apiClient.addDayPlanListedCustomers({
      'day_plan_id': dayPlanId,
      'route_id': routeId,
      'customer_ids': customerIds,
    });
  }

  Future<void> addUnlistedCustomer({
    required int dayPlanId,
    required int customerTypeId,
    required String name,
    required String qualification,
    required String phone,
    required String place,
  }) async {
    await _apiClient.addDayPlanUnlistedCustomer({
      'day_plan_id': dayPlanId,
      'customer_type_id': customerTypeId,
      'name': name,
      'qualification': qualification,
      'phone': phone,
      'place': place,
    });
  }

  Future<void> submit(int dayPlanId) async {
    await _apiClient.submitDayPlan({'day_plan_id': dayPlanId});
  }
}
