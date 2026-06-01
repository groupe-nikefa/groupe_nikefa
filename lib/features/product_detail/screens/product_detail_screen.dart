// Product detail screen — full product information with image carousel,
// variant selection, bulk pricing, and add-to-cart functionality.
//
// Features:
//   - Swipeable image carousel with zoom
//   - Product title, SKU, medical classification tags
//   - Dynamic price based on selected variant
//   - Variant selector (packaging options)
//   - Realtime stock indicator
//   - Add to cart button (disabled if out of stock)
//   - Full description with RTL/LTR auto-direction
//   - Related products section

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../catalog/providers/catalog_providers.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_variant.dart';
import '../../../data/models/medical_classification.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final localeCode = currentLocale.languageCode;

    final productAsync = ref.watch(productByIdProvider(widget.productId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: user != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  ref
                      .read(appShellScaffoldKeyProvider)
                      .currentState
                      ?.openDrawer();
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final productUrl =
                  'https://nikefa.net/app/#/product/${widget.productId}';
              Clipboard.setData(ClipboardData(text: productUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.share_product_copied),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) => _buildProductDetail(context, product, localeCode),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.red),
              const SizedBox(height: 16),
              Text(l10n.something_went_wrong),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the full product detail view.
  Widget _buildProductDetail(
    BuildContext context,
    Product product,
    String localeCode,
  ) {
    // Select first variant by default if available.
    if (_selectedVariant == null && product.variants.isNotEmpty) {
      _selectedVariant = product.variants.first;
    }

    // Calculate effective price.
    final effectivePrice = _selectedVariant != null
        ? _selectedVariant!.getPriceForQuantity(_quantity)
        : product.basePrice;

    final isInStock = _selectedVariant != null
        ? _selectedVariant!.isInStock
        : product.hasStock;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel
          _buildImageCarousel(product),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product title and SKU
                Text(
                  product.getLocalizedName(localeCode),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product.sku}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),

                // Medical classification tags
                if (product.medicalClassifications.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.medicalClassifications
                        .map((value) {
                          final classification =
                              parseMedicalClassification(value);
                          if (classification == null)
                            return const SizedBox.shrink();
                          return _ClassificationChip(
                            classification: classification,
                          );
                        })
                        .whereType<Widget>()
                        .toList(),
                  ),

                const SizedBox(height: 16),
                const Divider(),

                // Price display
                _buildPriceSection(effectivePrice, product, localeCode),

                const SizedBox(height: 16),

                // Stock indicator
                _buildStockIndicator(isInStock, product, localeCode),

                const SizedBox(height: 24),

                // Variant selector
                if (product.variants.isNotEmpty) _buildVariantSelector(product),

                const SizedBox(height: 24),

                // Quantity selector
                _buildQuantitySelector(),

                const SizedBox(height: 24),

                // Add to cart button
                _buildAddToCartButton(isInStock, effectivePrice),

                const SizedBox(height: 24),
                const Divider(),

                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.getLocalizedDescription(localeCode) ??
                      'No description available',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign:
                      localeCode == 'ar' ? TextAlign.right : TextAlign.left,
                ),

                const SizedBox(height: 24),

                // Bulk pricing section
                if (_selectedVariant?.bulkPricing.isNotEmpty ?? false)
                  _buildBulkPricingSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the swipeable image carousel.
  Widget _buildImageCarousel(Product product) {
    if (product.images.isEmpty) {
      return Container(
        height: 300,
        color: AppColors.surface,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Image view with page view for swiping
          PageView.builder(
            itemCount: product.images.length,
            onPageChanged: (index) {
              setState(() => _selectedImageIndex = index);
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: product.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),

          // Image counter
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedImageIndex + 1}/${product.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Image indicators
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedImageIndex == index
                        ? AppColors.goldenYellow
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the price display section.
  Widget _buildPriceSection(
    double price,
    Product product,
    String localeCode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${price.toStringAsFixed(2)} DZD',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.deepBlue,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (_selectedVariant != null && _quantity > 1)
          Text(
            'Total: ${(price * _quantity).toStringAsFixed(2)} DZD',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
      ],
    );
  }

  /// Builds the stock indicator.
  Widget _buildStockIndicator(
    bool isInStock,
    Product product,
    String localeCode,
  ) {
    final stockText = isInStock
        ? (localeCode == 'ar' ? 'متوفر في المخزون' : 'In Stock')
        : (localeCode == 'ar' ? 'غير متوفر' : 'Out of Stock');

    final stockCount = _selectedVariant?.stock ?? product.stock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isInStock
            ? Colors.green.withValues(alpha: 0.1)
            : AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInStock ? Colors.green : AppColors.red,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInStock ? Icons.check_circle : Icons.cancel,
            color: isInStock ? Colors.green : AppColors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            stockText,
            style: TextStyle(
              color: isInStock ? Colors.green : AppColors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isInStock) ...[
            const SizedBox(width: 8),
            Text(
              '($stockCount available)',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the variant selector for packaging options.
  Widget _buildVariantSelector(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Packaging Option',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: product.variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            return ChoiceChip(
              label: Text(
                  '${variant.name} - ${variant.price.toStringAsFixed(2)} DZD'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedVariant = variant);
                }
              },
              selectedColor: AppColors.goldenYellow.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds the quantity selector.
  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed:
                  _quantity > 1 ? () => setState(() => _quantity--) : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _quantity.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _quantity++),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the add to cart button.
  Widget _buildAddToCartButton(bool isInStock, double price) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: isInStock && !_isAddingToCart
            ? () async {
                setState(() => _isAddingToCart = true);

                Map<String, dynamic>? variantSelection;
                if (_selectedVariant != null) {
                  variantSelection = {
                    'variant_id': _selectedVariant!.id,
                    'name': _selectedVariant!.name,
                  };
                }

                final success =
                    await ref.read(cartActionProvider.notifier).addToCart(
                          productId: widget.productId,
                          quantity: _quantity,
                          variantSelection: variantSelection,
                        );

                if (!mounted) return;

                setState(() => _isAddingToCart = false);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Added to cart'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  final error = ref.read(cartActionProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error == 'exceeds_stock'
                          ? 'Insufficient stock'
                          : l10n.something_went_wrong),
                      backgroundColor: AppColors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            : null,
        icon: _isAddingToCart
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_shopping_cart),
        label: _isAddingToCart
            ? const Text('Adding...')
            : Text(
                isInStock ? l10n.add_to_cart : 'Out of Stock',
                style: const TextStyle(fontSize: 16),
              ),
        style: FilledButton.styleFrom(
          backgroundColor: isInStock ? AppColors.deepBlue : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Builds the bulk pricing expandable section.
  Widget _buildBulkPricingSection() {
    return ExpansionTile(
      title: Text(
        'Bulk Pricing',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      children: [
        ...(_selectedVariant!.bulkPricing.map((tier) {
          return ListTile(
            leading: const Icon(Icons.local_offer),
            title: Text(
              '${tier.minQty}${tier.maxQty != null ? '-${tier.maxQty}' : '+'} units',
            ),
            trailing: Text(
              '${tier.unitPrice.toStringAsFixed(2)} DZD/unit',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.deepBlue,
              ),
            ),
          );
        }).toList()),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Classification Chip Widget
// ──────────────────────────────────────────────────────────────

/// Chip displaying a medical classification.
class _ClassificationChip extends StatelessWidget {
  final MedicalClassification classification;

  const _ClassificationChip({required this.classification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.deepBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.deepBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            classification.icon,
            size: 14,
            color: AppColors.deepBlue,
          ),
          const SizedBox(width: 4),
          Text(
            classification.dbValue,
            style: const TextStyle(
              color: AppColors.deepBlue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
