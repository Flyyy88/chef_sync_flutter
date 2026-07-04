import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../menu/presentation/menu_providers.dart';
import '../../menu/domain/models/menu_item.dart';
import '../../tables/presentation/table_providers.dart';
import '../../tables/domain/models/table_model.dart';
import 'order_providers.dart';
import '../domain/models/order_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/responsive/responsive_padding.dart';
import '../../dashboard/presentations/dashboard_providers.dart';
import 'package:go_router/go_router.dart';

class PosScreen extends ConsumerStatefulWidget {
  final TableModel? selectedTable;

  const PosScreen({
    super.key,
    this.selectedTable,
  });

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  TableModel? _selectedTable;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.selectedTable;
  }

  // menuId -> jumlah di keranjang
  final Map<String, int> _cartQuantities = {};
  bool _isSubmitting = false;

  void _incrementItem(MenuItem item) {
    setState(() {
      _cartQuantities[item.id] = (_cartQuantities[item.id] ?? 0) + 1;
    });
  }

  void _decrementItem(MenuItem item) {
    setState(() {
      final current = _cartQuantities[item.id] ?? 0;
      if (current <= 1) {
        _cartQuantities.remove(item.id);
      } else {
        _cartQuantities[item.id] = current - 1;
      }
    });
  }

  double _subtotal(List<MenuItem> allMenus) {
    double total = 0;
    _cartQuantities.forEach((id, qty) {
      final menu = allMenus.where((m) => m.id == id).isEmpty
          ? null
          : allMenus.firstWhere((m) => m.id == id);
      if (menu != null) total += menu.price * qty;
    });
    return total;
  }

  Future<void> _submitOrder(List<MenuItem> allMenus) async {
    if (_selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih meja terlebih dahulu'),
        ),
      );
      return;
    }

    if (_cartQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang masih kosong'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final goRouter = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final items = _cartQuantities.entries.map((e) {
        final menu = allMenus.firstWhere((m) => m.id == e.key);

        return OrderItem(
          item: menu,
          quantity: e.value,
        );
      }).toList();

      final order = OrderModel(
        id: const Uuid().v4(),
        tableId: _selectedTable!.id,
        items: items,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      // Simpan order
      await ref.read(orderRepositoryProvider).saveOrder(order);

      // Update status meja
      await ref.read(tableRepositoryProvider).updateTableStatus(
            _selectedTable!.id,
            TableStatus.occupied,
            orderId: order.id,
            guests: _selectedTable!.activeGuests == 0
                ? 1
                : _selectedTable!.activeGuests,
          );

      // Refresh provider
      ref.invalidate(todayOrdersProvider);
      ref.invalidate(tableListProvider);
      ref.invalidate(dashboardStatsProvider);

      messenger.showSnackBar(
        const SnackBar(
          content: Text("Order berhasil dibuat"),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 1),
        ),
      );

      // Kembali ke halaman Restaurant
      if (context.mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/restaurant');
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Gagal membuat order: $e"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuListProvider);
    final tableAsync = ref.watch(tableListProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Buat Order Baru',
            style: TextStyle(
                color: AppTheme.secondaryColor, fontWeight: FontWeight.bold)),
      ),
      body: tableAsync.when(
        data: (tables) => menuAsync.when(
          data: (menus) {
            // Extract distinct categories dynamically
            final categories = ['All', ...menus.map((m) => m.category).toSet().where((c) => c.isNotEmpty)];
            
            var filteredMenus = menus;
            if (_selectedCategory != 'All') {
              filteredMenus = filteredMenus.where((m) => m.category == _selectedCategory).toList();
            }

            final isDesktop = MediaQuery.of(context).size.width >= 1024;
            
            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left panel: Categories
                  _buildDesktopCategories(categories),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  // Center panel: Tables & Menu Grid
                  Expanded(
                    child: Column(
                      children: [
                        _buildTableSelector(tables),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Expanded(child: _buildMenuGrid(filteredMenus)),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  // Right panel: Cart Details
                  _buildDesktopCartPanel(currency.format(_subtotal(menus)), menus),
                ],
              );
            } else {
              // Mobile / Tablet layout
              return Column(
                children: [
                  _buildTableSelector(tables),
                  _buildMobileCategories(categories),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(child: _buildMenuGrid(filteredMenus)),
                  if (_cartQuantities.isNotEmpty)
                    _buildCartBar(
                      currency.format(_subtotal(menus)),
                      _cartQuantities.values.fold<int>(0, (a, b) => a + b),
                      menus,
                    ),
                ],
              );
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Gagal memuat menu: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data meja: $e')),
      ),
    );
  }

  Widget _buildDesktopCategories(List<String> categories) {
    return Container(
      width: 200,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final category = categories[i];
                final isSelected = _selectedCategory == category;

                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.folder : Icons.folder_open,
                          size: 18,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.secondaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCategories(List<String> categories) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = categories[i];
          final isSelected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.secondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableSelector(List<TableModel> tables) {
    if (widget.selectedTable != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            const Icon(Icons.table_restaurant, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.selectedTable!.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (tables.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Belum ada data meja. Tambahkan dulu di Tables Screen.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('PILIH MEJA',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tables.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final table = tables[i];
                final isSelected = _selectedTable?.id == table.id;
                final isOccupied = table.status == TableStatus.occupied;

                return ChoiceChip(
                  label: Text(table.label),
                  selected: isSelected,
                  onSelected: isOccupied
                      ? null
                      : (_) => setState(() => _selectedTable = table),
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor:
                      isOccupied ? Colors.grey.shade100 : Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isOccupied ? Colors.grey : AppTheme.secondaryColor),
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(List<MenuItem> menus) {
    if (menus.isEmpty) {
      return const Center(
        child: Text('Belum ada menu di kategori ini',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Desktop uses ~2 columns due to categories & cart sidebar; tablet/mobile uses responsive columns
        int crossAxisCount = width >= 800 ? 3 : (width >= 480 ? 2 : 1);

        final double gridPadding = ResponsivePadding.horizontalForWidth(width);
        final double cardWidth =
            (width - (crossAxisCount - 1) * 12 - gridPadding * 2) /
                crossAxisCount;
        // Food card target height is around 180 to fit image and controls cleanly
        final double childAspectRatio = (cardWidth / 185.0).clamp(0.9, 1.4);

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: gridPadding, vertical: 16),
          itemCount: menus.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, i) {
            final menu = menus[i];
            final qty = _cartQuantities[menu.id] ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Food Image
                    Expanded(
                      child: Container(
                        color: Colors.grey.shade50,
                        child: menu.imageUrl.startsWith('http')
                            ? Image.network(
                                menu.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.fastfood_outlined, size: 36, color: Colors.grey),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.fastfood_outlined, size: 36, color: Colors.grey),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.secondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(menu.price),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (qty == 0)
                                InkWell(
                                  onTap: () => _incrementItem(menu),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: AppTheme.primaryColor,
                                      size: 18,
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _decrementItem(menu),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.remove,
                                          color: AppTheme.secondaryColor,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '$qty',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _incrementItem(menu),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: AppTheme.primaryColor,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopCartPanel(String subtotalText, List<MenuItem> menus) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Container(
      width: 320,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: AppTheme.secondaryColor),
              const SizedBox(width: 10),
              Text(
                'ORDER CART',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Expanded(
            child: _cartQuantities.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Keranjang masih kosong',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _cartQuantities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final entry = _cartQuantities.entries.elementAt(idx);
                      final menuId = entry.key;
                      final qty = entry.value;
                      final menu = menus.firstWhere((m) => m.id == menuId);

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColorLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    menu.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppTheme.secondaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currency.format(menu.price * qty),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _decrementItem(menu),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: const Icon(Icons.remove, size: 12, color: Colors.grey),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _incrementItem(menu),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: const Icon(Icons.add, size: 12, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),
          // Total Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Subtotal',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                subtotalText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting || _cartQuantities.isEmpty ? null : () => _submitOrder(menus),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'BUAT ORDER',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBar(
      String subtotalText, int totalItems, List<MenuItem> menus) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$totalItems item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(subtotalText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.secondaryColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitOrder(menus),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Buat Order'),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
