import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../orders/domain/models/order_model.dart';

class ReceiptItemTile extends StatelessWidget {
  final OrderItem item;
  final NumberFormat currency;

  const ReceiptItemTile({
    super.key,
    required this.item,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${item.quantity} x ${item.item.name}",
            ),
          ),
          Text(
            currency.format(item.totalPrice),
          ),
        ],
      ),
    );
  }
}
