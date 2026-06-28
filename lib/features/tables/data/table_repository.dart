import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/table_model.dart';

abstract class TableRepository {
  Future<List<TableModel>> fetchTables();
  Future<void> updateTableStatus(String tableId, TableStatus status, {String? orderId, int guests = 0});
}

// ==========================================
// 1. DAPUR SIMULASI (MOCK)
// ==========================================
class MockTableRepositoryImpl implements TableRepository {
  final List<TableModel> _tables = [
    TableModel(id: 't1', label: 'T-1', seatingCapacity: 2, status: TableStatus.occupied, activeOrderId: 'o101', activeGuests: 2),
    TableModel(id: 't2', label: 'T-2', seatingCapacity: 4, status: TableStatus.available),
    TableModel(id: 't3', label: 'T-3', seatingCapacity: 6, status: TableStatus.reserved),
    TableModel(id: 't4', label: 'T-4', seatingCapacity: 2, status: TableStatus.cleaning),
    TableModel(id: 't5', label: 'VIP Salon', seatingCapacity: 8, status: TableStatus.available),
    TableModel(id: 't6', label: 'Bar Seat 1', seatingCapacity: 1, status: TableStatus.occupied, activeOrderId: 'o102', activeGuests: 1),
  ];

  @override
  Future<List<TableModel>> fetchTables() async {
    return List.from(_tables);
  }

  @override
  Future<void> updateTableStatus(String tableId, TableStatus status, {String? orderId, int guests = 0}) async {
    final idx = _tables.indexWhere((e) => e.id == tableId);
    if (idx != -1) {
      _tables[idx] = _tables[idx].copyWith(
        status: status,
        activeOrderId: orderId,
        activeGuests: guests,
      );
    }
  }
}

// ==========================================
// 2. DAPUR ASLI (FIREBASE FIRESTORE)
// ==========================================
class FirestoreTableRepositoryImpl implements TableRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'tables';

  @override
  Future<List<TableModel>> fetchTables() async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs
          .map((doc) => TableModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception("Gagal mengambil data meja: $e");
    }
  }

  @override
  Future<void> updateTableStatus(String tableId, TableStatus status, {String? orderId, int guests = 0}) async {
    try {
      await _firestore.collection(collectionName).doc(tableId).update({
        'status': status.name,
        'activeOrderId': orderId,
        'activeGuests': guests,
      });
    } catch (e) {
      throw Exception("Gagal update status meja: $e");
    }
  }
}
