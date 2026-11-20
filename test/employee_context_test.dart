import 'package:flutter_test/flutter_test.dart';

import 'package:sdl_psr_field_app/models/employee_context.dart';

void main() {
  test('maps legacy location and territory fields to dashboard context', () {
    final employee = EmployeeContext.fromJson({
      'employee': {
        'emp_name': 'Pramod Kumar',
        'emp_code': '92345',
        'location': 'Lucknow_1',
        'division': 'SHL_India',
      },
    });

    expect(employee.geoName, 'Lucknow_1');
    expect(employee.divisionName, 'SHL_India');
  });

  test('keeps newer geography fields supported', () {
    final employee = EmployeeContext.fromJson({
      'employee': {
        'geo_name': 'Nashik-2',
        'hq_label': 'MHN02',
      },
    });

    expect(employee.geoName, 'Nashik-2');
    expect(employee.hqLabel, 'MHN02');
  });
}
