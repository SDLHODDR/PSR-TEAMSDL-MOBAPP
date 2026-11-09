import 'dart:convert';
import 'package:flutter/services.dart';
class MockDataService {
 Future<dynamic> read(String file) async => jsonDecode(await rootBundle.loadString('assets/data/$file'));
}
