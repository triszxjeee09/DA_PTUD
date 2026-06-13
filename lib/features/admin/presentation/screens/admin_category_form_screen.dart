import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/data/services/file_upload_service.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_category_model.dart';
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
  final _imagePicker = ImagePicker();
  final _fileUploadService = FileUploadService();

  String? _parentId;
  bool _isActive = true;
  bool _didStart = false;
  bool _isSlugEditedManually = false;
  bool _isUploadingImage = false;
  String _lastGeneratedSlug = '';
  String? _categoryIdFromArguments;

  String? get _categoryId {
    final fromWidget = _emptyToNull(widget.categoryId);
    if (fromWidget != null) {
      return fromWidget;
    }

    return _emptyToNull(_categoryIdFromArguments);
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_syncSlugFromName);
    _slugController.addListener(_trackManualSlugEdit);
    _imageUrlController.addListener(_refreshImagePreview);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    _categoryIdFromArguments = _readCategoryIdArgument();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncSlugFromName);
    _slugController.removeListener(_trackManualSlugEdit);
    _imageUrlController.removeListener(_refreshImagePreview);
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
    await provider.loadCategories(refresh: true);

    final categoryId = _categoryId;
    if (categoryId == null || !mounted) {
      return;
    }

    await provider.loadCategoryDetail(categoryId);

    if (!mounted) {
      return;
    }

    final category = provider.selectedCategory;
    if (category == null) {
      _showMessage(provider.errorMessage ?? 'Không thể tải danh mục.');
      return;
    }

    _fillForm(category);
  }

  void _fillForm(AdminCategoryModel category) {
    _nameController.text = category.name;
    _slugController.text = category.slug;
    _descriptionController.text = category.description ?? '';
    _imageUrlController.text = category.imageUrl ?? '';
    _lastGeneratedSlug = category.slug;
    _isSlugEditedManually = true;

    setState(() {
      _parentId = _emptyToNull(category.parentId);
      _isActive = category.isActive;
    });
  }

  void _syncSlugFromName() {
    if (_isSlugEditedManually) {
      return;
    }

    final slug = _toSlug(_nameController.text);
    _lastGeneratedSlug = slug;
    if (_slugController.text == slug) {
      return;
    }

    _slugController.text = slug;
  }

  void _trackManualSlugEdit() {
    final slug = _slugController.text.trim();
    if (slug.isEmpty || slug == _lastGeneratedSlug) {
      return;
    }

    _isSlugEditedManually = true;
  }

  void _refreshImagePreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickAndUploadCategoryImage() async {
    if (_isUploadingImage) {
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1400,
      );
      if (pickedFile == null || !mounted) {
        return;
      }

      setState(() => _isUploadingImage = true);
      final uploadResponse = await _fileUploadService.uploadImage(
        file: File(pickedFile.path),
        folder: 'categories',
      );

      if (!mounted) {
        return;
      }

      final fileUrl = uploadResponse.fileUrl.trim();
      if (fileUrl.isEmpty) {
        _showMessage('Không thể tải ảnh danh mục');
        return;
      }

      _imageUrlController.text = fileUrl;
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể tải ảnh danh mục');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
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

    final categoryId = _categoryId;
    final success = categoryId == null
        ? await provider.createCategory(request)
        : await provider.updateCategory(categoryId, request);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Không thể lưu danh mục.');
      return;
    }

    _showMessage(
      categoryId == null
          ? 'Thêm danh mục thành công'
          : 'Cập nhật danh mục thành công',
    );
    Navigator.pop(context, true);
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
    final isBusy =
        provider.isSubmitting || provider.isLoadingDetail || _isUploadingImage;
    final categoryId = _categoryId;
    final parentOptions = provider.categories
        .where((category) => category.id != categoryId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryId == null ? 'Thêm danh mục' : 'Sửa danh mục'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                _Section(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: !isBusy,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục',
                        hintText: 'VD: Thuốc không kê đơn',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      validator: (value) => _emptyToNull(value) == null
                          ? 'Tên danh mục không được rỗng'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _slugController,
                      enabled: !isBusy,
                      decoration: const InputDecoration(
                        labelText: 'Slug',
                        hintText: 'VD: thuoc-khong-ke-don',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                      validator: _validateSlug,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isBusy,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        hintText: 'Mô tả ngắn về danh mục',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ImageUploadField(
                      imageUrl: _imageUrlController.text,
                      isUploading: _isUploadingImage,
                      onChooseImage: _pickAndUploadCategoryImage,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrlController,
                      enabled: !isBusy,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Ảnh danh mục',
                        hintText: 'Nhập URL ảnh hoặc upload sau',
                        prefixIcon: Icon(Icons.image_rounded),
                      ),
                      validator: _validateImageUrl,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Section(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _safeDropdownValue(
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
                    const SizedBox(height: 8),
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
          child: AppPrimaryButton(
            label: provider.isSubmitting ? 'Đang lưu...' : 'Lưu danh mục',
            icon: Icons.save_rounded,
            isLoading: provider.isSubmitting,
            onPressed: isBusy ? null : _submit,
          ),
        ),
      ),
    );
  }

  String? _readCategoryIdArgument() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      return _emptyToNull(arguments['categoryId']?.toString());
    }

    return null;
  }

  String? _validateSlug(String? value) {
    final slug = _emptyToNull(value);
    if (slug == null) {
      return 'Slug không được rỗng';
    }

    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      return 'Slug chỉ gồm chữ thường, số và dấu gạch ngang';
    }

    return null;
  }

  String? _validateImageUrl(String? value) {
    final url = _emptyToNull(value);
    if (url == null) {
      return null;
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.trim().isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL ảnh không hợp lệ';
    }

    return null;
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

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _toSlug(String value) {
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

class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: children),
      ),
    );
  }
}

class _ImageUploadField extends StatelessWidget {
  const _ImageUploadField({
    required this.imageUrl,
    required this.isUploading,
    required this.onChooseImage,
  });

  final String imageUrl;
  final bool isUploading;
  final VoidCallback onChooseImage;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const AppLoading(),
                  errorWidget: (context, url, error) =>
                      const _ImageUploadPlaceholder(),
                )
              else
                const _ImageUploadPlaceholder(),
              if (isUploading)
                const ColoredBox(
                  color: Color(0xAAFFFFFF),
                  child: AppLoading(message: 'Đang tải ảnh...'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onChooseImage,
          icon: const Icon(Icons.photo_library_rounded),
          label: Text(isUploading ? 'Đang tải ảnh...' : 'Chọn ảnh'),
        ),
      ],
    );
  }
}

class _ImageUploadPlaceholder extends StatelessWidget {
  const _ImageUploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            color: AppTheme.primaryBlue,
            size: 42,
          ),
          SizedBox(height: 8),
          Text('Chưa có ảnh danh mục'),
        ],
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
