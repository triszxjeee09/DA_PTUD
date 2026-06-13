class UpdateProfileRequestModel {
  const UpdateProfileRequestModel({
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
  });

  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? gender;
  final String? dateOfBirth;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'dateOfBirth': _formatDateOfBirth(dateOfBirth),
    };
  }

  String? _formatDateOfBirth(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    final parsedDate = DateTime.tryParse(text);
    if (parsedDate == null) {
      return text;
    }

    final year = parsedDate.year.toString().padLeft(4, '0');
    final month = parsedDate.month.toString().padLeft(2, '0');
    final day = parsedDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
