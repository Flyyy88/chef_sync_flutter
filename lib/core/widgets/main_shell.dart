import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../../features/authentication/presentation/auth_providers.dart';

/// The four destinations behind the shell. Order and routes are exactly
/// what `app_router.dart`'s StatefulShellRoute already expects — this is
/// purely a display-layer description of that existing structure, not a
/// new source of truth for it.
class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem(this.label, this.icon, this.selectedIcon);
}

const _navItems = [
  _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
  _NavItem('Restaurant', Icons.restaurant_outlined, Icons.restaurant_rounded),
  _NavItem('Inventory', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
  _NavItem('Menu', Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded),
];

/// Adaptive shell:
///  - < 600px  : bottom navigation bar (thumb reach, mobile POS-on-the-go)
///  - 600-1199 : collapsed navigation rail (tablets used front-of-house)
///  - >= 1200  : full sidebar with brand lockup + account footer
///  (Odoo / Stripe Dashboard territory - nav is a permanent part of the
///  frame, not a drawer you have to summon.)
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  void _onSelect(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final layout = shellLayoutFor(width);

    if (layout == ShellLayout.compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: _CompactBottomBar(
          currentIndex: navigationShell.currentIndex,
          onSelect: _onSelect,
        ),
      );
    }

    final expanded = layout == ShellLayout.expanded;

    return Scaffold(
      body: Row(
        children: [
          expanded
              ? _ExpandedSidebar(
                  currentIndex: navigationShell.currentIndex,
                  onSelect: _onSelect,
                )
              : _MediumRail(
                  currentIndex: navigationShell.currentIndex,
                  onSelect: _onSelect,
                ),
          const VerticalDivider(width: 1, color: AppTheme.borderColor),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ===========================================================================
// Compact: bottom bar (mobile)
// ===========================================================================
class _CompactBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _CompactBottomBar({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.medium,
        border: const Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: selected ? AppTheme.primaryColor : AppTheme.textTertiary,
                        size: 23,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.primaryColor : AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Medium: icon rail (tablet) - labels on, no brand lockup, saves width
// ===========================================================================
class _MediumRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _MediumRail({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const _BrandMark(compact: true),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final selected = i == currentIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: selected ? AppTheme.primaryColor.withOpacity(0.10) : Colors.transparent,
                      borderRadius: AppRadius.mdRadius,
                      child: InkWell(
                        borderRadius: AppRadius.mdRadius,
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              Icon(
                                selected ? item.selectedIcon : item.icon,
                                color: selected ? AppTheme.primaryColor : AppTheme.textTertiary,
                                size: 21,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? AppTheme.primaryColor : AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const _RailAccountFooter(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Expanded: full sidebar (desktop / web) - brand + labelled nav + account
// ===========================================================================
class _ExpandedSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _ExpandedSidebar({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: _BrandMark(compact: false),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'WORKSPACE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final selected = i == currentIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: selected ? AppTheme.primaryColor.withOpacity(0.10) : Colors.transparent,
                      borderRadius: AppRadius.mdRadius,
                      child: InkWell(
                        borderRadius: AppRadius.mdRadius,
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                selected ? item.selectedIcon : item.icon,
                                size: 19,
                                color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 13),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                                ),
                              ),
                              if (selected) ...[
                                const Spacer(),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _SidebarAccountCard(),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Shared pieces
// ===========================================================================
class _BrandMark extends StatelessWidget {
  final bool compact;
  const _BrandMark({required this.compact});

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppRadius.smRadius,
      ),
      alignment: Alignment.center,
      child: const Text(
        'CS',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );

    if (compact) return mark;

    return Row(
      children: [
        mark,
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'ChefSync',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryColor,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RailAccountFooter extends ConsumerWidget {
  const _RailAccountFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserPrvdr);
    return userAsync.maybeWhen(
      data: (user) => CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.secondaryColor.withOpacity(0.08),
        child: Text(
          (user != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w700),
        ),
      ),
      orElse: () => const SizedBox(height: 32),
    );
  }
}

class _SidebarAccountCard extends ConsumerWidget {
  const _SidebarAccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserPrvdr);

    return userAsync.maybeWhen(
      data: (user) {
        if (user == null) return const SizedBox();
        return Material(
          color: AppTheme.backgroundColorLight,
          borderRadius: AppRadius.mdRadius,
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
            onTap: () => _showAccountSheet(context, ref, user.name, user.email),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.secondaryColor.withOpacity(0.08),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.secondaryColor),
                        ),
                        Text(
                          user.role.name,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert, size: 16, color: AppTheme.textTertiary),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox(),
    );
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref, String name, String email) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColorStrong,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            ListTile(
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(email),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text('Log out', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierPrvdr.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
