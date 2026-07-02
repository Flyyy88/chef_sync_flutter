import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../orders/domain/models/order_model.dart';

import 'widgets/receipt_action_buttons.dart';
import 'widgets/receipt_header.dart';
import 'widgets/receipt_item_tile.dart';
import 'widgets/receipt_summary.dart';

class ReceiptScreen extends StatelessWidget {
  final OrderModel order;

  const ReceiptScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("========== RECEIPT OPEN ==========");
    debugPrint(order.invoiceNumber);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipt"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ReceiptHeader(
              order: order,
              dateFormat: dateFormat,
            ),
            const SizedBox(height: 24),
            ...order.items.map(
              (item) => ReceiptItemTile(
                item: item,
                currency: currency,
              ),
            ),
            const Divider(height: 40),
            ReceiptSummary(
              order: order,
              currency: currency,
            ),
            const SizedBox(height: 30),
            ReceiptActionButtons(
              order: order,
            ),
          ],
        ),
      ),
    );
  }
}
