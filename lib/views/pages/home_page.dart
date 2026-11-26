import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/auth_service.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_exception.dart';
import '../../models/dashboard_data.dart';
import '../../models/employee_context.dart';
import '../../providers/employee_provider.dart';
import '../../services/mock_data_service.dart';
import '../../core/theme/app_theme.dart';
import 'placeholder_page.dart';
import 'expenses_page.dart';
import 'reports_page.dart';
import 'tour_plans_page.dart';
import 'field_work_page.dart';
import 'asp_campaign_page.dart';
import 'non_field_activity_page.dart';
import 'non_reporting_options_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MockDataService service = MockDataService();

  late Future<dynamic> data = service.read('dashboard.json');
  DashboardData? dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboardApi();
  }

  Future<void> _loadDashboardApi() async {
    try {
      final result = await AuthService.instance.loadDashboard();
      if (!mounted) return;
      setState(() => dashboard = result);
    } on ApiException {
      // Keep the existing mock dashboard if the API is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('SDL PSR')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    const Text('Unable to load dashboard data.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          data = service.read('dashboard.json');
                          dashboard = null;
                        });
                        _loadDashboardApi();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final d = snapshot.data as Map<String, dynamic>;
        final dashboardEmployee =
            Map<String, dynamic>.from(d['employee'] as Map);
        final employee = context.watch<EmployeeProvider>().employee;
        final employeeName = employee?.empName ??
            _employeeValue(dashboardEmployee, const [
              'name',
              'employee_name',
              'emp_name',
              'full_name',
            ]) ??
            employee?.loginId ??
            'Employee';
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            // Choose layout from available width, not device model.
            final isTablet = width >= 600;
            final isWideTablet = width >= 900;

            final horizontalPadding = isWideTablet ? 28.0 : 16.0;

            final summaryItems = (dashboard?.hasSalesMetrics ?? false)
                ? dashboard!.toSummary()
                : d['summary'] as List;
            final hasAspAccess = employee?.divisions.contains(1) == true;
            final reports = (d['reports'] as List)
                .where(
                    (item) => item['title'] != 'ASP Sanjeevani' || hasAspAccess)
                .toList(growable: false);
            final reportingBlocked =
                dashboard == null || _blocksFieldWorkReporting(dashboard!);

            return Scaffold(
              appBar: AppBar(
                toolbarHeight: isTablet ? 76 : 64,
                leadingWidth: isTablet ? 94 : 72,
                leading: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/sdl_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.spa_outlined,
                        color: AppColors.navy,
                        size: 34,
                      );
                    },
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      employeeName,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _greeting(employeeName),
                      style: TextStyle(
                        fontSize: isTablet ? 21 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Text(
                    //   [designation, division, location]
                    //       .where((value) => value.isNotEmpty)
                    //       .join(' • '),
                    //   style: TextStyle(
                    //     fontSize: isTablet ? 13 : 11,
                    //   ),
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Notifications',
                    iconSize: 27,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlaceholderPage(
                            title: 'Notifications',
                            description: 'Sample notifications. '
                                'Firebase Cloud Messaging '
                                'will be added later.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_none),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout),
                    onPressed: () => _logout(context),
                  ),
                  SizedBox(width: isTablet ? 12 : 4),
                ],
              ),
              body: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (employee != null) ...[
                        _buildEmployeeContextCard(employee, isTablet: isTablet),
                        const SizedBox(height: 22),
                      ],
                      const Text(
                        'TODAY AT A GLANCE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                          letterSpacing: 0.8,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        height: 76,
                        child: LayoutBuilder(
                          builder: (context, summaryConstraints) {
                            if (summaryConstraints.maxWidth < 420) {
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: summaryItems.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) => SizedBox(
                                  width: 144,
                                  child: _buildSummaryCard(summaryItems[index]),
                                ),
                              );
                            }
                            return Row(
                              children: [
                                for (var index = 0;
                                    index < summaryItems.length;
                                    index++) ...[
                                  Expanded(
                                    child:
                                        _buildSummaryCard(summaryItems[index]),
                                  ),
                                  if (index < summaryItems.length - 1)
                                    const SizedBox(width: 8),
                                ],
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 28),
                      if (dashboard == null ||
                          dashboard!.hasReportingBlock) ...[
                        _buildReportingWarning(dashboard),
                        const SizedBox(height: 18),
                      ],

                      // Tablet: activities and reports side by side.
                      // Mobile: show the sections vertically.
                      if (isTablet)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildSection(
                                title: 'My Activities',
                                items: d['activities'],
                                isTablet: true,
                                icon: Icons.spa_outlined,
                                reportingBlocked: reportingBlocked,
                                onItemTap: (item) {
                                  _openPlaceholder(
                                    context,
                                    item,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildSection(
                                title: 'Reports',
                                items: reports,
                                isTablet: true,
                                icon: Icons.bar_chart,
                                onItemTap: (item) {
                                  _openPlaceholder(
                                    context,
                                    item,
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildSection(
                          title: 'My Activities',
                          items: d['activities'],
                          isTablet: false,
                          icon: Icons.spa_outlined,
                          reportingBlocked: reportingBlocked,
                          onItemTap: (item) {
                            _openPlaceholder(context, item);
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Reports',
                          items: reports,
                          isTablet: false,
                          icon: Icons.bar_chart,
                          onItemTap: (item) {
                            _openPlaceholder(context, item);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.instance.logout();
    } finally {
      if (context.mounted) {
        context.read<EmployeeProvider>().clearEmployee();
      }
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  String _greeting(String employeeName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : hour < 21
                ? 'Good Evening'
                : 'Good Night';
    return '$greeting ! $employeeName';
  }

  String? _employeeValue(Map<String, dynamic> employee, List<String> keys) {
    for (final key in keys) {
      final value = employee[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Widget _buildSummaryCard(dynamic item) {
    final title = '${item['title']}';
    final isComparisonCard = title == 'CY Sale' || title == 'LY Sale';
    final badge = '${item['badge'] ?? '-'}';
    final metricLabel = title == 'CY Sale' ? 'YTM Ach' : 'Growth';
    final metricValue =
        badge.replaceFirst(RegExp(r'\s*(YTM Ach|Growth).*$'), '').trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E6F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isComparisonCard)
            Row(
              children: [
                Expanded(
                  child: _summaryMetric(
                    label: metricLabel,
                    value: metricValue.isEmpty ? '-' : metricValue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: const Color(0xFFD0DEEB),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryMetric(
                          label: title,
                          value: '${item['value']}',
                        ),
                      ),
                      const Icon(Icons.insights_outlined,
                          color: AppColors.navy, size: 16),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item['value']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.insights_outlined,
                    color: AppColors.navy, size: 16),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summaryMetric({required String label, required String value}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty) ...[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmployeeContextCard(
    EmployeeContext employee, {
    required bool isTablet,
  }) {
    final details = <String>[
      if (employee.empCode != null) 'Employee Code: ${employee.empCode}',
      if (employee.geoName != null) 'GEO: ${employee.geoName}',
      if (employee.divisionName != null) 'Division: ${employee.divisionName}',
      if (employee.hqLabel != null) 'HQ: ${employee.hqLabel}',
    ];
    final photo = employee.empPic;
    final photoUrl = photo == null
        ? null
        : '${ApiConfig.baseUrl}/${photo.replaceFirst(RegExp(r'^/+'), '')}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 18 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: isTablet ? 30 : 26,
              backgroundColor: const Color(0xFFEAF5E3),
              child: photoUrl == null
                  ? const Icon(Icons.person, color: AppColors.navy, size: 30)
                  : ClipOval(
                      child: Image.network(
                        photoUrl,
                        width: isTablet ? 60 : 52,
                        height: isTablet ? 60 : 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person,
                                color: AppColors.navy, size: 30),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (details.isNotEmpty)
                    Text(details.join('  •  '),
                        style: const TextStyle(color: AppColors.muted)),
                  if (employee.fyLabel != null) ...[
                    const SizedBox(height: 4),
                    Text('Financial year: ${employee.fyLabel}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required dynamic items,
    required bool isTablet,
    required IconData icon,
    bool reportingBlocked = false,
    required ValueChanged<dynamic> onItemTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 21 : 19,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              enabled: !reportingBlocked ||
                  !_isReportingActivity('${item['title']}'),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 8 : 4,
              ),
              minVerticalPadding: 8,
              leading: CircleAvatar(
                radius: isTablet ? 25 : 21,
                backgroundColor: const Color(0xFFEAF5E3),
                child: Icon(
                  icon,
                  color: AppColors.navy,
                  size: isTablet ? 27 : 23,
                ),
              ),
              title: Text(
                '${item['title']}',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              subtitle: Text(
                '${item['subtitle']}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isTablet ? 14 : 12,
                ),
              ),
              trailing:
                  reportingBlocked && _isReportingActivity('${item['title']}')
                      ? const Icon(Icons.lock_outline, color: Colors.black)
                      : const Icon(Icons.chevron_right, color: Colors.black),
              onTap:
                  reportingBlocked && _isReportingActivity('${item['title']}')
                      ? null
                      : () => onItemTap(item),
            ),
          ),
      ],
    );
  }

  Widget _buildReportingWarning(DashboardData? dashboard) {
    if (dashboard == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Reporting status is unavailable. Field Work and Non Field Work are disabled.',
          style: TextStyle(
            color: Colors.red.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final alerts = dashboard.reportingAlerts.isNotEmpty
        ? dashboard.reportingAlerts
        : [
            ...dashboard.nonReportingDays.map(
              (date) => ReportingAlert(date: date, status: 'non_reported'),
            ),
            ...dashboard.openRequests.map(
              (date) => ReportingAlert(date: date, status: 'delayed'),
            ),
          ];
    final allNonReported =
        alerts.every((alert) => alert.statusKey == 'non_reported');
    final allPending = alerts.every((alert) =>
        alert.statusKey == 'pending' ||
        alert.statusKey == 'pending_report' ||
        alert.statusKey == 'pending_reports');
    final allDelayed = alerts.isNotEmpty &&
        alerts.every((alert) => alert.statusKey == 'delayed');
    final allRejected = alerts.isNotEmpty &&
        alerts.every((alert) => alert.statusKey == 'rejected');
    final heading = allNonReported
        ? 'Not Reported'
        : allPending
            ? 'Pending Reports'
            : allDelayed
                ? 'Delayed'
                : allRejected
                    ? 'Rejected'
                    : 'Reporting Status';
    final reportingBackground =
        allDelayed ? Colors.amber.shade50 : Colors.red.shade50;
    final reportingBorder =
        allDelayed ? Colors.amber.shade200 : Colors.red.shade200;
    final headingColor = allDelayed ? Colors.black : Colors.red.shade800;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reportingBackground,
        border: Border.all(color: reportingBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_center,
                size: 18,
                color: headingColor,
              ),
              const SizedBox(width: 6),
              Text(
                heading,
                style: TextStyle(
                  color: headingColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final alert in alerts)
                OutlinedButton(
                  onPressed: () {
                    final date = _parseDashboardDate(alert.date);
                    if (date == null) return;
                    if (alert.statusKey == 'non_reported') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NonReportingOptionsPage(date: date),
                        ),
                      ).then((_) {
                        if (mounted) _loadDashboardApi();
                      });
                      return;
                    }
                    if (alert.statusKey == 'delayed') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FieldWorkPage(reportDate: date),
                        ),
                      ).then((_) {
                        if (mounted) _loadDashboardApi();
                      });
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FieldWorkPage(reportDate: date),
                      ),
                    ).then((_) {
                      if (mounted) _loadDashboardApi();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _reportingColor(alert),
                    side: BorderSide(color: _reportingBorderColor(alert)),
                    backgroundColor: _reportingBackgroundColor(alert),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(alert.date),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _reportingColor(ReportingAlert alert) {
    return alert.statusKey == 'delayed' ? Colors.black : AppColors.navy;
  }

  Color _reportingBorderColor(ReportingAlert alert) {
    return alert.statusKey == 'delayed' ? Colors.black : Colors.red.shade600;
  }

  Color _reportingBackgroundColor(ReportingAlert alert) {
    return alert.statusKey == 'delayed'
        ? Colors.amber.shade300
        : Colors.red.shade50;
  }

  bool _blocksFieldWorkReporting(DashboardData dashboard) {
    if (!dashboard.hasReportingBlock) return false;
    if (dashboard.reportingAlerts.isEmpty) return true;
    return dashboard.reportingAlerts
        .any((alert) => alert.statusKey != 'rejected');
  }

  DateTime? _parseDashboardDate(String value) {
    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) return isoDate;
    final parts = value.trim().split('-');
    if (parts.length != 3) return null;
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final day = int.tryParse(parts[0]);
    final month = months[parts[1].toLowerCase()];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  bool _isReportingActivity(String title) =>
      title == 'Field Work' ||
      title == 'Non Field Work' ||
      title == 'Non-Field Work';

  void _openPlaceholder(
    BuildContext context,
    dynamic item,
  ) {
    if (item['title'] == 'Expense') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpensesPage()),
      );
      return;
    }
    if (item['title'] == 'Monthly Report') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsPage()),
      );
      return;
    }
    if (item['title'] == 'ASP Sanjeevani') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AspCampaignPage()),
      );
      return;
    }
    if (item['title'] == 'Tour Plans') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const TourPlansPage()));
      return;
    }
    if (item['title'] == 'Field Work') {
      _openReportingActivity(context, const FieldWorkPage());
      return;
    }
    if (item['title'] == 'Non Field Work') {
      _openReportingActivity(context, const NonFieldActivityPage());
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceholderPage(
          title: item['title'],
          description: item['description'],
        ),
      ),
    );
  }

  void _openReportingActivity(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      if (mounted) _loadDashboardApi();
    });
  }
}
