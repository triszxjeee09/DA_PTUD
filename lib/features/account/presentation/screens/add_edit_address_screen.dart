import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../data/models/user_address_model.dart';
import '../../data/models/user_address_request_model.dart';
import '../../providers/user_address_provider.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key, this.addressId, this.address});

  final String? addressId;
  final UserAddressModel? address;

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _detailAddressController = TextEditingController();

  bool _isDefault = false;
  bool _didFillForm = false;

  bool get _isEditing => _effectiveAddressId != null;

  String? get _effectiveAddressId {
    final id = widget.addressId ?? widget.address?.id;
    if (id == null || id.trim().isEmpty) {
      return null;
    }

    return id;
  }

  @override
  void initState() {
    super.initState();
    _fillForm(widget.address);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.address != null || _effectiveAddressId == null) {
        return;
      }

      final provider = context.read<UserAddressProvider>();
      if (provider.addresses.isEmpty) {
        await provider.loadAddresses();
      }

      if (!mounted) {
        return;
      }

      _fillForm(_findAddress(provider.addresses, _effectiveAddressId!));
      setState(() {});
    });
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final request = UserAddressRequestModel(
      receiverName: _receiverNameController.text.trim(),
      receiverPhone: _receiverPhoneController.text.trim(),
      province: _provinceController.text.trim(),
      district: _districtController.text.trim(),
      ward: _wardController.text.trim(),
      detailAddress: _detailAddressController.text.trim(),
      isDefault: _isDefault,
    );

    final provider = context.read<UserAddressProvider>();
    final addressId = _effectiveAddressId;
    final success = addressId == null
        ? await provider.createAddress(request)
        : await provider.updateAddress(addressId, request);

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            addressId == null
                ? 'Thêm địa chỉ thành công'
                : 'Cập nhật địa chỉ thành công',
          ),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text(provider.errorMessage ?? 'Không thể lưu địa chỉ')),
    );
  }

  void _fillForm(UserAddressModel? address) {
    if (address == null || _didFillForm) {
      return;
    }

    _receiverNameController.text = address.receiverName;
    _receiverPhoneController.text = address.receiverPhone;
    _provinceController.text = address.province;
    _districtController.text = address.district;
    _wardController.text = address.ward;
    _detailAddressController.text = address.detailAddress;
    _isDefault = address.isDefault;
    _didFillForm = true;
  }

  UserAddressModel? _findAddress(
    List<UserAddressModel> addresses,
    String addressId,
  ) {
    for (final address in addresses) {
      if (address.id == addressId) {
        return address;
      }
    }

    return null;
  }

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<UserAddressProvider>().isSaving;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(title: Text(_isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _AddressTextField(
                      controller: _receiverNameController,
                      label: 'Tên người nhận',
                      hintText: 'Nhập họ và tên',
                      icon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _requiredValidator(
                        value,
                        'Vui lòng nhập tên người nhận',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AddressTextField(
                      controller: _receiverPhoneController,
                      label: 'Số điện thoại',
                      hintText: 'Nhập số điện thoại',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _requiredValidator(
                        value,
                        'Vui lòng nhập số điện thoại',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AddressTextField(
                      controller: _provinceController,
                      label: 'Tỉnh / Thành phố',
                      hintText: 'Nhập Tỉnh / Thành phố',
                      icon: Icons.location_city_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _requiredValidator(
                        value,
                        'Vui lòng nhập Tỉnh / Thành phố',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AddressTextField(
                      controller: _districtController,
                      label: 'Quận / Huyện',
                      hintText: 'Nhập Quận / Huyện',
                      icon: Icons.map_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _requiredValidator(
                        value,
                        'Vui lòng nhập Quận / Huyện',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AddressTextField(
                      controller: _wardController,
                      label: 'Phường / Xã',
                      hintText: 'Nhập Phường / Xã',
                      icon: Icons.place_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _requiredValidator(
                        value,
                        'Vui lòng nhập Phường / Xã',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _AddressTextField(
                      controller: _detailAddressController,
                      label: 'Địa chỉ chi tiết',
                      hintText: 'Số nhà, tên đường, tòa nhà...',
                      icon: Icons.home_outlined,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      validator: (value) => _requiredValidator(
                        value,
                        'Vui lòng nhập địa chỉ chi tiết',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _isDefault,
              onChanged: isSaving
                  ? null
                  : (value) {
                      setState(() {
                        _isDefault = value ?? false;
                      });
                    },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryBlue,
              title: const Text(
                'Đặt làm địa chỉ mặc định',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isSaving ? null : _saveAddress,
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(_isEditing ? 'Cập nhật địa chỉ' : 'Lưu địa chỉ'),
          ),
        ),
      ),
    );
  }
}

class _AddressTextField extends StatelessWidget {
  const _AddressTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: maxLines == 1 ? Icon(icon) : null,
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }
}
