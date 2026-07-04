import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_padding.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/models/menu_item.dart';
import 'menu_providers.dart';
import 'widgets/menu_grid_card.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _query = '';
  String _category = 'All';

  Future<void> _toggleAvailability(MenuItem item, bool value) async {
    await ref.read(menuRepositoryProvider).updateMenuItem(
          item.copyWith(isAvailable: value),
        );
    ref.invalidate(menuListProvider);
  }

  Future<void> _delete(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete menu item?'),
        content: Text('"${item.name}" will be removed from the menu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(menuRepositoryProvider).deleteMenuItem(item.id);
      ref.invalidate(menuListProvider);
    }
  }

  Future<void> _openEditor({MenuItem? item}) async {
    await context.push('/add-menu', extra: item);
    ref.invalidate(menuListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuListProvider);
    final horizontalPadding = ResponsivePadding.horizontal(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(menuListProvider);
            await ref.read(menuListProvider.future);
          },
          child: menuAsync.when(
            data: (items) {
              final categories = [
                'All',
                ...{for (final m in items) if (m.category.isNotEmpty) m.category},
              ];

              var filtered = items;
              if (_category != 'All') {
                filtered = filtered.where((m) => m.category == _category).toList();
              }
              if (_query.isNotEmpty) {
                final q = _query.toLowerCase();
                filtered = filtered.where((m) => m.name.toLowerCase().contains(q)).toList();
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 0),
                      child: const _MenuHeader(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 12),
                      child: SearchBar(
                        leading: const Icon(Icons.search, size: 20),
                        hintText: 'Search menu items',
                        onChanged: (v) => setState(() => _query = v),
                        elevation: const MaterialStatePropertyAll(0),
                        constraints: const BoxConstraints(minHeight: 46, maxHeight: 48),
                        padding: const MaterialStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16),
                        ),
                        backgroundColor: MaterialStatePropertyAll(Colors.grey.shade100),
                        shape: MaterialStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = categories[i];
                          final selected = cat == _category;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (_) => setState(() => _category = cat),
                            visualDensity: VisualDensity.compact,
                            showCheckmark: false,
                            selectedColor: AppTheme.primaryColor,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppTheme.secondaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MenuEmptyState(hasQuery: _query.isNotEmpty || _category != 'All'),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 100),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          int columns;
                          if (constraints.crossAxisExtent >= 1200) {
                            columns = 5;
                          } else if (constraints.crossAxisExtent >= 900) {
                            columns = 4;
                          } else if (constraints.crossAxisExtent >= 600) {
                            columns = 3;
                          } else {
                            columns = 2;
                          }

                          const spacing = 14.0;
                          final cardWidth =
                              (constraints.crossAxisExtent - (columns - 1) * spacing) / columns;
                          final aspectRatio = (cardWidth / 235).clamp(0.55, 0.85);

                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                              childAspectRatio: aspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => MenuGridCard(
                                item: filtered[i],
                                onEdit: () => _openEditor(item: filtered[i]),
                                onDelete: () => _delete(filtered[i]),
                                onAvailabilityChanged: (v) => _toggleAvailability(filtered[i], v),
                              ),
                              childCount: filtered.length,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            error: (e, _) => Center(child: Text('Failed to load menu: $e')),
          ),
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATALOG',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Menu',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Manage dishes, pricing, and availability',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}

class _MenuEmptyState extends StatelessWidget {
  final bool hasQuery;

  const _MenuEmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasQuery ? Icons.search_off_rounded : Icons.restaurant_menu_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No matching items' : 'No menu items yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try a different search term or category.'
                  : 'Tap "Add Item" to create your first dish.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
