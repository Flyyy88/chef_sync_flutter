import 'package:flutter/material.dart';

import '../../../orders/domain/models/order_model.dart';
import 'kitchen_order_card.dart';

class KitchenSection extends StatelessWidget {
  final String title;
  final List<OrderModel> orders;
  final void Function(OrderModel order)? onAction;

  const KitchenSection({
    super.key,
    required this.title,
    required this.orders,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title (${orders.length})",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...orders.map(
          (order) => KitchenOrderCard(
            order: order,
            onAction: onAction == null ? null : () => onAction!(order),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
