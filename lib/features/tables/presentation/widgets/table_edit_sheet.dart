import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/table_model.dart';
import '../table_providers.dart';

class TableEditSheet extends ConsumerStatefulWidget {
  final TableModel table;

  const TableEditSheet({
    super.key,
    required this.table,
  });

  @override
  ConsumerState<TableEditSheet> createState() => _TableEditSheetState();
}

class _TableEditSheetState extends ConsumerState<TableEditSheet> {
  late TableStatus status;
  late TextEditingController guestController;

  @override
  void initState() {
    super.initState();

    status = widget.table.status;

    guestController = TextEditingController(
      text: widget.table.activeGuests.toString(),
    );
  }

  @override
  void dispose() {
    guestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.table.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<TableStatus>(
                value: status,
                decoration: const InputDecoration(
                  labelText: "Status",
                ),
                items: TableStatus.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    status = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: guestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Guests",
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final guests = int.tryParse(guestController.text) ?? 0;

                    await ref.read(tableRepositoryProvider).updateTableStatus(
                          widget.table.id,
                          status,
                          orderId: widget.table.activeOrderId,
                          guests: guests,
                        );

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
