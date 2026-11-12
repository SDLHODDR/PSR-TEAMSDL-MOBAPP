class PriceListCategory {
  const PriceListCategory({
    required this.id,
    required this.name,
    required this.sequence,
    required this.products,
  });

  final int id;
  final String name;
  final int sequence;
  final List<PriceListProduct> products;

  factory PriceListCategory.fromJson(Map<String, dynamic> json) {
    final productsValue = json['products'];
    if (productsValue is! List) {
      throw const FormatException('Invalid price-list category products.');
    }

    return PriceListCategory(
      id: _requiredInt(json['category_id'], 'category_id'),
      name: _requiredString(json['name'], 'category name'),
      sequence: _int(json['sequence']) ?? 0,
      products: productsValue.map((value) {
        if (value is! Map) {
          throw const FormatException('Invalid price-list product.');
        }
        return PriceListProduct.fromJson(Map<String, dynamic>.from(value));
      }).toList(growable: false),
    );
  }
}

class PriceListProduct {
  const PriceListProduct({
    required this.id,
    required this.name,
    required this.rate,
  });

  final int id;
  final String name;
  final double rate;

  factory PriceListProduct.fromJson(Map<String, dynamic> json) {
    final rate = _double(json['rate']);
    if (rate == null || rate < 0) {
      throw const FormatException('Invalid product rate.');
    }
    return PriceListProduct(
      id: _requiredInt(json['product_id'], 'product_id'),
      name: _requiredString(json['name'], 'product name'),
      rate: rate,
    );
  }
}

class PriceListData {
  const PriceListData({
    required this.effectiveDate,
    required this.categories,
  });

  final String effectiveDate;
  final List<PriceListCategory> categories;

  factory PriceListData.fromJson(Map<String, dynamic> json) {
    final categoriesValue = json['categories'];
    if (categoriesValue is! List) {
      throw const FormatException('Invalid price-list categories.');
    }
    final categories = categoriesValue.map((value) {
      if (value is! Map) {
        throw const FormatException('Invalid price-list category.');
      }
      return PriceListCategory.fromJson(Map<String, dynamic>.from(value));
    }).toList(growable: false)
      ..sort((left, right) => left.sequence.compareTo(right.sequence));
    return PriceListData(
      effectiveDate: json['effective_date']?.toString() ?? '',
      categories: categories,
    );
  }

  int get productCount =>
      categories.fold(0, (total, category) => total + category.products.length);
}

int _requiredInt(dynamic value, String field) {
  final parsed = _int(value);
  if (parsed == null) {
    throw FormatException('Invalid price-list $field.');
  }
  return parsed;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String _requiredString(dynamic value, String field) {
  final parsed = value?.toString().trim() ?? '';
  if (parsed.isEmpty) throw FormatException('Invalid price-list $field.');
  return parsed;
}
