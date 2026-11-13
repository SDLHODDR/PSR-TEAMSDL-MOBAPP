import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/monthly_report_data.dart';

class ReportsService {
  ReportsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<MonthlyReport> loadMonth(DateTime month) async {
    final data = await _apiClient.monthlyReport(_monthValue(month));
    try {
      return MonthlyReport.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The monthly report response is invalid.');
    }
  }

  Future<DailyReport> loadDay(DateTime date) async {
    final data = await _apiClient.dailyReport(_dateValue(date));
    try {
      return DailyReport.fromJson(data);
    } on FormatException {
      throw const ApiException(message: 'The daily report response is invalid.');
    }
  }

  String _monthValue(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  String _dateValue(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
