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
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ActionTile(
                      title: 'Listed Customer',
                      subtitle: 'Add customers from the planned route',
                      icon: Icons.people_alt_outlined,
                      enabled: canEdit && plannedRouteId != null,
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
                      onTap: () => _chooseOtherRoute(
                        dayPlanId,
                        routes,
                        plannedRouteId,
                      ),
                    ),
                    _ActionTile(
                      title: 'Unlisted Customer',
                      subtitle: 'Add a customer not on a listed route',
                      icon: Icons.person_add_alt_1,
                      enabled: canEdit,
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
                      onTap: () async {
                        final submitted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _DayPlanSummaryPage(
                              service: _service,
                              plan: plan,
                              listedCustomers: _list(data['listed_customers']),
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
  ) async {
    _lastRoutes = routes;
    final otherRoutes = routes
        .where((route) => _int(route['route_id']) != plannedRouteId)
        .toList(growable: false);
    if (otherRoutes.isEmpty) {
      _showMessage('No other routes are available.');
      return;
    }
    final route = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Select Route')),
            for (final item in otherRoutes)
              ListTile(
                title: Text('Route ${item['route_id']} · ${item['town']}'),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    final routeId = _int(route?['route_id']);
    if (routeId != null) {
      await _openRouteCustomers(dayPlanId, routeId, 'Other Route');
    }
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
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          enabled: enabled,
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
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
          customerId: customerId,
          unlistedCustomerId: null,
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
        (widget.options['qualifications'] as List? ?? const []).map((value) {
      return value.toString();
    }).toList(growable: false);
    final previousNames =
        (widget.options['previous_unlisted_names'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Unlisted Customers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final customer in widget.customers)
            Card(
              child: ListTile(
                title: Text(customer['name']?.toString() ?? ''),
                subtitle: Text(customer['place']?.toString() ?? ''),
                trailing: Text(
                  (customer['total_pob'] ?? 0).toString(),
                ),
              ),
            ),
          if (widget.canEdit) ...[
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (previousNames.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Previous Customer'),
                      items: [
                        for (final name in previousNames)
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (value) {
                        if (value != null) _name.text = value;
                      },
                    ),
                  TextFormField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Customer Name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _typeId,
                    decoration:
                        const InputDecoration(labelText: 'Customer Type'),
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
                  if (qualifications.isNotEmpty)
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Qualification'),
                      items: [
                        for (final value in qualifications)
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (value) => _qualification.text = value ?? '',
                    ),
                  TextFormField(
                    controller: _phone,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  TextFormField(
                    controller: _place,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: 'Place'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Saving…' : 'Add customer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
    required this.customerId,
    required this.unlistedCustomerId,
    required this.activity,
    required this.title,
    required this.includeFreeQuantity,
  });

  final DayPlanService service;
  final int dayPlanId;
  final int? customerId;
  final int? unlistedCustomerId;
  final String activity;
  final String title;
  final bool includeFreeQuantity;

  @override
  State<_CustomerActivityPage> createState() => _CustomerActivityPageState();
}

class _CustomerActivityPageState extends State<_CustomerActivityPage> {
  final Set<int> _selected = {};
  final Map<int, TextEditingController> _quantities = {};
  final Map<int, TextEditingController> _freeQuantities = {};
  final TextEditingController _remarks = TextEditingController();
  final TextEditingController _orderTo = TextEditingController();
  late Future<Map<String, dynamic>> _future;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() => widget.service.loadCustomerActivity(
        dayPlanId: widget.dayPlanId,
        activity: widget.activity,
        customerId: widget.customerId,
        unlistedCustomerId: widget.unlistedCustomerId,
      );

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
    super.dispose();
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
                onRetry: () => setState(() => _future = _load()),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final products = _products(data['catalogue']);
            final savedProducts = _list(data['products']);
            _initialize(products, savedProducts, data);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (widget.activity == 'pob' &&
                          widget.customerId != null) ...[
                        TextField(
                          controller: _orderTo,
                          decoration:
                              const InputDecoration(labelText: 'Order To'),
                        ),
                        TextField(
                          controller: _remarks,
                          maxLength: 500,
                          decoration:
                              const InputDecoration(labelText: 'Remarks'),
                        ),
                      ],
                      for (final product in products) _productRow(product),
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
            Text('Rate: $rate'),
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
    setState(() => _saving = true);
    try {
      await widget.service.saveCustomerActivity(
        dayPlanId: widget.dayPlanId,
        activity: widget.activity,
        products: selectedProducts,
        customerId: widget.customerId,
        unlistedCustomerId: widget.unlistedCustomerId,
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
    final categories = _list(value);
    return [
      for (final category in categories) ..._list(category['products']),
    ];
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
    required this.listedCustomers,
    required this.unlistedCustomers,
    required this.onSubmit,
  });

  final DayPlanService service;
  final Map<String, dynamic> plan;
  final List<Map<String, dynamic>> listedCustomers;
  final List<Map<String, dynamic>> unlistedCustomers;
  final Future<void> Function() onSubmit;

  @override
  State<_DayPlanSummaryPage> createState() => _DayPlanSummaryPageState();
}

class _DayPlanSummaryPageState extends State<_DayPlanSummaryPage> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Day Plan Summary')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Remarks: ${widget.plan['remarks'] ?? ''}'),
            const SizedBox(height: 12),
            const Text('Listed Customers',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final customer in widget.listedCustomers)
              ListTile(
                title: Text(customer['name']?.toString() ?? ''),
                subtitle: Text('Route ${customer['route_id'] ?? ''}'),
                trailing: Text('${customer['total_pob'] ?? 0}'),
              ),
            const SizedBox(height: 8),
            const Text('Unlisted Customers',
                style: TextStyle(fontWeight: FontWeight.bold)),
            for (final customer in widget.unlistedCustomers)
              ListTile(
                title: Text(customer['name']?.toString() ?? ''),
                subtitle: Text(customer['place']?.toString() ?? ''),
                trailing: Text('${customer['total_pob'] ?? 0}'),
              ),
            if (widget.plan['can_edit'] == true) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child:
                    Text(_submitting ? 'Submitting…' : 'Submit for approval'),
              ),
            ],
          ],
        ),
      );

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
