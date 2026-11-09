import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/employee_provider.dart';
import '../../services/mock_data_service.dart';

class PriceListPage extends StatefulWidget {
  const PriceListPage({super.key});
  @override
  State<PriceListPage> createState() => _PriceListPageState();
}

class _PriceListPageState extends State<PriceListPage> {
  final MockDataService service = MockDataService();
  String query = '';

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<EmployeeProvider>().employee;
    return Scaffold(
      appBar: AppBar(
          title:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Price List'),
        if (employee?.divisionName != null)
          Text(employee!.divisionName!,
              style: Theme.of(context).textTheme.labelSmall),
      ])),
      body: FutureBuilder<dynamic>(
        future: service.read('products.json'),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Unable to load products.'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final products = (snapshot.data as List)
              .where((item) => '${item['name']}'.toLowerCase().contains(query))
              .toList();
          final groups = <String, List<dynamic>>{};
          for (final product in products)
            (groups[product['category'].toString()] ??= []).add(product);
          return Column(children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                    onChanged: (value) =>
                        setState(() => query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search products'))),
            Expanded(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                  for (final entry in groups.entries)
                    Card(
                        child: ExpansionTile(
                            title: Text(entry.key),
                            initiallyExpanded: entry.key == groups.keys.first,
                            children: [
                          for (final product in entry.value)
                            ListTile(
                                title: Text('${product['name']}'),
                                subtitle: Text('${product['pack']}'),
                                trailing: Text('${product['mrp']}'),
                                onTap: () => _showProduct(context, product))
                        ])),
                  if (groups.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No products found.'))),
                ])),
          ]);
        },
      ),
    );
  }

  void _showProduct(BuildContext context, dynamic product) =>
      showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${product['name']}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy)),
                        const SizedBox(height: 8),
                        Text('Pack: ${product['pack']}'),
                        Text('Category: ${product['category']}'),
                        Text('Rate: ${product['mrp']}')
                      ]))));
}
