import 'package:flutter/foundation.dart';

import '../models/employee_context.dart';

class EmployeeProvider extends ChangeNotifier {
  EmployeeContext? _employee;

  EmployeeContext? get employee => _employee;
  bool get hasEmployee => _employee != null;

  void setEmployee(EmployeeContext employee) {
    _employee = employee;
    notifyListeners();
  }

  void clearEmployee() {
    if (_employee == null) return;
    _employee = null;
    notifyListeners();
  }
}
