import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../data/models/category.dart' as models;
import '../../../data/models/product.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _searchQuery = '';
  String? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final productsAsync = ref.watch(adminProductsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.products_management,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800]),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToForm(),
                icon: const Icon(Icons.add),
                label: Text(l10n.add_new_product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.search_products,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: categoriesAsync.when(
                data: (catList) {
                  final categories =
                      catList.whereType<models.Category>().toList();
                  final topLevel = categories
                      .where((models.Category c) => c.parentId == null)
                      .toList();
                  return DropdownButtonFormField<String?>(
                    initialValue: _filterCategoryId,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      ...topLevel.map((models.Category c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nameFr))),
                    ],
                    onChanged: (v) => setState(() => _filterCategoryId = v),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: productsAsync.when(
            data: (productList) {
              final products = productList.whereType<Product>().toList();
              var filtered = products.where((Product p) {
                final name =
                    p.getLocalizedName(locale.languageCode).toLowerCase();
                final matchesSearch = _searchQuery.isEmpty ||
                    name.contains(_searchQuery) ||
                    p.sku.toLowerCase().contains(_searchQuery);
                final matchesCategory = _filterCategoryId == null ||
                    p.categoryId == _filterCategoryId;
                return matchesSearch && matchesCategory;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(l10n.no_products_found,
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminProductsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _ProductCard(product: filtered[index]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ],
    );
  }

  void _navigateToForm([Product? product]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminProductFormScreen(product: product),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final name = product.getLocalizedName(locale.languageCode);
    final isLow = product.stock > 0 && product.stock <= 10;
    final isOut = product.stock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isLow
                ? Colors.orange.withValues(alpha: 0.4)
                : isOut
                    ? Colors.red.withValues(alpha: 0.4)
                    : Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8)),
              child: product.primaryImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(product.primaryImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.inventory_2, color: Colors.grey[400])),
                    )
                  : Icon(Icons.inventory_2, color: Colors.grey[400]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey[800])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${l10n.sku}: ${product.sku}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 16),
                      Text(
                          '${l10n.currency_symbol}${product.basePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: AppColors.deepBlue,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _stockBadge(
                      stock: product.stock,
                      isLow: isLow,
                      isOut: isOut,
                      l10n: l10n),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.grey[600]),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => AdminProductFormScreen(product: product)),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[400]),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockBadge(
      {required int stock,
      required bool isLow,
      required bool isOut,
      required AppLocalizations l10n}) {
    final (color, bg, label) = isOut
        ? (Colors.red[700]!, Colors.red[50]!, l10n.out_of_stock)
        : isLow
            ? (Colors.orange[700]!, Colors.orange[50]!, l10n.low_stock_warning)
            : (
                Colors.green[700]!,
                Colors.green[50]!,
                '$stock ${l10n.in_stock}'
              );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.delete_product_confirmation),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = ref.read(adminRepositoryProvider);
        await repo.deleteProduct(product.id);
        ref.invalidate(adminProductsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.product_deleted)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }
}
