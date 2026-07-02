import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../orders/domain/models/order_model.dart';

class ReceiptHeader extends StatelessWidget {
  final OrderModel order;
  final DateFormat dateFormat;

  const ReceiptHeader({
    super.key,
    required this.order,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "EMERALD BISTRO",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          order.invoiceNumber ?? "-",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Table"),
            Text(order.tableId),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Payment"),
            Text(order.paymentMethod?.name ?? "-"),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Date"),
            Text(dateFormat.format(
              order.paidAt ?? order.createdAt,
            )),
          ],
        ),
      ],
    );
  }
}
