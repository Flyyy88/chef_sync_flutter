import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> fetchOrders();
  Future<List<OrderModel>> fetchTodayOrders();
  Future<void> saveOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}

// ==========================================
// 1. DAPUR SIMULASI (MOCK)
// ==========================================
class MockOrderRepositoryImpl implements OrderRepository {
  final List<OrderModel> _orders = [];

  @override
  Future<List<OrderModel>> fetchOrders() async => List.from(_orders);

  @override
  Future<List<OrderModel>> fetchTodayOrders() async {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day)
        .toList();
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    final idx = _orders.indexWhere((e) => e.id == order.id);
    if (idx != -1) {
      _orders[idx] = order;
    } else {
      _orders.add(order);
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final idx = _orders.indexWhere((e) => e.id == orderId);
    if (idx != -1) {
      _orders[idx] = _orders[idx].copyWith(status: status);
    }
  }
}

// ==========================================
// 2. DAPUR ASLI (FIREBASE FIRESTORE)
// ==========================================
class FirestoreOrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'orders';

  @override
  Future<List<OrderModel>> fetchOrders() async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception("Gagal mengambil data order: $e");
    }
  }

  @override
  Future<List<OrderModel>> fetchTodayOrders() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _firestore
          .collection(collectionName)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception("Gagal mengambil order hari ini: $e");
    }
  }

  @override
  Future<void> saveOrder(OrderModel order) async {
    try {
      await _firestore.collection(collectionName).doc(order.id).set(order.toJson());
    } catch (e) {
      throw Exception("Gagal menyimpan order: $e");
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(orderId)
          .update({'status': status.name});
    } catch (e) {
      throw Exception("Gagal update status order: $e");
    }
  }
}
