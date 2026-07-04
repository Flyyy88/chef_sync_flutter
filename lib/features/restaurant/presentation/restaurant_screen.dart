import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive_padding.dart';
import '../../tables/domain/models/table_model.dart';
import '../../tables/presentation/table_providers.dart';
import '../../tables/presentation/table_screen.dart';
import 'widgets/table_action_dialog.dart';

class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key});

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Available',
    'Occupied',
    'Reserved',
    'Cleaning',
  ];

  void _showTableActions(BuildContext context, TableModel table) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        void closeDialog() {
          Navigator.of(dialogContext).pop();
        }

        return TableActionDialog(
          table: table,
          onOpenPOS: () {
            closeDialog();
            TableScreen.openPOS(context, table);
          },
          onAssignWaiter: closeDialog,
          onReserve: closeDialog,
          onViewDetails: closeDialog,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Load tables from existing tableListProvider to calculate real statistics values
    final tablesAsync = ref.watch(tableListProvider);
    final tables = tablesAsync.valueOrNull ?? [];

    final availableCount = tables.where((t) => t.status == TableStatus.available).length;
    final occupiedCount = tables.where((t) => t.status == TableStatus.occupied).length;
    final reservedCount = tables.where((t) => t.status == TableStatus.reserved).length;
    final cleaningCount = tables.where((t) => t.status == TableStatus.cleaning).length;

    final stats = [
      _RestaurantStat(
        label: 'Available Tables',
        value: availableCount.toString(),
        color: const Color(0xFF2E7D32),
        icon: Icons.event_seat_outlined,
      ),
      _RestaurantStat(
        label: 'Occupied Tables',
        value: occupiedCount.toString(),
        color: const Color(0xFFC62828),
        icon: Icons.groups_outlined,
      ),
      _RestaurantStat(
        label: 'Reserved Tables',
        value: reservedCount.toString(),
        color: const Color(0xFF1565C0),
        icon: Icons.bookmark_border_outlined,
      ),
      _RestaurantStat(
        label: 'Cleaning Tables',
        value: cleaningCount.toString(),
        color: const Color(0xFFEF6C00),
        icon: Icons.cleaning_services_outlined,
      ),
    ];

    // Responsive horizontal padding based on screen width — shared scale
    // (16 / 24 / 32) so every section lines up with the rest of the app.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding =
        ResponsivePadding.horizontalForWidth(screenWidth);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RestaurantHeader(horizontalPadding: horizontalPadding),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final isDesktop = constraints.maxWidth >= 1100;
                  final crossAxisCount = isDesktop ? 4 : (isWide ? 4 : 2);

                  // Derive the aspect ratio from the real available width so
                  // the card height always has enough room for the icon +
                  // two lines of text, on any screen size.
                  const double spacing = 12;
                  final double cardWidth = (constraints.maxWidth -
                          (crossAxisCount - 1) * spacing) /
                      crossAxisCount;
                  const double targetHeight = 76;
                  final double childAspectRatio =
                      (cardWidth / targetHeight).clamp(1.8, 3.2);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      return _RestaurantStatCard(stat: stats[index]);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 0),
              child: _RestaurantSearchBar(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in _filters)
                    FilterChip(
                      label: Text(filter),
                      selected: filter == _selectedFilter,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: TextStyle(
                        fontWeight: filter == _selectedFilter
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: filter == _selectedFilter
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 13,
                      ),
                      selectedColor: colorScheme.primary,
                      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: filter == _selectedFilter
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Only this Expanded scrolls (TableScreen renders a single
            // GridView.builder that owns the scrolling). Everything above
            // it — header, statistics, search bar, filter chips — is a
            // fixed sibling in this Column, so it can never be scrolled
            // underneath by the grid.
            Expanded(
              child: TableScreen(
                onTableTap: _showTableActions,
                searchQuery: _searchQuery,
                selectedFilter: _selectedFilter,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  const _RestaurantHeader({
    required this.horizontalPadding,
  });

  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Good Afternoon',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Restaurant Operations',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantStatCard extends StatelessWidget {
  const _RestaurantStatCard({
    required this.stat,
  });

  final _RestaurantStat stat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantSearchBar extends StatelessWidget {
  const _RestaurantSearchBar({
    required this.onChanged,
  });

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SearchBar(
      leading: const Icon(Icons.search, size: 20),
      hintText: 'Search tables, orders, or reservations',
      hintStyle: const MaterialStatePropertyAll(TextStyle(fontSize: 14)),
      textStyle: const MaterialStatePropertyAll(TextStyle(fontSize: 14)),
      onChanged: onChanged,
      elevation: const MaterialStatePropertyAll(0),
      constraints: const BoxConstraints(minHeight: 46, maxHeight: 48),
      padding: const MaterialStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      backgroundColor: MaterialStatePropertyAll(
        colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class _RestaurantStat {
  const _RestaurantStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
}
