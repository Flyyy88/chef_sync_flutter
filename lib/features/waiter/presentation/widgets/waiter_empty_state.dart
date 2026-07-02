import 'package:flutter/material.dart';

class WaiterEmptyState extends StatelessWidget {
  const WaiterEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.room_service_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "Belum ada pesanan siap diantar",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Order READY akan muncul otomatis.",
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
