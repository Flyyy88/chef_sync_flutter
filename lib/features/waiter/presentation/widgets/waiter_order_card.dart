import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../orders/domain/models/order_model.dart';

class WaiterOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onServe;

  const WaiterOrderCard({
    super.key,
    required this.order,
    required this.onServe,
  });

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    "#${order.id.substring(0, 6).toUpperCase()}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "READY",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "${item.quantity}x ${item.item.name}",
              ),
            ),
          ),
          const Divider(height: 30),
          Text(
            "Ready Since : ${formatter.format(order.createdAt)}",
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.room_service),
              onPressed: onServe,
              label: const Text("Serve Food"),
            ),
          ),
        ],
      ),
    );
  }
}
