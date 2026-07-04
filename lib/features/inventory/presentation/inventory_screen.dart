import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive_padding.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/inventory_item.dart';
import 'inventory_providers.dart';
import 'widgets/inventory_card.dart';
import 'widgets/restock_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _query = '';
  String _filter = 'All';

  static const _filters = ['All', 'Low Stock', 'In Stock'];

  void _openRestock(InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RestockSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryListProvider);
    final horizontalPadding = ResponsivePadding.horizontal(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorLight,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inventoryListProvider);
            await ref.read(inventoryListProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 20, horizontalPadding, 0),
                  child: const _InventoryHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: inventoryAsync.when(
                  data: (items) => Padding(
                    padding: EdgeInsets.fromLTRB(
                        horizontalPadding, 20, horizontalPadding, 0),
                    child: _InventoryStatsRow(items: items),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 20, horizontalPadding, 0),
                  child: _SearchAndFilters(
                    query: _query,
                    selectedFilter: _filter,
                    filters: _filters,
                    onQueryChanged: (v) => setState(() => _query = v),
                    onFilterChanged: (v) => setState(() => _filter = v),
                  ),
                ),
              ),
              inventoryAsync.when(
                data: (items) {
                  var filtered = items;
                  if (_filter == 'Low Stock') {
                    filtered = filtered.where((i) => i.isLowStock).toList();
                  } else if (_filter == 'In Stock') {
                    filtered = filtered.where((i) => !i.isLowStock).toList();
                  }
                  if (_query.isNotEmpty) {
                    final q = _query.toLowerCase();
                    filtered = filtered
                        .where((i) =>
                            i.ingredientName.toLowerCase().contains(q) ||
                            i.supplier.toLowerCase().contains(q))
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _InventoryEmptyState(
                          hasQuery: _query.isNotEmpty || _filter != 'All'),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        horizontalPadding, 20, horizontalPadding, 32),
                    sliver: SliverToBoxAdapter(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int columns;
                          if (constraints.maxWidth >= 1200) {
                            columns = 4;
                          } else if (constraints.maxWidth >= 900) {
                            columns = 3;
                          } else if (constraints.maxWidth >= 600) {
                            columns = 2;
                          } else {
                            columns = 1;
                          }

                          const spacing = 14.0;
                          final cardWidth =
                              (constraints.maxWidth - (columns - 1) * spacing) /
                                  columns;

                          // Wrap lets every card report its own natural
                          // height (long ingredient names, long supplier
                          // names, etc. simply take more vertical space)
                          // instead of forcing all cards in a row into an
                          // identical, aspect-ratio-derived height.
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              for (final item in filtered)
                                SizedBox(
                                  width: cardWidth,
                                  child: InventoryCard(
                                    item: item,
                                    onRestock: () => _openRestock(item),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor)),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Failed to load inventory: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STOCK CONTROL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Inventory',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Track ingredient stock levels and suppliers',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}

class _InventoryStatsRow extends StatelessWidget {
  final List<InventoryItem> items;

  const _InventoryStatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final lowStock = items.where((i) => i.isLowStock).length;
    final total = items.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 2 : 1;
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _MiniStat(
                label: 'Total Ingredients',
                value: '$total',
                icon: Icons.inventory_2_outlined,
                color: AppTheme.secondaryColor,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MiniStat(
                label: 'Needs Restock',
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                color:
                    lowStock > 0 ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  final String query;
  final String selectedFilter;
  final List<String> filters;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;

  const _SearchAndFilters({
    required this.query,
    required this.selectedFilter,
    required this.filters,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(
          leading: const Icon(Icons.search, size: 20),
          hintText: 'Search ingredients or suppliers',
          onChanged: onQueryChanged,
          elevation: const MaterialStatePropertyAll(0),
          constraints: const BoxConstraints(minHeight: 46, maxHeight: 48),
          padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16)),
          backgroundColor: MaterialStatePropertyAll(Colors.grey.shade100),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in filters)
              FilterChip(
                label: Text(f),
                selected: selectedFilter == f,
                onSelected: (_) => onFilterChanged(f),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                labelStyle: TextStyle(
                  fontWeight:
                      selectedFilter == f ? FontWeight.bold : FontWeight.normal,
                  color: selectedFilter == f
                      ? Colors.white
                      : AppTheme.secondaryColor,
                  fontSize: 13,
                ),
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: selectedFilter == f
                        ? AppTheme.primaryColor
                        : Colors.grey.shade200,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  final bool hasQuery;

  const _InventoryEmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching ingredients' : 'No ingredients yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try a different search term or filter.'
                  : 'Stock items will appear here once added.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
