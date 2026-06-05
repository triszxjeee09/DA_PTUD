class OrderStatusStatisticModel {
  const OrderStatusStatisticModel({
    required this.status,
    required this.statusLabel,
    required this.count,
  });

  final String status;
  final String statusLabel;
  final int count;

  factory OrderStatusStatisticModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusStatisticModel(
      status: json['status']?.toString() ?? '',
      statusLabel: json['statusLabel']?.toString() ?? '',
      count: _readInt(json['count']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}
