import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/order_providers.dart';

import 'widgets/kitchen_empty_state.dart';
import 'widgets/kitchen_section.dart';
import '../../dashboard/presentations/dashboard_providers.dart';

class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(todayOrdersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kitchen Display"),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text(e.toString()),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const KitchenEmptyState();
          }

          final pending =
              orders.where((e) => e.status == OrderStatus.pending).toList();

          final preparing =
              orders.where((e) => e.status == OrderStatus.preparing).toList();

          final ready =
              orders.where((e) => e.status == OrderStatus.ready).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KitchenSection(
                  title: "Pending",
                  orders: pending,
                  onAction: (order) async {
                    await ref.read(orderRepositoryProvider).updateOrderStatus(
                          order.id,
                          OrderStatus.preparing,
                        );
                  },
                ),
                KitchenSection(
                  title: "Preparing",
                  orders: preparing,
                  onAction: (order) async {
                    await ref.read(orderRepositoryProvider).updateOrderStatus(
                          order.id,
                          OrderStatus.ready,
                        );
                    ref.invalidate(todayOrdersProvider);
                    ref.invalidate(dashboardStatsProvider);
                  },
                ),
                KitchenSection(
                  title: "Ready",
                  orders: ready,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
