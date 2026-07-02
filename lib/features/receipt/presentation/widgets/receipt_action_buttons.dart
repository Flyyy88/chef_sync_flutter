import 'package:flutter/material.dart';

import '../../../orders/domain/models/order_model.dart';

class ReceiptActionButtons extends StatelessWidget {
  final OrderModel order;

  const ReceiptActionButtons({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.print),
            label: const Text("Print Receipt"),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ),
      ],
    );
  }
}
