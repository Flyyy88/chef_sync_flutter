import '../domain/models/inventory_item.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> fetchInventory();
  Future<void> replenishStock(String id, double quantity);
}

class MockInventoryRepositoryImpl implements InventoryRepository {
  final List<InventoryItem> _items = [
    InventoryItem(
      id: 'i1',
      ingredientName: 'Fresh White Truffles',
      currentStock: 0.2,
      minimumRequired: 0.5,
      unit: 'kg',
      supplier: 'Alba Forest Delicacies',
      lastRestocked: DateTime.now().subtract(const Duration(days: 3)),
    ),
    InventoryItem(
      id: 'i2',
      ingredientName: 'Angus Beef Ribeye',
      currentStock: 22.0,
      minimumRequired: 15.0,
      unit: 'kg',
      supplier: 'Metropolitan Premium Meats',
      lastRestocked: DateTime.now().subtract(const Duration(days: 1)),
    ),
    InventoryItem(
      id: 'i3',
      ingredientName: 'Egg Pasta Tagliolini',
      currentStock: 12.5,
      minimumRequired: 5.0,
      unit: 'kg',
      supplier: 'Pastaficio Verona',
      lastRestocked: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<List<InventoryItem>> fetchInventory() async {
    return List.from(_items);
  }

  @override
  Future<void> replenishStock(String id, double quantity) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(
        currentStock: _items[idx].currentStock + quantity,
        lastRestocked: DateTime.now(),
      );
    }
  }
}
