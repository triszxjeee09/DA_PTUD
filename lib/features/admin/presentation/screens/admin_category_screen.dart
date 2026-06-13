import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/admin_category_model.dart';
import '../../providers/admin_category_provider.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  static const String _formRoute = '/admin/categories/form';

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool? _isActiveFilter;
  bool _didStart = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreWhenNearEnd);
  }

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

      _reload();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadMoreWhenNearEnd);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMoreWhenNearEnd() {
    if (!_scrollController.hasClients) {
      return;
    }

    final provider = context.read<AdminCategoryProvider>();
    if (provider.isLoading ||
        provider.isLoadingMore ||
        provider.isDeleting ||
        !provider.hasMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      provider.loadCategories(
        keyword: _searchController.text,
        isActive: _isActiveFilter,
      );
    }
  }

  Future<void> _reload() {
    return context.read<AdminCategoryProvider>().loadCategories(
      refresh: true,
      keyword: _searchController.text,
      isActive: _isActiveFilter,
    );
  }

  Future<void> _openForm({String? categoryId}) async {
    final normalizedCategoryId = categoryId?.trim();
    if (categoryId != null &&
        (normalizedCategoryId == null || normalizedCategoryId.isEmpty)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã danh mục')),
      );
      return;
    }

    final shouldRefresh = await Navigator.pushNamed<bool>(
      context,
      _formRoute,
      arguments: normalizedCategoryId == null
          ? null
          : {'categoryId': normalizedCategoryId},
    );

    if (!mounted || shouldRefresh != true) {
      return;
    }

    await _reload();
  }

  Future<void> _confirmDelete(AdminCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa danh mục'),
          content: const Text('Bạn có chắc chắn muốn xóa danh mục này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Xóa'),
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
              ? 'Xóa danh mục thành công'
              : provider.errorMessage ?? 'Không thể xóa danh mục',
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
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Consumer<AdminCategoryProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: _reload,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _CategoryToolbar(
                  controller: _searchController,
                  isLoading: provider.isLoading,
                  selectedFilter: _isActiveFilter,
                  onSearch: _reload,
                  onFilterChanged: (value) {
                    setState(() => _isActiveFilter = value);
                    _reload();
                  },
                  onAdd: () => _openForm(),
                ),
                const SizedBox(height: 16),
                _CategoryBody(
                  provider: provider,
                  onRetry: _reload,
                  onEdit: (category) => _openForm(categoryId: category.id),
                  onDelete: _confirmDelete,
                ),
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
    required this.selectedFilter,
    required this.onSearch,
    required this.onFilterChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool? selectedFilter;
  final VoidCallback onSearch;
  final ValueChanged<bool?> onFilterChanged;
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
            hintText: 'Tìm tên hoặc slug danh mục',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Tìm kiếm',
              onPressed: isLoading ? null : onSearch,
              icon: const Icon(Icons.search_rounded),
            ),
          ),
          onSubmitted: (_) => onSearch(),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<bool?>(
            selected: {selectedFilter},
            showSelectedIcon: false,
            onSelectionChanged: isLoading
                ? null
                : (values) => onFilterChanged(values.first),
            segments: const [
              ButtonSegment(value: null, label: Text('Tất cả')),
              ButtonSegment(value: true, label: Text('Đang hoạt động')),
              ButtonSegment(value: false, label: Text('Ngừng hoạt động')),
            ],
          ),
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

class _CategoryBody extends StatelessWidget {
  const _CategoryBody({
    required this.provider,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminCategoryProvider provider;
  final VoidCallback onRetry;
  final ValueChanged<AdminCategoryModel> onEdit;
  final ValueChanged<AdminCategoryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.categories.isEmpty) {
      return const SizedBox(
        height: 360,
        child: AppLoading(message: 'Đang tải danh mục...'),
      );
    }

    if (provider.errorMessage != null && provider.categories.isEmpty) {
      return _CategoryErrorView(
        message: provider.errorMessage!,
        onRetry: onRetry,
      );
    }

    if (provider.categories.isEmpty) {
      return const _CategoryEmptyView();
    }

    return Column(
      children: [
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
            onEdit: () => onEdit(category),
            onDelete: () => onDelete(category),
          ),
        ),
        if (provider.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
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

  final AdminCategoryModel category;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                _CategoryImage(imageUrl: category.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Slug: ${category.slug}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(isActive: category.isActive),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _fallback(category.description, 'Chưa có mô tả'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.account_tree_rounded,
              text:
                  'Danh mục cha: ${_fallback(category.parentName, 'Không có')}',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.calendar_month_rounded,
              text: 'Ngày tạo: ${_formatDate(category.createdAt)}',
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
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Xóa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fallback(String? value, String fallback) {
    final text = value?.trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Chưa có';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final fallback = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.category_rounded,
        color: AppTheme.primaryBlue,
        size: 28,
      ),
    );

    if (url == null || url.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(isActive ? 'Đang hoạt động' : 'Ngừng hoạt động'),
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
        child: Text('Chưa có danh mục nào', textAlign: TextAlign.center),
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
