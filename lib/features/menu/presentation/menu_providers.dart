import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/menu_repository.dart';
import '../domain/models/menu_item.dart';

// 1. Provider untuk Repository (Dapur)
// Ubah Provider<MenuRepository> menjadi Provider<FirestoreMenuRepositoryImpl>
final menuRepositoryProvider = Provider<FirestoreMenuRepositoryImpl>((ref) {
  return FirestoreMenuRepositoryImpl();
});

// 2. Provider untuk State/Daftar Menu (Pelayan)
final menuListProvider = FutureProvider<List<MenuItem>>((ref) async {
  // Memantau repository
  final repository = ref.watch(menuRepositoryProvider);

  // Meminta repository mengambil data daftar menu
  return repository.fetchMenuItems();
});
