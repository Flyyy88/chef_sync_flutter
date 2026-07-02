import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/domain/models/order_model.dart';
import '../../orders/presentation/order_providers.dart';

final kitchenOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final orders = ref.watch(allOrdersStreamProvider);

  return orders.when(
    data: (data) => Stream.value(
      data.where((order) {
        return order.status == OrderStatus.pending ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready;
      }).toList(),
    ),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
