import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../data/models/category_model.dart';
import '../../providers/category_provider.dart';

class CategoryBrowserScreen extends StatefulWidget {
  const CategoryBrowserScreen({super.key});

  @override
  State<CategoryBrowserScreen> createState() => _CategoryBrowserScreenState();
}

class _CategoryBrowserScreenState extends State<CategoryBrowserScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CategoryProvider>();
      if (provider.categories.isEmpty && !provider.isLoading) {
        provider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCategory(CategoryModel category) {
    Navigator.of(context).pushNamed(
      AppRoutes.productList,
      arguments: {'categoryId': category.id, 'categoryName': category.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Danh mục')),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories
              .where((category) => category.isActive)
              .where(
                (category) => category.name.toLowerCase().contains(
                  _query.trim().toLowerCase(),
                ),
              )
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: provider.loadCategories,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tìm theo nhóm sản phẩm',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppTheme.darkBlue),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Chọn nhóm phù hợp để xem các sản phẩm đang có.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Tìm danh mục',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Xóa tìm kiếm',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading && provider.categories.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.errorMessage != null &&
                    provider.categories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _CategoryMessage(
                      icon: Icons.cloud_off_outlined,
                      message: provider.errorMessage!,
                      actionLabel: 'Thử lại',
                      onAction: provider.loadCategories,
                    ),
                  )
                else if (categories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _CategoryMessage(
                      icon: Icons.search_off_rounded,
                      message: _query.isEmpty
                          ? 'Chưa có danh mục sản phẩm.'
                          : 'Không tìm thấy danh mục phù hợp.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final category = categories[index];
                        return _CategoryCard(
                          category: category,
                          onTap: () => _openCategory(category),
                        );
                      }, childCount: categories.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.12,
                          ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appearance = _appearanceFor(category.name);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: appearance.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(
                  appearance.icon,
                  color: appearance.foreground,
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text(
                    'Xem sản phẩm',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

({IconData icon, Color background, Color foreground}) _appearanceFor(
  String name,
) {
  final normalized = name.toLowerCase();
  if (normalized.contains('vitamin') || normalized.contains('bổ')) {
    return (
      icon: Icons.spa_outlined,
      background: const Color(0xFFE8F5E9),
      foreground: const Color(0xFF2E7D32),
    );
  }
  if (normalized.contains('thiết bị') || normalized.contains('y tế')) {
    return (
      icon: Icons.medical_services_outlined,
      background: const Color(0xFFE3F2FD),
      foreground: AppTheme.primaryBlue,
    );
  }
  if (normalized.contains('chăm sóc') || normalized.contains('da')) {
    return (
      icon: Icons.face_retouching_natural_outlined,
      background: const Color(0xFFFFF3E0),
      foreground: const Color(0xFFEF6C00),
    );
  }
  return (
    icon: Icons.medication_outlined,
    background: const Color(0xFFEDE7F6),
    foreground: const Color(0xFF5E35B1),
  );
}
