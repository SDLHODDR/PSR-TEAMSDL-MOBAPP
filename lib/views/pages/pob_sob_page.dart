import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/mock_data_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employee_provider.dart';
import 'placeholder_page.dart';

class PobSobPage extends StatefulWidget {
  const PobSobPage({super.key});

  @override
  State<PobSobPage> createState() => _PobSobPageState();
}

class _PobSobPageState extends State<PobSobPage> {
  final MockDataService service = MockDataService();

  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeProvider>().employee;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POB / SOB'),
            if (employee?.empCode != null)
              Text(
                employee!.empCode!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final columns = constraints.maxWidth >= 1000
              ? 3
              : isTablet
                  ? 2
                  : 1;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('POB'),
                        icon: Icon(Icons.shopping_bag_outlined),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('SOB'),
                        icon: Icon(Icons.store_outlined),
                      ),
                    ],
                    selected: {tab},
                    onSelectionChanged: (selection) {
                      setState(() {
                        tab = selection.first;
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tab == 0
                        ? 'Purchase Order Booking'
                        : 'Secondary Order Booking',
                    style: TextStyle(
                      fontSize: isTablet ? 21 : 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<dynamic>(
                  future: service.read('orders.json'),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Unable to load order data.'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final orders = snapshot.data as List<dynamic>;

                    if (orders.isEmpty) {
                      return const Center(
                        child: Text('No orders available.'),
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 24 : 16,
                        0,
                        isTablet ? 24 : 16,
                        24,
                      ),
                      itemCount: orders.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: isTablet ? 175 : 155,
                      ),
                      itemBuilder: (context, index) {
                        final order = orders[index];

                        return Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaceholderPage(
                                    title: order['orderNo'],
                                    description: '${order['customer']} · '
                                        '${order['amount']} · '
                                        '${order['status']}',
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_outlined,
                                        color: AppColors.navy,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${order['orderNo']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.navy,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${order['customer']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order['date']} · ${order['status']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${order['amount']}',
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
