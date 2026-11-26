import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

class DelayedReportingPage extends StatefulWidget {
  const DelayedReportingPage({super.key, required this.date});

  final DateTime date;

  @override
  State<DelayedReportingPage> createState() => _DelayedReportingPageState();
}

class _DelayedReportingPageState extends State<DelayedReportingPage> {
  final _remarks = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final remarks = _remarks.text.trim();
    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a remark.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final response = await ApiClient().saveDayPlanOpenRequest({
        'date': _dateValue(widget.date),
        'remarks': remarks,
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delayed Reporting Request Generated'),
          content: Text(_requestMessage(response)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Delayed Reporting Request')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(_dateLabel(widget.date)),
            ),
            const SizedBox(height: 20),
            const Text('Remark', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _remarks,
              enabled: !_saving,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Enter a remark'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving
                  ? 'Submitting...'
                  : 'Save and Send For Authorisation'),
            ),
          ],
        ),
      );

  String _requestMessage(Map<String, dynamic> response) {
    final requestId = _responseValue(response, const [
      'request_id',
      'requestId',
      'open_request_id',
      'openRequestId',
    ]);
    final taskId = _responseValue(response, const [
      'task_id',
      'taskId',
      'authorization_task_id',
      'authorizationTaskId',
    ]);
    final lines = <String>['Your delayed reporting request was submitted.'];
    if (requestId != null) lines.add('Request ID: $requestId');
    if (taskId != null) lines.add('Task ID: $taskId');
    if (requestId == null && taskId == null) {
      lines.add('Request and task details are available in the backend.');
    }
    return lines.join('\n');
  }

  String? _responseValue(
    Map<String, dynamic> response,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = response[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    for (final key in const ['request', 'task', 'open_request', 'details']) {
      final nested = response[key];
      if (nested is Map) {
        final value = _responseValue(
          Map<String, dynamic>.from(nested),
          keys,
        );
        if (value != null) return value;
      }
    }
    return null;
  }

  String _dateValue(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${_month(value.month)}-${value.year}';

  String _month(int value) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][value];
}
