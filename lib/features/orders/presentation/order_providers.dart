import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_repository.dart';
import '../domain/models/order_model.dart';

final orderRepositoryProvider = Provider<FirestoreOrderRepositoryImpl>((ref) {
  return FirestoreOrderRepositoryImpl();
});

final todayOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.fetchTodayOrders();
});
