import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/api_client.dart';
import '../core/api/api_config.dart';
import '../core/api/api_exception.dart';
import '../services/mock_data_service.dart';

class TourPlanService {
  TourPlanService({
    ApiClient? apiClient,
    MockDataService? mockDataService,
    FlutterSecureStorage? draftStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _mockDataService = mockDataService ?? MockDataService(),
        _draftStorage = draftStorage ?? const FlutterSecureStorage();

  final ApiClient _apiClient;
  final MockDataService _mockDataService;
  final FlutterSecureStorage _draftStorage;

  Future<Map<String, dynamic>> loadMonth(DateTime month) async {
    if (ApiConfig.useMockData) {
      final data = await _mockDataService.read('tour_plans.json');
      return Map<String, dynamic>.from(data as Map);
    }
    final data = await _apiClient.tourPlans(_monthValue(month));
    return {
      ...data,
      'days': _mapApiDays(data['days']),
    };
  }

  Future<List<TourPlanActivity>> loadActivities() async {
    final data = await _apiClient.tourPlanActivities();
    final values = data['activities'];
    if (values is! List) {
      throw const ApiException(
          message: 'The activity options response is invalid.');
    }
    return values
        .map((value) {
          if (value is! Map) {
            throw const ApiException(
                message: 'The activity options response is invalid.');
          }
          final row = Map<String, dynamic>.from(value);
          final code = row['activity_type']?.toString().trim() ?? '';
          final description =
              row['activity_description']?.toString().trim() ?? '';
          if (_isExcludedActivity(description)) return null;
          if (code.isEmpty || description.isEmpty) {
            throw const ApiException(
                message: 'The activity options response is invalid.');
          }
          return TourPlanActivity(code: code, description: description);
        })
        .whereType<TourPlanActivity>()
        .toList(growable: false);
  }

  Future<List<TourPlanRoute>> loadRoutes(DateTime date) async {
    final data = await _apiClient.tourPlanRoutes(_dateValue(date));
    final values = data['routes'];
    if (values is! List) {
      throw const ApiException(
          message: 'The route options response is invalid.');
    }
    return values.map((value) {
      if (value is! Map) {
        throw const ApiException(
            message: 'The route options response is invalid.');
      }
      final row = Map<String, dynamic>.from(value);
      final routeId = _int(row['route_id']);
      final town = row['town']?.toString().trim() ?? '';
      if (routeId == null || town.isEmpty) {
        throw const ApiException(
            message: 'The route options response is invalid.');
      }
      return TourPlanRoute(
        routeId: routeId,
        town: town,
        tourHq: _int(row['tour_hq']),
        customerCounts:
            _customerCounts({'customer_counts': row['customer_counts']}),
      );
    }).toList(growable: false);
  }

  Future<Map<int, Map<String, dynamic>>> loadLocalDrafts({
    required String employeeScope,
    required DateTime month,
  }) async {
    final value = await _draftStorage.read(
      key: _draftKey(employeeScope, month),
    );
    if (value == null || value.isEmpty) return {};
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw const ApiException(
          message: 'The saved tour-plan draft is invalid.');
    }

    final drafts = <int, Map<String, dynamic>>{};
    for (final item in decoded) {
      if (item is! Map) {
        throw const ApiException(
            message: 'The saved tour-plan draft is invalid.');
      }
      final row = Map<String, dynamic>.from(item);
      final date = _int(row['date']);
      if (date == null ||
          date < 1 ||
          date > DateTime(month.year, month.month + 1, 0).day) {
        throw const ApiException(
            message: 'The saved tour-plan draft is invalid.');
      }
      drafts[date] = row;
    }
    return drafts;
  }

  Future<void> saveLocalDrafts({
    required String employeeScope,
    required DateTime month,
    required Map<int, Map<String, dynamic>> drafts,
  }) async {
    final value = jsonEncode(drafts.values.toList(growable: false));
    await _draftStorage.write(
        key: _draftKey(employeeScope, month), value: value);
  }

  Future<void> clearLocalDrafts({
    required String employeeScope,
    required DateTime month,
  }) =>
      _draftStorage.delete(key: _draftKey(employeeScope, month));

  Future<Map<String, dynamic>> saveDraft({
    required DateTime month,
    required Map<String, dynamic> day,
  }) async {
    final dayPayload = _draftPayload(month, day);
    final body = {
      'month': _monthValue(month),
      'day': dayPayload,
    };
    if (ApiConfig.useMockData) return body;
    return _apiClient.saveTourPlanDraft(body);
  }

  Future<Map<String, dynamic>> submit({
    required DateTime month,
    required Iterable<Map<String, dynamic>> days,
  }) async {
    final body = {
      'month': _monthValue(month),
      'days':
          days.map((day) => _draftPayload(month, day)).toList(growable: false),
    };
    if (ApiConfig.useMockData) return {'status': 'submitted'};
    return _apiClient.submitTourPlan(body);
  }

  String _monthValue(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  String _dateValue(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _draftPayload(
    DateTime month,
    Map<String, dynamic> day,
  ) {
    final date = day['date']?.toString() ?? '';
    final dayNumber = int.tryParse(
          date.length >= 10 && date[4] == '-' && date[7] == '-'
              ? date.substring(8, 10)
              : date,
        ) ??
        0;
    final route = day['route']?.toString();
    final routeId = _int(day['route_id']) ??
        (route == null ? null : int.tryParse(route.split(' ').first));
    final activity = day['activity']?.toString() ?? '';
    final tourHq = _int(day['tour_hq']);
    return {
      'date': '${_monthValue(month)}-${dayNumber.toString().padLeft(2, '0')}',
      'activity_type':
          day['activity_type']?.toString() ?? _activityCode(activity),
      'activity': activity,
      'route_id': routeId,
      if (tourHq != null) 'tour_hq': tourHq,
      'remark': day['remarks']?.toString() ?? '',
    };
  }

  List<Map<String, dynamic>> _mapApiDays(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) {
      final row = Map<String, dynamic>.from(item as Map);
      final routeId = _int(row['route_id']);
      final town = row['town']?.toString().trim() ?? '';
      final activity = row['activity_description']?.toString().trim() ??
          row['activity_type']?.toString().trim() ??
          'Tour plan';
      final route = routeId != null;
      return {
        'date': _dayPart(row['date'] ?? row['tour_date']),
        'title': route ? '$routeId${town.isEmpty ? '' : ' - $town'}' : activity,
        'summary':
            route ? '$routeId${town.isEmpty ? '' : ' - $town'}' : activity,
        'kind': route ? 'route' : _activityKind(activity),
        'routeId': routeId,
        'route_id': routeId,
        'tour_hq': _int(row['tour_hq']),
        'activity_type': row['activity_type']?.toString(),
        'activity': row['activity_description']?.toString() ??
            row['activity_type']?.toString(),
        'route': route ? '$routeId${town.isEmpty ? '' : ' - $town'}' : null,
        'counts': _customerCounts(row),
        'remarks': row['remark'] ?? '',
        'workWith': row['joint_employee_id']?.toString() ?? '',
      };
    }).toList(growable: false);
  }

  Map<String, dynamic> _customerCounts(Map<String, dynamic> row) {
    final nestedCounts = row['customer_counts'] ?? row['counts'];
    if (nestedCounts is List) {
      final counts = <String, dynamic>{};
      for (final item in nestedCounts) {
        if (item is! Map) continue;
        final customer = Map<String, dynamic>.from(item);
        final count = _int(customer['count']);
        if (count == null) continue;
        final label = _customerTypeLabel(
          customer['customer_type']?.toString() ?? '',
        );
        if (label.isEmpty) continue;
        counts[label] = (_int(counts[label]) ?? 0) + count;
      }
      return counts;
    }

    final source = nestedCounts is Map ? nestedCounts : row;
    final counts = <String, dynamic>{};
    const categories = {
      'retailer': ['retailer', 'retailer_count', 'retailerCount'],
      'chemist': ['chemist', 'chemist_count', 'chemistCount'],
      'doctor': ['doctor', 'doctor_count', 'doctorCount'],
      'vaidya': ['vaidya', 'vaidya_count', 'vaidyaCount'],
      'stockist': ['stockist', 'stockist_count', 'stockistCount'],
      'institution': ['institution', 'institution_count', 'institutionCount'],
    };
    for (final entry in categories.entries) {
      for (final key in entry.value) {
        if (source[key] != null) {
          counts[entry.key] = source[key];
          break;
        }
      }
    }
    return counts;
  }

  String _customerTypeLabel(String value) {
    final label = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    switch (label.toLowerCase()) {
      case 'retailer / chemist':
        return 'Retailer/Chemist';
      case 'core vaidya / doctor':
        return 'Core Vaidya/Doctor';
      case 'vaidya / doctor':
        return 'Vaidya/Doctor';
      default:
        return label;
    }
  }

  String _dayPart(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 10 && text[4] == '-' && text[7] == '-') {
      return text.substring(8, 10);
    }
    return text.padLeft(2, '0');
  }

