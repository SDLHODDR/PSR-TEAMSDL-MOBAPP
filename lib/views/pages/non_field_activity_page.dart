import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/mock_data_service.dart';

class NonFieldActivityPage extends StatefulWidget {
  const NonFieldActivityPage({super.key});

  @override
  State<NonFieldActivityPage> createState() => _NonFieldActivityPageState();
}

class _NonFieldActivityPageState extends State<NonFieldActivityPage> {
  final MockDataService service = MockDataService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Non Field Activity')),
        body: FutureBuilder<dynamic>(
          future: service.read('non_field_activities.json'),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(child: Text('Unable to load activities.'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final rows = (snapshot.data as List).cast<Map>();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NonFieldActivityFormPage())),
                        icon:
                            const Icon(Icons.add_box, color: AppColors.navy))),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Remarks')),
                        DataColumn(label: Text('Status'))
                      ],
                      rows: [
                        for (var i = 0; i < rows.length; i++)
                          DataRow(cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(Text('${rows[i]['date']}')),
                            DataCell(Text('${rows[i]['activity']}')),
                            DataCell(Text('${rows[i]['status']}'))
                          ])
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class NonFieldActivityFormPage extends StatefulWidget {
  const NonFieldActivityFormPage({super.key});

  @override
  State<NonFieldActivityFormPage> createState() =>
      _NonFieldActivityFormPageState();
}

class _NonFieldActivityFormPageState extends State<NonFieldActivityFormPage> {
  String? activity;
  final remark = TextEditingController();
  static const activities = [
    'Campaign',
    'Exhibition',
    'HO Work',
    'Induction',
    'Meeting',
    'Training',
    'Transit'
  ];

  @override
  void dispose() {
    remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Non Field Activity')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Date',
                style: TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const TextField(
                enabled: false,
                controller: null,
                decoration: InputDecoration(hintText: '03-Nov-2026')),
            const SizedBox(height: 14),
            const Text('Activity',
                style: TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
                value: activity,
                items: [
                  for (final item in activities)
                    DropdownMenuItem(value: item, child: Text(item))
                ],
                onChanged: (value) => setState(() => activity = value)),
            const SizedBox(height: 14),
            const Text('Remark',
                style: TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(controller: remark, maxLines: 5),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Activity saved locally for demo.')));
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Save and Send For Authorisation')),
          ],
        ),
      );
}
