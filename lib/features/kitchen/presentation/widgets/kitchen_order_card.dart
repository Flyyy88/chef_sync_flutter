import 'package:flutter/material.dart';

import '../../../orders/domain/models/order_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class KitchenOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onAction;

  const KitchenOrderCard({
    super.key,
    required this.order,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = order.status == OrderStatus.pending;
    final isPreparing = order.status == OrderStatus.preparing;

    final duration = DateTime.now().difference(order.createdAt);

    final elapsed = "${duration.inHours.toString().padLeft(2, '0')}:"
        "${(duration.inMinutes % 60).toString().padLeft(2, '0')}";

    final formatter = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //---------------------------------------------------
          // HEADER
          //---------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Table ${order.tableId}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "#${order.id.substring(0, 6).toUpperCase()}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: order.status),
            ],
          ),

          //---------------------------------------------------
          // ORDER ITEMS
          //---------------------------------------------------

          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "${item.quantity}x ${item.item.name}",
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),

          const Divider(height: 28),

          //---------------------------------------------------
          // TIME
          //---------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Created : ${formatter.format(order.createdAt)}",
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  elapsed,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (order.generalNotes != null && order.generalNotes!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Note : ${order.generalNotes}",
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          //---------------------------------------------------
          // BUTTON
          //---------------------------------------------------

          if (isPending)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                child: const Text("Start Cooking"),
              ),
            ),

          if (isPreparing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                child: const Text("Mark Ready"),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;

      case OrderStatus.preparing:
        color = AppTheme.primaryColor;
        break;

      case OrderStatus.ready:
        color = Colors.green;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
