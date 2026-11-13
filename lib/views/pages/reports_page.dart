import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/monthly_report_data.dart';
import '../../services/reports_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ReportsService service = ReportsService();
  late DateTime selectedMonth;
  late Future<MonthlyReport> report;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    report = service.loadMonth(selectedMonth);
  }

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth =
          DateTime(selectedMonth.year, selectedMonth.month + offset);
      report = service.loadMonth(selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Monthly Report')),
        body: FutureBuilder<MonthlyReport>(
          future: report,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage(snapshot.error)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(
                          () => report = service.loadMonth(selectedMonth),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final monthlyReport = snapshot.data!;
            return LayoutBuilder(builder: (context, constraints) {
              final calendar = constraints.maxWidth >= 850;
              final columns = calendar ? 7 : 2;
              final firstDayOffset = calendar
                  ? DateTime(selectedMonth.year, selectedMonth.month, 1)
                          .weekday -
                      1
                  : 0;
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      monthlyReport.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: AppColors.navy,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: selectedMonth.year == DateTime.now().year &&
                              selectedMonth.month == DateTime.now().month
                          ? null
                          : () => _changeMonth(1),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (calendar) const _WeekHeader(),
                  if (monthlyReport.days.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No data found.')),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: firstDayOffset + monthlyReport.days.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        mainAxisExtent: calendar ? 145 : 180,
                      ),
                      itemBuilder: (context, index) {
                        final dayIndex = index - firstDayOffset;
                        if (dayIndex < 0) return const SizedBox.shrink();
                        return _ReportDayCard(
                          day: monthlyReport.days[dayIndex],
                          compact: calendar,
                          service: service,
                        );
                      },
                    ),
                ],
              );
            });
          },
        ),
      );
}

String _errorMessage(Object? error) =>
    error is ApiException ? error.message : 'Unable to load monthly report.';

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Mon'),
            Text('Tue'),
            Text('Wed'),
            Text('Thu'),
            Text('Fri'),
            Text('Sat'),
            Text('Sun'),
          ],
        ),
      );
}

class _ReportDayCard extends StatelessWidget {
  const _ReportDayCard({
    required this.day,
    required this.compact,
    required this.service,
  });

  final MonthlyReportDay day;
  final bool compact;
  final ReportsService service;

  @override
  Widget build(BuildContext context) {
    final isRoute = day.kind == 'route';
    final color = isRoute ? AppColors.navy : Colors.redAccent;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isRoute && day.hasDetails
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReportDetailsPage(day: day, service: service),
                  ),
                )
            : null,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: compact ? 29 : 34,
                  height: compact ? 29 : 34,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isRoute
                        ? 'Route ${day.routeId ?? ''}'
                        : _kindLabel(day.kind),
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isRoute && day.hasDetails)
                  const Icon(Icons.chevron_right, size: 16),
              ]),
              const SizedBox(height: 9),
              Text(
                day.summary,
                textAlign: TextAlign.center,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11 : 14,
                ),
              ),
              if (isRoute) ...[
                const SizedBox(height: 7),
                _SaleLine(label: 'POB', amount: day.pob),
                _SaleLine(label: 'SOB', amount: day.sob),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'activity':
        return 'Activity';
      case 'holiday':
        return 'Holiday';
      case 'openRequest':
        return 'Day-plan request';
      default:
        return 'No report';
    }
  }
}

class _SaleLine extends StatelessWidget {
  const _SaleLine({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          Expanded(
            child: Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ]),
      );
}

class ReportDetailsPage extends StatefulWidget {
  const ReportDetailsPage(
      {super.key, required this.day, required this.service});

  final MonthlyReportDay day;
  final ReportsService service;

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  late Future<DailyReport> dailyReport;

  @override
  void initState() {
    super.initState();
    dailyReport = widget.service.loadDay(widget.day.date);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Summary')),
        body: FutureBuilder<DailyReport>(
          future: dailyReport,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage(snapshot.error)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(
                          () => dailyReport =
                              widget.service.loadDay(widget.day.date),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final details = snapshot.data!.details;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navy, Color(0xFF176B87)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.route, color: Colors.white, size: 30),
                      const SizedBox(height: 10),
                      Text(
                        _dateLabel(widget.day.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.day.summary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _ReportMetric(label: 'POB', amount: widget.day.pob),
                          _ReportMetric(label: 'SOB', amount: widget.day.sob),
                          _ReportMetric(
                            label: 'Visits',
                            value: '${details.length}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (details.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No data found.')),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                    child: Text(
                      'CUSTOMER VISITS',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  for (var index = 0; index < details.length; index++) ...[
                    if (details[index].unlisted &&
                        (index == 0 || !details[index - 1].unlisted))
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 12, 4, 8),
                        child: Text(
                          'UNLISTED CUSTOMERS',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    _CustomerVisitCard(
                      detail: details[index],
                      index: details
                              .take(index + 1)
                              .where((item) => item.unlisted == details[index].unlisted)
                              .length,
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      );
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';

String _monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, this.amount, this.value});

  final String label;
  final double? amount;
  final String? value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value ?? '₹${amount!.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

class _CustomerVisitCard extends StatelessWidget {
  const _CustomerVisitCard({required this.detail, required this.index});

  final DailyReportDetail detail;
  final int index;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.navy.withValues(alpha: 0.08),
            foregroundColor: AppColors.navy,
            child: Text('$index',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(
            detail.customer,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: detail.routeId == null
              ? null
              : Text('Route ${detail.routeId}'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('POB',
                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
              Text(
                '₹${detail.pob.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
}
