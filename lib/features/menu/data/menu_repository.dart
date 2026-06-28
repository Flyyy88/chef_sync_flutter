import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/menu_item.dart';

abstract class MenuRepository {
  Future<List<MenuItem>> fetchMenuItems();
  Future<void> addMenuItem(MenuItem item); // Pastikan baris ini ADA
  Future<void> updateMenuItem(MenuItem item);
  Future<void> deleteMenuItem(String id);
}

// ==========================================
// 1. DAPUR SIMULASI (MOCK)
// ==========================================
class MockMenuRepositoryImpl implements MenuRepository {
  final List<MenuItem> _items = [
    MenuItem(
      id: 'm1',
      name: 'Truffle Tagliolini',
      description:
          'Handmade flat egg pasta dressed with white mountain truffle cream & aged pecorino cheese.',
      price: 24.50,
      category: 'Mains',
      imageUrl: 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a',
      isPopular: true,
    ),
    MenuItem(
      id: 'm2',
      name: 'Ribeye Steak Frites',
      description:
          'Prime Dry Aged ribeye accompanied by fresh rosemary butter sauce and salted hand-cut fries.',
      price: 36.00,
      category: 'Mains',
      imageUrl: 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092',
      isPopular: true,
    ),
    MenuItem(
      id: 'm3',
      name: 'Classic Caesar',
      description:
          'Crunchy little gem romaine hearts loaded with homemade Caesar cream and sourdough croutons.',
      price: 14.00,
      category: 'Appetizers',
      imageUrl: 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9',
    ),
    MenuItem(
      id: 'm4',
      name: 'Molten Lava Cake',
      description:
          'Decadent dark Belgian cocoa cake with molten chocolate core and Madagascar vanilla scoop.',
      price: 12.00,
      category: 'Desserts',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c',
      isPopular: true,
    ),
  ];

  @override
  Future<List<MenuItem>> fetchMenuItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_items);
  }

  @override
  Future<void> addMenuItem(MenuItem item) async {
    _items.add(item);
  }

  @override
  Future<void> updateMenuItem(MenuItem item) async {
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      _items[idx] = item;
    }
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    _items.removeWhere((e) => e.id == id);
  }
}

// ==========================================
// 2. DAPUR ASLI (FIREBASE FIRESTORE)
// ==========================================
class FirestoreMenuRepositoryImpl implements MenuRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'menu_items';

  @override
  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs.map((doc) {
        return MenuItem.fromJson(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception("Gagal mengambil menu dari Firebase: $e");
    }
  }

  @override
  Future<void> addMenuItem(MenuItem item) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(item.id)
          .set(item.toJson());
    } catch (e) {
      throw Exception("Gagal menambah menu: $e");
    }
  }

  @override
  Future<void> updateMenuItem(MenuItem item) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(item.id)
          .update(item.toJson());
    } catch (e) {
      throw Exception("Gagal mengubah menu: $e");
    }
  }

  @override
  Future<void> deleteMenuItem(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      throw Exception("Gagal menghapus menu: $e");
    }
  }
}
