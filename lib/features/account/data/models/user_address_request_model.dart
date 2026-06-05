class UserAddressRequestModel {
  const UserAddressRequestModel({
    required this.receiverName,
    required this.receiverPhone,
    required this.province,
    required this.district,
    required this.ward,
    required this.detailAddress,
    this.isDefault = false,
  });

  final String receiverName;
  final String receiverPhone;
  final String province;
  final String district;
  final String ward;
  final String detailAddress;
  final bool isDefault;

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'province': province,
      'district': district,
      'ward': ward,
      'detailAddress': detailAddress,
      'isDefault': isDefault,
    };
  }
}
