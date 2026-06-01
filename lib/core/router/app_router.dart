import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/account_type.dart';
import '../../features/cart/providers/cart_provider.dart';

import '../../features/home/home_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/password_reset_screen.dart';
import '../../features/product_detail/screens/product_detail_screen.dart';
import '../../features/admin/screens/admin_shell_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_products_screen.dart';
import '../../features/admin/screens/admin_categories_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/admin_order_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();
final adminShellNavigatorKey = GlobalKey<NavigatorState>();
final appShellScaffoldKey = GlobalKey<ScaffoldState>();

final appShellScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return appShellScaffoldKey;
});

GoRouter? _cachedRouter;

void invalidateRouter() {
  _cachedRouter = null;
}

GoRouter createRouter() {
  if (_cachedRouter != null) return _cachedRouter!;

  _cachedRouter = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    errorPageBuilder: (context, state) {
      return MaterialPage(
        child: Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: const Center(child: Text('The requested page does not exist.')),
        ),
      );
    },
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context, listen: false);
      final isAuthenticated = container.read(isAuthenticatedProvider);
      final isAdmin = container.read(isAdminProvider);
      final isOffline = container.read(isOfflineProvider).valueOrNull ?? false;

      // Fallback: check Supabase session directly in case Riverpod
      // hasn't resolved yet (e.g., after hot reload/restart).
      final hasSession = Supabase.instance.client.auth.currentSession != null;

      final currentPath = state.matchedLocation;

      final protectedRoutes = ['/checkout', '/orders', '/admin', '/profile'];
      final isProtectedRoute =
          protectedRoutes.any((r) => currentPath.startsWith(r));

      if (!isAuthenticated && !hasSession && isProtectedRoute) return '/login';

      if ((isAuthenticated || hasSession) &&
          (currentPath == '/login' || currentPath == '/register')) return '/';

      if (currentPath.startsWith('/admin') && !isAdmin) return '/';

      if (isOffline) {
        final networkRoutes = ['/catalog', '/cart', '/orders'];
        if (networkRoutes.contains(currentPath)) return '/';
      }

      return null;
    },
    refreshListenable: authChangeNotifier,
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
              path: '/',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: HomeScreen())),
          GoRoute(
              path: '/catalog',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: CatalogScreen())),
          GoRoute(
              path: '/cart',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: CartScreen())),
          GoRoute(
              path: '/orders',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: OrdersScreen())),
          GoRoute(
              path: '/profile',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
      ShellRoute(
        navigatorKey: adminShellNavigatorKey,
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AdminHomeScreen()),
          ),
          GoRoute(
            path: '/admin/products',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AdminProductsScreen()),
          ),
          GoRoute(
            path: '/admin/categories',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AdminCategoriesScreen()),
          ),
          GoRoute(
            path: '/admin/orders',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: AdminOrdersScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) {
                  final orderId = state.pathParameters['id']!;
                  return NoTransitionPage(
                      child: AdminOrderDetailScreen(orderId: orderId));
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/admin', redirect: (_, __) => '/admin/dashboard'),
      GoRoute(
          path: '/login',
          pageBuilder: (_, __) => const NoTransitionPage(child: LoginScreen())),
      GoRoute(
          path: '/register',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: RegisterScreen())),
      GoRoute(
          path: '/password-reset',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: PasswordResetScreen())),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (_, state) => NoTransitionPage(
            child: ProductDetailScreen(productId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: EditProfileScreen()),
      ),
      GoRoute(
          path: '/checkout',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: CheckoutScreen())),
      GoRoute(
        path: '/orders/:id',
        pageBuilder: (_, state) => NoTransitionPage(
            child: OrderDetailScreen(orderId: state.pathParameters['id']!)),
      ),
    ],
  );

  return _cachedRouter!;
}

class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentPath = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      key: appShellScaffoldKey,
      body: Column(
        children: [
          Expanded(child: child),
          if (user == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/login'),
                      child: Text(l10n.login),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.go('/register'),
                      child: Text(l10n.register),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndexFor(currentPath, user != null),
        onTap: (index) {
          final routes = user != null
              ? ['/', '/catalog', '/cart', '/orders', '/profile']
              : ['/', '/catalog', '/cart'];
          if (index < routes.length) context.go(routes[index]);
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined), label: l10n.home),
          BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_outlined), label: l10n.catalog),
          BottomNavigationBarItem(
            icon: const _CartIconWithBadge(),
            label: l10n.cart,
          ),
          if (user != null) ...[
            BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_outlined),
                label: l10n.orders),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline), label: l10n.profile),
          ],
        ],
      ),
      drawer: user != null
          ? Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFFFECB00)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(user.email,
                            style: const TextStyle(
                                color: Color(0xFF002664),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(user.isAdmin ? 'Admin' : user.accountType.dbValue,
                            style: const TextStyle(
                                color: Color(0xFF002664), fontSize: 12)),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(l10n.profile),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/profile');
                    },
                  ),
                  if (user.isAdmin)
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: Text(l10n.admin),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/admin/dashboard');
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(l10n.logout),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) context.go('/');
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }

  int _selectedIndexFor(String path, bool isAuthenticated) {
    if (path == '/') return 0;
    if (path == '/catalog' || path.startsWith('/product/')) return 1;
    if (path == '/cart') return 2;
    if (isAuthenticated) {
      if (path == '/orders' || path.startsWith('/orders/')) return 3;
      if (path == '/profile' || path.startsWith('/profile/')) return 4;
    }
    return 0;
  }
}

class _CartIconWithBadge extends ConsumerWidget {
  const _CartIconWithBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined),
          cartCount.when(
            data: (count) {
              if (count == 0) return const SizedBox.shrink();
              return Positioned(
                top: -6,
                right: -10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
