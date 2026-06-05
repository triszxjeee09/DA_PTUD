import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../pharmacy/data/models/pharmacy_model.dart';
import '../../data/models/admin_pharmacy_request_model.dart';
import '../../providers/admin_pharmacy_provider.dart';

class AdminPharmacyFormScreen extends StatefulWidget {
  const AdminPharmacyFormScreen({super.key, this.pharmacyId, this.pharmacy});

  final String? pharmacyId;
  final PharmacyModel? pharmacy;

  @override
  State<AdminPharmacyFormScreen> createState() =>
      _AdminPharmacyFormScreenState();
}

class _AdminPharmacyFormScreenState extends State<AdminPharmacyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _openingHoursController = TextEditingController();

  bool _isActive = true;

  bool get _isEditing => widget.pharmacyId?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    final pharmacy = widget.pharmacy;
    if (pharmacy != null) {
      _fillForm(pharmacy);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  void _fillForm(PharmacyModel pharmacy) {
    _nameController.text = pharmacy.name;
    _phoneController.text = pharmacy.phone ?? '';
    _provinceController.text = pharmacy.province;
    _districtController.text = pharmacy.district;
    _wardController.text = pharmacy.ward ?? '';
    _addressController.text = pharmacy.address;
    _latitudeController.text = pharmacy.latitude?.toString() ?? '';
    _longitudeController.text = pharmacy.longitude?.toString() ?? '';
    _openingHoursController.text = pharmacy.openingHours ?? '';
    _isActive = pharmacy.isActive;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<AdminPharmacyProvider>();
    final request = AdminPharmacyRequestModel(
      name: _nameController.text.trim(),
      phone: _emptyToNull(_phoneController.text),
      province: _provinceController.text.trim(),
      district: _districtController.text.trim(),
      ward: _emptyToNull(_wardController.text),
      address: _addressController.text.trim(),
      latitude: _readNullableDouble(_latitudeController.text),
      longitude: _readNullableDouble(_longitudeController.text),
      openingHours: _emptyToNull(_openingHoursController.text),
      isActive: _isActive,
    );

    final success = _isEditing
        ? await provider.updatePharmacy(widget.pharmacyId!.trim(), request)
        : await provider.createPharmacy(request);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Không thể lưu nhà thuốc.');
      return;
    }

    _showMessage(
      _isEditing
          ? 'Cập nhật nhà thuốc thành công'
          : 'Thêm nhà thuốc thành công',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    final provider = context.watch<AdminPharmacyProvider>();
    final isBusy = provider.isSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa nhà thuốc' : 'Thêm nhà thuốc'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _TextInput(
              controller: _nameController,
              label: 'Tên nhà thuốc',
              validator: _required('Tên nhà thuốc không được rỗng'),
            ),
            _TextInput(controller: _phoneController, label: 'Số điện thoại'),
            _TextInput(
              controller: _provinceController,
              label: 'Tỉnh/Thành phố',
              validator: _required('Tỉnh/Thành phố không được rỗng'),
            ),
            _TextInput(
              controller: _districtController,
              label: 'Quận/Huyện',
              validator: _required('Quận/Huyện không được rỗng'),
            ),
            _TextInput(controller: _wardController, label: 'Phường/Xã'),
            _TextInput(
              controller: _addressController,
              label: 'Địa chỉ chi tiết',
              validator: _required('Địa chỉ không được rỗng'),
            ),
            _TextInput(
              controller: _latitudeController,
              label: 'Latitude',
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
            ),
            _TextInput(
              controller: _longitudeController,
              label: 'Longitude',
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
            ),
            _TextInput(
              controller: _openingHoursController,
              label: 'Giờ mở cửa',
            ),
            SwitchListTile(
              value: _isActive,
              onChanged: isBusy
                  ? null
                  : (value) => setState(() => _isActive = value),
              title: const Text('Đang hoạt động'),
              activeColor: AppTheme.primaryBlue,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : _submit,
            icon: provider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(provider.isSaving ? 'Đang lưu...' : 'Lưu'),
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) => _emptyToNull(value) == null ? message : null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  double? _readNullableDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _NoPermissionView extends StatelessWidget {
  const _NoPermissionView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Bạn không có quyền truy cập khu vực Admin.')),
    );
  }
}