  String _activityKind(String activity) {
    final value = activity.toLowerCase();
    if (value.contains('leave')) return 'leave';
    if (value.contains('holiday') || value.contains('sunday')) return 'holiday';
    return 'activity';
  }

  String _activityCode(String activity) {
    switch (activity) {
      case 'Field Work':
        return 'F';
      case 'Leave':
        return 'L';
      case 'Holiday':
        return 'H';
      case 'Training':
        return 'T';
      case 'Exhibition':
        return 'E';
      default:
        return activity.toUpperCase();
    }
  }

  bool _isExcludedActivity(String description) => const {
        'remove',
        'leave',
        'holiday',
        'sunday',
      }.contains(description.trim().toLowerCase());

  String _draftKey(String employeeScope, DateTime month) {
    final scope =
        base64Url.encode(utf8.encode(employeeScope)).replaceAll('=', '');
    return 'sdl_tour_plan_${scope}_${_monthValue(month)}';
  }

  int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class TourPlanActivity {
  const TourPlanActivity({required this.code, required this.description});

  final String code;
  final String description;
}

class TourPlanRoute {
  const TourPlanRoute({
    required this.routeId,
    required this.town,
    this.tourHq,
    this.customerCounts = const {},
  });

  final int routeId;
  final String town;
  final int? tourHq;
  final Map<String, dynamic> customerCounts;

  String get label => '$routeId - $town';
}
