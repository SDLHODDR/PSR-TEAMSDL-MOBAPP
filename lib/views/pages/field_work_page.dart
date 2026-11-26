import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../services/day_plan_service.dart';

class FieldWorkPage extends StatefulWidget {
  const FieldWorkPage({super.key, this.reportDate});

  final DateTime? reportDate;

  @override
  State<FieldWorkPage> createState() => _FieldWorkPageState();
}

class _FieldWorkPageState extends State<FieldWorkPage> {
  final DayPlanService _service = DayPlanService();
  final TextEditingController _remarks = TextEditingController();
  late final String _date = _dateValue(widget.reportDate ?? DateTime.now());
  late Future<Map<String, dynamic>> _loadFuture;
  int? _townId;
  bool _saving = false;
  bool _townRequired = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await _service.load(_date);
    _lastRoutes = _list(data['routes']);
    final plan = _map(data['day_plan']);
    final options = _map(data['options']) ?? const <String, dynamic>{};
    final towns = _list(options['start_towns']);
    _townRequired = towns.isNotEmpty;
    final storedTown = _int(plan?['start_town_id']);
    final baseTown = _int(options['base_town_id']);
    final availableIds = towns.map((town) => _int(town['town_id'])).toSet();
    _townId = availableIds.contains(storedTown)
        ? storedTown
        : availableIds.contains(baseTown)
            ? baseTown
            : null;
    _remarks.text = plan?['remarks']?.toString() ?? '';
    return data;
  }

  void _reload() {
    setState(() => _loadFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field Work')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(
              message: _errorMessage(snapshot.error),
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final plan = _map(data['day_plan']);
          final options = _map(data['options']) ?? const <String, dynamic>{};
          final canEdit = plan == null || plan['can_edit'] == true;
          final routes = _list(data['routes']);
          final plannedRouteId = _int(data['planned_route_id']);
          final dayPlanId = _int(plan?['day_plan_id']);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Day Plan · ${_dateLabel(widget.reportDate ?? DateTime.now())}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (plan != null)
                _PlanStatusCard(
                  status: plan['status']?.toString() ?? '',
                  canEdit: canEdit,
                ),
              _HeaderForm(
                options: options,
                townId: _townId,
                remarks: _remarks,
                enabled: canEdit && !_saving,
                onTownChanged: (value) => setState(() => _townId = value),
                onSave: canEdit ? _saveDraft : null,
                saving: _saving,
              ),
              if (plan != null && dayPlanId != null) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final crossAxisCount = availableWidth >= 900 ? 4 : 2;
                    final showSubtitle = availableWidth >= 600;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: showSubtitle ? 112.0 : 72.0,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ActionTile(
                          title: 'Listed Customer',
                          subtitle: 'Add customers from the planned route',
                          icon: Icons.people_alt_outlined,
                          enabled: canEdit && plannedRouteId != null,
                          showSubtitle: showSubtitle,
                          onTap: () => _openRouteCustomers(
                            dayPlanId,
                            plannedRouteId!,
                            'Listed Customer',
                          ),
                        ),
                        _ActionTile(
                          title: 'Other Route',
                          subtitle: 'Add customers from another route',
                          icon: Icons.alt_route,
                          enabled: canEdit,
                          showSubtitle: showSubtitle,
                          onTap: () => _chooseOtherRoute(
                            dayPlanId,
                            routes,
                            plannedRouteId,
                            options,
                            _list(data['listed_customers']),
                          ),
                        ),
                        _ActionTile(
                          title: 'Unlisted Customer',
                          subtitle: 'Add a customer not on a listed route',
                          icon: Icons.person_add_alt_1,
                          enabled: canEdit,
                          showSubtitle: showSubtitle,
                          onTap: () async {
                            final saved = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _UnlistedCustomerPage(
                                  service: _service,
                                  dayPlanId: dayPlanId,
                                  options: options,
                                  customers: _list(data['unlisted_customers']),
                                  canEdit: canEdit,
                                ),
                              ),
                            );
                            if (saved == true) _reload();
                          },
                        ),
                        _ActionTile(
                          title: 'Summary & Submit',
                          subtitle: 'Review customers and submit the day plan',
                          icon: Icons.fact_check_outlined,
                          enabled: true,
                          showSubtitle: showSubtitle,
                          onTap: () async {
                            final submitted = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _DayPlanSummaryPage(
                                  service: _service,
                                  plan: plan,
                                  plannedRouteId: plannedRouteId,
                                  listedCustomers:
                                      _list(data['listed_customers']),
                                  unlistedCustomers:
                                      _list(data['unlisted_customers']),
                                  onSubmit: () => _submit(dayPlanId),
                                ),
                              ),
                            );
                            if (submitted == true) _reload();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_remarks.text.trim().isEmpty) {
      _showMessage('Remarks are required.');
      return;
    }
    if (_townRequired && _townId == null) {
      _showMessage('Select a start town.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.saveDraft(
        date: _date,
        remarks: _remarks.text.trim(),
        startTownId: _townId,
      );
      if (mounted) {
        _showMessage('Day plan saved.');
        _reload();
      }
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit(int dayPlanId) async {
    await _service.submit(dayPlanId);
  }

  Future<void> _openRouteCustomers(
    int dayPlanId,
    int routeId,
    String title,
  ) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ListedCustomerPage(
          service: _service,
          dayPlanId: dayPlanId,
          routeId: routeId,
          route: _routeWithId(_lastRoutes, routeId),
          title: title,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  List<Map<String, dynamic>> _lastRoutes = const [];

  Future<void> _chooseOtherRoute(
    int dayPlanId,
    List<Map<String, dynamic>> routes,
    int? plannedRouteId,
    Map<String, dynamic> options,
    List<Map<String, dynamic>> listedCustomers,
  ) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _OtherRouteCustomersPage(
          service: _service,
          dayPlanId: dayPlanId,
          plannedRouteId: plannedRouteId,
          customers: listedCustomers,
          routes: routes,
          workWith: _list(
            options['work_with'] ??
                options['work_with_employees'] ??
                options['employees'],
          ),
        ),
      ),
    );
    if (saved == true) _reload();
  }

  Map<String, dynamic> _routeWithId(
    List<Map<String, dynamic>> routes,
    int routeId,
  ) =>
      routes.firstWhere(
        (route) => _int(route['route_id']) == routeId,
        orElse: () => {'route_id': routeId, 'town': ''},
      );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderForm extends StatelessWidget {
  const _HeaderForm({
    required this.options,
    required this.townId,
    required this.remarks,
    required this.enabled,
    required this.onTownChanged,
    required this.onSave,
    required this.saving,
  });

  final Map<String, dynamic> options;
  final int? townId;
  final TextEditingController remarks;
  final bool enabled;
  final ValueChanged<int?> onTownChanged;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final towns = _list(options['start_towns']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (towns.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                initialValue: townId,
                decoration: const InputDecoration(labelText: 'Start Town'),
                items: [
                  for (final town in towns)
                    DropdownMenuItem<int>(
                      value: _int(town['town_id']),
                      child: Text(town['name']?.toString() ?? ''),
                    ),
                ],
                onChanged: enabled ? onTownChanged : null,
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: remarks,
              enabled: enabled,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Remarks'),
            ),
            if (onSave != null) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: Text(saving ? 'Saving…' : 'Save'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.status, required this.canEdit});

  final String status;
  final bool canEdit;

  @override
  Widget build(BuildContext context) => Card(
        color: canEdit
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          leading: Icon(canEdit ? Icons.edit_note : Icons.lock_outline),
          title: Text(canEdit ? 'Draft' : 'Submitted or confirmed'),
          subtitle: Text('Status: $status'),
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.showSubtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final bool showSubtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          enabled: enabled,
          leading: Icon(icon),
          title: Text(title),
          subtitle: showSubtitle ? Text(subtitle) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: enabled ? onTap : null,
        ),
      );
}

