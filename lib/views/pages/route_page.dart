import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/route_data.dart';
import '../../services/route_service.dart';

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final RouteService _service = RouteService();
  late Future<List<RouteSummary>> _routes;

  @override
  void initState() {
    super.initState();
    _routes = _service.loadRoutes();
  }

  Future<void> _refresh() async {
    final request = _service.loadRoutes();
    setState(() => _routes = request);
    await request;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Routes')),
        body: FutureBuilder<List<RouteSummary>>(
          future: _routes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _LoadError(
                message: _errorMessage(snapshot.error),
                onRetry: _refresh,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final routes = snapshot.data!;
            if (routes.isEmpty) {
              return const Center(child: Text('No routes found.'));
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 800 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  itemCount: routes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 195,
                  ),
                  itemBuilder: (context, index) => _RouteCard(
                    route: routes[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteCustomersPage(
                          route: routes[index],
                          service: _service,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, required this.onTap});

  final RouteSummary route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text(
                        '${route.routeId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      route.town,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.navy),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Route No. ${route.routeId} · ${route.customerCount} customers',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const Spacer(),
                Row(children: [
                  Expanded(
                    child: _RouteCount(
                      label: 'Verified',
                      value: route.verifiedCount,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _RouteCount(
                      label: 'Unverified',
                      value: route.unverifiedCount,
                      color: Colors.orange,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );
}

class _RouteCount extends StatelessWidget {
  const _RouteCount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      );
}

class RouteCustomersPage extends StatefulWidget {
  const RouteCustomersPage({
    super.key,
    required this.route,
    required this.service,
  });

  final RouteSummary route;
  final RouteService service;

  @override
  State<RouteCustomersPage> createState() => _RouteCustomersPageState();
}

class _RouteCustomersPageState extends State<RouteCustomersPage> {
  late Future<(RouteSummary, List<RouteCustomer>)> _customers;

  @override
  void initState() {
    super.initState();
    _customers = _load();
  }

  Future<(RouteSummary, List<RouteCustomer>)> _load() =>
      widget.service.loadCustomers(widget.route.routeId, widget.route);

  Future<void> _refresh() async {
    final request = _load();
    setState(() => _customers = request);
    await request;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Route ${widget.route.routeId}')),
        body: FutureBuilder<(RouteSummary, List<RouteCustomer>)>(
          future: _customers,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _LoadError(
                message: _errorMessage(snapshot.error),
                onRetry: _refresh,
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final (route, customers) = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Route No. ${route.routeId} · ${route.town}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${customers.length} customers · ${route.verifiedCount} verified · ${route.unverifiedCount} not verified',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  if (customers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('No customers found.')),
                    ),
                  for (final customer in customers)
                    _CustomerTile(
                      customer: customer,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RouteCustomerPage(
                              routeId: route.routeId,
                              customer: customer,
                              service: widget.service,
                            ),
                          ),
                        );
                        if (mounted) _refresh();
                      },
                    ),
                ],
              ),
            );
          },
        ),
      );
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final RouteCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: customer.verified
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: Icon(
              customer.verified
                  ? Icons.verified_outlined
                  : Icons.person_outline,
              color: customer.verified ? Colors.green : Colors.orange,
            ),
          ),
          title: Text(
            customer.name,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            [
              if (customer.customerType.isNotEmpty) customer.customerType,
              if (customer.verified)
                'Verified${customer.verifiedOn == null ? '' : ' · ${customer.verifiedOn}'}'
              else if (customer.otpPending)
                'OTP requested'
              else
                'Not verified',
            ].join(' · '),
          ),
          trailing: Icon(
            customer.verified ? Icons.check_circle : Icons.chevron_right,
            color: customer.verified ? Colors.green : AppColors.navy,
          ),
        ),
      );
}

class RouteCustomerPage extends StatefulWidget {
  const RouteCustomerPage({
    super.key,
    required this.routeId,
    required this.customer,
    required this.service,
  });

