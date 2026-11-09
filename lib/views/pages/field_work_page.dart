import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/mock_data_service.dart';

/// Field Work entry point: the Day Plan form.
class FieldWorkPage extends StatefulWidget {
  const FieldWorkPage({super.key});

  @override
  State<FieldWorkPage> createState() => _FieldWorkPageState();
}

class _FieldWorkPageState extends State<FieldWorkPage> {
  String town = 'Nasik (5827)';
  final remarks = TextEditingController();
  static const towns = [
    'Nasik (5827)',
    'Ashoka Marg (5828)',
    'Indira Nagar (5829)',
    'Satpur (5830)'
  ];

  @override
  void dispose() {
    remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dayplan')),
        body: LayoutBuilder(builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth >= 900 ? 760.0 : double.infinity;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FormCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Start Town'),
                                DropdownButtonFormField<String>(
                                    value: town,
                                    items: [
                                      for (final item in towns)
                                        DropdownMenuItem(
                                            value: item, child: Text(item))
                                    ],
                                    onChanged: (value) =>
                                        setState(() => town = value ?? town)),
                              ]),
                        ),
                        const SizedBox(height: 14),
                        _FormCard(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _FieldLabel('Remarks'),
                                TextField(controller: remarks, maxLines: 6),
                              ]),
                        ),
                        const SizedBox(height: 18),
                        Row(children: [
                          Expanded(
                              child: FilledButton(
                                  onPressed: _save,
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Save'))),
                          const SizedBox(width: 14),
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Cancel'))),
                        ]),
                      ]),
                ),
              ),
            ],
          );
        }),
      );

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Day plan saved locally for demo.')));
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Card(child: Padding(padding: const EdgeInsets.all(12), child: child));
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.navy, fontWeight: FontWeight.bold)));
}

/// Customer screen reached from a route or a route day in Tour Plans.
class RouteCustomersPage extends StatelessWidget {
  RouteCustomersPage({super.key, this.route});
  final Map? route;
  final MockDataService service = MockDataService();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title:
                Text(route == null ? 'Route Customers' : '${route!['name']}')),
        body: FutureBuilder<dynamic>(
          future: service.read('field_work.json'),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(child: Text('Unable to load customers.'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final data = snapshot.data as Map;
            final customers = (data['customers'] as List).cast<Map>();
            return LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1000
                  ? 3
                  : constraints.maxWidth >= 600
                      ? 2
                      : 1;
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text(
                    route == null
                        ? '${data['route']}'
                        : 'Route No. ${route!['routeNo']} · ${route!['name']}',
                    style: const TextStyle(
                        color: AppColors.navy, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${customers.length} customers',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: customers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: columns == 1 ? 132 : 154),
                    itemBuilder: (context, index) =>
                        _CustomerCard(customer: customers[index])),
              ]);
            });
          },
        ),
      );
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});
  final Map customer;
  @override
  Widget build(BuildContext context) => Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CustomerFormPage(customer: customer))),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Stack(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFEAF5E3),
                      child: Icon(_profileIcon('${customer['type']}'),
                          color: AppColors.navy)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${customer['name']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.navy)),
                                const SizedBox(height: 6),
                                Text('${customer['type']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 12)),
                                const SizedBox(height: 8),
                                Text(
                                    customer['verified'] == true
                                        ? 'Verified customer'
                                        : 'Customer profile',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.muted))
                              ])))
                ]),
                Positioned(
                    top: 0, right: 0, child: _StatusBadge(customer: customer))
              ]))));
}

IconData _profileIcon(String type) {
  final value = type.toLowerCase();
  if (value.contains('stockist')) return Icons.inventory_2_outlined;
  if (value.contains('retailer') || value.contains('chemist'))
    return Icons.storefront_outlined;
  if (value.contains('doctor') || value.contains('vaidya'))
    return Icons.medical_services_outlined;
  return Icons.person_outline;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.customer});
  final Map customer;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: customer['verified'] == true
              ? Colors.green.shade100
              : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(6)),
      child: Text(customer['verified'] == true ? 'Verified' : 'Not Verified',
          style: TextStyle(
              fontSize: 10,
              color: customer['verified'] == true
                  ? Colors.green.shade800
                  : Colors.orange.shade900,
              fontWeight: FontWeight.w600)));
}

class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key, required this.customer});
  final Map customer;
  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final fields = <String, TextEditingController>{};
  bool consent = false;
  bool get readOnly => widget.customer['verified'] == true;

  @override
  void initState() {
    super.initState();
    for (final item in [
      'State',
      'City',
      'Landmark',
      'Pincode',
      'Location Link',
      'Owner\'s Name',
      'Primary Phone',
      'Additional Phone',
      'Email ID',
      'Business Email ID'
    ]) {
      fields[item] = TextEditingController(
          text: item == 'State'
              ? 'Maharashtra'
              : item == 'City'
                  ? 'Nasik'
                  : item == 'Pincode'
                      ? '422009'
                      : item == "Owner's Name"
                          ? 'Mr. Roshan Choriya'
                          : item == 'Primary Phone'
                              ? '9922712087'
                              : item.contains('Email')
                                  ? 'roshanchoriya@gmail.com'
                                  : '');
    }
  }

  @override
  void dispose() {
    for (final controller in fields.values) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('${widget.customer['name']}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (readOnly)
          Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Verified customer profile. Fields are read-only.'))
              ])),
        for (final entry in fields.entries)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                  readOnly: readOnly,
                  controller: entry.value,
                  decoration: InputDecoration(labelText: entry.key))),
        if (!readOnly) ...[
          CheckboxListTile(
              value: consent,
              onChanged: (value) => setState(() => consent = value ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                  'I confirm that the information provided is accurate.')),
          Row(children: [
            Expanded(
                child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Customer saved locally for demo.')));
                      Navigator.pop(context);
                    },
                    child: const Text('Save'))),
            const SizedBox(width: 10),
            Expanded(
                child: OutlinedButton(
                    onPressed: () {}, child: const Text('Send OTP'))),
            const SizedBox(width: 10),
            Expanded(
                child: OutlinedButton(
                    onPressed: () {}, child: const Text('Verify OTP')))
          ])
        ] else
          Text('Last Verified: ${widget.customer['verifiedOn']}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted))
      ]));
}
