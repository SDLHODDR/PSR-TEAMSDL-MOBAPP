import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/employee_provider.dart';
import '../../services/mock_data_service.dart';
import 'field_work_page.dart';

class RoutePage extends StatelessWidget {
  RoutePage({super.key});
  final MockDataService service = MockDataService();

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeProvider>().employee;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Route'),
          if (employee?.geoName != null)
            Text(employee!.geoName!,
                style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),
      body: FutureBuilder<dynamic>(
        future: service.read('route_cards.json'),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Unable to load routes.'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final routes = (snapshot.data as List).cast<Map>();
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            itemCount: routes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 205,
            ),
            itemBuilder: (context, index) => _RouteCard(route: routes[index]),
          );
        },
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});
  final Map route;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RouteCustomersPage(route: route))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(11)),
                    child: Center(
                        child: Text('${route['routeNo']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)))),
                const SizedBox(width: 9),
                Expanded(
                    child: Text('${route['name']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy))),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.navy),
              ]),
              const SizedBox(height: 10),
              Text('Route No. ${route['routeNo']}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const Spacer(),
              Row(children: [
                Expanded(
                    child: _RouteCount(
                        label: 'Verified',
                        value: '${route['verifiedCustomers']}',
                        color: Colors.green)),
                const SizedBox(width: 6),
                Expanded(
                    child: _RouteCount(
                        label: 'Unverified',
                        value: '${route['unverifiedCustomers']}',
                        color: Colors.orange)),
              ]),
            ]),
          ),
        ),
      );
}

class _RouteCount extends StatelessWidget {
  const _RouteCount(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color, fontSize: 10))
        ]),
      );
}
