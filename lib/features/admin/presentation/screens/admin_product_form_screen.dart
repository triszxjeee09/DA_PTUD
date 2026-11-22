import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../brand/providers/brand_provider.dart';
import '../../../category/providers/category_provider.dart';
import '../../../product/data/models/product_model.dart';
import '../../data/models/admin_product_request_model.dart';
import '../../providers/admin_product_provider.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _slugController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _usageInstructionsController = TextEditingController();
  final _dosageController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _precautionsController = TextEditingController();
  final _storageInstructionsController = TextEditingController();
  final _dosageFormController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _contraindicationsController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();

  String? _categoryId;
  String? _brandId;
  bool _requiresPrescription = false;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _didStart = false;

  bool get _isEditing => widget.productId?.trim().isNotEmpty ?? false;

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
    _skuController.dispose();
    _slugController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _usageInstructionsController.dispose();
    _dosageController.dispose();
    _sideEffectsController.dispose();
    _precautionsController.dispose();
    _storageInstructionsController.dispose();
    _dosageFormController.dispose();
    _targetAudienceController.dispose();
    _symptomsController.dispose();
    _manufacturerController.dispose();
    _contraindicationsController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) {
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();
    final brandProvider = context.read<BrandProvider>();

    await Future.wait([
      categoryProvider.loadCategories(),
      brandProvider.loadBrands(),
    ]);

    if (!_isEditing || !mounted) {
      return;
    }

    final product = await context
        .read<AdminProductProvider>()
        .loadProductDetail(widget.productId!.trim());

    if (!mounted) {
      return;
    }

    if (product == null) {
      _showMessage(
        context.read<AdminProductProvider>().errorMessage ??
            'Không thể tải thông tin sản phẩm.',
      );
      return;
    }

    _fillForm(product);
  }

  void _fillForm(ProductModel product) {
    _nameController.text = product.name;
    _skuController.text = product.sku;
    _slugController.text = product.slug;
    _shortDescriptionController.text = product.shortDescription ?? '';
    _descriptionController.text = product.description ?? '';
    _ingredientsController.text = product.ingredients ?? '';
    _usageInstructionsController.text = product.usageInstructions ?? '';
    _dosageController.text = product.dosage ?? '';
    _sideEffectsController.text = product.sideEffects ?? '';
    _precautionsController.text = product.precautions ?? '';
    _storageInstructionsController.text = product.storageInstructions ?? '';
    _dosageFormController.text = product.dosageForm ?? '';
    _targetAudienceController.text = product.targetAudience ?? '';
    _symptomsController.text = product.symptoms ?? '';
    _manufacturerController.text = product.manufacturer ?? '';
    _contraindicationsController.text = product.contraindications ?? '';
    _unitController.text = product.unit;
    _priceController.text = _formatNumber(product.price);
    _originalPriceController.text = product.originalPrice == null
        ? ''
        : _formatNumber(product.originalPrice!);

    setState(() {
      _categoryId = _emptyToNull(product.categoryId);
      _brandId = _emptyToNull(product.brandId);
      _requiresPrescription = product.requiresPrescription;
      _isFeatured = product.isFeatured;
      _isActive = product.isActive;
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

    final provider = context.read<AdminProductProvider>();
    final request = AdminProductRequestModel(
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      slug: _slugController.text.trim().isEmpty
          ? _toSlug(_nameController.text)
          : _slugController.text.trim(),
      categoryId: _categoryId!.trim(),
      brandId: _emptyToNull(_brandId),
      shortDescription: _emptyToNull(_shortDescriptionController.text),
      description: _emptyToNull(_descriptionController.text),
      ingredients: _emptyToNull(_ingredientsController.text),
      usageInstructions: _emptyToNull(_usageInstructionsController.text),
      dosage: _emptyToNull(_dosageController.text),
      sideEffects: _emptyToNull(_sideEffectsController.text),
      precautions: _emptyToNull(_precautionsController.text),
      storageInstructions: _emptyToNull(_storageInstructionsController.text),
      dosageForm: _emptyToNull(_dosageFormController.text),
      targetAudience: _emptyToNull(_targetAudienceController.text),
      symptoms: _emptyToNull(_symptomsController.text),
      manufacturer: _emptyToNull(_manufacturerController.text),
      contraindications: _emptyToNull(_contraindicationsController.text),
      unit: _unitController.text.trim(),
      price: _readMoney(_priceController.text),
      originalPrice: _readNullableMoney(_originalPriceController.text),
      requiresPrescription: _requiresPrescription,
      isFeatured: _isFeatured,
      isActive: _isActive,
    );

    final success = _isEditing
        ? await provider.updateProduct(widget.productId!.trim(), request)
        : await provider.createProduct(request);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Không thể lưu sản phẩm.');
      return;
    }

    _showMessage(
      _isEditing ? 'Cập nhật sản phẩm thành công' : 'Thêm sản phẩm thành công',
    );
    Navigator.of(context).pop(true);
  }

  void _openImages() {
    if (!_isEditing) {
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.adminProductImages,
      arguments: {'productId': widget.productId!.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );

    if (!isAdmin) {
      return const _NoPermissionView();
    }

    final adminProvider = context.watch<AdminProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final brandProvider = context.watch<BrandProvider>();
    final isBusy = adminProvider.isSaving || adminProvider.isLoadingDetail;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (_isEditing) ...[
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : _openImages,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('Quản lý ảnh'),
                  ),
                  const SizedBox(height: 16),
                ],
                _FieldGroup(
                  title: 'Thông tin cơ bản',
                  children: [
                    _TextInput(
                      controller: _nameController,
                      label: 'Tên sản phẩm',
                      validator: _required('Tên sản phẩm không được rỗng'),
                    ),
                    _TextInput(
                      controller: _skuController,
                      label: 'SKU',
                      validator: _required('SKU không được rỗng'),
                    ),
                    _TextInput(controller: _slugController, label: 'Slug'),
                    DropdownButtonFormField<String>(
                      initialValue: _safeDropdownValue(
                        _categoryId,
                        categoryProvider.categories.map((item) => item.id),
                      ),
                      items: categoryProvider.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: isBusy
                          ? null
                          : (value) => setState(() => _categoryId = value),
                      decoration: InputDecoration(
                        labelText: categoryProvider.isLoading
                            ? 'Đang tải danh mục...'
                            : 'Danh mục',
                        prefixIcon: const Icon(Icons.category_rounded),
                      ),
                      validator: (value) => _emptyToNull(value) == null
                          ? 'Danh mục không được rỗng'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _safeDropdownValue(
                        _brandId,
                        brandProvider.brands.map((item) => item.id),
                      ),
                      items: brandProvider.brands
                          .map(
                            (brand) => DropdownMenuItem(
                              value: brand.id,
                              child: Text(brand.name),
                            ),
                          )
                          .toList(),
                      onChanged: isBusy
                          ? null
                          : (value) => setState(() => _brandId = value),
                      decoration: InputDecoration(
                        labelText: brandProvider.isLoading
                            ? 'Đang tải thương hiệu...'
                            : 'Thương hiệu',
                        prefixIcon: const Icon(Icons.sell_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FieldGroup(
                  title: 'Mô tả sản phẩm',
                  children: [
                    _TextInput(
                      controller: _shortDescriptionController,
                      label: 'Mô tả ngắn',
                      maxLines: 3,
                    ),
                    _TextInput(
                      controller: _descriptionController,
                      label: 'Mô tả chi tiết',
                      maxLines: 5,
                    ),
                    _TextInput(
                      controller: _ingredientsController,
                      label: 'Thành phần',
                      maxLines: 3,
                    ),
                    _TextInput(
                      controller: _usageInstructionsController,
                      label: 'Cách dùng',
                      maxLines: 3,
                    ),
                    _TextInput(
                      controller: _dosageController,
                      label: 'Liều dùng',
                      maxLines: 3,
                    ),
                    _TextInput(
                      controller: _sideEffectsController,
                      label: 'Tác dụng phụ',
                      maxLines: 3,
                    ),
                    _TextInput(
                      controller: _precautionsController,
                      label: 'Lưu ý',
                      maxLines: 3,
                    ),
                    _TextInput(
                      controller: _storageInstructionsController,
                      label: 'Bảo quản',
                      maxLines: 3,
                    ),
                    _TextInput(
                      controller: _dosageFormController,
                      label: 'Dạng bào chế (viên nén, siro...)',
                      maxLines: 1,
                    ),
                    _TextInput(
                      controller: _targetAudienceController,
                      label: 'Đối tượng sử dụng',
                      maxLines: 2,
                    ),
                    _TextInput(
                      controller: _symptomsController,
                      label: 'Triệu chứng/công dụng (cách nhau dấu phẩy)',
                      maxLines: 2,
                    ),
                    _TextInput(
                      controller: _manufacturerController,
                      label: 'Nhà sản xuất',
                      maxLines: 1,
                    ),
                    _TextInput(
                      controller: _contraindicationsController,
                      label: 'Chống chỉ định',
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _FieldGroup(
                  title: 'Giá và trạng thái',
                  children: [
                    _TextInput(
                      controller: _unitController,
                      label: 'Đơn vị',
                      validator: _required('Đơn vị không được rỗng'),
                    ),
                    _TextInput(
                      controller: _priceController,
                      label: 'Giá bán',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (_readMoney(value) <= 0) {
                          return 'Giá bán phải lớn hơn 0';
                        }

                        return null;
                      },
                    ),
                    _TextInput(
                      controller: _originalPriceController,
                      label: 'Giá gốc',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _SwitchRow(
                      title: 'Cần đơn thuốc',
                      value: _requiresPrescription,
                      onChanged: isBusy
                          ? null
                          : (value) =>
                                setState(() => _requiresPrescription = value),
                    ),
                    _SwitchRow(
                      title: 'Sản phẩm nổi bật',
                      value: _isFeatured,
                      onChanged: isBusy
                          ? null
                          : (value) => setState(() => _isFeatured = value),
                    ),
                    _SwitchRow(
                      title: 'Đang bán',
                      value: _isActive,
                      onChanged: isBusy
                          ? null
                          : (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
                if (categoryProvider.errorMessage != null ||
                    brandProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    categoryProvider.errorMessage ??
                        brandProvider.errorMessage ??
                        '',
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (adminProvider.isLoadingDetail)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99FFFFFF),
                child: AppLoading(message: 'Đang tải sản phẩm...'),
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
            icon: adminProvider.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(adminProvider.isSaving ? 'Đang lưu...' : 'Lưu'),
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

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toString();
  }

  String? _safeDropdownValue(String? value, Iterable<String> options) {
    final selected = _emptyToNull(value);
    if (selected == null) {
      return null;
    }

    return options.contains(selected) ? selected : null;
  }

  double _readMoney(String? value) {
    return double.tryParse((value ?? '').replaceAll(',', '').trim()) ?? 0;
  }

  double? _readNullableMoney(String? value) {
    final text = value?.replaceAll(',', '').trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
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

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.darkBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...children.expand((child) => [child, const SizedBox(height: 12)]),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      activeThumbColor: AppTheme.primaryBlue,
      contentPadding: EdgeInsets.zero,
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
