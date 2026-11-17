import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pob_sob_data.dart';
import '../../services/pob_sob_invoice_pdf.dart';
import '../../services/pob_sob_service.dart';
import 'pob_sob_order_form_page.dart';

class PobSobOrderDetailsPage extends StatefulWidget {
  const PobSobOrderDetailsPage({
    super.key,
    required this.service,
    required this.order,
  });

  final PobSobService service;
  final PobSobOrder order;

  @override
  State<PobSobOrderDetailsPage> createState() => _PobSobOrderDetailsPageState();
}

class _PobSobOrderDetailsPageState extends State<PobSobOrderDetailsPage> {
  late Future<PobSobOrderDetails> _order;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _order = widget.service.loadOrder(widget.order);
  }

  Future<void> _edit(PobSobOrderDetails order) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PobSobOrderFormPage(
          service: widget.service,
          existing: order,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _order = widget.service.loadOrderById(order.orderId, order.source);
      });
    }
  }

  Future<void> _confirm(PobSobOrderDetails order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm order?'),
        content: const Text(
          'This submits the order and prevents further editing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final result = await widget.service.confirm(order.orderId);
      if (mounted) {
        setState(() => _order = Future.value(result));
        _showMessage('Order confirmed.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          error is ApiException
              ? error.message
              : 'Unable to confirm the order.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _downloadPdf(PobSobOrderDetails order) async {
    setState(() => _busy = true);
    try {
      await const PobSobInvoicePdf().download(order);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to create or share the PDF report: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
          title: const Text('Order Details'),
          actions: [
            FutureBuilder<PobSobOrderDetails>(
              future: _order,
              builder: (context, snapshot) {
                final order = snapshot.data;
                if (order == null) return const SizedBox.shrink();
                return PopupMenuButton<String>(
                  enabled: !_busy,
                  onSelected: (action) {
                    switch (action) {
                      case 'pdf':
                        _downloadPdf(order);
                      case 'edit':
                        _edit(order);
                      case 'confirm':
                        _confirm(order);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'pdf',
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf_outlined),
                        title: Text('Download PDF'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (order.canEdit) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit Draft'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'confirm',
                        child: ListTile(
                          leading: Icon(Icons.check_circle_outline),
                          title: Text('Confirm Order'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<PobSobOrderDetails>(
          future: _order,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _DetailsError(
                message: snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Unable to load order details.',
                onRetry: () => setState(
                  () => _order = widget.service.loadOrder(widget.order),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final order = snapshot.data!;
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OrderSummary(order: order),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'PRODUCTS',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Text('${order.items.length} items'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var index = 0; index < order.items.length; index++)
                      _OrderLineCard(
                        item: order.items[index],
                        index: index + 1,
                      ),
                  ],
                ),
                if (_busy)
                  const ColoredBox(
                    color: Color(0x55000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      );
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});

  final PobSobOrderDetails order;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, Color(0xFF176B87)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.orderId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _OrderStatus(
                    status: order.status, processFlag: order.processFlag),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.type} · ${order.dateLabel}',
              style: const TextStyle(color: Colors.white70),
            ),
            const Divider(color: Colors.white38, height: 24),
            _SummaryField(
              label: 'Customer',
              value:
                  '${order.customer}${order.customerCode.isEmpty ? '' : ' (${order.customerCode})'}',
            ),
            _SummaryField(label: 'Order To', value: order.orderTo),
            if (order.employee.isNotEmpty)
              _SummaryField(label: 'Employee', value: order.employee),
            if (order.verifiedAt.isNotEmpty)
              _SummaryField(label: 'Verified', value: order.verifiedAt),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'INR ${order.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _SummaryField extends StatelessWidget {
  const _SummaryField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 82,
              child: Text(label, style: const TextStyle(color: Colors.white70)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _OrderStatus extends StatelessWidget {
  const _OrderStatus({required this.status, required this.processFlag});

  final String status;
  final String processFlag;

  @override
  Widget build(BuildContext context) {
    final confirmed = status == 'A' || processFlag.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:
            confirmed ? AppColors.green : Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        confirmed ? 'Confirmed' : 'Draft',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderLineCard extends StatelessWidget {
  const _OrderLineCard({required this.item, required this.index});

  final PobSobOrderLine item;
  final int index;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.navy.withValues(alpha: 0.08),
                foregroundColor: AppColors.navy,
                child: Text('$index'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.quantity} × ${item.rate.toStringAsFixed(2)}'
                      '${item.freeQuantity > 0 ? ' · Free ${item.freeQuantity}' : ''}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.amount.toStringAsFixed(2),
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

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message, required this.onRetry});

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
