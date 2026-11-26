import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/asp_campaign_data.dart';
import '../../services/asp_campaign_service.dart';

class AspCampaignPage extends StatefulWidget {
  const AspCampaignPage({super.key});

  @override
  State<AspCampaignPage> createState() => _AspCampaignPageState();
}

class _AspCampaignPageState extends State<AspCampaignPage> {
  final _service = AspCampaignService();
  late Future<List<AspCampaignOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _service.loadOrders();
  }

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AspCampaignAddPage(service: _service)),
    );
    if (saved == true && mounted)
      setState(() => _orders = _service.loadOrders());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ASP Sanjeevani')),
        floatingActionButton: FloatingActionButton(
          onPressed: _add,
          tooltip: 'Add ASP campaign order',
          child: const Icon(Icons.add),
        ),
        body: FutureBuilder<List<AspCampaignOrder>>(
          future: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Unable to load ASP campaign orders.'),
              );
            }
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final orders = snapshot.data!;
            if (orders.isEmpty)
              return const Center(child: Text('No data found'));
            return RefreshIndicator(
              onRefresh: () async =>
                  setState(() => _orders = _service.loadOrders()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) =>
                    _AspOrderCard(order: orders[index]),
              ),
            );
          },
        ),
      );
}

class _AspOrderCard extends StatelessWidget {
  const _AspOrderCard({required this.order});
  final AspCampaignOrder order;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEAF5E3),
            foregroundColor: AppColors.navy,
            child: Icon(Icons.campaign_outlined),
          ),
          title: Text(order.customer,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${order.date}\nOrder To: ${order.orderTo}'),
          isThreeLine: true,
          trailing: Text('₹${order.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.navy)),
        ),
      );
}

class _AspCampaignAddPage extends StatefulWidget {
  const _AspCampaignAddPage({required this.service});
  final AspCampaignService service;

  @override
  State<_AspCampaignAddPage> createState() => _AspCampaignAddPageState();
}

class _AspCampaignAddPageState extends State<_AspCampaignAddPage> {
  late Future<AspCampaignOptions> _options;
  int? _customerId;
  int? _orderToId;
  bool _saving = false;
  final Map<int, TextEditingController> _quantities = {};

  @override
  void initState() {
    super.initState();
    _options = widget.service.loadOptions();
  }

  @override
  void dispose() {
    for (final controller in _quantities.values) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ASP Sanjeevani Add')),
        body: FutureBuilder<AspCampaignOptions>(
          future: _options,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(child: Text('${snapshot.error}'));
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final options = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _dropdown<int>(
                    'Customer Name',
                    _customerId,
                    options.customers,
                    (item) => _int(item['id']),
                    (item) => item['name'],
                    (value) => setState(() => _customerId = value)),
                const SizedBox(height: 14),
                _dropdown<int>(
                    'Order To',
                    _orderToId,
                    options.orderTo,
                    (item) => _int(item['id']),
                    (item) => item['name'],
                    (value) => setState(() => _orderToId = value)),
                const SizedBox(height: 14),
                const Text(
                  'Upload Document',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Choose invoice after saving the order'),
                ),
                const SizedBox(height: 14),
                for (final product in options.products) ...[
                  _productRow(product),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : () => _save(options),
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ],
            );
          },
        ),
      );

  Widget _dropdown<T>(
          String label,
          T? value,
          List<Map<String, dynamic>> items,
          T? Function(Map<String, dynamic>) id,
          String? Function(Map<String, dynamic>) name,
          ValueChanged<T?> onChanged) =>
      DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in items)
            DropdownMenuItem(value: id(item), child: Text(name(item) ?? ''))
        ],
        onChanged: onChanged,
      );

  Widget _productRow(AspCampaignProduct product) {
    final controller =
        _quantities.putIfAbsent(product.id, TextEditingController.new);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_productIcon(product.category, product.name),
                    color: AppColors.navy),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(product.name,
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _amountField('Rate', product.rate)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration:
                        const InputDecoration(labelText: 'Qty', isDense: true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: _amountField('Free Qty', _freeQuantity(controller))),
                const SizedBox(width: 6),
                Expanded(
                    child:
                        _amountField('Amount', _amount(product, controller))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountField(String label, double value) => InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true),
        child: Text(value == 0 ? '0' : value.toStringAsFixed(2)),
      );

  double _quantity(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  double _freeQuantity(TextEditingController controller) =>
      _quantity(controller) >= 50 ? _quantity(controller) / 50 * 10 : 0;

  double _amount(
          AspCampaignProduct product, TextEditingController controller) =>
      product.rate * _quantity(controller);

  Future<void> _save(AspCampaignOptions options) async {
    if (_customerId == null || _orderToId == null) {
      _message('Select Customer Name and Order To.');
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final product in options.products) {
      final quantity = _quantity(_quantities[product.id]!);
      if (quantity > 0) {
        if (quantity < 50 || quantity % 50 != 0) {
          _message(
              '${product.name}: quantity must be at least 50 and in multiples of 50.');
          return;
        }
        items.add({'product_id': product.id, 'quantity': quantity});
      }
    }
    if (items.isEmpty) {
      _message('Enter quantity for at least one product.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service
          .save(customerId: _customerId!, orderToId: _orderToId!, items: items);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value');

IconData _productIcon(String category, String product) {
  final text = '$category $product'.toLowerCase();
  if (text.contains('tablet') ||
      text.contains('capsule') ||
      text.contains('cap ')) return Icons.medication_outlined;
  if (text.contains('syrup') ||
      text.contains('liquid') ||
      text.contains('suspension')) return Icons.local_drink_outlined;
  if (text.contains('injection') || text.contains('injectable'))
    return Icons.vaccines_outlined;
  if (text.contains('cream') ||
      text.contains('gel') ||
      text.contains('ointment')) return Icons.healing_outlined;
  if (text.contains('drop')) return Icons.water_drop_outlined;
  return Icons.inventory_2_outlined;
}
