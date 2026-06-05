class AdminPharmacyRequestModel {
  const AdminPharmacyRequestModel({
    required this.name,
    this.phone,
    required this.province,
    required this.district,
    this.ward,
    required this.address,
    this.latitude,
    this.longitude,
    this.openingHours,
    required this.isActive,
  });

  final String name;
  final String? phone;
  final String province;
  final String district;
  final String? ward;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'province': province,
      'district': district,
      'ward': ward,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'openingHours': openingHours,
      'isActive': isActive,
    };
  }
}
