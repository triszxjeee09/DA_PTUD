class UserAddressModel {
  const UserAddressModel({
    required this.id,
    required this.receiverName,
    required this.receiverPhone,
    required this.province,
    required this.district,
    required this.ward,
    required this.detailAddress,
    this.fullAddress,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String receiverName;
  final String receiverPhone;
  final String province;
  final String district;
  final String ward;
  final String detailAddress;
  final String? fullAddress;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: _readString(json['id']),
      receiverName: _readString(json['receiverName']),
      receiverPhone: _readString(json['receiverPhone']),
      province: _readString(json['province']),
      district: _readString(json['district']),
      ward: _readString(json['ward']),
      detailAddress: _readString(json['detailAddress']),
      fullAddress: _readNullableString(json['fullAddress']),
      isDefault: _readBool(json['isDefault']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'province': province,
      'district': district,
      'ward': ward,
      'detailAddress': detailAddress,
      'fullAddress': fullAddress,
      'isDefault': isDefault,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
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
