import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/table_model.dart';
import 'table_providers.dart';
import 'widgets/table_card.dart';
import 'widgets/table_empty_state.dart';

class TableScreen extends ConsumerWidget {
  const TableScreen({
    super.key,
    this.onTableTap,
    this.searchQuery = '',
    this.selectedFilter = 'All',
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final void Function(BuildContext context, TableModel table)? onTableTap;
  final String searchQuery;
  final String selectedFilter;

  /// Padding applied around the grid. Callers should pass the same
  /// horizontal padding used by the header/search bar above it so table
  /// cards line up with the rest of the page instead of hugging the
  /// screen edges at a different inset.
  final EdgeInsets padding;

  static void openPOS(BuildContext context, TableModel table) {
    context.push(
      '/orders',
      extra: table,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tableListProvider);

    return tablesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(
            "Error loading tables\n$error",
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (tables) {
        // Apply status filter chip
        var filteredTables = tables;
        if (selectedFilter != 'All') {
          final filterStatusName = selectedFilter.toLowerCase();
          filteredTables = filteredTables.where((t) {
            return t.status.name == filterStatusName;
          }).toList();
        }

        // Apply search bar query
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          filteredTables = filteredTables.where((t) {
            return t.label.toLowerCase().contains(query);
          }).toList();
        }

        if (filteredTables.isEmpty) {
          return const TableEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            // Responsive grid columns:
            // Mobile: 2 columns
            // Tablet: 3-4 columns (width >= 600 -> 3, width >= 900 -> 4)
            // Desktop: 4-6 columns (width >= 1200 -> 6)
            int crossAxisCount;
            if (width >= 1200) {
              crossAxisCount = 6;
            } else if (width >= 900) {
              crossAxisCount = 4;
            } else if (width >= 600) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            // Calculate childAspectRatio dynamically based on available width
            // to maintain a premium card design of height ~180px and prevent overflow
            final double cardWidth = (width -
                    (crossAxisCount - 1) * 16 -
                    padding.horizontal) /
                crossAxisCount;
            const double targetHeight = 180.0;
            final double childAspectRatio = (cardWidth / targetHeight).clamp(0.85, 1.4);

            return GridView.builder(
              padding: padding,
              itemCount: filteredTables.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final table = filteredTables[index];

                return TableCard(
                  table: table,
                  onTap: () {
                    final onTableTap = this.onTableTap;

                    if (onTableTap != null) {
                      onTableTap(context, table);
                      return;
                    }

                    openPOS(context, table);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
