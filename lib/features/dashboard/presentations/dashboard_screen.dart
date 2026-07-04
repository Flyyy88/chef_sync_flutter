import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../orders/domain/models/order_model.dart';
import '../../../core/theme/app_theme.dart';
import 'dashboard_providers.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../../core/responsive/responsive_padding.dart';
import '../../../core/theme/design_tokens.dart';
import '../widgets/active_orders_card.dart';
import '../widgets/occupancy_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/revenue_hero_card.dart';
import '../widgets/status_badge.dart';

/// Enterprise dashboard: a clear top-to-bottom story rather than a grid of
/// equally-weighted tiles — Header -> Today's Summary (hero revenue card +
/// supporting stats) -> Recent Orders -> Quick Actions.
///
/// Layout decisions are driven by `LayoutBuilder`'s local constraints
/// rather than `MediaQuery.of(context).size.width`. That distinction
/// matters now that `MainShell` puts a persistent sidebar/rail next to
/// this screen on tablet and desktop: MediaQuery still reports the full
/// window width, but the content pane the dashboard actually has to fill
/// is narrower than that. Measuring locally keeps the two/three-column
/// breakpoints accurate regardless of how much chrome the shell adds.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorLight,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth;
            final horizontalPadding =
                ResponsivePadding.horizontalForWidth(contentWidth);
            final sectionGap = contentWidth < 400 ? 28.0 : 36.0;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardStatsProvider);
                await ref.read(dashboardStatsProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(),
                      SizedBox(height: sectionGap),
                      _SectionLabel(
                        eyebrow: "TODAY'S SUMMARY",
                        title: 'Store performance',
                      ),
                      const SizedBox(height: 16),
                      statsAsync.when(
                        data: (stats) => _SummarySection(stats: stats),
                        loading: () => const _SummarySkeleton(),
                        error: (e, _) => _ErrorBox(message: '$e'),
                      ),
                      SizedBox(height: sectionGap),
                      _SectionLabel(
                        eyebrow: 'LIVE FEED',
                        title: 'Recent orders',
                      ),
                      const SizedBox(height: 16),
                      statsAsync.when(
                        data: (stats) =>
                            _RecentOrdersList(orders: stats.recentOrders),
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                      ),
                      SizedBox(height: sectionGap),
                      _SectionLabel(
                        eyebrow: 'SHORTCUTS',
                        title: 'Quick actions',
                      ),
                      const SizedBox(height: 16),
                      _QuickActionsGrid(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingFor(now.hour);
    final dateLabel = DateFormat('EEEE, d MMMM').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHEFSYNC ENTERPRISE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _ProfileMenu(),
      ],
    );
  }

  String _greetingFor(int hour) {
    if (hour < 11) return 'Good morning';
    if (hour < 15) return 'Good afternoon';
    if (hour < 19) return 'Good evening';
    return 'Good evening';
  }
}

