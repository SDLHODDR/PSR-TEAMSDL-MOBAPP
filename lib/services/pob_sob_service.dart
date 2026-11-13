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
}
