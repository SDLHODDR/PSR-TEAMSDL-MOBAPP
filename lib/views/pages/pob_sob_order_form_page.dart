import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pob_sob_data.dart';
import '../../services/pob_sob_service.dart';

class PobSobOrderFormPage extends StatefulWidget {
  const PobSobOrderFormPage({
    super.key,
    required this.service,
    this.existing,
  });

  final PobSobService service;
  final PobSobOrderDetails? existing;

  @override
  State<PobSobOrderFormPage> createState() => _PobSobOrderFormPageState();
}

class _PobSobOrderFormPageState extends State<PobSobOrderFormPage> {
  late Future<PobSobOptions> _options;
  int? _customerId;
  int? _orderToId;
  String? _selectedCategory;
  bool _saving = false;
  final Map<int, String> _quantities = {};
  final Map<int, String> _freeQuantities = {};

  @override
  void initState() {
    super.initState();
    final order = widget.existing;
    _customerId = order?.customerId;
    _orderToId = order?.orderToId;
    _options = widget.service.loadOptions(customerId: _customerId);
    for (final item in order?.items ?? const <PobSobOrderLine>[]) {
      _quantities[item.productId] = _quantityText(item.quantity);
      _freeQuantities[item.productId] = _quantityText(item.freeQuantity);
    }
  }

  void _selectCustomer(int? customerId) {
    setState(() {
      _customerId = customerId;
      _orderToId = null;
      _options = widget.service.loadOptions(customerId: customerId);
    });
  }

  Future<void> _save(PobSobOptions options) async {
    final customerId = _customerId;
    final orderToId = _orderToId;
    if (customerId == null || orderToId == null) {
      _showMessage('Select a customer and an order-to party.');
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final product in options.products) {
      final quantityText = (_quantities[product.id] ?? '').trim();
      final freeQuantityText = (_freeQuantities[product.id] ?? '').trim();
      final quantity = quantityText.isEmpty ? 0 : double.tryParse(quantityText);
      final freeQuantity =
          freeQuantityText.isEmpty ? 0 : double.tryParse(freeQuantityText);
      if (quantity == null ||
          freeQuantity == null ||
          !quantity.isFinite ||
          !freeQuantity.isFinite) {
        _showMessage('Enter valid numbers for quantities.');
        return;
      }
      if (quantity < 0 || freeQuantity < 0) {
        _showMessage('Quantities cannot be negative.');
        return;
      }
      if (quantity == 0 && freeQuantity > 0) {
        _showMessage('Enter a regular quantity for each free quantity.');
        return;
      }
      if (quantity > 0) {
        items.add({
          'product_id': product.id,
          'quantity': quantity,
          'free_quantity': freeQuantity,
        });
      }
    }
    if (items.isEmpty) {
      _showMessage('Enter a quantity for at least one product.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.service.saveDraft(
        orderId: widget.existing?.orderId,
        date: options.date,
        customerId: customerId,
        orderToId: orderToId,
        items: items,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _showMessage(
          error is ApiException ? error.message : 'Unable to save the order.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? 'Add POB / SOB' : 'Edit Order'),
        ),
        body: FutureBuilder<PobSobOptions>(
          future: _options,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _FormError(
                message: snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Unable to load order options.',
                onRetry: () => setState(
                  () => _options = widget.service.loadOptions(
                    customerId: _customerId,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final options = snapshot.data!;
            final categories = options.products
                .map((product) => product.category)
                .where((category) => category.isNotEmpty)
                .toSet()
                .toList(growable: false);
            final selectedCategory = categories.contains(_selectedCategory)
                ? _selectedCategory
                : null;
            final visibleProducts = options.products
                .where((product) =>
                    selectedCategory == null ||
                    product.category == selectedCategory)
                .toList(growable: false);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(_dateLabel(options.date)),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<int>(
                                key: ValueKey('customer-$_customerId'),
                                initialValue: _customerId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Customer',
                                  border: OutlineInputBorder(),
                                ),
                                items: options.customers
                                    .map(
                                      (customer) => DropdownMenuItem(
                                        value: customer.id,
                                        child: Text(
                                          customer.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: _selectCustomer,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<int>(
                                key: ValueKey(
                                    'order-to-$_customerId-$_orderToId'),
                                initialValue: options.orderToOptions.any(
                                        (option) => option.id == _orderToId)
                                    ? _orderToId
                                    : null,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Order To',
                                  border: OutlineInputBorder(),
                                ),
                                items: options.orderToOptions
                                    .map(
                                      (option) => DropdownMenuItem(
                                        value: option.id,
                                        child: Text(
                                          option.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: (value) =>
                                    setState(() => _orderToId = value),
                              ),
                              if (_customerId != null &&
                                  options.orderToOptions.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    'No eligible order-to parties are available for this customer.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (categories.isNotEmpty) ...[
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: selectedCategory == null,
                                onSelected: (_) => setState(
                                  () => _selectedCategory = null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              for (final category in categories) ...[
                                ChoiceChip(
                                  label: Text(category),
                                  selected: selectedCategory == category,
                                  onSelected: (_) => setState(
                                    () => _selectedCategory = category,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      for (final product in visibleProducts)
                        _ProductQuantityCard(
                          product: product,
                          quantity: _quantities[product.id] ?? '',
                          freeQuantity: _freeQuantities[product.id] ?? '',
                          onQuantityChanged: (value) =>
                              _quantities[product.id] = value,
                          onFreeQuantityChanged: (value) =>
                              _freeQuantities[product.id] = value,
                        ),
                      if (visibleProducts.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Center(
                              child: Text('No products are available today.'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(options),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving...' : 'Save Draft'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _ProductQuantityCard extends StatelessWidget {
  const _ProductQuantityCard({
    required this.product,
    required this.quantity,
    required this.freeQuantity,
    required this.onQuantityChanged,
    required this.onFreeQuantityChanged,
  });

  final PobSobProduct product;
  final String quantity;
  final String freeQuantity;
  final ValueChanged<String> onQuantityChanged;
  final ValueChanged<String> onFreeQuantityChanged;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (product.category.isNotEmpty)
                Text(
                  product.category,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Rate: ${product.rate.toStringAsFixed(2)}'),
                  ),
                  SizedBox(
                    width: 82,
                    child: TextFormField(
                      key: ValueKey('qty-${product.id}'),
                      initialValue: quantity,
                      onChanged: onQuantityChanged,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 82,
                    child: TextFormField(
                      key: ValueKey('free-${product.id}'),
                      initialValue: freeQuantity,
                      onChanged: onFreeQuantityChanged,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Free',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _quantityText(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';
