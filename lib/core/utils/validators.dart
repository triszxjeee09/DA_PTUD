class Validators {
  const Validators._();

  static String? requiredField(
    String? value, {
    String fieldName = 'Trường này',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }

    return null;
  }

  static String? phoneNumber(String? value) {
    final requiredError = requiredField(value, fieldName: 'Số điện thoại');
    if (requiredError != null) {
      return requiredError;
    }

    final normalizedValue = value!.trim();
    if (!RegExp(r'^(0[0-9]{9}|\+84[0-9]{9})$').hasMatch(normalizedValue)) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }
}
