class RevenueStatisticModel {
  const RevenueStatisticModel({
    required this.label,
    required this.revenue,
    required this.orderCount,
  });

  final String label;
  final double revenue;
  final int orderCount;

  factory RevenueStatisticModel.fromJson(Map<String, dynamic> json) {
    return RevenueStatisticModel(
      label: json['label']?.toString() ?? '',
      revenue: _readDouble(json['revenue']),
      orderCount: _readInt(json['orderCount']),
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

  static double _readDouble(Object? value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}
