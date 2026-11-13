import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/expenses_data.dart';

class ExpensesService {
  ExpensesService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ExpensesData> load() async {
    final data = await _apiClient.expenses();
    try {
      return ExpensesData.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The expenses response is invalid.');
    }
  }
}