class _ListedCustomerPage extends StatefulWidget {
  const _ListedCustomerPage({
    required this.service,
    required this.dayPlanId,
    required this.routeId,
    required this.route,
    required this.title,
  });

  final DayPlanService service;
  final int dayPlanId;
  final int routeId;
  final Map<String, dynamic> route;
  final String title;

  @override
  State<_ListedCustomerPage> createState() => _ListedCustomerPageState();
}

class _ListedCustomerPageState extends State<_ListedCustomerPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.service.loadRouteCustomers(
      widget.dayPlanId,
      widget.routeId,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorView(
                message: _errorMessage(snapshot.error),
                onRetry: () => setState(_load),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final customers = _list(snapshot.data!['customers']);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Route ${widget.routeId} · ${widget.route['town']}',
                  ),
                  subtitle: Text('${customers.length} customers'),
                ),
                if (customers.isEmpty)
                  const Center(child: Text('No listed customers found.'))
                else
                  for (final customer in customers) _customerCard(customer),
              ],
            );
          },
        ),
      );

  Widget _customerCard(Map<String, dynamic> customer) {
    final customerId = _int(customer['customer_id']);
    final orderType = customer['order_type']?.toString() ?? 'P';
    final pobLabel = orderType == 'S' ? 'SOB' : 'POB';
    final actions = <(String, String)>[
      ('Detailing', 'detailing'),
      ('Input', 'sample'),
      (pobLabel, 'pob'),
      if (_int(customer['customer_type_id']) == 2)
        ('Availability', 'availability'),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer['name']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer['customer_type']?.toString() ?? '',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final action in actions)
                        OutlinedButton(
                          onPressed: customerId == null
                              ? null
                              : () => _openActivity(
                                    customerId,
                                    customer,
                                    action.$1,
                                    action.$2,
                                  ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(action.$1),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete customer',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed:
                  customerId == null ? null : () => _deleteCustomer(customerId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openActivity(
    int customerId,
    Map<String, dynamic> customer,
    String title,
    String activity,
  ) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomerActivityPage(
          service: widget.service,
          dayPlanId: widget.dayPlanId,
          routeId: widget.routeId,
          customerId: customerId,
          unlistedCustomerId: null,
          orderType: customer['order_type']?.toString(),
          customerName: customer['name']?.toString(),
          activity: activity,
          title: title,
          includeFreeQuantity: customer['order_type']?.toString() == 'P',
        ),
      ),
    );
    if (saved == true && mounted) setState(_load);
  }

  Future<void> _deleteCustomer(int customerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: const Text('Remove this customer from the day plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteListedCustomer(
        dayPlanId: widget.dayPlanId,
        customerId: customerId,
      );
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer removed.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _RouteCustomerPage extends StatefulWidget {
  const _RouteCustomerPage({
    required this.service,
    required this.dayPlanId,
    required this.routeId,
    required this.route,
    required this.title,
  });

  final DayPlanService service;
  final int dayPlanId;
  final int routeId;
  final Map<String, dynamic> route;
  final String title;

  @override
  State<_RouteCustomerPage> createState() => _RouteCustomerPageState();
}

class _RouteCustomerPageState extends State<_RouteCustomerPage> {
  late Future<Map<String, dynamic>> _future;
  final Set<int> _selected = {};
  bool _initialSelectionLoaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future =
        widget.service.loadRouteCustomers(widget.dayPlanId, widget.routeId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorView(
                message: _errorMessage(snapshot.error),
                onRetry: () => setState(() {
                  _future = widget.service
                      .loadRouteCustomers(widget.dayPlanId, widget.routeId);
                }),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final customers = _list(snapshot.data!['customers']);
            if (!_initialSelectionLoaded) {
              for (final customer in customers) {
                final id = _int(customer['customer_id']);
                if (id != null && customer['selected'] == true) {
                  _selected.add(id);
                }
              }
              _initialSelectionLoaded = true;
            }
            return Column(
              children: [
                ListTile(
                  title:
                      Text('Route ${widget.routeId} · ${widget.route['town']}'),
                  subtitle: Text('${customers.length} customers'),
                ),
                Expanded(
                  child: customers.isEmpty
                      ? const Center(child: Text('No listed customers found.'))
                      : ListView.builder(
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            final id = _int(customer['customer_id']);
                            if (id == null) return const SizedBox.shrink();
                            return CheckboxListTile(
                              value: _selected.contains(id),
                              title: Text(customer['name']?.toString() ?? ''),
                              subtitle: Text(
                                customer['customer_type']?.toString() ?? '',
                              ),
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  _selected.add(id);
                                } else {
                                  _selected.remove(id);
                                }
                              }),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Saving…' : 'Save selection'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.service.addListedCustomers(
        dayPlanId: widget.dayPlanId,
        routeId: widget.routeId,
        customerIds: _selected.toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OtherRouteCustomersPage extends StatefulWidget {
  const _OtherRouteCustomersPage({
    required this.service,
    required this.dayPlanId,
    required this.plannedRouteId,
    required this.customers,
    required this.routes,
    required this.workWith,
  });

  final DayPlanService service;
  final int dayPlanId;
  final int? plannedRouteId;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> workWith;

  @override
  State<_OtherRouteCustomersPage> createState() =>
      _OtherRouteCustomersPageState();
}

class _OtherRouteCustomersPageState extends State<_OtherRouteCustomersPage> {
  final Set<int> _removedCustomerIds = {};

  List<Map<String, dynamic>> get _customers => widget.customers
      .where((customer) =>
          _int(customer['route_id']) != widget.plannedRouteId &&
          !_removedCustomerIds.contains(_int(customer['customer_id'])))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final customers = _customers;
    return Scaffold(
      appBar: AppBar(title: const Text('Other Route')),
      body: customers.isEmpty
          ? const Center(child: Text('No other route customers found.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final customer in customers) _customerCard(customer),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCustomer,
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _customerCard(Map<String, dynamic> customer) {
    final customerId = _int(customer['customer_id']);
    final routeId = _int(customer['route_id']);
    final orderType = customer['order_type']?.toString() ?? 'P';
    final actions = <(String, String)>[
      ('Detailing', 'detailing'),
      ('Input', 'sample'),
      (orderType == 'S' ? 'SOB' : 'POB', 'pob'),
      if (_int(customer['customer_type_id']) == 2)
        ('Availability', 'availability'),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer['name']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              'Route No: ${routeId ?? ''} · ${customer['customer_type'] ?? ''}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final action in actions)
                  OutlinedButton(
                    onPressed: customerId == null || routeId == null
                        ? null
                        : () => _openActivity(
                              customerId,
                              routeId,
                              customer,
                              action.$1,
                              action.$2,
                            ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(action.$1),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Delete customer',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: customerId == null
                    ? null
                    : () => _deleteCustomer(customerId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openActivity(
    int customerId,
    int routeId,
    Map<String, dynamic> customer,
    String title,
    String activity,
  ) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomerActivityPage(
          service: widget.service,
          dayPlanId: widget.dayPlanId,
          routeId: routeId,
          customerId: customerId,
          unlistedCustomerId: null,
          orderType: customer['order_type']?.toString(),
          customerName: customer['name']?.toString(),
          activity: activity,
          title: title,
          includeFreeQuantity: customer['order_type']?.toString() == 'P',
        ),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _deleteCustomer(int customerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: const Text('Remove this customer from the day plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.deleteListedCustomer(
        dayPlanId: widget.dayPlanId,
        customerId: customerId,
      );
      if (mounted) {
        setState(() => _removedCustomerIds.add(customerId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer removed.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openAddCustomer() async {
    final otherRoutes = widget.routes
        .where((route) => _int(route['route_id']) != widget.plannedRouteId)
        .toList(growable: false);
    if (otherRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other routes are available.')),
      );
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _OtherRoutePage(
          service: widget.service,
          dayPlanId: widget.dayPlanId,
          routes: otherRoutes,
          workWith: widget.workWith,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }
}

class _OtherRoutePage extends StatefulWidget {
  const _OtherRoutePage({
    required this.service,
    required this.dayPlanId,
    required this.routes,
    required this.workWith,
  });

  final DayPlanService service;
  final int dayPlanId;
  final List<Map<String, dynamic>> routes;
  final List<Map<String, dynamic>> workWith;

  @override
  State<_OtherRoutePage> createState() => _OtherRoutePageState();
}

class _OtherRoutePageState extends State<_OtherRoutePage> {
  int? _routeId;
  int? _workWithId;
  int? _customerId;
  Future<Map<String, dynamic>>? _customersFuture;
  bool _saving = false;

  void _selectRoute(int? routeId) {
    setState(() {
      _routeId = routeId;
      _customerId = null;
      _customersFuture = routeId == null
          ? null
          : widget.service.loadRouteCustomers(widget.dayPlanId, routeId);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Customer')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(
              title: 'Route:',
              child: DropdownButtonFormField<int>(
                initialValue: _routeId,
                decoration: const InputDecoration(hintText: 'Please Select'),
                items: [
                  for (final route in widget.routes)
                    DropdownMenuItem<int>(
                      value: _int(route['route_id']),
                      child: Text(
                        '${route['route_id']} - ${route['town'] ?? ''}',
                      ),
                    ),
                ],
                onChanged: _saving ? null : _selectRoute,
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Work With:',
              child: DropdownButtonFormField<int>(
                initialValue: _workWithId,
                decoration: const InputDecoration(hintText: 'Please Select'),
                items: [
                  for (final employee in widget.workWith)
                    DropdownMenuItem<int>(
                      value: _int(employee['employee_id'] ?? employee['id']),
                      child: Text(
                        employee['name']?.toString() ??
                            employee['employee_name']?.toString() ??
                            '',
                      ),
                    ),
                ],
                onChanged: _saving || widget.workWith.isEmpty
                    ? null
                    : (value) => setState(() => _workWithId = value),
              ),
            ),
            const SizedBox(height: 12),
            _section(
              title: 'Customer:',
              child: _customerField(),
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Submitting…' : 'Submit'),
              ),
            ),
          ],
        ),
      );

  Widget _customerField() {
    final future = _customersFuture;
    if (future == null) {
      return const Text('Select a route first.');
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            _errorMessage(snapshot.error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }
        final customers = _list(snapshot.data!['customers']);
        if (customers.isEmpty) return const Text('No customers found.');
        return DropdownButtonFormField<int>(
          initialValue: _customerId,
          decoration: const InputDecoration(hintText: 'Please Select'),
          items: [
            for (final customer in customers)
              DropdownMenuItem<int>(
                value: _int(customer['customer_id']),
                child: Text(customer['name']?.toString() ?? ''),
              ),
          ],
          onChanged:
              _saving ? null : (value) => setState(() => _customerId = value),
        );
      },
    );
  }

  Widget _section({required String title, required Widget child}) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );

  Future<void> _save() async {
    final routeId = _routeId;
    final customerId = _customerId;
    if (routeId == null || customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a route and customer.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.addListedCustomers(
        dayPlanId: widget.dayPlanId,
        routeId: routeId,
        customerIds: [customerId],
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _UnlistedCustomerPage extends StatefulWidget {
  const _UnlistedCustomerPage({
    required this.service,
    required this.dayPlanId,
    required this.options,
    required this.customers,
    required this.canEdit,
  });

  final DayPlanService service;
  final int dayPlanId;
  final Map<String, dynamic> options;
  final List<Map<String, dynamic>> customers;
  final bool canEdit;

  @override
  State<_UnlistedCustomerPage> createState() => _UnlistedCustomerPageState();
}

class _UnlistedCustomerPageState extends State<_UnlistedCustomerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlisted Customers')),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              tooltip: 'Add customer',
              onPressed: _openAddCustomer,
              child: const Icon(Icons.add),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.customers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Data not found'),
              ),
            )
          else
            for (final customer in widget.customers) _customerCard(customer),
        ],
      ),
    );
  }

  Future<void> _openAddCustomer() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _UnlistedCustomerAddPage(
          service: widget.service,
          dayPlanId: widget.dayPlanId,
          options: widget.options,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  Widget _customerCard(Map<String, dynamic> customer) {
    final customerId = _int(customer['unlisted_customer_id']);
    final orderType = customer['order_type']?.toString() ?? 'P';
    final actions = <(String, String)>[
      ('Detailing', 'detailing'),
      ('Input', 'sample'),
      (orderType == 'S' ? 'SOB' : 'POB', 'pob'),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer['name']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              '${customer['place'] ?? ''} · POB: ${customer['total_pob'] ?? 0}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final action in actions)
                  OutlinedButton(
                    onPressed: customerId == null
                        ? null
                        : () => _openActivity(
                              customerId,
                              customer,
                              action.$1,
                              action.$2,
                            ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(action.$1),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openActivity(
    int customerId,
    Map<String, dynamic> customer,
    String title,
    String activity,
  ) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomerActivityPage(
          service: widget.service,
          dayPlanId: widget.dayPlanId,
          customerId: null,
          unlistedCustomerId: customerId,
          orderType: customer['order_type']?.toString(),
          customerName: customer['name']?.toString(),
          activity: activity,
          title: title,
          includeFreeQuantity: customer['order_type']?.toString() == 'P',
        ),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }
}

class _UnlistedCustomerAddPage extends StatefulWidget {
  const _UnlistedCustomerAddPage({
    required this.service,
    required this.dayPlanId,
    required this.options,
  });

  final DayPlanService service;
  final int dayPlanId;
  final Map<String, dynamic> options;

  @override
  State<_UnlistedCustomerAddPage> createState() =>
      _UnlistedCustomerAddPageState();
}

class _UnlistedCustomerAddPageState extends State<_UnlistedCustomerAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _qualification = TextEditingController();
  final _phone = TextEditingController();
  final _place = TextEditingController();
  int? _typeId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _qualification.dispose();
    _phone.dispose();
    _place.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = _list(widget.options['customer_types']);
    final qualifications =
        (widget.options['qualifications'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false);
    final previousNames =
        (widget.options['previous_unlisted_names'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Unlisted Customers Add')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _name.text.isEmpty ? null : _name.text,
              decoration: const InputDecoration(labelText: 'Customer Name'),
              items: [
                for (final name in previousNames)
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: _applyPreviousCustomer,
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _typeId,
              decoration: const InputDecoration(labelText: 'Customer Type'),
              items: [
                for (final type in types)
                  DropdownMenuItem<int>(
                    value: _int(type['id']),
                    child: Text(type['name']?.toString() ?? ''),
                  ),
              ],
              onChanged: (value) => setState(() => _typeId = value),
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (qualifications.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Qualification'),
                items: [
                  for (final value in qualifications)
                    DropdownMenuItem(value: value, child: Text(value)),
                ],
                onChanged: (value) => _qualification.text = value ?? '',
              ),
            if (qualifications.isNotEmpty) const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _place,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Place'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreviousCustomer(String? name) {
    if (name == null) return;
    final previous =
        _list(widget.options['previous_unlisted_customers']).firstWhere(
      (customer) => customer['name']?.toString() == name,
      orElse: () => <String, dynamic>{},
    );
    setState(() {
      _name.text = name;
      _typeId = _int(previous['customer_type_id']);
      _qualification.text = previous['qualification']?.toString() ?? '';
      _phone.text = previous['phone']?.toString() ?? '';
      _place.text = previous['place']?.toString() ?? '';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _typeId == null) return;
    setState(() => _saving = true);
    try {
      await widget.service.addUnlistedCustomer(
        dayPlanId: widget.dayPlanId,
        customerTypeId: _typeId!,
        name: _name.text.trim(),
        qualification: _qualification.text.trim(),
        phone: _phone.text.trim(),
        place: _place.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CustomerActivityPage extends StatefulWidget {
  const _CustomerActivityPage({
    required this.service,
    required this.dayPlanId,
    this.routeId,
    required this.customerId,
    required this.unlistedCustomerId,
    this.orderType,
    this.customerName,
    required this.activity,
    required this.title,
    required this.includeFreeQuantity,
  });

  final DayPlanService service;
  final int dayPlanId;
  final int? routeId;
  final int? customerId;
  final int? unlistedCustomerId;
  final String? orderType;
  final String? customerName;
  final String activity;
  final String title;
  final bool includeFreeQuantity;

  @override
  State<_CustomerActivityPage> createState() => _CustomerActivityPageState();
}

class _CustomerActivityPageState extends State<_CustomerActivityPage> {
  final Set<int> _selected = {};
  final Set<int> _selectedWorkWith = {};
  final Map<int, TextEditingController> _quantities = {};
  final Map<int, TextEditingController> _freeQuantities = {};
  final TextEditingController _remarks = TextEditingController();
  final TextEditingController _orderTo = TextEditingController();
  final PageController _categoryController = PageController(
    viewportFraction: 0.94,
  );
  late Future<Map<String, dynamic>> _future;
  bool _initialized = false;
  bool _saving = false;
  bool _attemptedDayPlanAttach = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    try {
      return await widget.service.loadCustomerActivity(
        dayPlanId: widget.dayPlanId,
        activity: widget.activity,
        customerId: widget.customerId,
        unlistedCustomerId: widget.unlistedCustomerId,
        orderType: widget.orderType,
      );
    } on ApiException catch (error) {
      final canAttach = !_attemptedDayPlanAttach &&
          error.code == 'day_plan_customer_not_found' &&
          widget.customerId != null &&
          widget.routeId != null;
      if (!canAttach) rethrow;

      _attemptedDayPlanAttach = true;
      await widget.service.addListedCustomers(
        dayPlanId: widget.dayPlanId,
        routeId: widget.routeId!,
        customerIds: [widget.customerId!],
      );
      return widget.service.loadCustomerActivity(
        dayPlanId: widget.dayPlanId,
        activity: widget.activity,
        customerId: widget.customerId,
        unlistedCustomerId: widget.unlistedCustomerId,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    for (final controller in _freeQuantities.values) {
      controller.dispose();
    }
    _remarks.dispose();
    _orderTo.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.customerName?.trim().isNotEmpty == true
                ? '${widget.title} · ${widget.customerName!.trim()}'
                : widget.title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorView(
                message: _errorMessage(snapshot.error),
                onRetry: () => setState(() => _future = _load()),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final groups = _productGroups(data['catalogue']);
            final products = _products(data['catalogue']);
            final savedProducts = _list(data['products']);
            final orderToOptions = _list(data['order_to_options']);
            _initialize(products, savedProducts, data);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (widget.activity == 'detailing') ...[
                        const Text(
                          'Work With',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final employee in _list(data['work_with']))
                              ChoiceChip(
                                label: Text(
                                  employee['name']?.toString() ?? '',
                                ),
                                selected: _selectedWorkWith.contains(
                                  _int(employee['employee_id']),
                                ),
                                onSelected: (selected) {
                                  final id = _int(employee['employee_id']);
                                  if (id == null) return;
                                  setState(() {
                                    if (selected) {
                                      _selectedWorkWith.add(id);
                                    } else {
                                      _selectedWorkWith.remove(id);
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Products',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (widget.activity == 'pob' &&
                          widget.customerId != null) ...[
                        DropdownButtonFormField<String>(
                          value: orderToOptions.any(
                                  (item) => '${item['id']}' == _orderTo.text)
                              ? _orderTo.text
                              : null,
                          decoration:
                              const InputDecoration(labelText: 'Order To'),
                          items: [
                            for (final option in orderToOptions)
                              DropdownMenuItem<String>(
                                value: '${option['id']}',
                                child: Text(option['name']?.toString() ?? ''),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _orderTo.text = value ?? ''),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _remarks,
                          maxLength: 500,
                          decoration:
                              const InputDecoration(labelText: 'Remarks'),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (widget.activity == 'detailing' ||
                          widget.activity == 'availability')
                        _detailingProductCards(groups)
                      else if (widget.activity == 'sample')
                        _inputProductCards(groups)
                      else if (widget.activity == 'pob')
                        _pobProductCards(groups)
                      else
                        for (final group in groups) _productGroup(group),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : () => _save(products),
                        child: Text(_saving ? 'Saving…' : 'Save'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  void _initialize(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> savedProducts,
    Map<String, dynamic> data,
  ) {
    if (_initialized) return;
    final savedById = <int, Map<String, dynamic>>{};
    for (final item in savedProducts) {
      final id = _int(item['product_id']);
      if (id != null) savedById[id] = item;
    }
    if (widget.activity == 'detailing') {
      for (final id in _intList(data['selected_work_with'])) {
        _selectedWorkWith.add(id);
      }
    }
    for (final product in products) {
      final id = _int(product['product_id']);
      if (id == null) continue;
      final saved = savedById[id];
      if (saved != null && saved['selected'] == true) _selected.add(id);
      if (widget.activity == 'sample' || widget.activity == 'pob') {
        _quantities[id] = TextEditingController(
          text: saved == null ? '' : '${saved['quantity'] ?? 0}',
        );
      }
      if (widget.activity == 'pob' && widget.includeFreeQuantity) {
        _freeQuantities[id] = TextEditingController(
          text: saved == null ? '' : '${saved['free_quantity'] ?? 0}',
        );
      }
    }
    _remarks.text = data['remarks']?.toString() ?? '';
    _orderTo.text = data['order_to']?.toString() ?? '';
    _initialized = true;
  }

  Widget _productRow(Map<String, dynamic> product) {
    final id = _int(product['product_id']);
    if (id == null) return const SizedBox.shrink();
    final name = product['name']?.toString() ?? '';
    final rate = product['rate']?.toString() ?? '';
    final balance = product['balance']?.toString() ?? '';
    if (widget.activity == 'detailing' || widget.activity == 'availability') {
      return CheckboxListTile(
        value: _selected.contains(id),
        contentPadding: EdgeInsets.zero,
        title: Text(name),
        onChanged: (value) => setState(() {
          if (value == true) {
            _selected.add(id);
          } else {
            _selected.remove(id);
          }
        }),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (widget.activity == 'sample') Text('Balance: $balance'),
            if (widget.activity == 'pob') Text('Rate: $rate'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantities[id],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                if (widget.activity == 'pob' && widget.includeFreeQuantity) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _freeQuantities[id],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Free Quantity'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productGroup(Map<String, dynamic> group) {
    final name = group['name']?.toString() ?? 'Products';
    final products = _list(group['products']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(name),
        children: [for (final product in products) _productRow(product)],
      ),
    );
  }

  Widget _detailingProductCards(List<Map<String, dynamic>> groups) {
    if (groups.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No products available.')),
        ),
      );
    }

    return SizedBox(
      height: 430,
      child: PageView.builder(
        controller: _categoryController,
        itemCount: groups.length,
        padEnds: false,
        itemBuilder: (context, index) {
          final group = groups[index];
          final products = _list(group['products']);
          return Card(
            margin: const EdgeInsets.only(right: 10, bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group['name']?.toString() ?? 'Products',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${products.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, productIndex) =>
                        _detailingProductTile(products[productIndex]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    'Swipe for more categories',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailingProductTile(Map<String, dynamic> product) {
    final id = _int(product['product_id']);
    if (id == null) return const SizedBox.shrink();
    final name = product['name']?.toString() ?? '';
    return CheckboxListTile(
      value: _selected.contains(id),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _productIcon(name),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(name),
      onChanged: (value) => setState(() {
        if (value == true) {
          _selected.add(id);
        } else {
          _selected.remove(id);
        }
      }),
    );
  }

  Widget _inputProductCards(List<Map<String, dynamic>> groups) {
    if (groups.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No products available.')),
        ),
      );
    }

    return SizedBox(
      height: 430,
      child: PageView.builder(
        controller: _categoryController,
        itemCount: groups.length,
        padEnds: false,
        itemBuilder: (context, index) {
          final group = groups[index];
          final products = _list(group['products']);
          return Card(
            margin: const EdgeInsets.only(right: 10, bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group['name']?.toString() ?? 'Products',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${products.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 7, 16, 3),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 5,
                        child: Text(
                          'Product',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(
                        width: 58,
                        child: Text(
                          'Balance',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 82,
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, productIndex) =>
                        _inputProductTile(products[productIndex]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text(
                    'Swipe for more categories',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _inputProductTile(Map<String, dynamic> product) {
    final id = _int(product['product_id']);
    if (id == null) return const SizedBox.shrink();
    final name = product['name']?.toString() ?? '';
    final balance = product['balance']?.toString() ?? '0';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    _productIcon(name),
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(balance, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: TextField(
              controller: _quantities[id],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pobProductCards(List<Map<String, dynamic>> groups) {
    if (groups.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No products available.')),
        ),
      );
    }
    final hasFreeQuantity = widget.includeFreeQuantity;
    return SizedBox(
      height: 430,
      child: PageView.builder(
        controller: _categoryController,
        itemCount: groups.length,
        padEnds: false,
        itemBuilder: (context, index) {
          final group = groups[index];
          final products = _list(group['products']);
          return Card(
            margin: const EdgeInsets.only(right: 10, bottom: 8),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.category_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group['name']?.toString() ?? 'Products',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${products.length}'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 7, 16, 3),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Product',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(
                        width: 52,
                        child: Text('Rate',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: hasFreeQuantity ? 70 : 82,
                        child: const Text('Qty',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (hasFreeQuantity) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 70,
                          child: Text('Free',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, productIndex) =>
                        _pobProductTile(products[productIndex]),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text('Swipe for more categories',
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pobProductTile(Map<String, dynamic> product) {
    final id = _int(product['product_id']);
    if (id == null) return const SizedBox.shrink();
    final name = product['name']?.toString() ?? '';
    final hasFreeQuantity = widget.includeFreeQuantity;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(_productIcon(name), size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(product['rate']?.toString() ?? '0',
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: hasFreeQuantity ? 70 : 82,
            child: _quantityField(_quantities[id]),
          ),
          if (hasFreeQuantity) ...[
            const SizedBox(width: 8),
            SizedBox(width: 70, child: _quantityField(_freeQuantities[id])),
          ],
        ],
      ),
    );
  }

  Widget _quantityField(TextEditingController? controller) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          hintText: '0',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        ),
      );

  IconData _productIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('syrup') ||
        name.contains('solution') ||
        name.contains('suspension')) {
      return Icons.medication_liquid;
    }
    if (name.contains('injection') ||
        name.contains('vial') ||
        name.contains('ampoule')) {
      return Icons.vaccines_outlined;
    }
    if (name.contains('cream') ||
        name.contains('ointment') ||
        name.contains('gel')) {
      return Icons.sanitizer_outlined;
    }
    if (name.contains('drop')) return Icons.water_drop_outlined;
    if (name.contains('tablet') ||
        name.contains('tab ') ||
        name.contains('capsule') ||
        name.contains('cap ')) {
      return Icons.medication_outlined;
    }
    return Icons.local_pharmacy_outlined;
  }

  Future<void> _save(List<Map<String, dynamic>> products) async {
    final selectedProducts = <Map<String, dynamic>>[];
    for (final product in products) {
      final id = _int(product['product_id']);
      if (id == null) continue;
      final name = product['name']?.toString() ?? 'product';
      if (widget.activity == 'detailing' || widget.activity == 'availability') {
        if (_selected.contains(id)) selectedProducts.add({'product_id': id});
        continue;
      }
      final quantity = double.tryParse(_quantities[id]?.text.trim() ?? '');
      final quantityText = _quantities[id]?.text.trim() ?? '';
      if (quantityText.isNotEmpty && quantity == null) {
        _showMessage('Enter a valid quantity for $name.');
        return;
      }
      if (quantity != null && quantity < 0) {
        _showMessage('Quantity for $name cannot be negative.');
        return;
      }
      if (quantity == null || quantity <= 0) continue;
      final freeQuantityText = _freeQuantities[id]?.text.trim() ?? '';
      final freeQuantity = double.tryParse(freeQuantityText);
      if (freeQuantityText.isNotEmpty &&
          (freeQuantity == null || freeQuantity < 0)) {
        _showMessage('Enter a valid free quantity for $name.');
        return;
      }
      selectedProducts.add({
        'product_id': id,
        'quantity': quantity,
        if (widget.activity == 'pob' && widget.includeFreeQuantity)
          'free_quantity': freeQuantity ?? 0,
      });
    }
    if (widget.activity == 'pob' &&
        widget.customerId != null &&
        _orderTo.text.trim().isEmpty) {
      _showMessage('Select Order To.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.saveCustomerActivity(
        dayPlanId: widget.dayPlanId,
        activity: widget.activity,
        products: selectedProducts,
        customerId: widget.customerId,
        unlistedCustomerId: widget.unlistedCustomerId,
        routeId: widget.routeId,
        orderType: widget.orderType,
        workWithIds: _selectedWorkWith.toList(),
        remarks: _remarks.text.trim(),
        orderTo: _orderTo.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> _products(dynamic value) {
    return [
      for (final group in _productGroups(value)) ..._list(group['products'])
    ];
  }

  List<Map<String, dynamic>> _productGroups(dynamic value) {
    final categories = _list(value);
    return categories
        .map((category) => {
              'name': category['name'] ??
                  category['group_name'] ??
                  category['description'] ??
                  'Products',
              'products': _list(category['products']),
            })
        .where((category) => _list(category['products']).isNotEmpty)
        .toList(growable: false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DayPlanSummaryPage extends StatefulWidget {
  const _DayPlanSummaryPage({
    required this.service,
    required this.plan,
    required this.plannedRouteId,
    required this.listedCustomers,
    required this.unlistedCustomers,
    required this.onSubmit,
  });

  final DayPlanService service;
  final Map<String, dynamic> plan;
  final int? plannedRouteId;
  final List<Map<String, dynamic>> listedCustomers;
  final List<Map<String, dynamic>> unlistedCustomers;
  final Future<void> Function() onSubmit;

  @override
  State<_DayPlanSummaryPage> createState() => _DayPlanSummaryPageState();
}

class _DayPlanSummaryPageState extends State<_DayPlanSummaryPage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final listed = widget.listedCustomers
        .where((customer) =>
            widget.plannedRouteId == null ||
            _int(customer['route_id']) == widget.plannedRouteId)
        .toList(growable: false);
    final otherRoute = widget.listedCustomers
        .where((customer) =>
            widget.plannedRouteId != null &&
            _int(customer['route_id']) != widget.plannedRouteId)
        .toList(growable: false);
    final hasCustomers = listed.isNotEmpty ||
        otherRoute.isNotEmpty ||
        widget.unlistedCustomers.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.plan['date_label']?.toString() ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if ((widget.plan['remarks']?.toString() ?? '').isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Remarks: ${widget.plan['remarks']}'),
              ),
            ),
          if (!hasCustomers)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No data found')),
              ),
            )
          else ...[
            _summarySection('Customers', listed),
            if (otherRoute.isNotEmpty) ...[
              const SizedBox(height: 12),
              _summarySection('Other Route', otherRoute),
            ],
            if (widget.unlistedCustomers.isNotEmpty) ...[
              const SizedBox(height: 12),
              _summarySection('Unlisted', widget.unlistedCustomers),
            ],
          ],
          if (widget.plan['can_edit'] == true && hasCustomers) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Submitting…' : 'Submit'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summarySection(
    String title,
    List<Map<String, dynamic>> customers,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataTable(
            columnSpacing: 12,
            horizontalMargin: 12,
            headingRowHeight: 34,
            dataRowMinHeight: 42,
            dataRowMaxHeight: 56,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('POB'), numeric: true),
            ],
            rows: [
              for (var index = 0; index < customers.length; index++)
                DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          customers[index]['name']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_pobLabel(customers[index]['total_pob']))),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _pobLabel(dynamic value) {
    final amount = value is num ? value : num.tryParse('$value');
    if (amount == null) return '0';
    return amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit day plan?'),
        content: const Text('The submitted day plan cannot be edited.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

Map<String, dynamic>? _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

List<int> _intList(dynamic value) {
  if (value is! List) return const [];
  return value.map(_int).whereType<int>().toList(growable: false);
}

String _dateValue(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}-${_monthName(date.month)}-${date.year}';

String _monthName(int month) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];

String _errorMessage(Object? error) =>
    error is ApiException ? error.message : 'Unable to load the day plan.';
