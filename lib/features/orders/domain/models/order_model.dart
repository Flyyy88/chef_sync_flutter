import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../menu/domain/models/menu_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  completed,
  cancelled
}

class OrderItem {
  final MenuItem item;
  final int quantity;
  final String? customNotes;

  OrderItem({
    required this.item,
    required this.quantity,
    this.customNotes,
  });

  double get totalPrice => item.price * quantity;

  Map<String, dynamic> toJson() => {
        'menuItem': item.toJson(),
        'quantity': quantity,
        'customNotes': customNotes,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final menuJson = json['menuItem'] as Map<String, dynamic>;
    return OrderItem(
      item: MenuItem.fromJson(menuJson, menuJson['id'] ?? ''),
      quantity: json['quantity'] ?? 1,
      customNotes: json['customNotes'],
    );
  }
}

class OrderModel {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final OrderStatus status;
  final double tax;
  final double serviceCharge;
  final String? generalNotes;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.items,
    this.status = OrderStatus.pending,
    this.tax = 0.10, // 10% VAT
    this.serviceCharge = 0.05, // 5% Service Charge
    this.generalNotes,
    required this.createdAt,
  });

  double get subtotal => items.fold(0.0, (val, e) => val + e.totalPrice);
  double get calculatedTax => subtotal * tax;
  double get calculatedServiceCharge => subtotal * serviceCharge;
  double get grandTotal => subtotal + calculatedTax + calculatedServiceCharge;

  // Untuk tampilan ringkas di Dashboard, contoh: "2x Ribeye Steak, 1x Merlot"
  String get itemsSummary => items.map((e) => '${e.quantity}x ${e.item.name}').join(', ');

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'tax': tax,
        'serviceCharge': serviceCharge,
        'generalNotes': generalNotes,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json, String id) {
    return OrderModel(
      id: id,
      tableId: json['tableId'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      tax: (json['tax'] ?? 0.1).toDouble(),
      serviceCharge: (json['serviceCharge'] ?? 0.05).toDouble(),
      generalNotes: json['generalNotes'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  OrderModel copyWith({
    OrderStatus? status,
    List<OrderItem>? items,
    String? generalNotes,
  }) {
    return OrderModel(
      id: id,
      tableId: tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      tax: tax,
      serviceCharge: serviceCharge,
      generalNotes: generalNotes ?? this.generalNotes,
      createdAt: createdAt,
    );
  }
}
