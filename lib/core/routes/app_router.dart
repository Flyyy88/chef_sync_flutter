import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentations/dashboard_screen.dart';
import '../../features/menu/presentation/add_menu_screen.dart';
import '../../features/orders/presentation/pos_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/auth_providers.dart';
import '../../features/authentication/domain/models/user_model.dart';
import '../widgets/main_shell.dart';
import '../../features/kitchen/presentation/kitchen_screen.dart';
import '../../features/waiter/presentation/waiter_screen.dart';
import '../../features/cashier/presentation/cashier_screen.dart';
import '../../features/receipt/presentation/receipt_screen.dart';
import '../../features/orders/domain/models/order_model.dart';
import '../../features/tables/domain/models/table_model.dart';
import '../../features/restaurant/presentation/restaurant_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/menu/domain/models/menu_item.dart';

// ============================================================
// Rute yang diizinkan per role
// Dipakai di redirect guard agar role tidak bisa akses
// halaman yang bukan haknya.
// ============================================================
const _roleHomeRoute = {
  UserRole.admin: '/dashboard',
  UserRole.manager: '/dashboard',
  UserRole.cashier: '/cashier',
  UserRole.waiter: '/waiter',
  UserRole.kitchen: '/kitchen',
};

const _allowedRoutes = {
  UserRole.admin: {
    '/dashboard',
    '/orders',
    '/restaurant',
    '/inventory',
    '/menu',
    '/add-menu',
    '/kitchen',
    '/waiter',
    '/cashier',
    '/receipt'
  },
  UserRole.manager: {
    '/dashboard',
    '/orders',
    '/restaurant',
    '/inventory',
    '/menu',
    '/add-menu',
    '/kitchen',
    '/waiter',
    '/cashier',
    '/receipt'
  },
  UserRole.cashier: {'/dashboard', '/cashier', '/restaurant', '/receipt'},
  UserRole.waiter: {'/orders', '/restaurant', '/waiter'},
  UserRole.kitchen: {'/kitchen'},
};

// ============================================================
// Router provider
//
// Menggunakan `refreshListenable` yang wrap `currentUserPrvdr`
// sehingga setiap perubahan auth state otomatis trigger
// re-evaluate redirect — tanpa perlu manual navigasi di widget.
// ============================================================
final appRouterPrvdr = Provider<GoRouter>((ref) {
  // Notifier yang memberitahu GoRouter kalau stream currentUser berubah
  final notifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
    redirect: (context, state) {
      final authState = ref.read(currentUserPrvdr);
      final location = state.uri.path;
      final isGoingToLogin = location == '/login';
      debugPrint("");
      debugPrint("========== ROUTER ==========");
      debugPrint("PATH : ${state.uri.path}");

      // Saat stream masih loading (app baru buka), jangan redirect dulu
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;

      // Belum login → paksa ke /login
      if (user == null) {
        return isGoingToLogin ? null : '/login';
      }

      // Sudah login tapi mau ke /login → arahkan ke home role-nya
      if (isGoingToLogin) {
        return _roleHomeRoute[user.role] ?? '/dashboard';
      }

      // Cek apakah role punya akses ke halaman yang dituju
      final allowed = _allowedRoutes[user.role] ?? {};
      debugPrint("ROLE : ${user.role}");
      debugPrint("ALLOWED : ${allowed.contains(state.uri.path)}");
      if (!allowed.contains(location)) {
        return _roleHomeRoute[user.role] ?? '/dashboard';
      }

      return null;
    },
    routes: [
      // -------------------------------------------------------
      // Routes TANPA bottom nav
      // -------------------------------------------------------
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/add-menu',
        builder: (context, state) {
          final item = state.extra as MenuItem?;
          return AddMenuScreen(initialItem: item);
        },
      ),
      GoRoute(
        path: '/kitchen',
        builder: (context, state) => const KitchenScreen(),
      ),
      GoRoute(
        path: '/waiter',
        builder: (context, state) => const WaiterScreen(),
      ),
      GoRoute(
        path: '/cashier',
        builder: (context, state) => const CashierScreen(),
      ),
      GoRoute(
        path: '/receipt',
        builder: (context, state) {
          final order = state.extra as OrderModel;

          return ReceiptScreen(
            order: order,
          );
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) {
          final table = state.extra as TableModel?;

          return PosScreen(
            selectedTable: table,
          );
        },
      ),

      // -------------------------------------------------------
      // Routes DENGAN bottom nav (StatefulShellRoute)
      // -------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/restaurant',
              builder: (context, state) => const RestaurantScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inventory',
              builder: (context, state) => const InventoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/menu',
              builder: (context, state) => const MenuScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

// ============================================================
// _RouterRefreshNotifier
//
// Jembatan antara Riverpod stream dan GoRouter refreshListenable.
// GoRouter hanya menerima Listenable (ChangeNotifier / ValueNotifier),
// sedangkan currentUserPrvdr adalah AsyncValue dari StreamProvider.
// Class ini listen perubahan provider lalu notify GoRouter.
// ============================================================
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // ref.listen otomatis dibersihkan saat provider ini di-dispose,
    // jadi tidak perlu simpan/dispose subscription manual.
    ref.listen<AsyncValue<dynamic>>(
      currentUserPrvdr,
      (_, __) => notifyListeners(),
    );
  }
}
