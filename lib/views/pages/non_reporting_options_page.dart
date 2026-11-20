import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/non_field_activity_service.dart';
import 'non_field_activity_page.dart';
import 'delayed_reporting_page.dart';

class NonReportingOptionsPage extends StatelessWidget {
  const NonReportingOptionsPage({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Non-Reporting')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Option(
              title: 'Leave',
              icon: Icons.payments_outlined,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Leave requests are handled in the Leave portal.'),
                ),
              ),
            ),
            _Option(
              title: 'Non-Field Work',
              icon: Icons.groups_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NonFieldActivityFormPage(
                    service: NonFieldActivityService(),
                    initialDate: date,
                  ),
                ),
              ),
            ),
            _Option(
              title: 'Delayed Reporting',
              icon: Icons.business_center_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DelayedReportingPage(date: date),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Option extends StatelessWidget {
  const _Option({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEAF5E3),
            foregroundColor: AppColors.navy,
            child: Icon(icon),
          ),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
