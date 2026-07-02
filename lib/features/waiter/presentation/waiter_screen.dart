import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/order_providers.dart';

import 'waiter_providers.dart';
import 'widgets/waiter_empty_state.dart';
import 'widgets/waiter_order_card.dart';
import '../../dashboard/presentations/dashboard_providers.dart';

class WaiterScreen extends ConsumerWidget {
  const WaiterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readyOrders = ref.watch(readyOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Waiter"),
      ),
      body: readyOrders.isEmpty
          ? const WaiterEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: readyOrders.length,
              itemBuilder: (context, index) {
                final order = readyOrders[index];

                return WaiterOrderCard(
                  order: order,
                  onServe: () async {
                    await ref.read(orderRepositoryProvider).updateOrderStatus(
                          order.id,
                          OrderStatus.served,
                        );
                    ref.invalidate(todayOrdersProvider);
                    ref.invalidate(dashboardStatsProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Order ${order.tableId} telah disajikan",
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
