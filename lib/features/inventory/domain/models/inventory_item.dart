class InventoryItem {
  final String id;
  final String ingredientName;
  final double currentStock;
  final double minimumRequired;
  final String unit; // kg, liters, units
  final String supplier;
  final DateTime lastRestocked;

  InventoryItem({
    required this.id,
    required this.ingredientName,
    required this.currentStock,
    required this.minimumRequired,
    required this.unit,
    required this.supplier,
    required this.lastRestocked,
  });

  bool get isLowStock => currentStock <= minimumRequired;

  InventoryItem copyWith({
    double? currentStock,
    DateTime? lastRestocked,
  }) {
    return InventoryItem(
      id: id,
      ingredientName: ingredientName,
      currentStock: currentStock ?? this.currentStock,
      minimumRequired: minimumRequired,
      unit: unit,
      supplier: supplier,
      lastRestocked: lastRestocked ?? this.lastRestocked,
    );
  }
}
