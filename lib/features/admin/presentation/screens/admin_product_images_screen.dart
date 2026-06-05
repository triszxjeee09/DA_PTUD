import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../product/data/models/product_image_model.dart';
import '../../../product/data/models/product_model.dart';
import '../../providers/admin_product_provider.dart';

class AdminProductImagesScreen extends StatefulWidget {
  const AdminProductImagesScreen({super.key, required this.productId});

  final String productId;

  @override
  State<AdminProductImagesScreen> createState() =>
      _AdminProductImagesScreenState();
}

class _AdminProductImagesScreenState extends State<AdminProductImagesScreen> {
  final _imagePicker = ImagePicker();
  List<XFile> _selectedImages = const [];
  bool _didStart = false;

  String get _productId => widget.productId.trim();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
  }

  Future<void> _loadProduct() async {
    if (!mounted || _productId.isEmpty) {
      return;
    }

    await context.read<AdminProductProvider>().loadProductDetail(_productId);
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (!mounted || images.isEmpty) {
      return;
    }

    setState(() => _selectedImages = images);
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      _showMessage('Vui lòng chọn ảnh trước khi upload.');
      return;
    }

    final provider = context.read<AdminProductProvider>();
    final success = await provider.uploadProductImages(
      _productId,
      _selectedImages,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Không thể upload ảnh.');
      return;
    }

    setState(() => _selectedImages = const []);
    _showMessage('Upload ảnh thành công');
  }

  Future<void> _setThumbnail(ProductImageModel image) async {
    final provider = context.read<AdminProductProvider>();
    final success = await provider.setProductThumbnail(_productId, image.id);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Đã đặt ảnh đại diện'
          : provider.errorMessage ?? 'Không thể đặt ảnh đại diện.',
    );
  }

  Future<void> _confirmDelete(ProductImageModel image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa ảnh'),
          content: const Text('Bạn có chắc chắn muốn xóa ảnh này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminProductProvider>();
    final success = await provider.deleteProductImage(_productId, image.id);

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Xóa ảnh thành công'
          : provider.errorMessage ?? 'Không thể xóa ảnh.',
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

    if (_productId.isEmpty) {
      return const Scaffold(
        appBar: _ProductImagesAppBar(),
        body: Center(child: Text('Không tìm thấy sản phẩm.')),
      );
    }

    final provider = context.watch<AdminProductProvider>();
    final selectedProduct = provider.selectedProduct;
    final product = selectedProduct?.id == _productId ? selectedProduct : null;
    final isBusy =
        provider.isLoadingDetail ||
        provider.isUploadingImages ||
        provider.isUpdatingImage;

    return Scaffold(
      appBar: const _ProductImagesAppBar(),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _loadProduct,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (provider.isLoadingDetail && product == null)
              const SizedBox(
                height: 420,
                child: AppLoading(message: 'Đang tải ảnh sản phẩm...'),
              )
            else if (provider.errorMessage != null && product == null)
              _ErrorView(message: provider.errorMessage!, onRetry: _loadProduct)
            else ...[
              _ProductHeader(product: product),
              const SizedBox(height: 16),
              _UploadPanel(
                selectedImages: _selectedImages,
                isUploading: provider.isUploadingImages,
                onPickImages: isBusy ? null : _pickImages,
                onUpload: isBusy ? null : _uploadImages,
                onClear: isBusy
                    ? null
                    : () => setState(() => _selectedImages = const []),
                onRemove: isBusy
                    ? null
                    : (image) {
                        setState(() {
                          _selectedImages = _selectedImages
                              .where((item) => item.path != image.path)
                              .toList();
                        });
                      },
              ),
              const SizedBox(height: 20),
              Text(
                'Danh sách ảnh',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.darkBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (provider.isLoadingDetail)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppTheme.primaryBlue,
                ),
              const SizedBox(height: 12),
              _ImageGrid(
                images: product?.images ?? const [],
                isBusy: isBusy,
                onSetThumbnail: _setThumbnail,
                onDelete: _confirmDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductImagesAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProductImagesAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Ảnh sản phẩm'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final ProductModel? product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product?.name ?? 'Đang tải sản phẩm...',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SKU: ${product?.sku.isNotEmpty == true ? product!.sku : 'Chưa có'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({
    required this.selectedImages,
    required this.isUploading,
    required this.onPickImages,
    required this.onUpload,
    required this.onClear,
    required this.onRemove,
  });

  final List<XFile> selectedImages;
  final bool isUploading;
  final VoidCallback? onPickImages;
  final VoidCallback? onUpload;
  final VoidCallback? onClear;
  final ValueChanged<XFile>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPickImages,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('+ Thêm ảnh'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: selectedImages.isEmpty ? null : onUpload,
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(isUploading ? 'Đang upload...' : 'Upload'),
              ),
            ),
          ],
        ),
        if (selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Preview ảnh đã chọn',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.darkBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onClear, child: const Text('Xóa chọn')),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final image = selectedImages[index];
                return _PreviewImage(image: image, onRemove: onRemove);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.image, required this.onRemove});

  final XFile image;
  final ValueChanged<XFile>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 118,
            height: 118,
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  return const ColoredBox(
                    color: AppTheme.lightBlue,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Image.memory(bytes, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
              minimumSize: const Size.square(30),
            ),
            onPressed: onRemove == null ? null : () => onRemove!(image),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.isBusy,
    required this.onSetThumbnail,
    required this.onDelete,
  });

  final List<ProductImageModel> images;
  final bool isBusy;
  final ValueChanged<ProductImageModel> onSetThumbnail;
  final ValueChanged<ProductImageModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Sản phẩm chưa có ảnh.')),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final image = images[index];
        return _ProductImageTile(
          image: image,
          isBusy: isBusy,
          onSetThumbnail: () => onSetThumbnail(image),
          onDelete: () => onDelete(image),
        );
      },
    );
  }
}

class _ProductImageTile extends StatelessWidget {
  const _ProductImageTile({
    required this.image,
    required this.isBusy,
    required this.onSetThumbnail,
    required this.onDelete,
  });

  final ProductImageModel image;
  final bool isBusy;
  final VoidCallback onSetThumbnail;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: image.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ColoredBox(
                    color: AppTheme.lightBlue,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const ColoredBox(
                    color: AppTheme.lightBlue,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: AppTheme.primaryBlue,
                      size: 34,
                    ),
                  ),
                ),
                if (image.isThumbnail)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          'Ảnh đại diện',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy || image.isThumbnail
                      ? null
                      : onSetThumbnail,
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Đặt đại diện'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: isBusy ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
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