  final int routeId;
  final RouteCustomer customer;
  final RouteService service;

  @override
  State<RouteCustomerPage> createState() => _RouteCustomerPageState();
}

class _RouteCustomerPageState extends State<RouteCustomerPage> {
  late Future<RouteCustomerProfile> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<RouteCustomerProfile> _load() =>
      widget.service.loadCustomer(widget.routeId, widget.customer.customerId);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.customer.name)),
        body: FutureBuilder<RouteCustomerProfile>(
          future: _profile,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _LoadError(
                message: _errorMessage(snapshot.error),
                onRetry: () => setState(() => _profile = _load()),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _RouteCustomerForm(
              key: ValueKey(snapshot.data!.customerId),
              routeId: widget.routeId,
              profile: snapshot.data!,
              service: widget.service,
            );
          },
        ),
      );
}

class _RouteCustomerForm extends StatefulWidget {
  const _RouteCustomerForm({
    super.key,
    required this.routeId,
    required this.profile,
    required this.service,
  });

  final int routeId;
  final RouteCustomerProfile profile;
  final RouteService service;

  @override
  State<_RouteCustomerForm> createState() => _RouteCustomerFormState();
}

class _RouteCustomerFormState extends State<_RouteCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late RouteCustomerProfile _profile;
  late final Map<String, TextEditingController> _fields;
  final _otp = TextEditingController();
  bool _saved = false;
  bool _consent = false;
  bool _busy = false;
  bool _otpQueued = false;

  bool get _readOnly => _profile.verified;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _otpQueued = _profile.otpPending;
    _fields = {
      'Address': TextEditingController(text: _profile.address),
      'State': TextEditingController(text: _profile.state),
      'City': TextEditingController(text: _profile.city),
      'Landmark': TextEditingController(text: _profile.landmark),
      'Pincode': TextEditingController(text: _profile.pincode),
      'Location Link': TextEditingController(text: _profile.locationUrl),
      "Owner's Name": TextEditingController(text: _profile.ownerName),
      'Primary Phone': TextEditingController(text: _profile.primaryPhone),
      'Additional Phone': TextEditingController(text: _profile.additionalPhone),
      'Email ID': TextEditingController(text: _profile.personalEmail),
      'Business Email ID': TextEditingController(text: _profile.businessEmail),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _otp.dispose();
    super.dispose();
  }

  RouteCustomerProfile _editedProfile() => RouteCustomerProfile(
        customerId: _profile.customerId,
        name: _profile.name,
        customerType: _profile.customerType,
        customerTypeId: _profile.customerTypeId,
        verified: _profile.verified,
        verifiedOn: _profile.verifiedOn,
        otpPending: _profile.otpPending,
        address: _fields['Address']!.text.trim(),
        state: _fields['State']!.text.trim(),
        city: _fields['City']!.text.trim(),
        landmark: _fields['Landmark']!.text.trim(),
        pincode: _fields['Pincode']!.text.trim(),
        locationUrl: _fields['Location Link']!.text.trim(),
        ownerName: _fields["Owner's Name"]!.text.trim(),
        primaryPhone: _fields['Primary Phone']!.text.trim(),
        additionalPhone: _fields['Additional Phone']!.text.trim(),
        personalEmail: _fields['Email ID']!.text.trim(),
        businessEmail: _fields['Business Email ID']!.text.trim(),
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final saved = await widget.service.saveCustomer(
        widget.routeId,
        _editedProfile(),
      );
      if (!mounted) return;
      setState(() {
        _profile = saved;
        _saved = true;
        _otpQueued = saved.otpPending;
      });
      _message('Customer details saved.');
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestOtp() async {
    if (!_consent || !_saved) return;
    setState(() => _busy = true);
    try {
      await widget.service.requestConsentOtp(
        widget.routeId,
        _profile.customerId,
      );
      if (!mounted) return;
      setState(() => _otpQueued = true);
      _message(
        'OTP queued in Oracle. SMS delivery is pending gateway integration.',
      );
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final value = _otp.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      _message('Enter the 4-digit customer OTP.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.verifyConsentOtp(
        widget.routeId,
        _profile.customerId,
        value,
      );
      if (!mounted) return;
      _message('Customer consent verified.');
      Navigator.pop(context);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _formKey,
        onChanged: () {
          if (_saved && !_readOnly) setState(() => _saved = false);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              title: 'Customer',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_profile.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (_profile.customerType.isNotEmpty)
                    Text(_profile.customerType,
                        style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            if (_readOnly)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Verified${_profile.verifiedOn == null ? '' : ' on ${_profile.verifiedOn}'}. Customer details are read-only.',
                ),
              ),
            ..._fields.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: TextFormField(
                    controller: entry.value,
                    readOnly: _readOnly || _busy,
                    keyboardType: _keyboardType(entry.key),
                    maxLength: _maxLength(entry.key),
                    validator: (value) => _validateField(entry.key, value),
                    decoration: InputDecoration(
                      labelText: entry.key,
                      counterText: '',
                    ),
                    onChanged: (_) {
                      if (_saved && !_readOnly) {
                        setState(() => _saved = false);
                      }
                    },
                  ),
                )),
            if (!_readOnly) ...[
              FilledButton(
                onPressed: _busy || _saved ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save details'),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _consent = value ?? false),
                title: const Text(
                  'I confirm the customer consents to registering this information on the SDL portal.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              OutlinedButton.icon(
                onPressed: _busy || !_consent || !_saved ? null : _requestOtp,
                icon: const Icon(Icons.sms_outlined),
                label: const Text('Request consent OTP'),
              ),
              if (_otpQueued) ...[
                const SizedBox(height: 8),
                const Text(
                  'OTP is queued. SMS delivery is not configured in the API yet.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otp,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: '4-digit customer OTP',
                    counterText: '',
                  ),
                ),
                FilledButton(
                  onPressed: _busy ? null : _verifyOtp,
                  child: const Text('Verify customer'),
                ),
              ],
            ],
          ],
        ),
      );

  Widget _sectionCard({required String title, required Widget child}) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );

  TextInputType _keyboardType(String field) {
    if (field.contains('Phone') || field == 'Pincode') {
      return TextInputType.number;
    }
    if (field.contains('Email')) return TextInputType.emailAddress;
    if (field == 'Location Link') return TextInputType.url;
    return TextInputType.text;
  }

  int? _maxLength(String field) {
    if (field == 'Address') return 50;
    if (field == 'State' || field == 'Owner\'s Name') return 50;
    if (field == 'City' || field == 'Landmark') return 50;
    if (field == 'Pincode') return 20;
    if (field == 'Location Link') return 500;
    if (field.contains('Email')) return 50;
    if (field.contains('Phone')) return 10;
    return null;
  }

  String? _validateField(String field, String? input) {
    final value = input?.trim() ?? '';
    const requiredFields = {
      'Address',
      'State',
      'City',
      'Pincode',
      'Primary Phone',
      'Email ID',
    };
    if (requiredFields.contains(field) && value.isEmpty) {
      return 'Required';
    }
    if (field == 'Primary Phone' && !RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a 10-digit phone number';
    }
    if (field == 'Additional Phone' &&
        value.isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a 10-digit phone number';
    }
    if (field.contains('Email') &&
        value.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    if (field == "Owner's Name" &&
        value.isEmpty &&
        !_ownerNameOptional(_profile.customerTypeId)) {
      return 'Required for this customer type';
    }
    return null;
  }

  bool _ownerNameOptional(int? customerTypeId) =>
      const {8, 9, 23, 24, 25, 27}.contains(customerTypeId);
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

String _errorMessage(Object? error) =>
    error is ApiException ? error.message : 'Unable to load route information.';
