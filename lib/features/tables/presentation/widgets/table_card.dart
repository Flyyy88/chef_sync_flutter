import 'package:flutter/material.dart';

import '../../domain/models/table_model.dart';
import 'table_status_chip.dart';
import 'table_edit_sheet.dart';

class TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback? onTap;

  const TableCard({
    super.key,
    required this.table,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          builder: (_) => TableEditSheet(
            table: table,
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.table_restaurant,
                size: 34,
                color: Color(0xff004AC6),
              ),
              const Spacer(),
              Text(
                table.label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TableStatusChip(
                status: table.status,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.event_seat,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${table.seatingCapacity} Seats",
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (table.activeGuests > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${table.activeGuests} Guests",
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
