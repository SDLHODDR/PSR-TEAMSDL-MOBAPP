import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/non_field_activity_service.dart';

void main() {
  test('loads activity options and employee activity records from the API',
      () async {
    final apiClient = _NonFieldActivityApiClient(
      optionsResponse: {
        'activities': [
          {'activity_type': 'M', 'activity_description': 'Meeting'},
          {'activity_type': 'T', 'activity_description': 'Training'},
        ],
      },
      activitiesResponse: {
        'activities': [
          {
            'activity_id': 74,
            'date': '2026-11-08',
            'activity_type': 'M',
            'activity': 'Meeting',
            'remarks': 'Regional review',
            'status_code': 'X',
            'status': 'Rejected',
            'can_edit': true,
          },
        ],
      },
    );
    final service = NonFieldActivityService(apiClient: apiClient);

    final options = await service.loadOptions();
    final activities = await service.loadActivities();

    expect(options.map((item) => item.description), ['Meeting', 'Training']);
    expect(activities.single.id, 74);
    expect(activities.single.date, DateTime(2026, 11, 8));
    expect(activities.single.canEdit, isTrue);
  });

  test('sends a new activity or a rejected record for resubmission', () async {
    final apiClient = _NonFieldActivityApiClient();
    final service = NonFieldActivityService(apiClient: apiClient);

    await service.save(
      date: DateTime(2026, 11, 9),
      activityType: 'M',
      remarks: 'Monthly review',
      activityId: 74,
    );

    expect(apiClient.savedBody, {
      'date': '2026-11-09',
      'activity_type': 'M',
      'remarks': 'Monthly review',
      'activity_id': 74,
    });
  });
}

class _NonFieldActivityApiClient extends ApiClient {
  _NonFieldActivityApiClient({
    this.optionsResponse = const {'activities': []},
    this.activitiesResponse = const {'activities': []},
  });

  final Map<String, dynamic> optionsResponse;
  final Map<String, dynamic> activitiesResponse;
  Map<String, dynamic>? savedBody;

  @override
  Future<Map<String, dynamic>> nonFieldActivityOptions() async =>
      optionsResponse;

  @override
  Future<Map<String, dynamic>> nonFieldActivities() async => activitiesResponse;

  @override
  Future<Map<String, dynamic>> saveNonFieldActivity(
    Map<String, dynamic> body,
  ) async {
    savedBody = body;
    return {'activity_id': 74};
  }
}
