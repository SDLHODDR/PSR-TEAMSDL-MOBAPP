class EmployeeContext {
  const EmployeeContext({
    this.loginId,
    this.loginType,
    this.empId,
    this.empCode,
    this.empName,
    this.empEmail,
    this.empPic,
    this.empLevel,
    this.managerId,
    this.divisions = const [],
    this.divisionName,
    this.geoId,
    this.newGeoId,
    this.geoLevel,
    this.geoName,
    this.hqLabel,
    this.fyLabel,
    this.fyFromDate,
    this.fyToDate,
  });

  final String? loginId;
  final String? loginType;
  final int? empId;
  final String? empCode;
  final String? empName;
  final String? empEmail;
  final String? empPic;
  final int? empLevel;
  final int? managerId;
  final List<int> divisions;
  final String? divisionName;
  final int? geoId;
  final int? newGeoId;
  final int? geoLevel;
  final String? geoName;
  final String? hqLabel;
  final String? fyLabel;
  final String? fyFromDate;
  final String? fyToDate;

  factory EmployeeContext.fromJson(Map<String, dynamic> source) {
    final json = _unwrap(source);
    final geography = _map(json['geography'] ?? json['geo']);
    final financialYear = _map(
      json['financial_year'] ?? json['financialYear'] ?? json['fy'],
    );

    return EmployeeContext(
      loginId: _string(json, const ['login_id', 'loginId']),
      loginType: _string(json, const ['login_type', 'loginType']),
      empId: _int(json['emp_id'] ?? json['employee_id'] ?? json['empId']),
      empCode: _string(json, const ['emp_code', 'employee_code', 'empCode']),
      empName: _string(json, const [
        'emp_name',
        'employee_name',
        'full_name',
        'name',
        'display_name',
      ]),
      empEmail: _string(json, const ['emp_email', 'email']),
      empPic:
          _string(json, const ['emp_pic', 'employee_pic', 'photo', 'image']),
      empLevel: _int(json['emp_level'] ?? json['employee_level']),
      managerId: _int(json['manager_id'] ?? json['managerId']),
      divisions: _intList(json['divisions'] ?? json['division_ids']),
      divisionName: _string(json, const ['division_name', 'division']),
      geoId: _int(json['geo_id'] ?? geography['geo_id'] ?? geography['id']),
      newGeoId: _int(json['new_geo_id'] ?? geography['new_geo_id']),
      geoLevel: _int(
          json['geo_level'] ?? geography['geo_level'] ?? geography['level']),
      geoName: _string(json, const ['geo_name', 'geography_name']) ??
          _string(geography, const ['name', 'geo_name']),
      hqLabel: _string(json, const ['hq_label', 'hq_name', 'headquarter']) ??
          _string(geography, const ['hq_label', 'hq_name']),
      fyLabel: _string(json, const ['fy_label', 'financial_year_label']) ??
          _string(financialYear, const ['label', 'fy_label']),
      fyFromDate:
          _string(json, const ['fy_from_date', 'financial_year_from']) ??
              _string(financialYear, const ['from_date', 'from']),
      fyToDate: _string(json, const ['fy_to_date', 'financial_year_to']) ??
          _string(financialYear, const ['to_date', 'to']),
    );
  }

  Map<String, dynamic> toJson() => {
        'login_id': loginId,
        'login_type': loginType,
        'emp_id': empId,
        'emp_code': empCode,
        'emp_name': empName,
        'emp_email': empEmail,
        'emp_pic': empPic,
        'emp_level': empLevel,
        'manager_id': managerId,
        'divisions': divisions,
        'division_name': divisionName,
        'geo_id': geoId,
        'new_geo_id': newGeoId,
        'geo_level': geoLevel,
        'geo_name': geoName,
        'hq_label': hqLabel,
        'fy_label': fyLabel,
        'fy_from_date': fyFromDate,
        'fy_to_date': fyToDate,
      };
}

Map<String, dynamic> _unwrap(Map<String, dynamic> source) {
  final employee = source['employee'];
  return employee is Map
      ? Map<String, dynamic>.from(employee)
      : Map<String, dynamic>.from(source);
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}

List<int> _intList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_int).whereType<int>().toList(growable: false);
}
