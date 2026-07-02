import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dashboard/presentations/dashboard_providers.dart';
import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/order_providers.dart';
import '../../tables/presentation/table_providers.dart';

import 'cashier_providers.dart';
import 'widgets/cashier_empty_state.dart';
import 'widgets/cashier_order_card.dart';

class CashierScreen extends ConsumerWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servedOrders = ref.watch(servedOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settlement"),
      ),
      body: servedOrders.isEmpty
          ? const CashierEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: servedOrders.length,
              itemBuilder: (context, index) {
                final order = servedOrders[index];

                return CashierOrderCard(
                  order: order,
                  onComplete: (paymentMethod) async {
                    try {
                      final receiptOrder = order.copyWith(
                        status: OrderStatus.completed,
                        paymentMethod: paymentMethod,
                        paidAt: DateTime.now(),
                        invoiceNumber: "INV-TEST",
                      );

                      if (context.mounted) {
                        await context.push(
                          '/receipt',
                          extra: receiptOrder,
                        );
                      }

                      await ref.read(orderRepositoryProvider).completeOrder(
                            order,
                            paymentMethod: paymentMethod,
                          );

                      ref.invalidate(todayOrdersProvider);
                      ref.invalidate(tableListProvider);
                      ref.invalidate(dashboardStatsProvider);
                    } catch (e, s) {
                      debugPrint("========== CASHIER ERROR ==========");
                      debugPrint(e.toString());
                      debugPrintStack(stackTrace: s);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: $e"),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
