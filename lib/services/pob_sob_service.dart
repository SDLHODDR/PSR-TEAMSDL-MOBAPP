import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/pob_sob_data.dart';

class PobSobService {
  PobSobService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PobSobMonth> loadMonth(DateTime month) async {
    final value = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final data = await _apiClient.pobSobOrders(value);
    try {
      return PobSobMonth.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The POB/SOB response is invalid.');
    }
  }

  Future<PobSobOptions> loadOptions({int? customerId}) async {
    final data = await _apiClient.pobSobOptions(customerId: customerId);
    try {
      return PobSobOptions.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The POB/SOB options are invalid.');
    }
  }

  Future<PobSobOrderDetails> loadOrder(PobSobOrder order) =>
      loadOrderById(order.orderId, order.source);

  Future<PobSobOrderDetails> loadOrderById(int orderId, String source) async {
    final data = await _apiClient.pobSobOrder(orderId, source);
    try {
      return PobSobOrderDetails.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The POB/SOB order is invalid.');
    }
  }

  Future<PobSobOrderDetails> saveDraft({
    int? orderId,
    required DateTime date,
    required int customerId,
    required int orderToId,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await _apiClient.savePobSobOrder({
      if (orderId != null) 'order_id': orderId,
      'date': _dateString(date),
      'customer_id': customerId,
      'order_to_id': orderToId,
      'items': items,
    });
    try {
      return PobSobOrderDetails.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The saved POB/SOB order is invalid.');
    }
  }

  Future<PobSobOrderDetails> confirm(int orderId) async {
    final data = await _apiClient.confirmPobSobOrder(orderId);
    try {
      return PobSobOrderDetails.fromJson(data);
    } on FormatException {
      throw const ApiException(
          message: 'The confirmed POB/SOB order is invalid.');
    }
  }

  String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
