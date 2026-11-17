import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/route_data.dart';
import '../../services/route_service.dart';

class SmsTestPage extends StatefulWidget {
  const SmsTestPage({super.key, this.service});

  final RouteService? service;

  @override
  State<SmsTestPage> createState() => _SmsTestPageState();
}

class _SmsTestPageState extends State<SmsTestPage> {
  late final RouteService _service;
  late Future<List<RouteSummary>> _routes;
  Future<(RouteSummary, List<RouteCustomer>)>? _customers;
  final TextEditingController _otp = TextEditingController();

  RouteSummary? _selectedRoute;
  int? _selectedCustomerId;
  int? _verifiedCustomerId;
  bool _consent = false;
  bool _busy = false;
  bool _otpSent = false;
  String? _status;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? RouteService();
    _routes = _service.loadRoutes();
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _reloadRoutes() {
    setState(() => _routes = _service.loadRoutes());
  }

  void _selectRoute(int? routeId, List<RouteSummary> routes) {
    RouteSummary? selected;
    for (final route in routes) {
      if (route.routeId == routeId) {
        selected = route;
        break;
      }
    }
    final route = selected;
    if (route == null) return;

    setState(() {
      _selectedRoute = route;
      _customers = _service.loadCustomers(route.routeId, route);
      _selectedCustomerId = null;
      _verifiedCustomerId = null;
      _consent = false;
      _otpSent = false;
      _otp.clear();
      _status = null;
    });
  }

  void _selectCustomer(int? customerId) {
    if (customerId == null) return;
    setState(() {
      _selectedCustomerId = customerId;
      _verifiedCustomerId = null;
      _consent = false;
      _otpSent = false;
      _otp.clear();
      _status = null;
    });
  }

  RouteCustomer? _selectedCustomer(List<RouteCustomer> customers) {
    for (final customer in customers) {
      if (customer.customerId == _selectedCustomerId) return customer;
    }
    return null;
  }

  Future<void> _sendOtp(RouteCustomer customer) async {
    final route = _selectedRoute;
    if (route == null || !_consent || customer.verified) return;

    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _service.requestConsentOtp(route.routeId, customer.customerId);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _status = "Consent OTP sent. Check the customer's registered phone.";
        _statusIsError = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = error.message;
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp(RouteCustomer customer) async {
    final route = _selectedRoute;
    final value = _otp.text.trim();
    if (route == null) return;
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      setState(() {
        _status = 'Enter the 4-digit customer OTP.';
        _statusIsError = true;
      });
      return;
    }

    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await _service.verifyConsentOtp(route.routeId, customer.customerId, value);
      if (!mounted) return;
      setState(() {
        _verifiedCustomerId = customer.customerId;
        _status = 'Customer consent verified successfully.';
        _statusIsError = false;
        _customers = _service.loadCustomers(route.routeId, route);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _status = error.message;
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('SMS Test')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.navy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This sends a real consent OTP to an existing route customer. '
                        "Use only with the customer's consent; the customer's profile "
                        'must have a valid primary phone number.',
                        style: TextStyle(color: Colors.blueGrey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _routeSelector(),
            if (_customers != null) ...[
              const SizedBox(height: 12),
              _customerSelector(),
            ],
          ],
        ),
      );

  Widget _routeSelector() => FutureBuilder<List<RouteSummary>>(
        future: _routes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(
              message: _errorMessage(snapshot.error),
              onRetry: _reloadRoutes,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final routes = snapshot.data!;
          if (routes.isEmpty) {
            return const Text('No routes found.');
          }

          return DropdownButtonFormField<int>(
            initialValue: _selectedRoute?.routeId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Route',
              prefixIcon: Icon(Icons.route_outlined),
            ),
            items: routes
                .map((route) => DropdownMenuItem(
                      value: route.routeId,
                      child: Text('${route.routeId} - ${route.town}'),
                    ))
                .toList(),
            onChanged:
                _busy ? null : (routeId) => _selectRoute(routeId, routes),
          );
        },
      );

  Widget _customerSelector() => FutureBuilder<
          (RouteSummary, List<RouteCustomer>)>(
        future: _customers,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(
              message: _errorMessage(snapshot.error),
              onRetry: () {
                final route = _selectedRoute;
                if (route != null) {
                  setState(() => _customers =
                      _service.loadCustomers(route.routeId, route));
                }
              },
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final (route, customers) = snapshot.data!;
          if (customers.isEmpty) {
            return const Text('No customers found for this route.');
          }
          final customer = _selectedCustomer(customers);
          final isVerified = customer != null &&
              (customer.verified ||
                  _verifiedCustomerId == customer.customerId);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                key: ValueKey(route.routeId),
                initialValue: customer?.customerId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: customers
                    .map((item) => DropdownMenuItem(
                          value: item.customerId,
                          child: Text(item.name),
                        ))
                    .toList(),
                onChanged: _busy
                    ? null
                    : (customerId) =>
                        _selectCustomer(customerId),
              ),
              if (customer != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (customer.customerType.isNotEmpty)
                          Text(
                            customer.customerType,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        const SizedBox(height: 6),
                        Text(_phoneDescription(customer.primaryPhone)),
                        if (isVerified) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Consent is already verified for this customer.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ] else ...[
                          if (customer.otpPending)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'An OTP request is already pending. Ask the customer for the code before requesting another.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _consent,
                            onChanged: _busy
                                ? null
                                : (value) => setState(
                                      () => _consent = value ?? false,
                                    ),
                            title: const Text(
                              'The customer has agreed to receive and share a consent OTP.',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          FilledButton.icon(
                            onPressed: _busy ||
                                    !_consent ||
                                    _otpSent ||
                                    (customer.primaryPhone?.trim().isEmpty ??
                                        true)
                                ? null
                                : () => _sendOtp(customer),
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sms_outlined),
                            label: Text(
                              _otpSent
                                  ? 'OTP sent'
                                  : 'Send consent OTP',
                            ),
                          ),
                          if (_otpSent || customer.otpPending) ...[
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
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _verifyOtp(customer),
                              icon: const Icon(Icons.verified_outlined),
                              label: const Text('Verify OTP'),
                            ),
                          ],
                        ],
                        if (_status != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _status!,
                            style: TextStyle(
                              color: _statusIsError
                                  ? Colors.red
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      );

  String _phoneDescription(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'No primary phone number saved.';
    final suffix = digits.length <= 4 ? digits : digits.substring(digits.length - 4);
    return 'OTP will be sent to the registered phone ending $suffix.';
  }

  String _errorMessage(Object? error) => error is ApiException
      ? error.message
      : 'Unable to load SMS test options: $error';
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      );
}
