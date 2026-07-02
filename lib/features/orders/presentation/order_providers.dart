import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/order_repository.dart';
import '../domain/models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirestoreOrderRepositoryImpl();
});

final todayOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.watch(orderRepositoryProvider).fetchTodayOrders();
});

final todayOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).watchTodayOrders();
});

final allOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).watchOrders();
});
