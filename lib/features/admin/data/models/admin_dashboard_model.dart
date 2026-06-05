class AdminDashboardModel {
  const AdminDashboardModel({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalPendingOrders,
    required this.totalDeliveredOrders,
    required this.totalPrescriptions,
    required this.totalPendingPrescriptions,
    required this.totalPharmacies,
    required this.totalReviews,
    required this.totalRevenue,
  });

  final int totalUsers;
  final int totalProducts;
  final int totalOrders;
  final int totalPendingOrders;
  final int totalDeliveredOrders;
  final int totalPrescriptions;
  final int totalPendingPrescriptions;
  final int totalPharmacies;
  final int totalReviews;
  final double totalRevenue;

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      totalUsers: _readInt(json['totalUsers']),
      totalProducts: _readInt(json['totalProducts']),
      totalOrders: _readInt(json['totalOrders']),
      totalPendingOrders: _readInt(json['totalPendingOrders']),
      totalDeliveredOrders: _readInt(json['totalDeliveredOrders']),
      totalPrescriptions: _readInt(json['totalPrescriptions']),
      totalPendingPrescriptions: _readInt(json['totalPendingPrescriptions']),
      totalPharmacies: _readInt(json['totalPharmacies']),
      totalReviews: _readInt(json['totalReviews']),
      totalRevenue: _readDouble(json['totalRevenue']),
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
