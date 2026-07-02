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

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order berhasil dibuat"),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 1),
        ),
      );

      // Kembali ke halaman Tables
      context.go('/tables');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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
          data: (menus) => _buildBody(tables, menus),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Gagal memuat menu: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data meja: $e')),
      ),
    );
  }

  Widget _buildBody(List<TableModel> tables, List<MenuItem> menus) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final subtotal = _subtotal(menus);
    final totalItems = _cartQuantities.values.fold<int>(0, (a, b) => a + b);

    return Column(
      children: [
        _buildTableSelector(tables),
        const Divider(height: 1),
        Expanded(child: _buildMenuList(menus)),
        if (totalItems > 0)
          _buildCartBar(currency.format(subtotal), totalItems, menus),
      ],
    );
  }

  Widget _buildTableSelector(List<TableModel> tables) {
    if (widget.selectedTable != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            const Icon(Icons.table_restaurant),
            const SizedBox(width: 10),
            Text(
              widget.selectedTable!.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                  // Meja yang sudah 'occupied' tidak bisa dipakai untuk order BARU
                  // (untuk order tambahan di meja yang sama, akan dibuat fitur terpisah nanti)
                  onSelected: isOccupied
                      ? null
                      : (_) => setState(() => _selectedTable = table),
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor:
                      isOccupied ? Colors.grey.shade200 : Colors.white,
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

  Widget _buildMenuList(List<MenuItem> menus) {
    if (menus.isEmpty) {
      return const Center(
        child: Text('Belum ada menu. Tambahkan dulu di halaman Menu.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: menus.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final menu = menus[i];
        final qty = _cartQuantities[menu.id] ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(menu.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(menu.price),
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (qty == 0)
                IconButton(
                  onPressed: () => _incrementItem(menu),
                  icon: const Icon(Icons.add_circle,
                      color: AppTheme.primaryColor, size: 28),
                )
              else
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _decrementItem(menu),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppTheme.secondaryColor),
                    ),
                    Text('$qty',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () => _incrementItem(menu),
                      icon: const Icon(Icons.add_circle,
                          color: AppTheme.primaryColor),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
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
                children: [
                  Text('$totalItems item',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(subtotalText,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            SizedBox(
              width: 160,
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
                    : const Text('Buat Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
