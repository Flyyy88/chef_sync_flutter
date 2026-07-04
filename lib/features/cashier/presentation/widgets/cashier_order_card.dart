import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../orders/domain/models/order_model.dart';

class CashierOrderCard extends StatelessWidget {
  final OrderModel order;
  final Future<void> Function(PaymentMethod paymentMethod) onComplete;

  const CashierOrderCard({
    super.key,
    required this.order,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );

    final formatter = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //-------------------------------------------------
          // HEADER
          //-------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Table ${order.tableId}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                  color: Colors.blue.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "SERVED",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          //-------------------------------------------------
          // ITEM LIST
          //-------------------------------------------------
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${item.quantity}x ${item.item.name}",
                    ),
                  ),
                  Text(
                    currency.format(item.totalPrice),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          //-------------------------------------------------
          // TOTAL
          //-------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatter.format(order.createdAt),
              ),
              Text(
                currency.format(order.grandTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          //-------------------------------------------------
          // BUTTON
          //-------------------------------------------------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payments),
              label: const Text("Complete Payment"),
              onPressed: () async {
                final method = await showModalBottomSheet<PaymentMethod>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => const _PaymentMethodSheet(),
                );

                if (method != null) {
                  await onComplete(method);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

//======================================================
// PAYMENT METHOD SHEET
//======================================================

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet();

  @override
  Widget build(BuildContext context) {
    // No fixed dialog height: the sheet is capped at 90% of the screen
    // height and 480 wide (so it stays a comfortable dialog size on
    // tablets), and only the *content* inside scrolls if it doesn't fit —
    // the sheet itself (and the screen behind it) never scrolls.
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Payment Method",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTile(
                  context,
                  Icons.payments,
                  "Cash",
                  PaymentMethod.cash,
                ),
                _buildTile(
                  context,
                  Icons.qr_code,
                  "QRIS",
                  PaymentMethod.qris,
                ),
                _buildTile(
                  context,
                  Icons.credit_card,
                  "Debit Card",
                  PaymentMethod.debitCard,
                ),
                _buildTile(
                  context,
                  Icons.credit_card,
                  "Credit Card",
                  PaymentMethod.creditCard,
                ),
                _buildTile(
                  context,
                  Icons.account_balance_wallet,
                  "E-Wallet",
                  PaymentMethod.eWallet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    PaymentMethod method,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context, method);
      },
    );
  }
}
