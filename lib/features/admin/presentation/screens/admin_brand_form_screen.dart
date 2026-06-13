import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../brand/data/models/brand_model.dart';
import '../../data/models/admin_brand_request_model.dart';
import '../../providers/admin_brand_provider.dart';

class AdminBrandFormScreen extends StatefulWidget {
  const AdminBrandFormScreen({super.key, this.brandId});

  final String? brandId;

  @override
  State<AdminBrandFormScreen> createState() => _AdminBrandFormScreenState();
}

class _AdminBrandFormScreenState extends State<AdminBrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoUrlController = TextEditingController();

  bool _isActive = true;
  bool _didStart = false;

  bool get _isEditing => widget.brandId?.trim().isNotEmpty ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!_isEditing || !mounted) {
      return;
    }

    final provider = context.read<AdminBrandProvider>();
    final brand = await provider.loadBrandDetail(widget.brandId!.trim());

    if (!mounted) {
      return;
    }

    if (brand == null) {
      _showMessage(provider.errorMessage ?? 'Không thể tải thương hiệu.');
      return;
    }

    _fillForm(brand);
  }

  void _fillForm(BrandModel brand) {
    _nameController.text = brand.name;
    _countryController.text = brand.country ?? '';
    _descriptionController.text = brand.description ?? '';
    _logoUrlController.text = brand.logoUrl ?? '';

    setState(() => _isActive = brand.isActive);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<AdminBrandProvider>();
    final request = AdminBrandRequestModel(
      name: _nameController.text.trim(),
      country: _emptyToNull(_countryController.text),
      description: _emptyToNull(_descriptionController.text),
      logoUrl: _emptyToNull(_logoUrlController.text),
      isActive: _isActive,
    );

    final success = _isEditing
        ? await provider.updateBrand(widget.brandId!.trim(), request)
        : await provider.createBrand(request);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Không thể lưu thương hiệu.');
      return;
    }

    _showMessage(
      _isEditing
          ? 'Cập nhật thương hiệu thành công'
          : 'Thêm thương hiệu thành công',
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

    final provider = context.watch<AdminBrandProvider>();
    final isBusy = provider.isSaving || provider.isLoadingDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa thương hiệu' : 'Thêm thương hiệu'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thương hiệu',
                  ),
                  validator: (value) => _emptyToNull(value) == null
                      ? 'Tên thương hiệu không được rỗng'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(labelText: 'Quốc gia'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _logoUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Logo URL'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  onChanged: isBusy
                      ? null
                      : (value) => setState(() => _isActive = value),
                  title: const Text('Đang hoạt động'),
                  activeThumbColor: AppTheme.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (provider.isLoadingDetail)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99FFFFFF),
                child: AppLoading(message: 'Đang tải thương hiệu...'),
              ),
            ),
        ],
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
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
