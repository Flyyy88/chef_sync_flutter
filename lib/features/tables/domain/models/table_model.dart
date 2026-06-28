enum TableStatus { available, occupied, reserved, cleaning }

class TableModel {
  final String id;
  final String label;
  final int seatingCapacity;
  final TableStatus status;
  final String? activeOrderId;
  final int activeGuests;

  TableModel({
    required this.id,
    required this.label,
    required this.seatingCapacity,
    required this.status,
    this.activeOrderId,
    this.activeGuests = 0,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'seatingCapacity': seatingCapacity,
        'status': status.name,
        'activeOrderId': activeOrderId,
        'activeGuests': activeGuests,
      };

  factory TableModel.fromJson(Map<String, dynamic> json, String id) {
    return TableModel(
      id: id,
      label: json['label'] ?? '',
      seatingCapacity: json['seatingCapacity'] ?? 0,
      status: TableStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TableStatus.available,
      ),
      activeOrderId: json['activeOrderId'],
      activeGuests: json['activeGuests'] ?? 0,
    );
  }

  TableModel copyWith({
    TableStatus? status,
    String? activeOrderId,
    int? activeGuests,
  }) {
    return TableModel(
      id: id,
      label: label,
      seatingCapacity: seatingCapacity,
      status: status ?? this.status,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      activeGuests: activeGuests ?? this.activeGuests,
    );
  }
}
