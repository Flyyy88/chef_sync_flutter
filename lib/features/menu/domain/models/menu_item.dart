class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isAvailable;
  final String imageUrl;
  final bool isPopular;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    required this.imageUrl,
    this.isPopular = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'isPopular': isPopular,
    };
  }

  factory MenuItem.fromJson(Map<String, dynamic> json, String id) {
    return MenuItem(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] ?? 0).toDouble(), // Ubah jadi toDouble()
      isAvailable: json['isAvailable'] ?? true, // Sesuaikan dengan toJson
      isPopular: json['isPopular'] ?? false, // Sesuaikan dengan toJson
    );
  }

  MenuItem copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    String? imageUrl,
    bool? isPopular,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      isPopular: isPopular ?? this.isPopular,
    );
  }
}
