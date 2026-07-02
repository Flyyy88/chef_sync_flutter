import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/table_model.dart';
import 'table_providers.dart';
import 'widgets/table_card.dart';
import 'widgets/table_empty_state.dart';

class TableScreen extends ConsumerWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tableListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tables"),
        centerTitle: true,
      ),
      body: tablesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text(
            "Error\n$error",
            textAlign: TextAlign.center,
          ),
        ),
        data: (tables) {
          if (tables.isEmpty) {
            return const TableEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tables.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (context, index) {
              final table = tables[index];

              return TableCard(
                table: table,
                onTap: () {
                  context.push(
                    '/orders',
                    extra: table,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
