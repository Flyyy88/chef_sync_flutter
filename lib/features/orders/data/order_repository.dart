import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/order_model.dart';
import 'package:flutter/foundation.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> fetchOrders();
  Future<List<OrderModel>> fetchTodayOrders();
  Stream<List<OrderModel>> watchOrders();

  Stream<List<OrderModel>> watchTodayOrders();
  Future<void> saveOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<void> completeOrder(
    OrderModel order, {
    required PaymentMethod paymentMethod,
  });
}

// ==========================================
// 1. DAPUR SIMULASI (MOCK)
// ==========================================
class MockOrderRepositoryImpl implements OrderRepository {
  final List<OrderModel> _orders = [];
  final _controller = StreamController<List<OrderModel>>.broadcast();

  @override
  Stream<List<OrderModel>> watchOrders() {
    _controller.add(List.from(_orders));
    return _controller.stream;
  }

  @override
  Stream<List<OrderModel>> watchTodayOrders() {
    return watchOrders().map((orders) {
      final now = DateTime.now();

      return orders.where((o) {
        return o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day;
      }).toList();
    });
  }

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
      _controller.add(List.from(_orders));
    }
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final idx = _orders.indexWhere((e) => e.id == orderId);

    if (idx == -1) return;

    final order = _orders[idx];

    if (status == OrderStatus.preparing) {
      _orders[idx] = order.copyWith(
        status: status,
        cookingStartedAt: DateTime.now(),
      );
    } else if (status == OrderStatus.ready) {
      _orders[idx] = order.copyWith(
        status: status,
        readyAt: DateTime.now(),
      );
    } else {
      _orders[idx] = order.copyWith(
        status: status,
      );
    }

    _controller.add(List.from(_orders));
  }

  @override
  Future<void> completeOrder(
    OrderModel order, {
    required PaymentMethod paymentMethod,
  }) async {
    final updated = order.copyWith(
      status: OrderStatus.completed,
      paymentMethod: paymentMethod,
      paidAt: DateTime.now(),
      invoiceNumber: "INV-${DateTime.now().millisecondsSinceEpoch}",
    );

    final idx = _orders.indexWhere((e) => e.id == order.id);

    if (idx != -1) {
      _orders[idx] = updated;
      _controller.add(List.from(_orders));
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
  Stream<List<OrderModel>> watchOrders() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<OrderModel>> watchTodayOrders() {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    return _firestore
        .collection(collectionName)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'createdAt',
          isLessThan: Timestamp.fromDate(endOfDay),
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

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

      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final endOfDay = startOfDay.add(
        const Duration(days: 1),
      );

      final snapshot = await _firestore
          .collection(collectionName)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'createdAt',
            isLessThan: Timestamp.fromDate(endOfDay),
          )
          .orderBy(
            'createdAt',
            descending: true,
          )
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
      await _firestore
          .collection(collectionName)
          .doc(order.id)
          .set(order.toJson());
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint("SAVE ORDER ERROR");
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
      }
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    try {
      final data = <String, dynamic>{
        'status': status.name,
      };

      if (status == OrderStatus.preparing) {
        data['cookingStartedAt'] = Timestamp.now();
      }

      if (status == OrderStatus.ready) {
        data['readyAt'] = Timestamp.now();
      }

      await _firestore.collection(collectionName).doc(orderId).update(data);
    } catch (e) {
      throw Exception("Gagal update status order: $e");
    }
  }

  @override
  Future<void> completeOrder(
    OrderModel order, {
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final batch = _firestore.batch();

      final orderRef = _firestore.collection(collectionName).doc(order.id);

      final invoiceNumber = "INV-TEST";

      batch.update(orderRef, {
        'status': OrderStatus.completed.name,
        'paymentMethod': paymentMethod.name,
        'paidAt': Timestamp.now(),
        'invoiceNumber': invoiceNumber,
      });

      final tableRef = _firestore.collection('tables').doc(order.tableId);

      batch.update(tableRef, {
        'status': 'available',
        'activeOrderId': null,
        'activeGuests': 0,
      });

      await batch.commit();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint("COMPLETE ORDER ERROR");
        debugPrint(e.toString());
        debugPrintStack(stackTrace: s);
      }
      rethrow;
    }
  }

  Future<String> _generateInvoiceNumber() async {
    final docRef = _firestore.collection('system').doc('invoice');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      int lastNumber = 0;

      if (snapshot.exists) {
        lastNumber = snapshot.data()?['lastNumber'] ?? 0;
      }

      lastNumber++;

      transaction.set(
        docRef,
        {
          'lastNumber': lastNumber,
        },
        SetOptions(merge: true),
      );

      final now = DateTime.now();

      final date = "${now.year}"
          "${now.month.toString().padLeft(2, '0')}"
          "${now.day.toString().padLeft(2, '0')}";

      final runningNumber = lastNumber.toString().padLeft(4, '0');

      return "INV-$date-$runningNumber";
    });
  }
}
