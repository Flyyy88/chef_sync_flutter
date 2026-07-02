import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../orders/domain/models/order_model.dart';

class ReceiptSummary extends StatelessWidget {
  final OrderModel order;
  final NumberFormat currency;

  const ReceiptSummary({
    super.key,
    required this.order,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(
          "Subtotal",
          currency.format(order.subtotal),
        ),
        _row(
          "Tax",
          currency.format(order.calculatedTax),
        ),
        _row(
          "Service",
          currency.format(
            order.calculatedServiceCharge,
          ),
        ),
        const Divider(),
        _row(
          "TOTAL",
          currency.format(order.grandTotal),
          bold: true,
        ),
      ],
    );
  }

  Widget _row(
    String left,
    String right, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
