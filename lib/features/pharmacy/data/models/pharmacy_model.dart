class PharmacyModel {
  const PharmacyModel({
    required this.id,
    required this.name,
    this.phone,
    required this.province,
    required this.district,
    this.ward,
    required this.address,
    this.fullAddress,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String province;
  final String district;
  final String? ward;
  final String address;
  final String? fullAddress;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    final address = _readString(json['address']);
    final ward = _readNullableString(json['ward']);
    final district = _readString(json['district']);
    final province = _readString(json['province']);

    return PharmacyModel(
      id: _readString(json['id']),
      name: _readString(json['name']),
      phone: _readNullableString(json['phone']),
      province: province,
      district: district,
      ward: ward,
      address: address,
      fullAddress:
          _readNullableString(json['fullAddress']) ??
          _buildFullAddress(
            address: address,
            ward: ward,
            district: district,
            province: province,
          ),
      latitude: _readNullableDouble(json['latitude']),
      longitude: _readNullableDouble(json['longitude']),
      openingHours: _readNullableString(json['openingHours']),
      isActive: _readBool(json['isActive'], fallback: true),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'province': province,
      'district': district,
      'ward': ward,
      'address': address,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'openingHours': openingHours,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String? _buildFullAddress({
    required String address,
    required String? ward,
    required String district,
    required String province,
  }) {
    final text = [
      address,
      ward,
      district,
      province,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    return text.isEmpty ? null : text;
  }

  static String _readString(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return text;
  }

  static double? _readNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    return fallback;
  }

  static DateTime? _readDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
