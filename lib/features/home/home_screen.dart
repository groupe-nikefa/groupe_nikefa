// Home screen — landing page with featured products and language switcher.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/brand_name.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/providers/auth_provider.dart';
import '../catalog/providers/catalog_providers.dart';
import '../../data/demo/demo_products.dart';
import '../../data/models/product.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final featuredAsync = ref.watch(featuredProductsProvider);
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
        title: const BrandNameCompact(),
        actions: [
          // Language toggle button in the AppBar
          IconButton(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLocale.languageCode == 'ar' ? 'FR' : 'عربي',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.language, size: 20),
              ],
            ),
            onPressed: () {
              // Toggle between Arabic and French
              final newLocale = currentLocale.languageCode == 'ar'
                  ? const Locale('fr')
                  : const Locale('ar');
              ref.read(localeProvider.notifier).state = newLocale;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            _buildHeroSection(context, l10n),

            const SizedBox(height: 24),

            // Featured products section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.featured_products,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 16),

            // Featured products grid (demo catalog fallback for sales demos)
            featuredAsync.when(
              data: (products) => _buildFeaturedProductsGrid(
                context,
                products.isEmpty ? demoProducts : products,
                currentLocale.languageCode,
                isDemo: products.isEmpty,
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => _buildFeaturedProductsGrid(
                context,
                demoProducts,
                currentLocale.languageCode,
                isDemo: true,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Builds the hero section with tagline and CTA.
  Widget _buildHeroSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.deepBlue,
            AppColors.deepBlue.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.app_tagline,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/catalog'),
            icon: const Icon(Icons.grid_view_outlined),
            label: Text(l10n.browse_catalog),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.goldenYellow,
              foregroundColor: AppColors.deepBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the featured products grid.
  Widget _buildFeaturedProductsGrid(
    BuildContext context,
    List<Product> products,
    String localeCode, {
    bool isDemo = false,
  }) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No featured products available'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _FeaturedProductCard(
          product: product,
          localeCode: localeCode,
          isDemo: isDemo || isDemoProduct(product),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Featured Product Card
// ──────────────────────────────────────────────────────────────

/// Simplified product card for the home page featured section.
class _FeaturedProductCard extends StatelessWidget {
  final Product product;
  final String localeCode;
  final bool isDemo;

  const _FeaturedProductCard({
    required this.product,
    required this.localeCode,
    this.isDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (isDemo) {
            showDemoProductSheet(context, product, localeCode);
          } else {
            context.push('/product/${product.id}');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: product.primaryImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  // Featured / demo badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldenYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDemo ? '★ Demo' : '★ Featured',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.getLocalizedName(localeCode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      '${product.effectivePrice.toStringAsFixed(2)} FCFA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.deepBlue,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Demo product sheet (display-only, for sales demos without backend)
// ──────────────────────────────────────────────────────────────

/// Shows an attractive bottom sheet for demo products.
///
/// Demo products have no backend record, so instead of navigating to
/// the detail page (which streams from Supabase), we present the
/// product inline with a call-to-action toward the live catalog.
void showDemoProductSheet(
  BuildContext context,
  Product product,
  String localeCode,
) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Demo image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.primaryImageUrl,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 240,
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 240,
                      color: AppColors.deepBlue.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        size: 64,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          localeCode == 'ar'
                              ? '★ منتج تجريبي'
                              : '★ Produit démo',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.getLocalizedName(localeCode),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.sku,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${product.effectivePrice.toStringAsFixed(0)} FCFA',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.deepBlue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            localeCode == 'ar'
                                ? 'متوفر — ${product.stock} قطعة'
                                : 'En stock — ${product.stock} unités',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        product.getLocalizedDescription(localeCode) ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            context.push('/catalog');
                          },
                          icon: const Icon(Icons.grid_view_outlined),
                          label: Text(l10n.browse_catalog),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.goldenYellow,
                            foregroundColor: AppColors.deepBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
