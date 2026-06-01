import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class AdminShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShellScreen({super.key, required this.child});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  int _selectedIndex = 0;

  static const _routes = [
    '/admin/dashboard',
    '/admin/products',
    '/admin/categories',
    '/admin/orders',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _routes.indexWhere((r) => location.startsWith(r));
    if (idx >= 0 && idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final currentLocale = ref.watch(localeProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    final currentUser = ref.watch(currentUserProvider);

    final items = [
      _NavItem(l10n.dashboard, Icons.dashboard_outlined),
      _NavItem(l10n.products, Icons.inventory_2_outlined),
      _NavItem(l10n.category, Icons.category_outlined),
      _NavItem(l10n.orders, Icons.shopping_cart_outlined),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            const SizedBox(width: 12),
            Text(l10n.admin_panel, style: const TextStyle(fontSize: 20)),
          ],
        ),
        elevation: 2,
        actions: [
          TextButton.icon(
            onPressed: () {
              final newLocale =
                  isArabic ? const Locale('fr') : const Locale('ar');
              ref.read(localeProvider.notifier).state = newLocale;
            },
            icon: Icon(Icons.language, color: Colors.white, size: 20),
            label: Text(
              isArabic ? 'FR' : 'عربي',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop) _buildSideNav(items, currentUser),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) {
                setState(() => _selectedIndex = i);
                context.go(_routes[i]);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.deepBlue,
              items: items
                  .map((item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        label: item.label,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildSideNav(List<_NavItem> items, dynamic currentUser) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.deepBlue.withValues(alpha: 0.1),
                  child:
                      Icon(Icons.person, color: AppColors.deepBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    currentUser?.email.split('@').first ?? 'Admin',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    items[index].icon,
                    color: isSelected ? AppColors.deepBlue : Colors.grey[600],
                  ),
                  title: Text(
                    items[index].label,
                    style: TextStyle(
                      color: isSelected ? AppColors.deepBlue : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.deepBlue.withValues(alpha: 0.08),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    context.go(_routes[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
