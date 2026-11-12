class RouteSummary {
  const RouteSummary({
    required this.routeId,
    required this.town,
    required this.customerCount,
    required this.verifiedCount,
    required this.unverifiedCount,
  });

  final int routeId;
  final String town;
  final int customerCount;
  final int verifiedCount;
  final int unverifiedCount;

  factory RouteSummary.fromJson(Map<String, dynamic> json) => RouteSummary(
        routeId: _requiredInt(json['route_id'], 'route_id'),
        town: _requiredString(json['town'], 'town'),
        customerCount: _requiredInt(json['customer_count'], 'customer_count'),
        verifiedCount: _requiredInt(json['verified_count'], 'verified_count'),
        unverifiedCount:
            _requiredInt(json['unverified_count'], 'unverified_count'),
      );
}

class RouteCustomer {
  const RouteCustomer({
    required this.customerId,
    required this.name,
    required this.customerType,
    required this.verified,
    this.customerTypeId,
    this.verifiedOn,
    this.primaryPhone,
    this.otpPending = false,
  });

  final int customerId;
  final String name;
  final String customerType;
  final int? customerTypeId;
  final bool verified;
  final String? verifiedOn;
  final String? primaryPhone;
  final bool otpPending;

  factory RouteCustomer.fromJson(Map<String, dynamic> json) => RouteCustomer(
        customerId: _requiredInt(json['customer_id'], 'customer_id'),
        name: _requiredString(json['name'], 'name'),
        customerType: json['customer_type']?.toString() ?? '',
        customerTypeId: _int(json['customer_type_id']),
        verified: json['verified'] == true,
        verifiedOn: json['verified_on']?.toString(),
        primaryPhone: json['primary_phone']?.toString(),
        otpPending: json['otp_pending'] == true,
      );
}

class RouteCustomerProfile extends RouteCustomer {
  const RouteCustomerProfile({
    required super.customerId,
    required super.name,
    required super.customerType,
    required super.verified,
    super.customerTypeId,
    super.verifiedOn,
    super.primaryPhone,
    super.otpPending,
    this.address = '',
    this.state = '',
    this.city = '',
    this.pincode = '',
    this.landmark = '',
    this.locationUrl = '',
    this.personalEmail = '',
    this.businessEmail = '',
    this.additionalPhone = '',
    this.ownerName = '',
  });

  final String address;
  final String state;
  final String city;
  final String pincode;
  final String landmark;
  final String locationUrl;
  final String personalEmail;
  final String businessEmail;
  final String additionalPhone;
  final String ownerName;

  factory RouteCustomerProfile.fromJson(Map<String, dynamic> json) =>
      RouteCustomerProfile(
        customerId: _requiredInt(json['customer_id'], 'customer_id'),
        name: _requiredString(json['name'], 'name'),
        customerType: json['customer_type']?.toString() ?? '',
        customerTypeId: _int(json['customer_type_id']),
        verified: json['verified'] == true,
        verifiedOn: json['verified_on']?.toString(),
        primaryPhone: json['primary_phone']?.toString(),
        otpPending: json['otp_pending'] == true,
        address: json['address']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
        landmark: json['landmark']?.toString() ?? '',
        locationUrl: json['location_url']?.toString() ?? '',
        personalEmail: json['personal_email']?.toString() ?? '',
        businessEmail: json['business_email']?.toString() ?? '',
        additionalPhone: json['additional_phone']?.toString() ?? '',
        ownerName: json['owner_name']?.toString() ?? '',
      );

  Map<String, dynamic> toProfileJson() => {
        'address': address,
        'state': state,
        'city': city,
        'pincode': pincode,
        'landmark': landmark,
        'location_url': locationUrl,
        'personal_email': personalEmail,
        'business_email': businessEmail,
        'primary_phone': primaryPhone ?? '',
        'additional_phone': additionalPhone,
        'owner_name': ownerName,
      };
}

int _requiredInt(dynamic value, String field) {
  final parsed = _int(value);
  if (parsed == null) {
    throw FormatException('The route response has an invalid $field.');
  }
  return parsed;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String _requiredString(dynamic value, String field) {
  final parsed = value?.toString().trim() ?? '';
  if (parsed.isEmpty) {
    throw FormatException('The route response has an invalid $field.');
  }
  return parsed;
}
