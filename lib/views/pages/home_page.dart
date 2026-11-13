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
import 'non_field_activity_page.dart';
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

            final summaryColumns = isWideTablet
                ? 4
                : isTablet
                    ? 3
                    : 2;

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
                      _greeting(),
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
                        _buildEmployeeContextCard(
                          employee,
                          isTablet: isTablet,
                        ),
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

                      // Responsive summary cards.
                      GridView.count(
                        crossAxisCount: summaryColumns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        // The API metrics include an additional achievement /
                        // growth line, so give the cards enough vertical room
                        // on tablets and phones.
                        childAspectRatio: isTablet ? 1.4 : 1.15,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final item
                              in (dashboard?.hasSalesMetrics ?? false)
                                  ? dashboard!.toSummary()
                                  : d['summary'])
                            _buildSummaryCard(
                              item,
                              isTablet: isTablet,
                            ),
                        ],
                      ),

                      const SizedBox(height: 28),

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
                                items: d['reports'],
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
                          onItemTap: (item) {
                            _openPlaceholder(context, item);
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          title: 'Reports',
                          items: d['reports'],
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    if (hour < 21) return 'Good evening!';
    return 'Good night!';
  }

  String? _employeeValue(Map<String, dynamic> employee, List<String> keys) {
    for (final key in keys) {
      final value = employee[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  Widget _buildSummaryCard(
    dynamic item, {
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            color: AppColors.navy,
            size: isTablet ? 28 : 24,
          ),
          const SizedBox(height: 6),
          Text(
            '${item['value']}',
            style: TextStyle(
              fontSize: isTablet ? 23 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (item['badge'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${item['badge']}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 3),
          Text(
            '${item['title']}',
            style: TextStyle(fontSize: isTablet ? 14 : 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeContextCard(
    EmployeeContext employee, {
    required bool isTablet,
  }) {
    // final details = <String>[
    //   if (employee.empCode != null) 'Employee Code: ${employee.empCode}',
    //   // if (employee.empId != null) 'Employee ID: ${employee.empId}',
    //   //if (employee.empLevel != null) 'Level: ${employee.empLevel}',
    //   //if (employee.loginType != null) 'Type: ${employee.loginType}',
    //   if (employee.geoId != null) 'Geography: ${employee.geoId}',
    //   if (employee.divisions.isNotEmpty)
    //     'Divisions: ${employee.divisions.join(', ')}',
    // ];
    final details = <String>[
      if (employee.empCode != null) 'Employee Code: ${employee.empCode}',
      if (employee.geoName != null) 'GEO: ${employee.geoName}',
      if (employee.divisionName != null) 'Division: ${employee.divisionName}',
      if (employee.hqLabel != null) 'HQ: ${employee.hqLabel}',
    ];
    final email = employee.empEmail;
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
                            const Icon(
                          Icons.person,
                          color: AppColors.navy,
                          size: 30,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.empName ?? employee.loginId ?? 'Employee',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: isTablet ? 20 : 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 3),
                    Text(email, overflow: TextOverflow.ellipsis),
                  ],
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      details.join('  •  '),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
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
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              subtitle: Text(
                '${item['subtitle']}',
                style: TextStyle(fontSize: isTablet ? 14 : 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onItemTap(item),
            ),
          ),
      ],
    );
  }

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
    if (item['title'] == 'Tour Plans') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => TourPlansPage()));
      return;
    }
    if (item['title'] == 'Field Work') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => FieldWorkPage()));
      return;
    }
    if (item['title'] == 'Non Field Work') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NonFieldActivityPage()));
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
}
