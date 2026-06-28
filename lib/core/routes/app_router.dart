import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentations/dashboard_screen.dart';
import '../../features/menu/presentation/add_menu_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/auth_providers.dart';
import '../../features/authentication/domain/models/user_model.dart';
import '../widgets/main_shell.dart';

// ============================================================
// Rute yang diizinkan per role
// Dipakai di redirect guard agar role tidak bisa akses
// halaman yang bukan haknya.
// ============================================================
const _roleHomeRoute = {
  UserRole.admin:   '/dashboard',
  UserRole.manager: '/dashboard',
  UserRole.cashier: '/orders',
  UserRole.waiter:  '/orders',
  UserRole.kitchen: '/kitchen',
};

const _allowedRoutes = {
  UserRole.admin:   {'/dashboard', '/orders', '/tables', '/inventory', '/menu', '/add-menu', '/kitchen'},
  UserRole.manager: {'/dashboard', '/orders', '/tables', '/inventory', '/menu', '/add-menu', '/kitchen'},
  UserRole.cashier: {'/dashboard', '/orders', '/tables'},
  UserRole.waiter:  {'/orders', '/tables'},
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
      final location = state.uri.toString();
      final isGoingToLogin = location == '/login';

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
        builder: (context, state) => const AddMenuScreen(),
      ),
      GoRoute(
        path: '/kitchen',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Kitchen Display Screen')),
        ),
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
              path: '/orders',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Orders / POS Screen')),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tables',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Tables Screen')),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inventory',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Inventory Screen')),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/menu',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Menu List Screen')),
              ),
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
