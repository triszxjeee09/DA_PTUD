import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../brand/data/models/brand_model.dart';
import '../../providers/admin_brand_provider.dart';

class AdminBrandScreen extends StatefulWidget {
  const AdminBrandScreen({super.key});

  @override
  State<AdminBrandScreen> createState() => _AdminBrandScreenState();
}

class _AdminBrandScreenState extends State<AdminBrandScreen> {
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

      context.read<AdminBrandProvider>().loadBrands();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({String? brandId}) async {
    final shouldRefresh = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminBrandForm,
      arguments: brandId == null ? null : {'brandId': brandId},
    );

    if (!mounted || shouldRefresh != true) {
      return;
    }

    await context.read<AdminBrandProvider>().loadBrands();
  }

  Future<void> _confirmDelete(BrandModel brand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ẩn thương hiệu'),
          content: Text(
            'Bạn có chắc chắn muốn ẩn thương hiệu "${brand.name}" không?',
          ),
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

    final provider = context.read<AdminBrandProvider>();
    final success = await provider.deleteBrand(brand.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã ẩn thương hiệu'
              : provider.errorMessage ?? 'Không thể ẩn thương hiệu.',
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
      appBar: AppBar(title: const Text('Quản lý thương hiệu')),
      body: Consumer<AdminBrandProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => provider.loadBrands(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _BrandToolbar(
                  controller: _searchController,
                  isLoading: provider.isLoading,
                  onSearchChanged: provider.search,
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.allBrands.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải thương hiệu...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.allBrands.isEmpty)
                  _BrandErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadBrands(),
                  )
                else if (provider.brands.isEmpty)
                  const _BrandEmptyView()
                else ...[
                  if (provider.isLoading || provider.isDeleting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ...provider.brands.map(
                    (brand) => _BrandCard(
                      brand: brand,
                      isBusy: provider.isDeleting,
                      onEdit: () => _openForm(brandId: brand.id),
                      onDelete: () => _confirmDelete(brand),
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

class _BrandToolbar extends StatelessWidget {
  const _BrandToolbar({
    required this.controller,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm thương hiệu',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('+ Thêm thương hiệu'),
        ),
      ],
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.brand,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final BrandModel brand;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandLogo(url: brand.logoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          brand.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatusChip(isActive: brand.isActive),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Quốc gia: ${_fallback(brand.country, 'Chưa có')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _fallback(brand.description, 'Chưa có mô tả'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Sửa'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: isBusy ? null : onDelete,
                          icon: const Icon(Icons.visibility_off_rounded),
                          label: const Text('Ẩn'),
                        ),
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

  String _fallback(String? value, String fallback) {
    final text = value?.trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final logoUrl = url?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 58,
        height: 58,
        color: AppTheme.lightBlue,
        child: logoUrl == null || logoUrl.isEmpty
            ? const Icon(
                Icons.sell_rounded,
                color: AppTheme.primaryBlue,
                size: 30,
              )
            : CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.sell_rounded,
                  color: AppTheme.primaryBlue,
                  size: 30,
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Đang hoạt động' : 'Đã ẩn'),
      visualDensity: VisualDensity.compact,
      backgroundColor: isActive
          ? AppTheme.success.withValues(alpha: 0.12)
          : AppTheme.textSecondary.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        color: isActive ? AppTheme.success : AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BrandErrorView extends StatelessWidget {
  const _BrandErrorView({required this.message, required this.onRetry});

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

class _BrandEmptyView extends StatelessWidget {
  const _BrandEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: Text(
          'Chưa có thương hiệu phù hợp.',
          textAlign: TextAlign.center,
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
