import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../category/data/models/category_model.dart';
import '../../providers/admin_category_provider.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
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

      context.read<AdminCategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({String? categoryId}) async {
    final shouldRefresh = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminCategoryForm,
      arguments: categoryId == null ? null : {'categoryId': categoryId},
    );

    if (!mounted || shouldRefresh != true) {
      return;
    }

    await context.read<AdminCategoryProvider>().loadCategories();
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ẩn danh mục'),
          content: Text(
            'Bạn có chắc chắn muốn ẩn danh mục "${category.name}" không?',
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

    final provider = context.read<AdminCategoryProvider>();
    final success = await provider.deleteCategory(category.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã ẩn danh mục'
              : provider.errorMessage ?? 'Không thể ẩn danh mục.',
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
      appBar: AppBar(title: const Text('Quản lý danh mục')),
      body: Consumer<AdminCategoryProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => provider.loadCategories(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _CategoryToolbar(
                  controller: _searchController,
                  isLoading: provider.isLoading,
                  onSearchChanged: provider.search,
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 16),
                if (provider.isLoading && provider.allCategories.isEmpty)
                  const SizedBox(
                    height: 360,
                    child: AppLoading(message: 'Đang tải danh mục...'),
                  )
                else if (provider.errorMessage != null &&
                    provider.allCategories.isEmpty)
                  _CategoryErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadCategories(),
                  )
                else if (provider.categories.isEmpty)
                  const _CategoryEmptyView()
                else ...[
                  if (provider.isLoading || provider.isDeleting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ...provider.categories.map(
                    (category) => _CategoryCard(
                      category: category,
                      isBusy: provider.isDeleting,
                      onEdit: () => _openForm(categoryId: category.id),
                      onDelete: () => _confirmDelete(category),
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

class _CategoryToolbar extends StatelessWidget {
  const _CategoryToolbar({
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
            hintText: 'Tìm danh mục',
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
          label: const Text('+ Thêm danh mục'),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Slug: ${category.slug}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(isActive: category.isActive),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _fallback(category.description, 'Chưa có mô tả'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            if ((category.parentName ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Danh mục cha: ${category.parentName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    );
  }

  String _fallback(String? value, String fallback) {
    final text = value?.trim();
    return text == null || text.isEmpty ? fallback : text;
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

class _CategoryErrorView extends StatelessWidget {
  const _CategoryErrorView({required this.message, required this.onRetry});

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

class _CategoryEmptyView extends StatelessWidget {
  const _CategoryEmptyView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 320,
      child: Center(
        child: Text('Chưa có danh mục phù hợp.', textAlign: TextAlign.center),
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
