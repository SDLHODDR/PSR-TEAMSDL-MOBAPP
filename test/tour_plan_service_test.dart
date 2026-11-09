import 'package:flutter_test/flutter_test.dart';
import 'package:sdl_psr_field_app/core/api/api_client.dart';
import 'package:sdl_psr_field_app/services/tour_plan_service.dart';

void main() {
  test('maps customer count list returned by tour plans API', () async {
    final service = TourPlanService(
      apiClient: _TourPlanApiClient({
        'days': [
          {
            'date': '2026-11-02',
            'route_id': 2,
            'town': 'Ashoka Marg',
            'customer_counts': [
              {
                'customer_type_id': 2,
                'customer_type': 'Retailer / Chemist',
                'count': 6,
              },
              {
                'customer_type_id': 9,
                'customer_type': 'Vaidya / Doctor',
                'count': 10,
              },
              {
                'customer_type_id': 11,
                'customer_type': 'Stockist',
                'count': 2,
              },
            ],
          },
        ],
      }),
    );

    final result = await service.loadMonth(DateTime(2026, 11));
    final day = (result['days'] as List).single as Map<String, dynamic>;

    expect(day['counts'], {
      'Retailer/Chemist': 6,
      'Vaidya/Doctor': 10,
      'Stockist': 2,
    });
  });

  test('loads activity and date-scoped route options from the API', () async {
    final apiClient = _TourPlanApiClient(
      {'days': []},
      activityResponse: {
        'activities': [
          {'activity_type': 'I', 'activity_description': 'Induction'},
        ],
      },
      routeResponse: {
        'routes': [
          {'route_id': 6, 'town': 'Satpur', 'tour_hq': 5827},
        ],
      },
    );
    final service = TourPlanService(apiClient: apiClient);

    final activities = await service.loadActivities();
    final routes = await service.loadRoutes(DateTime(2026, 12, 3));

    expect(activities.single.code, 'I');
    expect(activities.single.description, 'Induction');
    expect(routes.single.routeId, 6);
    expect(routes.single.label, '6 - Satpur');
    expect(routes.single.tourHq, 5827);
    expect(apiClient.requestedRouteDate, '2026-12-03');
  });

  test('saves selected activity and route identifiers without relabeling',
      () async {
    final apiClient = _TourPlanApiClient({'days': []});
    final service = TourPlanService(apiClient: apiClient);

    await service.saveDraft(
      month: DateTime(2026, 12),
      day: {
        'date': 3,
        'activity_type': 'I',
        'activity': 'Induction',
        'route_id': 6,
        'tour_hq': 5827,
        'route': '6 - Satpur',
        'remarks': 'Morning visit',
      },
    );

    expect(apiClient.savedDraft?['day'], {
      'date': '2026-12-03',
      'activity_type': 'I',
      'activity': 'Induction',
      'route_id': 6,
      'tour_hq': 5827,
      'remark': 'Morning visit',
    });
  });
}

class _TourPlanApiClient extends ApiClient {
  _TourPlanApiClient(
    this.response, {
    this.activityResponse = const {'activities': []},
    this.routeResponse = const {'routes': []},
  });

  final Map<String, dynamic> response;
  final Map<String, dynamic> activityResponse;
  final Map<String, dynamic> routeResponse;
  String? requestedRouteDate;
  Map<String, dynamic>? savedDraft;

  @override
  Future<Map<String, dynamic>> tourPlans(String month) async => response;

  @override
  Future<Map<String, dynamic>> tourPlanActivities() async => activityResponse;

  @override
  Future<Map<String, dynamic>> tourPlanRoutes(String date) async {
    requestedRouteDate = date;
    return routeResponse;
  }

  @override
  Future<Map<String, dynamic>> saveTourPlanDraft(
    Map<String, dynamic> body,
  ) async {
    savedDraft = body;
    return {'status': 'saved'};
  }
}
