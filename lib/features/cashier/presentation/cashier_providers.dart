import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/order_providers.dart';

final servedOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(todayOrdersStreamProvider).value ?? [];

  return orders.where((order) => order.status == OrderStatus.served).toList();
});
