class NonFieldActivityType {
  const NonFieldActivityType({
    required this.code,
    required this.description,
  });

  final String code;
  final String description;

  factory NonFieldActivityType.fromJson(Map<String, dynamic> json) {
    final code = json['activity_type']?.toString().trim() ?? '';
    final description = json['activity_description']?.toString().trim() ?? '';
    if (code.isEmpty || description.isEmpty) {
      throw const FormatException('Invalid non-field activity option.');
    }
    return NonFieldActivityType(code: code, description: description);
  }
}

class NonFieldActivityRecord {
  const NonFieldActivityRecord({
    required this.id,
    required this.date,
    required this.activityType,
    required this.activity,
    required this.remarks,
    required this.statusCode,
    required this.status,
    required this.canEdit,
  });

  final int id;
  final DateTime date;
  final String activityType;
  final String activity;
  final String remarks;
  final String statusCode;
  final String status;
  final bool canEdit;

  factory NonFieldActivityRecord.fromJson(Map<String, dynamic> json) {
    final id = _int(json['activity_id']);
    final dateText = json['date']?.toString() ?? '';
    final date = DateTime.tryParse(dateText);
    if (id == null || id <= 0 || date == null) {
      throw const FormatException('Invalid non-field activity record.');
    }
    return NonFieldActivityRecord(
      id: id,
      date: date,
      activityType: json['activity_type']?.toString() ?? '',
      activity: json['activity']?.toString() ?? '',
      remarks: json['remarks']?.toString() ?? '',
      statusCode: json['status_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      canEdit: json['can_edit'] == true,
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
