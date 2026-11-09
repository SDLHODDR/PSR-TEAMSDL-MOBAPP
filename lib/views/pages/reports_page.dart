import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/mock_data_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final MockDataService service = MockDataService();
  int monthIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Monthly Report')),
        body: FutureBuilder<dynamic>(
          future: service.read('monthly_reports.json'),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(
                  child: Text('Unable to load monthly report.'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final months = (snapshot.data['months'] as List).cast<Map>();
            final days = (months[monthIndex]['days'] as List).cast<Map>();
            return LayoutBuilder(builder: (context, constraints) {
              final calendar = constraints.maxWidth >= 850;
              final columns = calendar ? 7 : 2;
              return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                          onPressed: monthIndex < months.length - 1
                              ? () => setState(() => monthIndex++)
                              : null,
                          icon: const Icon(Icons.arrow_back)),
                      Text('${months[monthIndex]['label']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: AppColors.navy)),
                      IconButton(
                          onPressed: monthIndex > 0
                              ? () => setState(() => monthIndex--)
                              : null,
                          icon: const Icon(Icons.arrow_forward))
                    ]),
                    const SizedBox(height: 8),
                    if (calendar) const _WeekHeader(),
                    GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: days.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: calendar ? 145 : 180),
                        itemBuilder: (context, index) => _ReportDayCard(
                            day: days[index], compact: calendar)),
                  ]);
            });
          },
        ),
      );
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Text('Mon'),
        Text('Tue'),
        Text('Wed'),
        Text('Thu'),
        Text('Fri'),
        Text('Sat'),
        Text('Sun')
      ]));
}

class _ReportDayCard extends StatelessWidget {
  const _ReportDayCard({required this.day, required this.compact});
  final Map day;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isRoute = day['kind'] == 'route';
    final hasDetails = (day['details'] as List).isNotEmpty;
    final color = isRoute ? AppColors.navy : Colors.redAccent;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasDetails
            ? () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ReportDetailsPage(day: day)))
            : null,
        child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: compact ? 29 : 34,
                    height: compact ? 29 : 34,
                    decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(8)),
                    child: Center(
                        child: Text('${day['day']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(
                        isRoute
                            ? 'Route ${day['routeId']}'
                            : '${day['kind'] == 'holiday' ? 'Holiday' : 'No report'}',
                        style: TextStyle(
                            color: color,
                            fontSize: compact ? 10 : 12,
                            fontWeight: FontWeight.bold))),
                if (hasDetails) const Icon(Icons.chevron_right, size: 16)
              ]),
              const SizedBox(height: 9),
              Text('${day['summary']}',
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 11 : 14)),
              if (isRoute) ...[
                const SizedBox(height: 7),
                _SaleLine(label: 'POB', amount: day['pob']),
                _SaleLine(label: 'SOB', amount: day['sob']),
              ],
            ])),
      ),
    );
  }
}

class _SaleLine extends StatelessWidget {
  const _SaleLine({required this.label, required this.amount});
  final String label;
  final dynamic amount;
  @override
  Widget build(BuildContext context) {
    final value = amount is num ? amount : 0;
    return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Text('$label: ',
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          Expanded(
              child: Text('₹${value.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)))
        ]));
  }
}

class ReportDetailsPage extends StatelessWidget {
  const ReportDetailsPage({super.key, required this.day});
  final Map day;

  @override
  Widget build(BuildContext context) {
    final details = (day['details'] as List).cast<Map>();
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text("Day ${day['day']} · ${day['summary']}",
            style: const TextStyle(
                color: AppColors.navy, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('POB'))
                ], rows: [
                  for (var i = 0; i < details.length; i++)
                    DataRow(cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(Text('${details[i]['customer']}')),
                      DataCell(Text(
                          '₹${(details[i]['pob'] as num).toStringAsFixed(2)}'))
                    ])
                ]))),
      ]),
    );
  }
}
