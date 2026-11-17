import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../models/price_list_data.dart';
import '../../providers/employee_provider.dart';
import '../../services/price_list_service.dart';

class PriceListPage extends StatefulWidget {
  const PriceListPage({super.key});

  @override
  State<PriceListPage> createState() => _PriceListPageState();
}

class _PriceListPageState extends State<PriceListPage> {
  final PriceListService _service = PriceListService();
  final TextEditingController _searchController = TextEditingController();
  late Future<PriceListData> _priceList;
  String _query = '';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _priceList = _service.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final request = _service.load();
    setState(() => _priceList = request);
    await request;
  }

  @override
  Widget build(BuildContext context) {
    final divisionName =
        context.watch<EmployeeProvider>().employee?.divisionName;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Price List'),
            if (divisionName != null && divisionName.isNotEmpty)
              Text(divisionName, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      body: FutureBuilder<PriceListData>(
        future: _priceList,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PriceListError(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Unable to load the price list.',
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCatalogue(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildCatalogue(BuildContext context, PriceListData data) {
    final categories = data.categories;
    final filteredCategories = categories
        .where((category) =>
            _selectedCategoryId == null || category.id == _selectedCategoryId)
        .map((category) {
          final products = category.products.where((product) {
            return product.name.toLowerCase().contains(_query);
          }).toList(growable: false);
          return _CategoryResults(category: category, products: products);
        })
        .where((result) => result.products.isNotEmpty)
        .toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryChip(
                label: 'All',
                count: data.productCount,
                selected: _selectedCategoryId == null,
                onSelected: () => setState(() => _selectedCategoryId = null),
              ),
              for (final category in categories)
                _CategoryChip(
                  label: category.name,
                  count: category.products.length,
                  selected: _selectedCategoryId == category.id,
                  onSelected: () =>
                      setState(() => _selectedCategoryId = category.id),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (filteredCategories.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No products found.')),
                  )
                else
                  for (final result in filteredCategories) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverList.separated(
                        itemCount: result.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => _ProductTile(
                          key: ValueKey(
                            '${result.category.id}-${result.products[index].id}-$index',
                          ),
                          product: result.products[index],
                        ),
                      ),
                    ),
                  ],
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryResults {
  const _CategoryResults({
    required this.category,
    required this.products,
  });

  final PriceListCategory category;
  final List<PriceListProduct> products;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          selected: selected,
          onSelected: (_) => onSelected(),
          showCheckmark: false,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.navy.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white : AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          selectedColor: AppColors.navy,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? AppColors.navy : AppColors.border,
          ),
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({super.key, required this.product});

  final PriceListProduct product;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: AppColors.navy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${product.rate.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _PriceListError extends StatelessWidget {
  const _PriceListError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
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
