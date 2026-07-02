import 'package:flutter/material.dart';

import '../../domain/models/table_model.dart';

class TableStatusChip extends StatelessWidget {
  final TableStatus status;

  const TableStatusChip({
    super.key,
    required this.status,
  });

  Color get color {
    switch (status) {
      case TableStatus.available:
        return Colors.green;

      case TableStatus.occupied:
        return Colors.orange;

      case TableStatus.reserved:
        return Colors.blue;

      case TableStatus.cleaning:
        return Colors.red;
    }
  }

  String get label {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
