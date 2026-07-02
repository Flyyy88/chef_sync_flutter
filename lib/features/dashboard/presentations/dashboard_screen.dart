import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../orders/domain/models/order_model.dart';
import '../../../core/theme/app_theme.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorLight,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          await ref.read(dashboardStatsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingHeader(),
              const SizedBox(height: 24),
              statsAsync.when(
                data: (stats) => _buildBentoGrid(stats),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _buildErrorBox('$e'),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("Recent Orders"),
              const SizedBox(height: 16),
              statsAsync.when(
                data: (stats) => _buildRecentOrdersList(stats.recentOrders),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("Quick Actions"),
              const SizedBox(height: 16),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Emerald Bistro",
            style: TextStyle(
                color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined,
                color: AppTheme.secondaryColor),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(backgroundColor: Color(0xFFE5E7EB)),
          ),
        ],
      );

  Widget _buildGreetingHeader() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("STORE OVERVIEW",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppTheme.primaryColor)),
          SizedBox(height: 4),
          Text("Good Evening, Chef",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildErrorBox(String message) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
        ),
        child: Text(
          'Gagal memuat data dashboard: $message',
          style: const TextStyle(color: AppTheme.errorColor),
        ),
      );

  Widget _buildBentoGrid(DashboardStats stats) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Column(
      children: [
        _StatCard(
          title: "TOTAL SALES TODAY",
          icon: Icons.payments_outlined,
          iconColor: AppTheme.primaryColor,
          value: currency.format(stats.totalSalesToday),
        ),
        const SizedBox(height: 12),
        _ActiveOrdersCard(
          preparingCount: stats.preparingCount,
          readyCount: stats.readyCount,
        ),
        const SizedBox(height: 12),
        _OccupancyCard(
          occupied: stats.occupiedTables,
          reserved: stats.reservedTables,
          total: stats.totalTables,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));

  Widget _buildRecentOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text("Belum ada order hari ini",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, i) {
          final order = orders[i];
          final isReady = order.status == OrderStatus.ready;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '#${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor)),
                      const SizedBox(height: 4),
                      Text(order.itemsSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                _StatusBadge(
                    label: order.status.name.toUpperCase(), isActive: isReady),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _QuickActionButton(
            label: "New Order",
            icon: Icons.add_circle_outline,
            isPrimary: true,
            onTap: () => context.push('/orders'),
          ),
          _QuickActionButton(
            label: "Kitchen",
            icon: Icons.soup_kitchen_outlined,
            onTap: () => context.push('/kitchen'),
          ),
          _QuickActionButton(
            label: "Waiter",
            icon: Icons.room_service_outlined,
            onTap: () => context.push('/waiter'),
          ),
          _QuickActionButton(
            label: "Settlement",
            icon: Icons.receipt_long_outlined,
            onTap: () => context.push('/cashier'),
          ),
          _QuickActionButton(
            label: "Day Report",
            icon: Icons.print_outlined,
            onTap: () => _showComingSoon(context, "Day Report"),
          ),
        ]);
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur "$feature" akan segera hadir.')),
    );
  }
}

// === Reusable Small Widgets ===

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _ActiveOrdersCard extends StatelessWidget {
  final int preparingCount;
  final int readyCount;
  const _ActiveOrdersCard(
      {required this.preparingCount, required this.readyCount});

  @override
  Widget build(BuildContext context) {
    final total = preparingCount + readyCount;
    final readyRatio = total == 0 ? 0.0 : readyCount / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ACTIVE ORDERS",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.outdoor_grill_outlined,
                    color: AppTheme.secondaryColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$total',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('In Preparation ($preparingCount)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text('Ready ($readyCount)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : readyRatio,
              minHeight: 8,
              backgroundColor: AppTheme.secondaryColor.withOpacity(0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  final int occupied;
  final int reserved;
  final int total;
  const _OccupancyCard(
      {required this.occupied, required this.reserved, required this.total});

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0 : ((occupied / total) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TABLE OCCUPANCY",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_restaurant_outlined,
                    color: Colors.amber, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$rate%',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _Pill(
                  text: '$occupied/$total TABLES',
                  color: AppTheme.primaryColor),
              _Pill(text: '$reserved RESERVED', color: AppTheme.errorColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  const _StatusBadge({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryColor.withOpacity(0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color:
                    isActive ? AppTheme.primaryColor : Colors.grey.shade600)),
      );
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: isPrimary ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border:
                  isPrimary ? null : Border.all(color: Colors.grey.shade200),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: isPrimary ? Colors.white : AppTheme.primaryColor),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPrimary
                            ? Colors.white
                            : AppTheme.secondaryColor)),
              ],
            ),
          ),
        ),
      );
}
