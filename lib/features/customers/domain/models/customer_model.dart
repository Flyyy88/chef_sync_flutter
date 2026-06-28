class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final int loyaltyPoints;
  final List<String> favoriteItems;
  final int visitCount;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.loyaltyPoints,
    required this.favoriteItems,
    required this.visitCount,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      loyaltyPoints: json['loyaltyPoints'] as int,
      favoriteItems: List<String>.from(json['favoriteItems']),
      visitCount: json['visitCount'] as int,
    );
  }
}
