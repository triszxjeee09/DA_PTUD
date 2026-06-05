import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../category/data/models/category_model.dart';
import '../../data/models/admin_category_request_model.dart';
import '../../providers/admin_category_provider.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  const AdminCategoryFormScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  State<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _parentId;
  bool _isActive = true;
  bool _didStart = false;

  bool get _isEditing => widget.categoryId?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_generateSlugWhenEmpty);
  }

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
    _nameController.removeListener(_generateSlugWhenEmpty);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) {
      return;
    }

    final provider = context.read<AdminCategoryProvider>();
    if (provider.allCategories.isEmpty) {
      await provider.loadCategories();
    }

    if (!_isEditing || !mounted) {
      return;
    }

    final category = await provider.loadCategoryDetail(
      widget.categoryId!.trim(),
    );

    if (!mounted) {
      return;
    }

    if (category == null) {
      _showMessage(provider.errorMessage ?? 'Không thể tải danh mục.');
      return;
    }

    _fillForm(category);
  }

  void _fillForm(CategoryModel category) {
    _nameController.text = category.name;
    _slugController.text = category.slug;
    _descriptionController.text = category.description ?? '';
    _imageUrlController.text = category.imageUrl ?? '';

    setState(() {
      _parentId = _emptyToNull(category.parentId);
      _isActive = category.isActive;
    });
  }

  void _generateSlugWhenEmpty() {
    if (_slugController.text.trim().isNotEmpty) {
      return;
    }

    final slug = _toSlug(_nameController.text);
    if (_slugController.text == slug) {
      return;
    }

    _slugController.text = slug;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<AdminCategoryProvider>();
    final request = AdminCategoryRequestModel(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      description: _emptyToNull(_descriptionController.text),
      imageUrl: _emptyToNull(_imageUrlController.text),
      parentId: _emptyToNull(_parentId),
      isActive: _isActive,
    );

    final success = _isEditing
        ? await provider.updateCategory(widget.categoryId!.trim(), request)
        : await provider.createCategory(request);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Không thể lưu danh mục.');
      return;
    }

    _showMessage(
      _isEditing ? 'Cập nhật danh mục thành công' : 'Thêm danh mục thành công',
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

    final provider = context.watch<AdminCategoryProvider>();
    final isBusy = provider.isSaving || provider.isLoadingDetail;
    final parentOptions = provider.allCategories
        .where((category) => category.id != widget.categoryId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa danh mục' : 'Thêm danh mục'),
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
                  decoration: const InputDecoration(labelText: 'Tên danh mục'),
                  validator: _required('Tên danh mục không được rỗng'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _slugController,
                  decoration: const InputDecoration(labelText: 'Slug'),
                  validator: _required('Slug không được rỗng'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'URL ảnh'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _safeDropdownValue(
                    _parentId,
                    parentOptions.map((category) => category.id),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Không có danh mục cha'),
                    ),
                    ...parentOptions.map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                  onChanged: isBusy
                      ? null
                      : (value) => setState(() => _parentId = value),
                  decoration: const InputDecoration(
                    labelText: 'Danh mục cha',
                    prefixIcon: Icon(Icons.account_tree_rounded),
                  ),
                ),
                const SizedBox(height: 12),
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
          if (provider.isLoadingDetail)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99FFFFFF),
                child: AppLoading(message: 'Đang tải danh mục...'),
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

  FormFieldValidator<String> _required(String message) {
    return (value) => _emptyToNull(value) == null ? message : null;
  }

  String? _safeDropdownValue(String? value, Iterable<String> options) {
    final selected = _emptyToNull(value);
    if (selected == null) {
      return '';
    }

    return options.contains(selected) ? selected : '';
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

  String _toSlug(String value) {
    var text = value.trim().toLowerCase();
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    replacements.forEach((source, target) {
      text = text.replaceAll(source, target);
    });

    return text
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
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
