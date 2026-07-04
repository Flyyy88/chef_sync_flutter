import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/inventory_repository.dart';
import '../domain/models/inventory_item.dart';

// Thin wiring layer only — mirrors the same pattern used by
// menu_providers.dart / table_providers.dart. No business logic lives
// here, it only exposes the existing InventoryRepository to the
// presentation layer so the (previously empty) Inventory screen can
// render real data.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return MockInventoryRepositoryImpl();
});

final inventoryListProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.fetchInventory();
});
