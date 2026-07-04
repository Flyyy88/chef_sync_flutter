import 'package:flutter/material.dart';

import '../../domain/models/table_model.dart';

extension TableStatusExtension on TableStatus {
  Color get color {
    switch (this) {
      case TableStatus.available:
        return const Color(0xFF2E7D32);
      case TableStatus.occupied:
        return const Color(0xFFC62828);
      case TableStatus.reserved:
        return const Color(0xFF1565C0);
      case TableStatus.cleaning:
        return const Color(0xFFEF6C00);
    }
  }

  String get label {
    switch (this) {
      case TableStatus.available:
        return "Available";
      case TableStatus.occupied:
        return "Occupied";
      case TableStatus.reserved:
        return "Reserved";
      case TableStatus.cleaning:
        return "Cleaning";
    }
  }
}

class TableStatusChip extends StatelessWidget {
  final TableStatus status;

  const TableStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status.color;
    final statusLabel = status.label;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
