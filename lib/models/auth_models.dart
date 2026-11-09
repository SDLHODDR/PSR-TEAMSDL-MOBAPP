class EmployeeProfile {
  const EmployeeProfile({
    required this.loginId,
    required this.employeeId,
    required this.geoId,
    required this.geoLevel,
    this.name,
    this.designation,
    this.division,
    this.location,
  });

  final String? loginId;
  final int? employeeId;
  final int? geoId;
  final int? geoLevel;
  final String? name;
  final String? designation;
  final String? division;
  final String? location;

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      loginId: json['login_id'] as String?,
      employeeId: _asInt(json['emp_id']),
      geoId: _asInt(json['geo_id']),
      geoLevel: _asInt(json['geo_level']),
      name: _firstString(json, const [
        'name',
        'employee_name',
        'emp_name',
        'full_name',
        'display_name',
      ]),
      designation: _firstString(json, const [
        'designation',
        'designation_name',
        'desig',
        'role',
      ]),
      division: _firstString(json, const ['division', 'division_name']),
      location: _firstString(
        json,
        const ['location', 'location_name', 'territory', 'territory_name'],
      ),
    );
  }
}

class AuthSession {
  const AuthSession({
    this.employee,
    required this.accessToken,
    required this.accessExpiresAt,
  });

  final EmployeeProfile? employee;
  final String accessToken;
  final DateTime? accessExpiresAt;

  factory AuthSession.fromData(Map<String, dynamic> data) {
    final expiresAt = _dateTime(data['expires_at']);
    final expiresIn = _seconds(data['expires_in']);
    return AuthSession(
      employee: data['employee'] is Map
          ? EmployeeProfile.fromJson(
              Map<String, dynamic>.from(data['employee'] as Map),
            )
          : null,
      accessToken: data['access_token']?.toString() ?? '',
      accessExpiresAt: expiresAt ??
          (expiresIn == null
              ? null
              : DateTime.now().toUtc().add(Duration(seconds: expiresIn))),
    );
  }
}

DateTime? _dateTime(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}

int? _seconds(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}