class _ProfileMenu extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserPrvdr);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconAction(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        userAsync.when(
          data: (user) {
            if (user == null) return const SizedBox();

            return PopupMenuButton<String>(
              offset: const Offset(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.lgRadius,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(
                      color: AppTheme.borderColorStrong, width: 1.5)),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                  child: const Icon(Icons.person,
                      size: 18, color: AppTheme.secondaryColor),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'logout') {
                  await ref.read(authNotifierPrvdr.notifier).logout();
                }
              },
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: AppTheme.borderColorStrong, width: 1.5),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 19, color: AppTheme.secondaryColor),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionLabel({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  final DashboardStats stats;

  const _SummarySection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final availableTables =
        stats.totalTables - stats.occupiedTables - stats.reservedTables;
    final completedOrders = stats.recentOrders
        .where((o) => o.status == OrderStatus.completed)
        .length;

    final hero = RevenueHeroCard(
      amountText: currency.format(stats.totalSalesToday),
      completedOrders: completedOrders,
      occupancyRate: stats.occupancyRate,
    );

    final activeOrdersCard = ActiveOrdersCard(
      preparingCount: stats.preparingCount,
      readyCount: stats.readyCount,
    );
    final occupancyCard = OccupancyCard(
      occupied: stats.occupiedTables,
      reserved: stats.reservedTables,
      total: stats.totalTables,
    );
    final availableTablesCard = _AvailableTablesCard(
      available: availableTables,
      total: stats.totalTables,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 14.0;

        // Desktop (>=900): hero sits beside the three stat cards, stacked
        // in a column. Every card sizes to its own content — no forced
        // equal heights — so a card with a long value or a wrapped pill
        // never gets clipped by its neighbor's height.
        if (width >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: hero),
              const SizedBox(width: 16),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    activeOrdersCard,
                    const SizedBox(height: spacing),
                    occupancyCard,
                    const SizedBox(height: spacing),
                    availableTablesCard,
                  ],
                ),
              ),
            ],
          );
        }

        // Tablet (600-899): hero on top, Active Orders and Occupancy sit
        // side by side via Wrap (each card still reports its own natural
        // height), Available Tables takes the full width below.
        if (width >= 600) {
          final pairWidth = (width - spacing) / 2;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: spacing),
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(width: pairWidth, child: activeOrdersCard),
                  SizedBox(width: pairWidth, child: occupancyCard),
                ],
              ),
              const SizedBox(height: spacing),
              availableTablesCard,
            ],
          );
        }

        // Mobile (<600): everything stacks in a single column, each card
        // full width and free to grow to whatever height its content
        // needs.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            const SizedBox(height: spacing),
            activeOrdersCard,
            const SizedBox(height: spacing),
            occupancyCard,
            const SizedBox(height: spacing),
            availableTablesCard,
          ],
        );
      },
    );
  }
}

class _AvailableTablesCard extends StatelessWidget {
  final int available;
  final int total;

  const _AvailableTablesCard({required this.available, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppShadows.low,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'AVAILABLE TABLES',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: AppRadius.smRadius,
                ),
                child: const Icon(
                  Icons.event_seat_outlined,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$available / $total',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ready for new guests',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not load dashboard data: $message',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  final List<OrderModel> orders;

  const _RecentOrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: AppShadows.low,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 32, color: AppTheme.textTertiary),
            const SizedBox(height: 10),
            const Text(
              'No orders yet today',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppShadows.low,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppTheme.borderColor),
        itemBuilder: (context, i) {
          final order = orders[i];
          final isReady = order.status == OrderStatus.ready;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.06),
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    size: 18,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order.itemsSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                StatusBadge(
                    label: order.status.name.toUpperCase(), isActive: isReady),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        if (constraints.maxWidth >= 900) {
          columns = 5;
        } else if (constraints.maxWidth >= 600) {
          columns = 4;
        } else {
          columns = 3;
        }

        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        final buttons = [
          QuickActionButton(
            label: 'New Order',
            icon: Icons.add_circle_outline,
            isPrimary: true,
            onTap: () => context.go('/restaurant'),
          ),
          QuickActionButton(
            label: 'Kitchen',
            icon: Icons.soup_kitchen_outlined,
            onTap: () => context.push('/kitchen'),
          ),
          QuickActionButton(
            label: 'Waiter',
            icon: Icons.room_service_outlined,
            onTap: () => context.push('/waiter'),
          ),
          QuickActionButton(
            label: 'Settlement',
            icon: Icons.receipt_long_outlined,
            onTap: () => context.push('/cashier'),
          ),
          QuickActionButton(
            label: 'Day Report',
            icon: Icons.print_outlined,
            onTap: () => _showComingSoon(context, 'Day Report'),
          ),
        ];

        // Wrap lets each button size to its own content (icon + up to two
        // lines of label) instead of being forced into a fixed
        // childAspectRatio cell that clipped longer labels.
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final button in buttons)
              SizedBox(width: itemWidth, child: button),
          ],
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$feature" is coming soon.')),
    );
  }
}
