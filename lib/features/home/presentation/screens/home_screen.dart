import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../category/data/models/category_model.dart';
import '../../../category/providers/category_provider.dart';
import '../../../notification/providers/notification_provider.dart';
import '../../../product/data/models/product_model.dart';
import '../../../product/providers/product_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<CategoryProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts(
        isFeatured: true,
        refresh: true,
      );
      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final displayName = user?.fullName?.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<CategoryProvider>().loadCategories(),
              context.read<ProductProvider>().loadProducts(
                isFeatured: true,
                refresh: true,
              ),
              context.read<NotificationProvider>().loadUnreadCount(),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  name: displayName == null || displayName.isEmpty
                      ? null
                      : displayName,
                  onSearchTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.productSearch);
                  },
                  onNotificationTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.notifications);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _PrescriptionBanner(),
                      const SizedBox(height: 22),
                      _QuickActions(
                        onPrescriptionTap: _showComingSoon,
                        onPharmacyTap: () {
                          Navigator.of(context).pushNamed(AppRoutes.pharmacies);
                        },
                      ),
                      const SizedBox(height: 28),
                      const _CategorySection(),
                      const SizedBox(height: 28),
                      const _FeaturedProductSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  final String? name;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name ?? 'An Tâm Pharma',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Thông báo',
                    onPressed: onNotificationTap,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppTheme.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tìm thuốc, triệu chứng, vitamin...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionBanner extends StatelessWidget {
  const _PrescriptionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppTheme.darkBlue, AppTheme.primaryBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'Tải đơn thuốc\nDược sĩ tư vấn miễn phí',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(Icons.local_pharmacy_outlined, color: Colors.white, size: 58),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPrescriptionTap,
    required this.onPharmacyTap,
  });

  final VoidCallback onPrescriptionTap;
  final VoidCallback onPharmacyTap;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        label: 'Gửi đơn thuốc',
        icon: Icons.upload_file_outlined,
        onTap: onPrescriptionTap,
      ),
      _QuickActionData(
        label: 'Tìm nhà thuốc',
        icon: Icons.storefront_outlined,
        onTap: onPharmacyTap,
      ),
      _QuickActionData(
        label: 'Theo dõi đơn hàng',
        icon: Icons.receipt_long_outlined,
        onTap: () => _showComingSoon(context),
      ),
      _QuickActionData(
        label: 'Tư vấn dược sĩ',
        icon: Icons.support_agent_outlined,
        onTap: () => _showComingSoon(context),
      ),
    ];

    return Row(
      children: actions
          .map((action) => Expanded(child: _QuickActionButton(data: action)))
          .toList(),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển')));
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(data.icon, color: AppTheme.primaryBlue, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Danh mục nổi bật'),
        const SizedBox(height: 14),
        if (provider.isLoading)
          const _InlineLoading()
        else if (provider.errorMessage != null)
          _InlineError(message: provider.errorMessage!)
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.categories.isEmpty
                  ? _fallbackCategories.length
                  : provider.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = provider.categories.isEmpty
                    ? _fallbackCategories[index]
                    : provider.categories[index];

                return _CategoryChip(
                  category: category,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.productList,
                      arguments: {'categoryId': category.id},
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: AppTheme.primaryBlue,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedProductSection extends StatelessWidget {
  const _FeaturedProductSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Sản phẩm nổi bật',
          actionLabel: 'Xem tất cả',
          onActionTap: () {
            Navigator.of(context).pushNamed(AppRoutes.productList);
          },
        ),
        const SizedBox(height: 14),
        if (provider.isLoading)
          const _InlineLoading()
        else if (provider.errorMessage != null && provider.products.isEmpty)
          _InlineError(message: provider.errorMessage!)
        else if (provider.products.isEmpty)
          const _InlineError(message: 'Chưa có sản phẩm nổi bật')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final product = provider.products[index];

              return _ProductCard(
                product: product,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.productDetail,
                    arguments: {'id': product.id},
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.lightBlue,
                    child: product.thumbnailUrl == null
                        ? const Icon(
                            Icons.medication_liquid_outlined,
                            color: AppTheme.primaryBlue,
                            size: 46,
                          )
                        : CachedNetworkImage(
                            imageUrl: product.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.medication_liquid_outlined,
                              color: AppTheme.primaryBlue,
                              size: 46,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (product.requiresPrescription) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Cần đơn thuốc',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CurrencyFormatter.format(product.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 19,
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
      ],
    );
  }
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.textSecondary),
      ),
    );
  }
}

const _fallbackCategories = [
  CategoryModel(id: 'prescription', name: 'Thuốc không kê đơn', slug: 'thuoc'),
  CategoryModel(
    id: 'supplement',
    name: 'Thực phẩm chức năng',
    slug: 'thuc-pham-chuc-nang',
  ),
  CategoryModel(
    id: 'personal-care',
    name: 'Chăm sóc cá nhân',
    slug: 'cham-soc-ca-nhan',
  ),
  CategoryModel(id: 'medical-device', name: 'Thiết bị y tế', slug: 'thiet-bi'),
];
