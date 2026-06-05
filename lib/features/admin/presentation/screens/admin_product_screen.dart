import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../product/data/models/product_model.dart';
import '../../providers/admin_product_provider.dart';
import '../widgets/admin_action_button.dart';
import '../widgets/admin_empty_view.dart';
import '../widgets/admin_status_chip.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final _searchController = TextEditingController();
  bool _didStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didStart) {
      return;
    }

    _didStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      if (!(authProvider.currentUser?.isAdmin ?? false)) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        return;
      }

      context.read<AdminProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitSearch() {
    return context.read<AdminProductProvider>().loadProducts(
      keyword: _searchController.text,
    );
  }

  Future<void> _openForm({String? productId}) async {
    final shouldRefresh = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminProductForm,
      arguments: productId == null ? null : {'productId': productId},
    );

    if (!mounted || shouldRefresh != true) {
      return;
    }

    await context.read<AdminProductProvider>().loadProducts();
  }

  void _openImages(String productId) {
    Navigator.of(context).pushNamed(
      AppRoutes.adminProductImages,
      arguments: {'productId': productId},
    );
  }

  Future<void> _confirmHideProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ẩn sản phẩm'),
          content: const Text('Bạn có chắc chắn muốn ẩn sản phẩm này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ẩn'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<AdminProductProvider>();
    final success = await provider.hideProduct(product.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã ẩn sản phẩm.'
              : provider.errorMessage ?? 'Không thể ẩn sản phẩm.',
        ),
      ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sản phẩm')),
      body: Consumer<AdminProductProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => provider.loadProducts(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _ProductToolbar(
                  controller: _searchController,
                  isLoading: provider.isLoading,
                  onSearch: _submitSearch,
                  onChanged: () => setState(() {}),
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.products.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải sản phẩm...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.products.isEmpty)
                  _ProductErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadProducts(),
                  )
                else if (provider.products.isEmpty)
                  const _ProductEmptyView()
                else ...[
                  if (provider.isLoading || provider.isDeleting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ...provider.products.map(
                    (product) => _ProductCard(
                      product: product,
                      isBusy: provider.isDeleting,
                      onEdit: () => _openForm(productId: product.id),
                      onImages: () => _openImages(product.id),
                      onHide: () => _confirmHideProduct(product),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminProductFormPlaceholderScreen extends StatelessWidget {
  const AdminProductFormPlaceholderScreen({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (provider) => provider.currentUser?.isAdmin ?? false,
    );
    if (!isAdmin) {
      return const _NoPermissionView();
    }

    final isEditing = productId != null && productId!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isEditing ? 'Form sửa sản phẩm' : 'Form thêm sản phẩm',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.darkBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductToolbar extends StatelessWidget {
  const _ProductToolbar({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
    required this.onChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onSearch;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Tìm sản phẩm',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      controller.clear();
                      onSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        AdminActionButton(
          onPressed: isLoading ? null : onAdd,
          icon: Icons.add_rounded,
          label: '+ Thêm sản phẩm',
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isBusy,
    required this.onEdit,
    required this.onImages,
    required this.onHide,
  });

  final ProductModel product;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onImages;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final category = _fallbackText(product.categoryName);
    final brand = _fallbackText(product.brandName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(url: product.thumbnailUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${_fallbackText(product.sku)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(label: category, icon: Icons.category_rounded),
                      _InfoChip(label: brand, icon: Icons.sell_rounded),
                      AdminStatusChip(
                        status: product.isActive ? 'ACTIVE' : 'INACTIVE',
                        label: product.isActive ? 'Đang bán' : 'Đã ẩn',
                      ),
                      if (product.requiresPrescription)
                        const _PrescriptionChip(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onImages,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('Quản lý ảnh'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Sửa'),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: isBusy ? null : onHide,
                        icon: const Icon(Icons.visibility_off_rounded),
                        label: const Text('Ẩn'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Chưa có' : text;
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 78,
        height: 78,
        color: AppTheme.lightBlue,
        child: imageUrl == null || imageUrl.isEmpty
            ? const Icon(
                Icons.medication_rounded,
                color: AppTheme.primaryBlue,
                size: 34,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.medication_rounded,
                    color: AppTheme.primaryBlue,
                    size: 34,
                  );
                },
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryBlue),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PrescriptionChip extends StatelessWidget {
  const _PrescriptionChip();

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: const Text('Cần đơn thuốc'),
      visualDensity: VisualDensity.compact,
      backgroundColor: AppTheme.warning.withValues(alpha: 0.14),
      labelStyle: const TextStyle(
        color: AppTheme.warning,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ProductErrorView extends StatelessWidget {
  const _ProductErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
      ),
    );
  }
}

class _ProductEmptyView extends StatelessWidget {
  const _ProductEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: AdminEmptyView(
        message: 'Chưa có sản phẩm phù hợp.',
        icon: Icons.medication_rounded,
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
