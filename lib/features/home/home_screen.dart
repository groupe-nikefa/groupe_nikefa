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

            // Featured products grid
            featuredAsync.when(
              data: (products) => _buildFeaturedProductsGrid(
                context,
                products,
                currentLocale.languageCode,
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SizedBox(
                height: 200,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.failed_to_load_featured_products,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
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
    String localeCode,
  ) {
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
        return _FeaturedProductCard(product: product, localeCode: localeCode);
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

  const _FeaturedProductCard({
    required this.product,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
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

                  // Featured badge
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
                      child: const Text(
                        '★ Featured',
                        style: TextStyle(
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
                      '${product.effectivePrice.toStringAsFixed(2)} DZD',
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
