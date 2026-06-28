import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/presentation/order_providers.dart';
import '../../orders/domain/models/order_model.dart';
import '../../tables/presentation/table_providers.dart';
import '../../tables/domain/models/table_model.dart';

class DashboardStats {
  final double totalSalesToday;
  final int preparingCount;
  final int readyCount;
  final int occupiedTables;
  final int reservedTables;
  final int totalTables;
  final List<OrderModel> recentOrders;

  DashboardStats({
    required this.totalSalesToday,
    required this.preparingCount,
    required this.readyCount,
    required this.occupiedTables,
    required this.reservedTables,
    required this.totalTables,
    required this.recentOrders,
  });

  int get activeOrdersCount => preparingCount + readyCount;
  double get occupancyRate => totalTables == 0 ? 0 : occupiedTables / totalTables;
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  // watch .future supaya auto-refresh kalau todayOrdersProvider/tableListProvider di-invalidate
  final orders = await ref.watch(todayOrdersProvider.future);
  final tables = await ref.watch(tableListProvider.future);

  final totalSales = orders
      .where((o) => o.status == OrderStatus.completed)
      .fold<double>(0, (sum, o) => sum + o.grandTotal);

  final preparing = orders.where((o) => o.status == OrderStatus.preparing).length;
  final ready = orders.where((o) => o.status == OrderStatus.ready).length;

  final occupied = tables.where((t) => t.status == TableStatus.occupied).length;
  final reserved = tables.where((t) => t.status == TableStatus.reserved).length;

  final recent = List<OrderModel>.from(orders)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return DashboardStats(
    totalSalesToday: totalSales,
    preparingCount: preparing,
    readyCount: ready,
    occupiedTables: occupied,
    reservedTables: reserved,
    totalTables: tables.length,
    recentOrders: recent.take(4).toList(),
  );
});
