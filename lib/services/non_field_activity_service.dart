import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/non_field_activity_data.dart';

class NonFieldActivityService {
  NonFieldActivityService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NonFieldActivityType>> loadOptions() async {
    final data = await _apiClient.nonFieldActivityOptions();
    final values = data['activities'];
    if (values is! List) {
      throw const ApiException(
          message: 'The activity options response is invalid.');
    }
    return values.map((value) {
      if (value is! Map) {
        throw const ApiException(
            message: 'The activity options response is invalid.');
      }
      try {
        return NonFieldActivityType.fromJson(Map<String, dynamic>.from(value));
      } on FormatException {
        throw const ApiException(
            message: 'The activity options response is invalid.');
      }
    }).toList(growable: false);
  }

  Future<List<NonFieldActivityRecord>> loadActivities() async {
    final data = await _apiClient.nonFieldActivities();
    final values = data['activities'];
    if (values is! List) {
      throw const ApiException(
          message: 'The activity list response is invalid.');
    }
    return values.map((value) {
      if (value is! Map) {
        throw const ApiException(
            message: 'The activity list response is invalid.');
      }
      try {
        return NonFieldActivityRecord.fromJson(
            Map<String, dynamic>.from(value));
      } on FormatException {
        throw const ApiException(
            message: 'The activity list response is invalid.');
      }
    }).toList(growable: false);
  }

  Future<void> save({
    required DateTime date,
    required String activityType,
    required String remarks,
    int? activityId,
  }) async {
    await _apiClient.saveNonFieldActivity({
      'date': _dateValue(date),
      'activity_type': activityType,
      'remarks': remarks,
      if (activityId != null) 'activity_id': activityId,
    });
  }

  String _dateValue(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
